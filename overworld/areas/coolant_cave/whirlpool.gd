class_name Whirlpool
extends Area2D

class Circle:
	var radius: float
	var alpha: float
	
	func _init(rad, trans):
		radius = rad
		alpha = trans

@export var NUM_CIRCLES = 10
@export var SUCTION_SPEED = 50

@onready var _COLLISION = $CollisionShape2D
@onready var CENTER: Vector2 = _COLLISION.position
@onready var MAX_RADIUS: float = _COLLISION.shape.radius
const FADE_IN_SPEED = 2
const MAX_CIRCLE_ALPHA = 1
const MIN_CIRCLE_ALPHA = 0.7

var circles = []

func _ready():
	assert(_COLLISION)
	assert(MAX_RADIUS >= 0)
	
	var radius_per_circle = MAX_RADIUS / NUM_CIRCLES
	for i in NUM_CIRCLES:
		circles.append(Circle.new((i+1) * radius_per_circle, MAX_CIRCLE_ALPHA))
		

func _draw():
	for circle in circles:
		draw_arc(CENTER, circle.radius, 0, deg_to_rad(360), 100, Color.WHITE * circle.alpha, 1, false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for i in circles.size():
		var circle = circles[i]
		circle.radius -= SUCTION_SPEED * delta
		circle.alpha = min(circle.alpha + delta * FADE_IN_SPEED, MAX_CIRCLE_ALPHA)
		if circle.radius < 0:
			circle.radius = MAX_RADIUS
			circle.alpha = MIN_CIRCLE_ALPHA
	queue_redraw()
