class_name PushZone
extends Area2D

enum Direction {
	PUSH_UP, PUSH_DOWN, PUSH_LEFT, PUSH_RIGHT
}

var bodies = []
@export var direction = Direction.PUSH_LEFT
@export var force = 100

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
		body.apply_velocity(force * _direction_vector())

# don't forget to connect the signal to yourself for this
func _on_body_entered(body):
	assert(not bodies.has(body))
	bodies.append(body)

# and this one as well
func _on_body_exited(body):
	assert(bodies.has(body))
	bodies.erase(body)
