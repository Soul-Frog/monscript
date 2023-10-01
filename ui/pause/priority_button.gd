# a button which increases its z_index to the front when moused over
extends Button

func _on_mouse_exited():
	z_index = 0

func _on_mouse_entered():
	z_index = 100
