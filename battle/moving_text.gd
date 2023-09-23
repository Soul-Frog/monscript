extends RichTextLabel

enum Direction {
	UP, DOWN
}

var text_content = ""
var move_direction = Direction.UP
var move_speed = 50
var display_time = 0.5
var velocity = 0
var text_color = Global.COLOR_WHITE

const format = "[center][color=#%s]%s[/color][/center]"

# stupidly named tx because 'text' is taken
func tx(txt):
	self.text_content = txt
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

func color(clr):
	self.text_color = clr
	return self

func _update_text():
	self.text = format % [text_color.to_html(), text_content]

func _ready():
	assert("%s" % self.text_content != "", "No text set for moving_text, be sure to call txt()!")
	_update_text()
	if move_direction == Direction.UP:
		velocity = -move_speed
	else: #direction == Direction.DOWN:
		velocity = move_speed
	await Global.delay(display_time)
	queue_free()

func _process(delta):
	position.y += velocity * delta
