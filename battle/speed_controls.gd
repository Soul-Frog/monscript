class_name BattleSpeedControls
extends Node2D

signal speed_changed

@onready var _run_button: SelectableButton = $Run
@onready var _speedup_button: SelectableButton = $Speedup
@onready var _pause_button: SelectableButton = $Pause

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
	_run_button.pressed.connect(_on_run_button_pressed)
	_speedup_button.pressed.connect(_on_speedup_button_pressed)
	_pause_button.pressed.connect(_on_pause_button_pressed)

func reset():
	_on_run_button_pressed()

func _on_run_button_pressed():
	_on_button_pressed(_run_button)

func _on_speedup_button_pressed():
	_on_button_pressed(_speedup_button)

func _on_pause_button_pressed():
	_on_button_pressed(_pause_button)

func _on_button_pressed(button: SelectableButton):
	# update the speed
	speed = _button_to_speed[button]
	
	# unselect each other option
	for btn in _button_to_speed.keys():
		if btn != button:
			btn.unselect()
			
	# and notify that the speed was changed
	emit_signal("speed_changed")
