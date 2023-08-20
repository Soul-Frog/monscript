extends Node

enum FadeType {
	OSCILLATE, ONESHOT_FADE_OUT, ONESHOT_FADE_IN
}

@export var _fade_type = FadeType.OSCILLATE
@export var _min_alpha = 0
@export var _max_alpha = 1
@export var _fade_speed = 0.1

static var global_alpha = 1

enum Direction { 
	IN, OUT
}

var _fade_direction = Direction.OUT

var _done = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if _fade_type == FadeType.ONESHOT_FADE_IN:
		get_parent().modulate.a = 0
		_fade_direction = Direction.IN
	elif _fade_type == FadeType.ONESHOT_FADE_OUT:
		get_parent().modulate.a = 1
		_fade_direction = Direction.OUT
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not _done:
		var fade_delta = _fade_speed * delta * (-1 if _fade_direction == Direction.OUT else 1)
		get_parent().modulate.a += fade_delta
		
		if _fade_direction == Direction.OUT and get_parent().modulate.a <= _min_alpha:
			if _fade_type == FadeType.ONESHOT_FADE_OUT:
				_done = true
			else:
				_fade_direction = Direction.IN
		elif _fade_direction == Direction.IN and get_parent().modulate.a >= _max_alpha:
			if _fade_type == FadeType.ONESHOT_FADE_IN:
				_done = true
			else:
				_fade_direction = Direction.OUT
