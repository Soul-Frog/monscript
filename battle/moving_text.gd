class_name MovingText
extends RichTextLabel

enum Direction {
	UP, DOWN
}

signal deleted

# a signal emitted after this text has existed for a certain period of time
# only used if callback_timer is set when creating the text
signal callback

var _speed_scale = 1.0

var ofset = Vector2.ZERO
var text_content = ""
var move_direction = Direction.UP
var move_speed = 50
var display_time = 0.5
var velocity = 0
var text_color = Global.COLOR_WHITE
var callback_timer = null

const format = "[center][color=#%s]%s[/color][/center]"

# stupidly named tx because 'text' is taken
func tx(txt):
	self.text_content = txt
	return self

func setup_callback(timer):
	self.callback_timer = timer
	return self

func offset(pos):
	self.ofset = pos
	return self

func speed(spd, spd_scale):
	self.move_speed = spd
	self._speed_scale = spd_scale
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
	assert(callback_timer == null or callback_timer < display_time, "Callback is shorter than text's life, will never happen!")
	self.position += ofset
	_update_text()
	if move_direction == Direction.UP:
		velocity = -move_speed
	else: #direction == Direction.DOWN:
		velocity = move_speed

func _process(delta):
	position.y += velocity * delta * _speed_scale
	display_time -= delta * _speed_scale
	if callback_timer != null:
		callback_timer -= delta * _speed_scale
		if callback_timer <= 0:
			callback_timer = null
			emit_signal("callback")
	if display_time <= 0:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.05 if _speed_scale == 0 else 0.05 / _speed_scale)
		tween.tween_callback(_delete)

func _delete():
	emit_signal("deleted")
	self.queue_free()

func set_speed_scale(speed_scale: float):
	_speed_scale = speed_scale
