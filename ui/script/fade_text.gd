extends Label

@onready var FADE_DECORATOR = preload("res://decorators/fade_decorator.tscn")

# how long in seconds the text is fully opaque before fading out again
const FULL_VISIBILITY_TIME = 1
var _time_before_fadeout = 0

func _ready():
	modulate.a = 0 # make transparent

func flash():
	$FadeDecoratorIn.active = true
	$FadeDecoratorOut.active = false

func _on_fade_decorator_in_fade_done():
	_time_before_fadeout = FULL_VISIBILITY_TIME

func _process(delta):
	if not $FadeDecoratorIn.active and modulate.a != 0:
		_time_before_fadeout = max(0, _time_before_fadeout - delta)
		if _time_before_fadeout == 0:
			$FadeDecoratorOut.active = true
