class_name Whirlpool
extends SuckZone

class Circle:
	var radius: float
	var alpha: float
	
	func _init(rad, trans):
		radius = rad
		alpha = trans

@export var CIRCLE_COLOR: Color = Color.WHITE #circle color
@export var NUM_CIRCLES: int = 10 #number of circles used when rendering the whirlpool
@export var CIRCLE_SPEED: float = 50 #speed of the graphical circles

const _FADE_IN_SPEED = 2 #how quickly a new outer circle fades in
const _MAX_CIRCLE_ALPHA = 1 #maximum alpha of a circle
const _MIN_CIRCLE_ALPHA = 0.7 #starting alpha of an outer circle - looks less like it 'pops' in if we start partially transparent

var _circles = []

func _ready():
	super()
	var radius_per_circle = _MAX_RADIUS / NUM_CIRCLES
	for i in NUM_CIRCLES:
		_circles.append(Circle.new((i+1) * radius_per_circle, _MAX_CIRCLE_ALPHA))

func _draw():
	for circle in _circles:
		draw_arc(_CENTER, circle.radius, 0, deg_to_rad(360), 100, CIRCLE_COLOR * circle.alpha, 1, false)

func _process(delta):
	super(delta)
	for i in _circles.size():
		var circle = _circles[i]
		circle.radius -= CIRCLE_SPEED * delta
		circle.alpha = min(circle.alpha + delta * _FADE_IN_SPEED, _MAX_CIRCLE_ALPHA)
		if circle.radius < 0:
			circle.radius = _MAX_RADIUS
			circle.alpha = _MIN_CIRCLE_ALPHA
	queue_redraw()
