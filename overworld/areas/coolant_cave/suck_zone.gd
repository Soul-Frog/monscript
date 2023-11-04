# A Area2D with a circular collision shape which pulls players into the center
class_name SuckZone
extends Area2D

@export var SUCTION_STRENGTH: float = 100 #how quickly the whirlpool pulls player to center at maximum

@onready var _CIRCLE = $SuckCircle
@onready var _CENTER: Vector2 = _CIRCLE.position
@onready var _MAX_RADIUS: float = _CIRCLE.shape.radius

var _bodies = []

func _ready():
	assert(_CIRCLE)
	assert(_MAX_RADIUS >= 0)

func _process(delta):
	for body in _bodies:
		# I'm not really sure why we're doing -7 and -21, but it doesn't line up right if we don't
		var magic_position = body.position + Vector2(-7, -21)
		
		# measure distance to center of whirlpool
		var dist = magic_position.distance_to(_CENTER) #how far are we from the center?
		var x_dist = abs(magic_position.x - _CENTER.x) #how far are we from the center in x?
		var y_dist = abs(magic_position.y - _CENTER.y) #how far are we from the center in y?
		
		var x_direction = -1 if magic_position.x > _CENTER.x else 1 #pull left or right?
		var y_direction = -1 if magic_position.y > _CENTER.y else 1 #pull up or down?
		var total_force = (1-(dist/_MAX_RADIUS)) * SUCTION_STRENGTH #calculate force based on distance to center
		
		# we want to look like we're smoothly sliding to the center, so if we are closer in one dimension, 
		# apply less to that dimension
		var x_force_mult = x_dist / dist
		var y_force_mult = y_dist / dist
		
		# if within a reasonable range to the center (3 pixels); don't apply force to avoid jittering
		var x_force = 0 if x_dist <= 5 else total_force * x_force_mult * x_direction
		var y_force = 0 if y_dist <= 5 else total_force * y_force_mult * y_direction
		
		# apply force to player body
		body.apply_velocity(Vector2(x_force, y_force))

func _on_body_entered(body):
	assert(body is Player)
	_bodies.append(body)


func _on_body_exited(body):
	assert(body is Player)
	_bodies.erase(body)
