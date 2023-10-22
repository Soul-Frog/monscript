class_name ColorDecorator
extends Node

enum EffectType {
	OSCILLATE
}

# should the effect automatically play when the parent node enters the scene?
@export var autostart := false
# what effect should play if autostarting
@export var autostart_effect_type := EffectType.OSCILLATE

# red values to oscillate between
@export var min_red := 255.0
@export var max_red := 255.0
@export var red_speed := 0

# green values to oscillate between
@export var min_green := 255.0
@export var max_green := 255.0
@export var green_speed := 0

# blue values to oscillate between
@export var min_blue := 255.0
@export var max_blue := 255.0
@export var blue_speed := 0

enum _Direction { 
	IN, OUT
}

# whether this effect is currently changing alpha; set to false after completing a fade
var _active := false
var _effect_type = EffectType.OSCILLATE
var _red_direction := _Direction.OUT
var _green_direction := _Direction.OUT
var _blue_direction := _Direction.OUT

func _ready():
	if autostart:
		_effect_type = autostart_effect_type
		_active = true

func stop():
	_active = false

func oscillate():
	_effect_type = EffectType.OSCILLATE
	_active = true

func _process(delta):
	if _active:
		if red_speed != 0:
			var red_delta = red_speed * delta * (-1 if _red_direction == _Direction.OUT else 1)
			get_parent().modulate.r += red_delta/255.0
			
			if _red_direction == _Direction.OUT and get_parent().modulate.r <= min_red/255.0:
				get_parent().modulate.r = min_red/255.0
				_red_direction = _Direction.IN
			elif _red_direction == _Direction.IN and get_parent().modulate.r >= max_red/255.0:
				get_parent().modulate.r = max_red/255.0
				_red_direction = _Direction.OUT
		
		if green_speed != 0:
			var green_delta = green_speed * delta * (-1 if _green_direction == _Direction.OUT else 1)
			get_parent().modulate.g += green_delta/255.0
			
			if _green_direction == _Direction.OUT and get_parent().modulate.g <= min_green/255.0:
				get_parent().modulate.g = min_green/255.0
				_green_direction = _Direction.IN
			elif _green_direction == _Direction.IN and get_parent().modulate.g >= max_green/255.0:
				get_parent().modulate.g = max_green/255.0
				_green_direction = _Direction.OUT
		
		if blue_speed != 0:
			var blue_delta = blue_speed * delta * (-1 if _blue_direction == _Direction.OUT else 1)
			get_parent().modulate.b += blue_delta/255.0
			
			if _blue_direction == _Direction.OUT and get_parent().modulate.b <= min_blue/255.0:
				get_parent().modulate.b = min_blue/255.0
				_blue_direction = _Direction.IN
			elif _blue_direction == _Direction.IN and get_parent().modulate.b >= max_blue/255.0:
				get_parent().modulate.b = max_blue/255.0
				_blue_direction = _Direction.OUT
