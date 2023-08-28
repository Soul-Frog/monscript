extends MarginContainer

signal clicked

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and $Indicator.get_global_rect().has_point(event.position):
		emit_signal("clicked", self)
