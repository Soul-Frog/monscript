class_name ScriptUI
extends VBoxContainer

signal exited
signal saved

func _ready() -> void:
	_add_new_line()

func _add_new_line() -> void:
	var line: ScriptLine = load("res://ui/script/script_line.tscn").instantiate()
	line.line_started.connect(_on_line_started)
	line.line_deleted.connect(_on_line_deleted)
	line.line_edited.connect(_on_line_edited)
	$Window/Lines.add_child(line)
	
func _on_line_started() -> void:
	_add_new_line()

func _on_line_deleted(line: ScriptLine) -> void:
	line.queue_free()
	$Window/Lines.remove_child(line)
	if $Window/Lines.get_child_count() == 0:
		_add_new_line()
	$MenuBar/Middle/Save.disabled = not line.is_valid()

func _on_line_edited(line: ScriptLine):
	$MenuBar/Middle/Save.disabled = not line.is_valid()

func _export_script() -> ScriptData.MonScript:
	return null

func import_script(script: ScriptData.MonScript) -> void:
	pass
	
func _on_save_pressed():
	#TODO assert script is valid
	emit_signal("saved", _export_script())

func _on_exit_pressed():
	emit_signal("exited")
