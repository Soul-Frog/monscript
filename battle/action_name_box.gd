class_name BattleActionNameBox
extends Node2D

@onready var _background = $Background
@onready var _label = $ActionLabel
const _LABEL_FORMAT = "> %s"

var _speed_scale := 1.0
var _active_tweens = []

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(_background)
	assert(_label)
	reset()

func reset():
	modulate.a = 0

func make_visible():
	var tween = create_tween()
	tween.set_speed_scale(_speed_scale)
	tween.tween_property(self, "modulate:a", 1, 0.125)
	_active_tweens.append(tween)

func make_invisible():
	var tween = create_tween()
	tween.set_speed_scale(_speed_scale)
	tween.tween_property(self, "modulate:a", 0, 0.125)
	_active_tweens.append(tween)

func set_action_text(action: String):
	_label.text = _LABEL_FORMAT % action
	
	var string_size = _label.get_theme().get_default_font().get_string_size(_label.text)
	
	_background.size.x = string_size.x + 12

	var viewport_size = get_viewport_rect().size
	_label.position.x = (viewport_size.x / 2) - (string_size.x / 2)
	_background.position.x = (viewport_size.x / 2) - (_background.size.x / 2)

func set_speed_scale(speed_scale: float) -> void:
	_speed_scale = speed_scale
	var invalid_tweens = []
	for tween in _active_tweens:
		if not tween.is_valid():
			invalid_tweens.append(tween)
			continue
		tween.set_speed_scale(speed_scale)
	
	for invalid_tween in invalid_tweens:
		_active_tweens.erase(invalid_tween)
