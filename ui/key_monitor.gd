extends Node

signal key_down
signal key_up

var keymap = []

func _input(event):
	if event is InputEventKey and not event.is_echo():
		var s = OS.get_keycode_string(event.keycode)
		if not s in keymap: #key down
			keymap.append(s)
			emit_signal("key_down", s)
		else:
			keymap.erase(s)
			emit_signal("key_up", s)
