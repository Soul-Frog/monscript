extends Node

var _mouse_over := false

func _ready():
	get_parent().mouse_entered.connect(_on_mouse_entered)
	get_parent().mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_mouse_over = true

func _on_mouse_exited() -> void:
	_mouse_over = false

# returns whether the mouse is over the parent control
func mouse_over() -> bool:
	return _mouse_over
