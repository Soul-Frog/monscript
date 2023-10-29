class_name PushZone
extends Area2D

enum Direction {
	PUSH_UP, PUSH_DOWN, PUSH_LEFT, PUSH_RIGHT
}

const FORCE = 100

var bodies = []
@export var direction = Direction.PUSH_LEFT

func _direction_vector():
	match direction:
		Direction.PUSH_LEFT:
			return Vector2.LEFT
		Direction.PUSH_RIGHT:
			return Vector2.RIGHT
		Direction.PUSH_UP:
			return Vector2.UP
		Direction.PUSH_DOWN:
			return Vector2.DOWN
	assert(false)
	return Vector2.ZERO

func _physics_process(delta):
	for body in bodies:
		body.apply_velocity(FORCE * _direction_vector())

func _on_body_entered(body):
	assert(not bodies.has(body))
	bodies.append(body)

func _on_body_exited(body):
	assert(bodies.has(body))
	bodies.erase(body)
