class_name ForegroundElement
extends Sprite2D

@onready var _FADE = $FadeDecorator

func _on_fade_zone_body_entered(body):
	if body is PlayerPlatformer or body is PlayerOverhead:
		_FADE.fade_out()

func _on_fade_zone_body_exited(body):
	if body is PlayerPlatformer or body is PlayerOverhead:
		_FADE.fade_in()
