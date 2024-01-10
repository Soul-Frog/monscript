class_name BattleScriptLineViewer
extends HBoxContainer

# extra delay added after showing a line before the line fades out
const DELAY_AFTER_SHOWING = 0.7

var _BLOCK_SCENE = preload("res://ui/script/script_block.tscn")
var _LINE_SCENE = preload("res://ui/script/script_line.tscn")
var _line

var _speed_scale := 1.0
var _active_tweens = []

func _ready():
	assert(get_child_count() == 0)
	reset()

func reset():
	for child in get_children():
		child.queue_free()

func show_block(block: ScriptData.Block) -> void:
	# if we're already showing a line, immediately hide it
	if _line != null:
		_line.hide()
	
	_line = _BLOCK_SCENE.instantiate() as UIScriptBlock
	add_child(_line)
	
	_line.set_data(block.type, block.name, false)
	
	_fade_in()

func show_line(lineNumber: int, ifBlock: ScriptData.Block, doBlock: ScriptData.Block, toBlock: ScriptData.Block) -> void:
	# if we're already showing a line, immediately hide it
	if _line != null:
		_line.hide()
	
	_line = _LINE_SCENE.instantiate() as UIScriptLine
	add_child(_line)
	
	_line.set_line_number(lineNumber)
	
	if ifBlock:
		var uiIf: UIScriptBlock = _BLOCK_SCENE.instantiate()
		uiIf.set_data(ScriptData.Block.Type.IF, ifBlock.name, false)
		_line.add_block(uiIf)
	if doBlock:
		var uiDo: UIScriptBlock = _BLOCK_SCENE.instantiate()
		uiDo.set_data(ScriptData.Block.Type.DO, doBlock.name, false)
		_line.add_block(uiDo)
	if toBlock:
		var uiTo: UIScriptBlock = _BLOCK_SCENE.instantiate()
		uiTo.set_data(ScriptData.Block.Type.TO, toBlock.name, false)
		_line.add_block(uiTo)
	
	# disable clicking on the line
	_line.disable_editing()
	
	_fade_in()

func _fade_in():
	assert(_line)
	_line.modulate.a = 0
	var tween = create_tween()
	tween.set_speed_scale(_speed_scale)
	tween.tween_property(_line, "modulate:a", 1.0, 0.1)
	_active_tweens.append(tween)

func hide_line() -> void:
	assert(_line)
	
	var to_delete = _line
	
	await Global.delay(DELAY_AFTER_SHOWING)
	
	if not _line:
		return # might have been deleted by now
	
	# fade out the line
	var tween = create_tween()
	tween.set_speed_scale(_speed_scale)
	tween.tween_property(_line, "modulate:a", 0.0, 0.1)
	_active_tweens.append(tween)
	
	# delete after fading out
	await tween.finished
	remove_child(to_delete)
	to_delete.queue_free()

func set_speed_scale(speed_scale: float) -> void:
	_speed_scale = speed_scale
	var invalid_tweens = []
	for tween in _active_tweens:
		if not tween.is_valid():
			invalid_tweens.append(tween)
			continue
		tween.set_speed_scale(speed_scale)
	
	for invalid_tween in invalid_tweens:
		_active_tweens.erase(invalid_tween)
