class_name Wave
extends StaticBody2D

@export var _SPEED = 120
var _top = null
var _bottom = null

func set_top(top: float) -> void:
	_top = top

func set_bottom(bottom: float) -> void:
	_bottom = bottom

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.y += _SPEED * delta
	
	if position.y >= _bottom:
		position.y = _top
