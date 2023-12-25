extends Node2D

signal inject_completed

enum InjectState {
	INACTIVE, SELECT_MON, SELECT_DO, SELECT_TARGET, EXECUTING
}

const INJECT_SCENE = preload("res://battle/inject_target.tscn")
@onready var _player_targets = $PlayerTargets
@onready var _computer_targets = $ComputerTargets
var _target_to_mon = {}

var _inject_state = InjectState.INACTIVE
var _log: BattleLog

var _injected_mon = null
var _do_block = null
var _target = null

func _ready():
	assert(_player_targets)
	assert(_computer_targets)
	self.modulate.a = 0
	_player_targets.hide()
	_computer_targets.hide()

func is_injecting() -> bool:
	return _inject_state != InjectState.INACTIVE

func start_inject(battle_log: BattleLog, player_mons: Array, computer_mons: Array) -> void:
	_injected_mon = null
	_do_block = null
	_target = null
	
	_log = battle_log
	_log.add_text("Launching code injection!")
	
	# show only the player targets
	_update_inject_state(InjectState.SELECT_MON)
	_computer_targets.hide()
	_player_targets.show()
	
	# delete all existing targets
	for target in _player_targets.get_children() + _computer_targets.get_children():
		target.queue_free()
	# and clear the map
	_target_to_mon.clear()
	
	var create_targets := func(mons, add_to, callback):
		for mon in mons:
			if not mon.is_defeated():
				var target = INJECT_SCENE.instantiate()
				target.position = mon.position - target.texture_unselected.get_size()/2
				_target_to_mon[target] = mon
				target.button_selected.connect(callback)
				add_to.add_child(target)
	
	create_targets.call(player_mons, _player_targets, _on_player_target_selected)
	create_targets.call(computer_mons, _computer_targets, _on_computer_target_selected)
	
	var tween = create_tween() # fade in
	tween.tween_property(self, "modulate:a", 1, 0.2)
	

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
	
	# tween them out to the center in a list
	# iterate over inject mon's do blocks...
	
	_update_inject_state(InjectState.SELECT_DO)

func _on_do_block_selected() -> void:
	if _inject_state != InjectState.SELECT_DO:
		return #ignore clicks on do while we should be selecting do/target
	
	# if there is no target for this do, just perform it?
	# _perform_inject()
	# end_inject()
	# else:
	
	_computer_targets.show()
	
	_update_inject_state(InjectState.SELECT_TARGET)

func _on_computer_target_selected() -> void:
	if _inject_state != InjectState.SELECT_TARGET:
		return #ignore clicks on target while we should be executing
	
	# hide all other computer targets
	for i in _computer_targets.get_child_count():
		var target = _player_targets.get_child(i)
		if target.selected:
			_target = _target_to_mon[target]
		else:
			target.hide()
	assert(_target)
	
	_perform_inject()

func _perform_inject() -> void:
	assert(_injected_mon)
	assert(_do_block)
	assert(_target)
	
	_update_inject_state(InjectState.EXECUTING)
	
	
	
	# TODO perform the specified actions
	
	end_inject()

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
		_update_inject_state(InjectState.SELECT_MON)
	elif _inject_state == InjectState.SELECT_TARGET:
		#todo
		pass

func end_inject() -> void:
	_log.add_text("Code injection complete!")
	_update_inject_state(InjectState.INACTIVE)
	
	var tween = create_tween() # fade out
	tween.tween_property(self, "modulate:a", 1, 0.2)
	
	emit_signal("inject_completed")

func _input(event) -> void:
	if Input.is_action_just_pressed("inject_undo") and is_injecting():
		_undo()
