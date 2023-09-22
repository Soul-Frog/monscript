class_name FadeDecorator
extends Node

signal fade_done
signal fade_out_done
signal fade_in_done

enum FadeType {
	OSCILLATE, FADE_OUT, FADE_IN
}

# whether this effect is currently changing alpha; set to false after completing a fade
@export var active := true 

# behavior of the fade
@export var fade_type := FadeType.OSCILLATE

# minimum transparency
@export var min_alpha := 0.0

# maximum opacity
@export var max_alpha := 1.0

# how fast the fade effect is
@export var fade_speed := 0.5

# how long (if any) a fade out waits before signaling, or, if oscillating, fading in again
@export var fade_out_hangtime := 0.0

# how long (if any) a fade in waits before signaling, or, if oscillating, fading out again
@export var fade_in_hangtime := 0.0

enum _Direction { 
	IN, OUT
}

var _fade_direction := _Direction.OUT

func _ready():
	if fade_type == FadeType.FADE_IN:
		get_parent().modulate.a = min_alpha
		_fade_direction = _Direction.IN
	elif fade_type == FadeType.FADE_OUT:
		get_parent().modulate.a = max_alpha
		_fade_direction = _Direction.OUT

func fade_out():
	fade_type = FadeType.FADE_OUT
	active = true

func fade_in():
	fade_type = FadeType.FADE_IN
	active = true

func oscillate():
	fade_type = FadeType.OSCILLATE
	active = true

func _process(delta):
	if active:
		var fade_delta = fade_speed * delta * (-1 if _fade_direction == _Direction.OUT else 1)
		get_parent().modulate.a += fade_delta
		
		if _fade_direction == _Direction.OUT and get_parent().modulate.a <= min_alpha:
			get_parent().modulate.a = min_alpha
			if fade_type == FadeType.FADE_OUT:
				active = false
				await Global.delay(fade_out_hangtime)
				emit_signal("fade_out_done")
				emit_signal("fade_done")
			else:
				_fade_direction = _Direction.IN
		elif _fade_direction == _Direction.IN and get_parent().modulate.a >= max_alpha:
			get_parent().modulate.a = max_alpha
			if fade_type == FadeType.FADE_IN:
				active = false
				await Global.delay(fade_in_hangtime)
				emit_signal("fade_in_done")
				emit_signal("fade_done")
			else:
				_fade_direction = _Direction.OUT
