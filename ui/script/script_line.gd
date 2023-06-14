extends ScrollContainer

func _ready():
	_recolor_font($Line/GrowLineButton, Global.COLOR_GREEN)
	_recolor_font($Line/DeleteLineButton, Global.COLOR_RED)
	_update_controls()

func _recolor_font(node, color):
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_hover_color", color)
	node.add_theme_color_override("font_focus_color", color)
	node.add_theme_color_override("font_disabled_color", color)
	node.add_theme_color_override("font_pressed_color", color)

func _is_each_dropdown_valid():
	for child in $Line/Blocks.get_children():
		if child == $Line/GrowLineButton:
			continue
		if not child.is_valid():
			return false
	return true

func _last_dropdown():
	if $Line/Blocks.get_children().size() == 0:
		return null
	return $Line/Blocks.get_child($Line/Blocks.get_children().size() - 1)

func _on_grow_line_button_pressed():
	var previous_dropdown = _last_dropdown()
	if previous_dropdown != null:
		_add_block(previous_dropdown.next_block_type())
	else:
		_add_block(ScriptData.Block.Type.IF)
	_update_controls()

func _add_block(block_type):
	var new_dropdown = load("res://ui/script/script_dropdown.tscn").instantiate()
	new_dropdown.name = "IF"
	new_dropdown.assign_type(block_type)
	new_dropdown.text_changed.connect(_on_dropdown_text_changed)
	$Line/Blocks.add_child(new_dropdown)
	_update_controls()

func _on_delete_line_button_pressed():
	for child in $Line/Blocks.get_children():
		$Line/Blocks.remove_child(child)
		child.queue_free()
	_update_controls()

func _on_dropdown_text_changed():
	_update_controls()

func _update_controls():
	_update_grow_line_button()
	_update_delete_line_button()
	_update_validity_indicator()

func _update_validity_indicator():
	$Line/ValidityIndicator.visible = $Line/Blocks.get_children().size() != 0
	if not $Line/GrowLineButton.visible and _is_each_dropdown_valid():
		$Line/ValidityIndicator.color = Global.COLOR_GREEN
	else:
		$Line/ValidityIndicator.color = Global.COLOR_RED

func _update_grow_line_button():
	if _last_dropdown() == null or (_is_each_dropdown_valid() and _last_dropdown().next_block_type() != ScriptData.Block.Type.NONE):
		$Line/GrowLineButton.visible = true
	else:
		$Line/GrowLineButton.visible = false

func _update_delete_line_button():
	$Line/DeleteLineButton.visible = $Line/Blocks.get_children().size() != 0
	
