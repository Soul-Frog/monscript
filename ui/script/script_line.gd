extends ScrollContainer

func add_block(block_type):
	var new_dropdown = load("res://ui/script/script_dropdown.tscn").instantiate()
	new_dropdown.name = "IF"
	new_dropdown.assign_type(block_type)
	new_dropdown.text_changed.connect(_on_dropdown_text_changed)
	$Line.add_child(new_dropdown)

func _is_each_dropdown_valid():
	for child in $Line.get_children():
		if child == $Line/GrowLineButton:
			continue
		if not child.is_valid():
			return false
	return true

func _last_dropdown():
	if $Line.get_children().size() == 1:
		return null
	return $Line.get_child($Line.get_children().size() - 2)

func _on_grow_line_button_pressed():
	var previous_dropdown = _last_dropdown()
	if previous_dropdown != null:
		add_block(previous_dropdown.next_block_type())
	else:
		add_block(ScriptData.Block.Type.IF)
	$Line/GrowLineButton.visible = false
	$Line.move_child($Line/GrowLineButton, $Line.get_children().size())

func _on_dropdown_text_changed():
	print("here")
	if _is_each_dropdown_valid() and _last_dropdown().next_block_type() != null:
		$Line/GrowLineButton.visible = true
	else:
		$Line/GrowLineButton.visible = false
