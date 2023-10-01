extends Button

func _on_mouse_exited():
	z_index = 0

func _on_mouse_entered():
	z_index = 1
