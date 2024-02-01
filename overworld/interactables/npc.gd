class_name NPC
extends DialogueInteractable

# npc's speed while moving
@export var SPEED = 70

signal reached_point
var target_point = null

func _physics_process(delta):
	var input_direction = Vector2.ZERO
	
	if target_point != null:
		input_direction = Global.direction_towards_point(position, target_point)
		
		if input_direction == Vector2.ZERO:
			target_point = null
			emit_signal("reached_point")
	
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
