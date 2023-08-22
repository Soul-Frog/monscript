class_name FadeDecorator
extends Node

signal fade_done

enum FadeType {
	OSCILLATE, FADE_OUT, FADE_IN
}

@export var active = true # if this decorator should be playing. After completion, this is set to false.
@export var fade_type = FadeType.OSCILLATE
@export var min_alpha = 0.0
@export var max_alpha = 1.0
@export var fade_speed = 0.5


enum _Direction { 
	IN, OUT
}

var _fade_direction = _Direction.OUT

# Called when the node enters the scene tree for the first time.
func _ready():
	if fade_type == FadeType.FADE_IN:
		get_parent().modulate.a = min_alpha
		_fade_direction = _Direction.IN
	elif fade_type == FadeType.FADE_OUT:
		get_parent().modulate.a = max_alpha
		_fade_direction = _Direction.OUT

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if active:
		var fade_delta = fade_speed * delta * (-1 if _fade_direction == _Direction.OUT else 1)
		get_parent().modulate.a += fade_delta
		
		print("fadein" if _fade_direction == _Direction.IN else "fadeout")
		print(get_parent().modulate.a)
		
		if _fade_direction == _Direction.OUT and get_parent().modulate.a <= min_alpha:
			get_parent().modulate.a = min_alpha
			if fade_type == FadeType.FADE_OUT:
				emit_signal("fade_done")
				active = false
			else:
				_fade_direction = _Direction.IN
		elif _fade_direction == _Direction.IN and get_parent().modulate.a >= max_alpha:
			get_parent().modulate.a = max_alpha
			if fade_type == FadeType.FADE_IN:
				emit_signal("fade_done")
				active = false
			else:
				_fade_direction = _Direction.OUT
