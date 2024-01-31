class_name NPC
extends DialogueInteractable

# npc's speed while moving
@export var SPEED = 70

signal reached_point
var target_point = null

func _physics_process(delta):
	var input_direction = Vector2.ZERO
	
	if target_point != null:
		# see if we've gotten 'close enough' to the target point
		const THRESHOLD = 2.0
		var at_correct_x = abs(position.x - target_point.x) <= THRESHOLD
		var at_correct_y = abs(position.y - target_point.y) <= THRESHOLD
		
		if at_correct_x and at_correct_y: # if we reached it, emit and set target to null
			target_point = null
			emit_signal("reached_point")
		else: #otherwise move towards
			if not at_correct_x:
				if position.x < target_point.x:
					input_direction.x = 1
				else:
					input_direction.x = -1
			if not at_correct_y:
				if position.y < target_point.y:
					input_direction.y = 1
				else:
					input_direction.y = -1
	
	velocity = SPEED * input_direction
	
	if velocity.x != 0:
		face_left() if velocity.x < 0 else face_right()
	
	move_and_slide()

func move_to_point(point: Vector2) -> void:
	target_point = point

func face_left() -> void:
	_SPRITE.flip_h = true

func face_right() -> void:
	_SPRITE.flip_h = false
