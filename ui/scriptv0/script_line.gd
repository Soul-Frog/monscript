extends ScrollContainer

# emitted when the first block is created on this line
signal line_started

# emitted when the line is deleted
signal line_deleted

# emitted whenever a block in this line is edited
signal line_edited

const UI_SCRIPT_BLOCK_SCENE = preload("res://ui/script/script_block.tscn")

func _ready() -> void:
	_recolor_font($Line/GrowLineButton, Global.COLOR_GREEN)
	_recolor_font($Line/DeleteLineButton, Global.COLOR_RED)
	_update_controls()

func import(line: ScriptData.Line):
	for block in line.blocks:
		var added_block: UIScriptBlock = _add_block(block.type)
		added_block.import(block)
	emit_signal("line_edited", self)
	assert(is_valid(), "Imported line is invalid?")

func export() -> String:
	var s := ""
	for i in range(0, $Line/Blocks.get_child_count()):
		if i != 0: # don't add delimiter to empty string; add after each element but last
			s += ScriptData.BLOCK_DELIMITER
		var block: UIScriptBlock = $Line/Blocks.get_child(i)
		s += block.export()
	return s

# returns if this is a fully complete and valid line
func is_valid():
	return _is_each_block_valid() and _last_block().next_block_type() == ScriptData.Block.Type.NONE

func _on_grow_line_button_pressed() -> void:
	var previous_block: UIScriptBlock = _last_block()
	if previous_block != null:
		_add_block(previous_block.next_block_type())
	else:
		_add_block(ScriptData.Block.Type.IF)
		emit_signal("line_started")
	_update_controls()

func _is_each_block_valid() -> bool:
	for child in $Line/Blocks.get_children():
		if child == $Line/GrowLineButton:
			continue
		if not child.is_valid():
			return false
	return true

func _add_block(block_type: ScriptData.Block.Type) -> UIScriptBlock:
	var new_block: UIScriptBlock = UI_SCRIPT_BLOCK_SCENE.instantiate()
	new_block.assign_type(block_type)
	new_block.text_changed.connect(_on_block_text_changed)
	$Line/Blocks.add_child(new_block)
	_update_controls()
	return new_block

func _last_block() -> UIScriptBlock:
	if $Line/Blocks.get_children().size() == 0:
		return null
	return $Line/Blocks.get_child($Line/Blocks.get_children().size() - 1)

func _on_delete_line_button_pressed() -> void:
	emit_signal("line_deleted", self)

func _on_block_text_changed() -> void:
	_update_controls()
	_try_shrink()
	emit_signal("line_edited", self)

func _update_controls() -> void:
	_update_grow_line_button()
	_update_delete_line_button()
	_update_validity_indicator()

# Checks if the line needs to be shrunk, and shrinks if needed
# The case where this happens is if the middle (DO) block changes
# from a block with a TO to a block without a TO.
func _try_shrink() -> void:
	for i in range(0, $Line/Blocks.get_child_count() - 1):
		var block: UIScriptBlock = $Line/Blocks.get_child(i) 
		# if this block is valid and has no next block, delete all remaining blocks
		if block.is_valid() and block.next_block_type() == ScriptData.Block.Type.NONE:
			for j in range(i+1, $Line/Blocks.get_child_count()):
				$Line/Blocks.get_child(j).queue_free()
			break # don't loop over deleted blocks

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

func _recolor_font(node: Node, color: Color) -> void:
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_hover_color", color)
	node.add_theme_color_override("font_focus_color", color)
	node.add_theme_color_override("font_disabled_color", color)
	node.add_theme_color_override("font_pressed_color", color)
