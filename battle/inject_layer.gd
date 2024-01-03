extends Node2D

signal inject_completed

enum InjectState {
	INACTIVE, SELECT_MON, SELECT_DO, SELECT_TARGET, EXECUTING
}

const SELECTED_DO_POSITION = Vector2(160, 5)
const PLAYER_INJECT_SCENE = preload("res://battle/player_inject_target.tscn")
const COMPUTER_INJECT_SCENE = preload("res://battle/computer_inject_target.tscn")
const BLOCK_SCENE = preload("res://ui/script/script_block.tscn")
@onready var _player_targets = $PlayerTargets
@onready var _do_blocks = $DoBlocks
@onready var _computer_targets = $ComputerTargets
var _target_to_mon = {}

var _inject_state = InjectState.INACTIVE

var _injected_mon: BattleMon = null
var _do_block: ScriptData.Block = null
var _ui_do_block: UIScriptBlock = null
var _target: BattleMon = null

var _log: BattleLog
var _animator: BattleAnimator
var _friends
var _foes

func _ready():
	assert(_player_targets)
	assert(_do_blocks)
	assert(_computer_targets)
	#self.modulate.a = 0
	_player_targets.hide()
	_computer_targets.hide()

func is_injecting() -> bool:
	return _inject_state != InjectState.INACTIVE

func start_inject(blog: BattleLog, animator: BattleAnimator, player_mons: Array, computer_mons: Array) -> void:
	_friends = player_mons
	_foes = computer_mons
	_animator = animator
	_log = blog
	assert(_friends)
	assert(_foes)
	assert(_animator)
	assert(_log)
	_log.add_text("Launching code injection!")
	
	_target_to_mon.clear()
	_injected_mon = null
	_do_block = null
	_target = null
	
	# show only the player targets
	_update_inject_state(InjectState.SELECT_MON)
	_computer_targets.hide()
	_player_targets.show()
	
	var create_targets := func(mons, target_scene, add_to, callback):
		for mon in mons:
			if not mon.is_defeated():
				var target = target_scene.instantiate()
				target.position = mon.position - target.texture_unselected.get_size()/2
				_target_to_mon[target] = mon
				target.button_selected.connect(callback)
				target.modulate.a = 0
				create_tween().tween_property(target, "modulate:a", 1, 0.2)
				add_to.add_child(target)
	
	create_targets.call(player_mons, PLAYER_INJECT_SCENE, _player_targets, _on_player_target_selected)
	create_targets.call(computer_mons, COMPUTER_INJECT_SCENE, _computer_targets, _on_computer_target_selected)

func _on_player_target_selected() -> void:
	if _inject_state != InjectState.SELECT_MON:
		return #ignore clicks on target while we should be selecting do/target
	
	# hide each other player select target
	for i in _player_targets.get_child_count():
		var target = _player_targets.get_child(i)
		if target.selected:
			_injected_mon = _target_to_mon[target]
		else:
			target.hide()
	assert(_injected_mon)
	
	_create_do_blocks()
	
	_update_inject_state(InjectState.SELECT_DO)

func _create_do_blocks():
	assert(_injected_mon)
	
	var doBlocks = _injected_mon.underlying_mon.get_possible_do_blocks() + [ScriptData.get_block_by_name("Escape")]
	var top = _injected_mon.position.y - doBlocks.size() * 8
	for i in doBlocks.size():
		var doBlock = doBlocks[i]
		var block = BLOCK_SCENE.instantiate()
		block.set_data(ScriptData.Block.Type.DO, doBlock.name, false)
		block.position = _injected_mon.position + Vector2(0, -8)
		block.modulate.a = 0
		block.clicked.connect(_on_do_block_selected)
		
		var tween = create_tween()
		var ending_position = Vector2(block.position.x + 15, top + i*16)
		tween.tween_property(block, "position", ending_position, 0.3).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(block, "modulate:a", 1, 0.15)
		
		_do_blocks.add_child(block)

func _on_do_block_selected(selected_block) -> void:
	if _inject_state != InjectState.SELECT_DO:
		return #ignore clicks on do while we should be selecting do/target
	
	# remove the other _do_blocks
	for block in _do_blocks.get_children():
		if block != selected_block:
			var tween = create_tween()
			tween.tween_property(block, "modulate:a", 0, 0.2)
			tween.tween_callback(block.queue_free)
	
	_ui_do_block = selected_block
	_do_block = selected_block.to_block()
	
	var tween = create_tween()
	tween.tween_property(selected_block, "position", SELECTED_DO_POSITION - Vector2(selected_block.size.x/2, 0), 0.3).set_trans(Tween.TRANS_CUBIC)
	
	# if this block needs a target, initiate that
	if selected_block.to_block().next_block_type == ScriptData.Block.Type.TO:
		_computer_targets.show()
		_update_inject_state(InjectState.SELECT_TARGET)
	else: # otherwise, wait for the block to reach the top for visual effect, then perform the inject
		await tween.finished
		_perform_inject()

func _on_computer_target_selected() -> void:
	if _inject_state != InjectState.SELECT_TARGET:
		return #ignore clicks on target while we should be executing
	
	# hide all other computer targets
	for i in _computer_targets.get_child_count():
		var target = _computer_targets.get_child(i)
		if target.selected:
			_target = _target_to_mon[target]
		else:
			target.hide()
	assert(_target)
	
	_perform_inject()

func _perform_inject() -> void:
	assert(_injected_mon)
	assert(_do_block)
	assert(_target or _do_block.next_block_type == ScriptData.Block.Type.NONE)
	
	_update_inject_state(InjectState.EXECUTING)
	
	# fade out the block
	var to_fade_out = _do_blocks.get_children() + _player_targets.get_children() + _computer_targets.get_children()
	for node in to_fade_out:
		var tween = create_tween()
		tween.tween_property(node, "modulate:a", 0, 0.125)
		tween.tween_callback(node.queue_free)
	
	# perform the inject action
	await _injected_mon.take_inject_action(_friends, _foes, _animator, _do_block, _target)
	
	end_inject()

func end_inject() -> void:
	_log.add_text("Code injection complete!")
	_update_inject_state(InjectState.INACTIVE)
	
	#var tween = create_tween() # fade out
	#tween.tween_property(self, "modulate:a", 0, 0.1)
	
	emit_signal("inject_completed")

func _update_inject_state(new_state: InjectState):
	_inject_state = new_state
	match _inject_state:
		InjectState.SELECT_MON:
			_log.add_text("Selecting mon to inject...")
		InjectState.SELECT_DO:
			_log.add_text("Selecting code fragment...")
		InjectState.SELECT_TARGET:
			_log.add_text("Selecting target mon...")
		InjectState.EXECUTING:
			_log.add_text("Executing code injection!")

func _undo() -> void:
	if _inject_state == InjectState.SELECT_DO:
		for target in _player_targets.get_children():
			target.show()
			target.unselect()
		for block in _do_blocks.get_children():
			block.queue_free()
		_injected_mon = null
		_update_inject_state(InjectState.SELECT_MON)
	elif _inject_state == InjectState.SELECT_TARGET:
		_computer_targets.hide()
		for block in _do_blocks.get_children():
			block.queue_free()
		_do_block = null
		_create_do_blocks()
		_update_inject_state(InjectState.SELECT_DO)

func _input(event) -> void:
	if Input.is_action_just_pressed("inject_undo") and is_injecting():
		_undo()
