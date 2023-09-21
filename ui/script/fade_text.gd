extends Label

# how long in seconds the text is fully opaque before fading out again
const FULL_VISIBILITY_TIME = 1
var _time_before_fadeout = 0

@onready var FADE = $FadeDecorator

func _ready():
	modulate.a = 0 # make transparent

func flash():
	FADE.fade_in()

func _on_fade_decorator_in_fade_done():
	_time_before_fadeout = FULL_VISIBILITY_TIME

func _process(delta):
	if FADE.fade_type == FadeDecorator.FadeType.FADE_IN and not FADE.active:
		_time_before_fadeout = max(0, _time_before_fadeout - delta)
		if _time_before_fadeout == 0:
			FADE.fade_out()

func _on_fade_in_done():
	_time_before_fadeout = FULL_VISIBILITY_TIME
