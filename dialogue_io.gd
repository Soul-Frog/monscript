extends Node

# don't ever emit this manually; use the emit function
signal dialogue_signal

var _first_time = true
var _IN = null
var _OUT = null

# use within a dialogue like this: 
# do DialogueIO.emit( PARAMS )
# to emit a signal, with optional parameters
func emit(params = null):
	if params != null:
		emit_signal("dialogue_signal", params)
	else:
		emit_signal("dialogue_signal")

func set_in(params: Array):
	assert(_IN == null or _first_time)
	assert(_OUT != null or _first_time)
	_first_time = false
	_IN = params
	_OUT = null

func set_out(params: Array):
	assert(_OUT == null or _first_time)
	assert(_IN != null or _first_time)
	_first_time = false
	_IN = null
	_OUT = params

func get_in():
	assert(not _first_time)
	assert(_IN != null)
	return _IN

func get_out():
	assert(not _first_time)
	assert(_OUT != null or _first_time)
	return _OUT
