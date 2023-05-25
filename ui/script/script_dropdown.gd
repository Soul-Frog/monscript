extends Node2D

var options = ["Test", "Exam", "Trial"]

func _ready():
	for option in options:
		$Intellisense.add_item(option)
	$Intellisense.visible = false

func _on_dropdown_button_clicked():
	$Intellisense.visible = not $Intellisense.visible

func _on_intellisense_item_clicked(index, at_position, mouse_button_index):
	var selected_suggestion = $Intellisense.get_item_text(index)
	$TextEdit.text = selected_suggestion
	$TextEdit.emit_signal("text_changed")
	$Intellisense.visible = false

func _has_prefix(prefix, s):
	if prefix.length() > s.length():
		return false
	for i in range(0, prefix.length()):
		if prefix[i] != s[i]:
			return false
	return true

func _on_text_changed():
	$Intellisense.clear()
	for option in options:
		if _has_prefix($TextEdit.text.to_lower(), option.to_lower()):
			$Intellisense.add_item(option)
	if $Intellisense.item_count != 0:
			$Intellisense.visible = true
	
	if $TextEdit.text.length() == 0:
		$Intellisense.visible = false
