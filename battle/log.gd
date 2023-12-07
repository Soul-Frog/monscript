class_name BattleLog
extends Node2D

@onready var text = $Text

const _TEXT_SPEED_DELTA := 60.0
var _visible_characters := 0.0

const _AUTOSCROLL_SPEED := 40.0
var _scroll_value := 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(text)
	clear()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# new characters in log should appear gradually instead of immediately
	if _visible_characters < text.get_parsed_text().length():
		_visible_characters = min(_visible_characters + (delta * _TEXT_SPEED_DELTA), text.get_parsed_text().length())
		text.visible_characters = int(_visible_characters)
	
	# smoothly scroll when new lines are added to bottom of log
	var scroll_bar: VScrollBar = text.get_v_scroll_bar()
	if _scroll_value < scroll_bar.max_value - scroll_bar.page:
		_scroll_value = min(_scroll_value + (delta * _AUTOSCROLL_SPEED), scroll_bar.max_value - scroll_bar.page)
		scroll_bar.value = int(_scroll_value)

# Add a new line of text to the log
func add_text(line: String) -> void:
	# todo - process [MON] into a name, pass a mon name and team color
	text.append_text(line + "\n")

# Clears and resets the log
func clear() -> void:
	text.clear()
	text.visible_characters = 0
	text.get_v_scroll_bar().value = 0
	_visible_characters = 0
	_scroll_value = 0
