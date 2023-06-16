class_name ScriptUI
extends ScrollContainer

func _ready() -> void:
	_add_new_line()

func _add_new_line() -> void:
	var line: ScriptLine = load("res://ui/script/script_line.tscn").instantiate()
	line.line_started.connect(_on_line_started)
	line.line_deleted.connect(_on_line_deleted)
	$Lines.add_child(line)

func _on_line_started() -> void:
	_add_new_line()

func _on_line_deleted(line: ScriptLine) -> void:
	line.queue_free()
	$Lines.remove_child(line)
	if $Lines.get_child_count() == 0:
		_add_new_line()
