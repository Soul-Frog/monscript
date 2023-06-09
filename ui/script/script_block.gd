class_name UIScriptBlock
extends Control

signal text_changed

var options := ["ERROR"]
var type: ScriptData.Block.Type

# whether this block was valid at one point in time or not
var was_once_valid := false

func assign_type(block_type: ScriptData.Block.Type) -> void:
	type = block_type
	
	# get the list of blocks to be added as options
	var block_list := []
	match type:
		ScriptData.Block.Type.IF:
			block_list = ScriptData.IF_BLOCK_LIST
		ScriptData.Block.Type.DO:
			block_list = ScriptData.DO_BLOCK_LIST
		ScriptData.Block.Type.TO:
			block_list = ScriptData.TO_BLOCK_LIST
		_:
			assert(false, "No match found for block_type!")
	
	options.clear()
	
	# add each block's name to options
	for block in block_list:
		assert(block.type == type, "Types don't match!")
		options.append(block.name)
	assert(options.size() != 0, "No options for script dropdown!")
	
	_update_intellisense()

func _ready() -> void:
	$CanvasLayer/Intellisense.visible = false

func import(block: ScriptData.Block) -> void:
	$TextEdit.text = block.as_string()
	$TextEdit.emit_signal("text_changed")
	assert(is_valid(), "Imported block is invalid?")

func export() -> String:
	return $TextEdit.text

func _on_intellisense_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	var selected_suggestion = $CanvasLayer/Intellisense.get_item_text(index)
	$TextEdit.text = selected_suggestion
	$TextEdit.emit_signal("text_changed")
	$CanvasLayer/Intellisense.visible = false

func _has_prefix(prefix: String, s: String) -> bool:
	if prefix.length() > s.length():
		return false
	for i in range(0, prefix.length()):
		if prefix[i] != s[i]:
			return false
	return true

const EXCLUDED_KEYS := [KEY_SPACE, KEY_TAB, KEY_ENTER]
func _input(event: InputEvent) -> void:
	# block space and enter inputs to TextEdit
	if $TextEdit.has_focus():
		if event is InputEventKey and event.is_pressed():
			if event.keycode in EXCLUDED_KEYS:
				get_viewport().set_input_as_handled()

func _on_text_changed() -> void:
	emit_signal("text_changed")
	_update_intellisense()
	if is_valid():
		was_once_valid = true
		$TextEdit.add_theme_color_override("font_color", Global.COLOR_GREEN)
	else:
		# if we were valid in the past, make it red now
		if was_once_valid:
			$TextEdit.add_theme_color_override("font_color", Global.COLOR_RED)
		else:
			$TextEdit.remove_theme_color_override("font_color")

func _update_intellisense() -> void:
	if(get_parent() != null): # horrible terrible hack
		var translate = get_parent().position + self.position + Vector2(0, 33)
		$CanvasLayer.transform = Transform2D(Vector2(1, 0), Vector2(0, 1), translate)
	
	$CanvasLayer/Intellisense.clear()
	for option in options:
		if _has_prefix($TextEdit.text.to_lower(), option.to_lower()):
			$CanvasLayer/Intellisense.add_item(option)
	
	if $CanvasLayer/Intellisense.item_count != 0:
			$CanvasLayer/Intellisense.visible = true
	
	if $TextEdit.text.length() == 0 or is_valid():
		$CanvasLayer/Intellisense.visible = false

func is_valid() -> bool:
	for option in options:
		if option.to_lower() == $TextEdit.text.to_lower():
			$TextEdit.text = option
			$TextEdit.set_caret_column($TextEdit.text.length())
			return true
	return false

func next_block_type() -> ScriptData.Block.Type:
	var block = ScriptData.get_block_by_name($TextEdit.text)
	if block == null:
		return ScriptData.Block.Type.NONE
	return block.next_block_type

func _on_text_edit_focus_exited():
	# don't close intellisense if we're clicking on it... otherwise close it
	if not $CanvasLayer/Intellisense.get_rect().has_point(get_local_mouse_position()):
		$CanvasLayer/Intellisense.visible = false

func _on_text_edit_focus_entered():
	_update_intellisense()
