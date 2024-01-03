extends Node2D

signal escape_state_changed

@onready var button = $Button
@onready var text = $Text
@onready var text_fade = $Text/FadeDecorator

const TEXT_FORMAT = "[center]%s%s[/center]"
const TEXT = "Attempting to escape"
const MAX_DOTS = 3
var _dots = 1

func _ready():
	assert(button)
	assert(text)
	assert(_dots <= MAX_DOTS)
	text.modulate.a = 0
	reset()

func _on_dot_timer_timeout():
	_dots += 1
	if _dots > MAX_DOTS:
		_dots = 1
	text.text = TEXT_FORMAT % [TEXT, Global.repeat_str(".", _dots)]

func reset():
	button.reset()
	text_fade.fade_out()
	text.modulate.a = 0
	modulate.a = 1

func toggle_escape():
	button.emit_signal("pressed")

func _on_escape_state_changed():
	if button.selected:
		text_fade.fade_in()
		_dots = 0
	else:
		text_fade.fade_out()
	emit_signal("escape_state_changed", button.selected)
