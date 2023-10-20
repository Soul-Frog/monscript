extends Node

# don't ever emit this manually; use the emit function
signal dialogue_signal

# emitted after a dialogue completes
signal dialogue_ended

# variables to store parameters passed to dialogue
# if you add more of these, you must update set_in
var IN0
var IN1
var IN2
var IN3
var IN4
var IN5

# variables to store parameters passed from dialogue
# if you add more of these, you must update get_out
var OUT0
var OUT1
var OUT2
var OUT3
var OUT4
var OUT5

# track whether a dialogue is currently open
var _in_dialogue = false

enum _IOState {
	AWAITING_IN, AWAITING_OUT
}
var _state = _IOState.AWAITING_IN

func is_dialogue_active():
	return _in_dialogue

# use within a dialogue like this: 
# do DialogueIO.emit( PARAMS )
# to emit a generic signal, with optional parameters
func emit(params = null):
	assert(_in_dialogue, "Should only be called from within a dialogue.")
	if params != null:
		emit_signal("dialogue_signal", params)
	else:
		emit_signal("dialogue_signal")

# Set parameters that can be accessed from the dialogue.
# You NEVER need to call this. (play already calls it with the parameters passed to play)
func _in(p0 = null, p1 = null, p2 = null, p3 = null, p4 = null, p5 = null):
	assert(not _in_dialogue, "Already in a dialogue!")
	assert(_state == _IOState.AWAITING_IN)
	IN0 = p0
	IN1 = p1
	IN2 = p2
	IN3 = p3
	IN4 = p4
	IN5 = p5
	_state = _IOState.AWAITING_OUT

# Get parameters outputted from the dialaogue.
# You NEVER need to call this. (play already calls it and returns the result)
func _out() -> Array:
	assert(_in_dialogue, "Must be in a dialogue to get out-params from that dialogue!")
	assert(_state == _IOState.AWAITING_OUT)
	_state = _IOState.AWAITING_IN
	return [OUT0, OUT1, OUT2, OUT3, OUT4, OUT5]

# used in the dialoguemanager to show an error
func ERROR(msg: String):
	assert(_in_dialogue, "Should only be called from within a dialogue.")
	assert(false, msg)

# play a dialogue from the given resource with the given tab; you ALWAYS want to await this:
# await Dialogue.play(..., ..., ......)
# up to 6 optional inputs can be passed to the dialogue
# up to 6 possible outputs from the dialogue are returned in an array
func play(res: DialogueResource, tag: String, p0 = null, p1 = null, p2 = null, p3 = null, p4 = null, p5 = null):
	assert(not _in_dialogue, "Can't start a new dialogue with one already open!")
	assert(res != null and tag != null)
	
	# set in-params
	_in(p0, p1, p2, p3, p4, p5)
	
	# display the dialogue balloon and wait for it to complete
	_in_dialogue = true
	DialogueManager.show_example_dialogue_balloon(res, tag)
	await DialogueManager.dialogue_ended
	
	# get the out-params
	var outs = _out() 
	
	# signal that the dialogue is over
	_in_dialogue = false
	emit_signal("dialogue_ended")
	
	# return out-params
	return outs
