extends Control

signal selection_made

func _on_yes_button_pressed():
	hide()
	emit_signal("selection_made", true)

func _on_no_button_pressed():
	hide()
	emit_signal("selection_made", false)
