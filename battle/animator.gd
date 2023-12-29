class_name BattleAnimator extends Node2D

signal animation_finished 

var _speed_scale = 1.0

var current_fx = null
var was_animation_canceled = false

func _play_fx(fx):
	was_animation_canceled = false
	current_fx = fx
	fx.speed_scale = _speed_scale
	add_child(fx)
	fx.play()
	await fx.animation_finished
	fx.queue_free()
	current_fx = null
	remove_child(fx)

func slash(mon):
	# create a new slash effect
	var slash_fx = load("res://battle/animations/slash.tscn").instantiate()
	
	# place over mon
	slash_fx.position = mon.position
	
	# play it and wait for it to completed
	await _play_fx(slash_fx)

	#signal that animation is done
	emit_signal("animation_finished")

func set_speed_scale(speed_scale: float) -> void:
	_speed_scale = speed_scale
	if current_fx:
		current_fx.speed_scale = speed_scale

func cancel_animation() -> void:
	if current_fx != null:
		was_animation_canceled = true
		current_fx.stop()
		current_fx.emit_signal("animation_finished")
