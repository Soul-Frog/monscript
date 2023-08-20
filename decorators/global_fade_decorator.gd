extends Node

static var _global_alpha := 1.0
static var _instance_count = 0
static var _process_counter = 0
static var _process_til_update = 1

# in the future, if needed, could have multiple different speeds
# and an export enum to represent diff speeds.
const SPEED := 2.0
const MIN_ALPHA = 0.3
const MAX_ALPHA = 1

enum Direction { 
	IN, OUT
}

var _fade_direction = Direction.OUT

func _notification(what):
	if (what == NOTIFICATION_EXIT_TREE):
		_instance_count -= 1
	if (what == NOTIFICATION_ENTER_TREE):
		_instance_count += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_process_counter += 1
	
	# only update the global alpha when the last GlobalFadeDecorator in the scene tree is processed
	if _process_counter == _process_til_update:
		_process_counter = 0
		var fade_delta = SPEED * delta * (-1.0 if _fade_direction == Direction.OUT else 1.0)
		_global_alpha += fade_delta
		
		if _fade_direction == Direction.OUT and _global_alpha <= MIN_ALPHA:
			_fade_direction = Direction.IN
		elif _fade_direction == Direction.IN and _global_alpha >= MAX_ALPHA:
			_fade_direction = Direction.OUT
	
	# update the alpha for everyone though
	get_parent().modulate.a = _global_alpha

	if _process_til_update != _instance_count:
		_process_til_update = _instance_count
