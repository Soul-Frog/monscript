class_name UIScriptMenu
extends VBoxContainer

# emitted when this menu should be closed
signal closed

var monEdited: MonData.Mon

func setup(mon: MonData.Mon) -> void:
	self.monEdited = mon
	
	$MenuBar/Left/MonNameLabel.text = mon.get_name()
	
	# clear previous data
	for line in $Window/Lines.get_children():
		line.queue_free()
	
	var script: ScriptData.MonScript = mon.get_monscript()
	_import(script)

func _add_new_line() -> UIScriptLine:
	var line: UIScriptLine = load("res://ui/script/script_line.tscn").instantiate()
	line.line_started.connect(_on_line_started)
	line.line_deleted.connect(_on_line_deleted)
	line.line_edited.connect(_on_line_edited)
	$Window/Lines.add_child(line)
	return line
	
func _on_line_started() -> void:
	_add_new_line()

func _on_line_deleted(line: UIScriptLine) -> void:
	line.queue_free()
	$Window/Lines.remove_child(line)
	if $Window/Lines.get_child_count() == 0:
		_add_new_line()
	$MenuBar/Middle/Save.disabled = not line.is_valid()

func _on_line_edited(line: UIScriptLine):
	$MenuBar/Middle/Save.disabled = not line.is_valid()

func _export_script_to_mon() -> void:
	#insert header
	var script_str := ScriptData.SCRIPT_START
	
	#insert lines
	for line in $Window/Lines.get_children():
		script_str += ScriptData.LINE_DELIMITER
		script_str += line.export()
	
	#insert footer
	script_str += ScriptData.LINE_DELIMITER + ScriptData.SCRIPT_END
	
	#parse as a script
	var script: ScriptData.MonScript = ScriptData.MonScript.new(script_str)
	
	monEdited.set_monscript(script)

func _import(script: ScriptData.MonScript) -> void:
	for line in script.lines:
		var new_line: UIScriptLine = _add_new_line()
		new_line.import(line)

func _on_save_pressed() -> void:
	_export_script_to_mon()
	emit_signal("closed")

func _on_exit_pressed() -> void:
	emit_signal("closed")
