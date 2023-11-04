class_name ForegroundElement
extends Sprite2D

@onready var _FADE = $FadeDecorator

# TODO - figure out if I really want these fades or not...

func _on_fade_zone_body_entered(body):
	return
	if body is Player:
		_FADE.fade_out()

func _on_fade_zone_body_exited(body):
	return
	if body is Player:
		_FADE.fade_in()
