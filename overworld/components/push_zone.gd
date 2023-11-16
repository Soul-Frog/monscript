class_name PushZone
extends Area2D

enum Direction {
	PUSH_UP, PUSH_DOWN, PUSH_LEFT, PUSH_RIGHT
}

var bodies = []
@export var direction = Direction.PUSH_LEFT
@export var force = 100

func _ready():
	# if not connected through editor, do it automatically here
	if body_entered.get_connections().size() == 0:
		body_entered.connect(_on_body_entered)
	if body_exited.get_connections().size() == 0:
		body_exited.connect(_on_body_exited)

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

func _on_body_entered(body):
	assert(not bodies.has(body))
	bodies.append(body)

# and this one as well
func _on_body_exited(body):
	assert(bodies.has(body))
	bodies.erase(body)
