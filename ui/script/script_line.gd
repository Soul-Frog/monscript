class_name ScriptLine
extends ScrollContainer

# emitted when the first block is created on this line
signal line_started

# emitted when the line is deleted
signal line_deleted

func _ready() -> void:
	_recolor_font($Line/GrowLineButton, Global.COLOR_GREEN)
	_recolor_font($Line/DeleteLineButton, Global.COLOR_RED)
	_update_controls()

func _recolor_font(node: Node, color: Color) -> void:
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_hover_color", color)
	node.add_theme_color_override("font_focus_color", color)
	node.add_theme_color_override("font_disabled_color", color)
	node.add_theme_color_override("font_pressed_color", color)

func _is_each_block_valid() -> bool:
	for child in $Line/Blocks.get_children():
		if child == $Line/GrowLineButton:
			continue
		if not child.is_valid():
			return false
	return true

func _last_block() -> ScriptBlock:
	if $Line/Blocks.get_children().size() == 0:
		return null
	return $Line/Blocks.get_child($Line/Blocks.get_children().size() - 1)

func _on_grow_line_button_pressed() -> void:
	var previous_block: ScriptBlock = _last_block()
	if previous_block != null:
		_add_block(previous_block.next_block_type())
	else:
		_add_block(ScriptData.Block.Type.IF)
		emit_signal("line_started")
	_update_controls()

func _add_block(block_type: ScriptData.Block.Type) -> void:
	var new_block: ScriptBlock = load("res://ui/script/script_block.tscn").instantiate()
	new_block.assign_type(block_type)
	new_block.text_changed.connect(_on_block_text_changed)
	$Line/Blocks.add_child(new_block)
	_update_controls()

func _on_delete_line_button_pressed() -> void:
	emit_signal("line_deleted", self)

func _on_block_text_changed() -> void:
	_update_controls()

func _update_controls() -> void:
	_update_grow_line_button()
	_update_delete_line_button()
	_update_validity_indicator()

func _update_validity_indicator() -> void:
	$Line/ValidityIndicator.visible = $Line/Blocks.get_children().size() != 0
	if not $Line/GrowLineButton.visible and _is_each_block_valid():
		$Line/ValidityIndicator.color = Global.COLOR_GREEN
	else:
		$Line/ValidityIndicator.color = Global.COLOR_RED

func _update_grow_line_button() -> void:
	if _last_block() == null or (_is_each_block_valid() and _last_block().next_block_type() != ScriptData.Block.Type.NONE):
		$Line/GrowLineButton.visible = true
	else:
		$Line/GrowLineButton.visible = false

func _update_delete_line_button() -> void:
	$Line/DeleteLineButton.visible = $Line/Blocks.get_children().size() != 0
