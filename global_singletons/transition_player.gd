extends Node2D

enum Effect {
	NONE, 						# doesn't do anything
	
	QUICK_FADE_OUT, 			# a very fast fade out
	FADE_OUT, 					# a normal, reasonable fade out
	SLOW_FADE_OUT_AND_WAIT,		# a fade out with a delay after fading fully to black
	
	FADE_IN,					# fading in
	QUICK_FADE_IN,				# fade in faster
	SLOW_FADE_IN				# fade in slowly
}

@onready var _FADE = $Fade

var _is_playing = false

func _ready():
	assert(_FADE)
	for child in get_children():
		child.hide()
	_FADE.modulate.a = 0.0

# play a transition effect
func play(effect: Effect) -> void:
	if effect == Effect.NONE:
		return
	
	_is_playing = true
	
	match effect:
		Effect.QUICK_FADE_OUT:
			await _fade_out(0.06, 0.0)
		Effect.FADE_OUT:
			await _fade_out(0.15, 0.0)
		Effect.SLOW_FADE_OUT_AND_WAIT:
			await _fade_out(2.0, 4.0)
		
		Effect.FADE_IN:
			await _fade_in(0.15)
		Effect.QUICK_FADE_IN:
			await _fade_in(0.06)
		Effect.SLOW_FADE_IN:
			await _fade_in(2.0)
	
	_is_playing = false
	
# check whether an effect is playing
func is_playing() -> bool:
	return _is_playing

func _fade_out(fade_time: float, hang_time: float) -> void:
	_FADE.modulate.a = 0.0
	
	_FADE.show() # show so the fade blocks mouse clicks
	_is_playing = true
	
	# perform the fade out
	var tween = create_tween()
	tween.tween_property(_FADE, "modulate:a", 1.0, fade_time)
	await tween.finished
	
	# wait for hang time
	await Global.delay(hang_time)

func _fade_in(fade_time: float) -> void:
	_FADE.modulate.a = 1.0
	
	# perform the fade out
	var tween = create_tween()
	tween.tween_property(_FADE, "modulate:a", 0.0, fade_time)
	await tween.finished
	
	_FADE.hide() #hide so the fade no longer blocks mouse clicks
