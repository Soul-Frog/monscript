class_name BattleSpeedControls
extends Node2D

signal speed_changed

@onready var _run_button: SelectableButton = $Run
@onready var _speedup_button: SelectableButton = $Speedup
@onready var _pause_button: SelectableButton = $Pause
@onready var _pause_filter = $PauseFilter
@onready var _speedup_filter = $SpeedUpFilter
@onready var _pause_filter_fade: FadeDecorator = $PauseFilter/Fade
@onready var _speedup_filter_fade: FadeDecorator = $SpeedUpFilter/Fade

@onready var _button_to_speed = {
	_run_button : Battle.Speed.NORMAL,
	_speedup_button : Battle.Speed.SPEEDUP,
	_pause_button : Battle.Speed.PAUSE
}

var speed = Battle.Speed.NORMAL

func _ready():
	assert(_run_button)
	assert(_speedup_button)
	assert(_pause_button)
	assert(_pause_filter_fade)
	assert(_speedup_filter_fade)
	_run_button.pressed.connect(_on_run_button_pressed)
	_speedup_button.pressed.connect(_on_speedup_button_pressed)
	_pause_button.pressed.connect(_on_pause_button_pressed)

func reset():
	_on_run_button_pressed()
	_pause_filter.modulate.a = 0
	_speedup_filter.modulate.a = 0
	modulate.a = 1

func _on_run_button_pressed():
	_on_button_pressed(_run_button)
	update_filters()

func _on_speedup_button_pressed():
	_on_button_pressed(_speedup_button)
	update_filters()

func _on_pause_button_pressed():
	_on_button_pressed(_pause_button)
	update_filters()

func fade_out_filters() -> void:
	_pause_filter_fade.fade_out()
	_speedup_filter_fade.fade_out()

func update_filters() -> void:
	if speed == Battle.Speed.NORMAL:
		_pause_filter_fade.fade_out()
		_speedup_filter_fade.fade_out()
	elif speed == Battle.Speed.SPEEDUP:
		_pause_filter_fade.fade_out()
		_speedup_filter_fade.fade_in()
	elif speed == Battle.Speed.PAUSE:
		_pause_filter_fade.fade_in()
		_speedup_filter_fade.fade_out()

func run():
	_run_button.emit_signal("pressed")

func speedup():
	_speedup_button.emit_signal("pressed")

func pause(): 
	_pause_button.emit_signal("pressed")

func _on_button_pressed(button: SelectableButton):
	# update the speed
	speed = _button_to_speed[button]
	
	# unselect each other option
	for btn in _button_to_speed.keys():
		if btn != button:
			btn.unselect()
			
	# and notify that the speed was changed
	emit_signal("speed_changed")
