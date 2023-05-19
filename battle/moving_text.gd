extends RichTextLabel

enum Direction {
	UP, DOWN
}

var move_direction = Direction.UP
var move_speed = 50
var display_time = 0.5

var velocity = 0

const format = "[center]%s[/center]"

# stupidly named tx because 'text' is taken
func tx(txt):
	self.text = format % txt
	return self

func speed(spd):
	self.move_speed = spd
	return self

func time(tm):
	self.display_time = tm
	return self

func direction_down():
	self.move_direction = Direction.DOWN
	return self

func direction_up():
	self.move_direction = Direction.UP
	return self

# Called when the node enters the scene tree for the first time.
func _ready():
	if move_direction == Direction.UP:
		velocity = -move_speed
	else: #direction == Direction.DOWN:
		velocity = move_speed
	Global.call_after_delay(display_time, self, func(node): 
		if is_instance_valid(node):
			node.queue_free())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.y += velocity * delta
