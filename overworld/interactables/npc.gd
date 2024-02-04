class_name NPC
extends DialogueInteractable

# npc's speed while moving
@export var SPEED = 70

signal reached_point
var _target_point = null
var _time_blocked = 0.0
const _TIME_BLOCKED_BEFORE_GIVE_UP = 0.5

func _physics_process(delta):
	var input_direction = Vector2.ZERO
	
	if _target_point != null:
		input_direction = Global.direction_towards_point(position, _target_point)
		
		if input_direction == Vector2.ZERO:
			_on_reached_point()
	
	velocity = SPEED * input_direction
	
	if velocity.x != 0:
		face_left() if velocity.x < 0 else face_right()
	
	var previous_position = position
	move_and_slide()
	
	# if we're trying to move to a point but get stuck, give up after some time
	if _target_point != null and previous_position == position:
		_time_blocked += delta
		if _time_blocked >= _TIME_BLOCKED_BEFORE_GIVE_UP:
			_on_reached_point()
		else:
			_time_blocked = 0.0

func _on_reached_point() -> void:
	_target_point = null
	emit_signal("reached_point")

func move_to_point(point: Vector2) -> void:
	_target_point = point
	_time_blocked = 0.0

func face_left() -> void:
	_SPRITE.flip_h = true

func face_right() -> void:
	_SPRITE.flip_h = false
