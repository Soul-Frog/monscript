extends Node

# don't ever emit this manually; use the emit function
signal dialogue_signal

var _first_time = true

# variables to store parameters passed to dialogue
var IN0
var IN1
var IN2
var IN3
var IN4
var IN5

# variables to store parameters passed from dialogue
var OUT0
var OUT1
var OUT2
var OUT3
var OUT4
var OUT5

# use within a dialogue like this: 
# do DialogueIO.emit( PARAMS )
# to emit a signal, with optional parameters
func emit(params = null):
	if params != null:
		emit_signal("dialogue_signal", params)
	else:
		emit_signal("dialogue_signal")

"""
func _all_null(arr: Array) -> bool:
	for elem in arr:
		if elem != null:
			return false
	return true

func _all_not_null(arr: Array) -> bool:
	for elem in arr:
		if elem == null:
			return false
	return true

func _nullify(arr: Array):
	for elem in arr:
		elem = null

func set_int(index: int, param):
	assert(_all_null([IN0, IN1, IN2, IN3, IN4, IN5]) or _first_time)
	assert(_all_not_null([OUT0, OUT1, OUT2, OUT3, OUT4, OUT5]) or _first_time)
	_first_time = false
	[IN0, IN1, IN2, IN3, IN4, IN5][index] = param
	_nullify([OUT0, OUT1, OUT2, OUT3, OUT4, OUT5])

func set_out(index: int, param):
	assert(_all_null([OUT0, OUT1, OUT2, OUT3, OUT4, OUT5]) or _first_time)
	assert(_all_not_null([IN0, IN1, IN2, IN3, IN4, IN5]) or _first_time)
	_first_time = false
	_nullify([IN0, IN1, IN2, IN3, IN4, IN5])
	[OUT0, OUT1, OUT2, OUT3, OUT4, OUT5][index] = param

func get_out(index: int):
	assert(not _first_time)
	assert(_all_not_null([OUT0, OUT1, OUT2, OUT3, OUT4, OUT5]) != null or _first_time)
	return [OUT0, OUT1, OUT2, OUT3, OUT4, OUT5][index]
"""
