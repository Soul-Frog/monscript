extends Node2D

# how long should a debug drawable linger on the screen before being cleared
@export var drawable_timeout_time = 5

class Drawable extends Node:
	var timer
	var should_be_deleted
	
	func _init():
		should_be_deleted = false
		
	func on_timeout():
		should_be_deleted = true

class Line extends Drawable:
	var point1
	var point2
	var line_color
	
	func _init(from, to, color = Color.BLACK):
		super()
		self.point1 = from
		self.point2 = to
		self.line_color = color
		
class Point extends Drawable:
	var point
	var point_color
	
	func _init(at, color = Color.BLACK):
		super()
		self.point = at
		self.point_color = color

var drawables = []

func _ready():
	assert(drawable_timeout_time > 0, "Can't have a negative time.")
	#Global.p(self, "DebugTool loaded.")

# adds a new point to be drawn
func add_point(at, color = Color.BLACK):
	_add_drawable(Point.new(at, color))

# adds a new line to be drawn
func add_line(from, to, color = Color.BLACK):
	_add_drawable(Line.new(from, to, color))

# removes all things currently being drawn
func clear_drawables():
	drawables.clear()
	
func _add_drawable(drawable):
	drawables.append(drawable)
	get_tree().create_timer(drawable_timeout_time).timeout.connect(drawable.on_timeout)

# has a memory leak somewhere
func _clean_drawables():
	for i in range(drawables.size() -1, -1, -1):
		if drawables[i].should_be_deleted:
			drawables.remove_at(i)

func _draw():
	if Global.DEBUG_DRAW:
		for drawable in drawables:
			if drawable is Point:
				draw_circle(drawable.point - get_parent().position, 1, drawable.point_color)
			elif drawable is Line:
				draw_line(drawable.point1 - get_parent().position, drawable.point2 - get_parent().position, drawable.line_color, 1.0)
			else:
				assert(false, "Illegal object in DebugTool")
	_clean_drawables()

func _process(_delta):
	queue_redraw()
