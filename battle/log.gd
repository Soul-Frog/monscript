class_name BattleLog
extends Node2D

@onready var background = $Background
@onready var text = $Text
@onready var scroll_bar = text.get_v_scroll_bar()
@onready var click_blocker = $ClickBlocker
@onready var expand_button = $ExpandButton

const _TEXT_SPEED_DELTA := 130.0
var _visible_characters := 0.0

const _AUTOSCROLL_SPEED := 50.0
var _scroll_value := 0.0

const _GROWTH_AMOUNT = 120

const PLAYER_TEAM_COLOR: Color = Global.COLOR_GREEN
const ENEMY_TEAM_COLOR: Color = Global.COLOR_RED

const MON_NAME_PLACEHOLDER = "[MONNAME]"

var _speed_scale = 1.0

var _scrollable = false

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(background)
	assert(text)
	assert(click_blocker)
	assert(expand_button)
	clear()

func make_scrollable_and_expandable():
	_show_buffered_characters()
	call_deferred("_scroll_to_bottom") # need to wait 1 frame for scroll bar to update BEFORE scrolling...
	scroll_bar.modulate.a = 1
	click_blocker.hide()
	_scrollable = true
	expand_button.show()

func make_unscrollable_and_unexpandable():
	call_deferred("_scroll_to_bottom") # need to wait 1 frame for scroll bar to update BEFORE scrolling...
	
	scroll_bar.modulate.a = 0
	click_blocker.show()
	_scrollable = false
	expand_button.hide()
	if expand_button.selected: # if expanded, shrink back down to normal
		expand_button.unselect()

func _scroll_to_bottom():
	scroll_bar.value = scroll_bar.max_value - scroll_bar.page
	_scroll_value = scroll_bar.max_value - scroll_bar.page

func _show_buffered_characters():
	text.visible_characters = text.get_parsed_text().length()
	_visible_characters = text.get_parsed_text().length()
	print(text.get_parsed_text())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(unscaled_delta):
	var delta = unscaled_delta * (_speed_scale if _speed_scale != 0 else 1.0)
	
	# new characters in log should appear gradually instead of immediately
	if _visible_characters < text.get_parsed_text().length():
		_visible_characters = min(_visible_characters + (delta * _TEXT_SPEED_DELTA), text.get_parsed_text().length())
		text.visible_characters = int(_visible_characters)
	
	# smoothly scroll when new lines are added to bottom of log
	if _scroll_value < scroll_bar.max_value - scroll_bar.page and not _scrollable:
		_scroll_value = min(_scroll_value + (delta * _AUTOSCROLL_SPEED), scroll_bar.max_value - scroll_bar.page)
		scroll_bar.value = int(_scroll_value)

# Add a new line of text to the log
func add_text(line: String, mon: BattleMon = null) -> void:
	if mon != null:
		# replace [MONNAME] with a colored name
		line = line.replace(MON_NAME_PLACEHOLDER, "[color=%s]%s[/color]" % [mon.log_color.to_html(), mon.log_name])
	
	# add new line to the log
	text.append_text("%s\n" % line)

# Clears and resets the log
func clear() -> void:
	text.clear()
	text.visible_characters = 0
	text.get_v_scroll_bar().value = 0
	_visible_characters = 0
	_scroll_value = 0
	make_unscrollable_and_unexpandable()
	expand_button.hide()
	if expand_button.selected: # if expanded, shrink back down to normal
		expand_button.unselect()

func set_speed_scale(speed_scale: float) -> void:
	_speed_scale = speed_scale

func _on_expand_pressed():
	if not expand_button.selected:
		_move_and_resize(-_GROWTH_AMOUNT)
	else:
		_move_and_resize(_GROWTH_AMOUNT)

func can_expand():
	return expand_button.visible

func toggle_expand():
	expand_button.emit_signal("pressed")

func _move_and_resize(amount: int):
	background.size.y += amount
	background.position.y -= amount
	click_blocker.size.y += amount
	click_blocker.position.y -= amount
	text.size.y += amount
	text.position.y -= amount
	expand_button.position.y -= amount
