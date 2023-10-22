class_name FadeDecorator
extends Node

signal fade_done
signal fade_out_done
signal fade_in_done

enum FadeType {
	OSCILLATE, FADE_OUT, FADE_IN
}

# should the effect automatically play when the parent node enters the scene?
@export var autostart := false
# what effect should play if autostarting
@export var autostart_effect_type := FadeType.OSCILLATE

# minimum transparency
@export var min_alpha := 0.0

# maximum opacity
@export var max_alpha := 1.0

# how fast the fade effect isq
@export var fade_speed := 0.5

# how long (if any) a fade out waits before signaling, or, if oscillating, fading in again
@export var fade_out_hangtime := 0.0

# how long (if any) a fade in waits before signaling, or, if oscillating, fading out again
@export var fade_in_hangtime := 0.0

enum _Direction { 
	IN, OUT
}

# if the fade is active
var _active := false 
# the type of fade being performed
var _fade_type := FadeType.OSCILLATE
# the current fade direction
var _fade_direction := _Direction.OUT

func _ready():
	if autostart:
		_fade_type = autostart_effect_type
		_active = true

func is_active():
	return _active

func fade_out():
	_fade_type = FadeType.FADE_OUT
	_fade_direction = _Direction.OUT
	_active = true

func fade_in():
	_fade_type = FadeType.FADE_IN
	_fade_direction = _Direction.IN
	_active = true

func oscillate():
	_fade_type = FadeType.OSCILLATE
	_active = true

func stop():
	_active = false

func _process(delta):
	if _active:
		var fade_delta = fade_speed * delta * (-1 if _fade_direction == _Direction.OUT else 1)
		get_parent().modulate.a += fade_delta
		
		if _fade_direction == _Direction.OUT and get_parent().modulate.a <= min_alpha:
			get_parent().modulate.a = min_alpha
			if _fade_type == FadeType.FADE_OUT:
				_active = false
				await Global.delay(fade_out_hangtime)
				emit_signal("fade_out_done")
				emit_signal("fade_done")
			else:
				_fade_direction = _Direction.IN
		elif _fade_direction == _Direction.IN and get_parent().modulate.a >= max_alpha:
			get_parent().modulate.a = max_alpha
			if _fade_type == FadeType.FADE_IN:
				_active = false
				await Global.delay(fade_in_hangtime)
				emit_signal("fade_in_done")
				emit_signal("fade_done")
			else:
				_fade_direction = _Direction.OUT
