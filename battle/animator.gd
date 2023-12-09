class_name BattleAnimator extends Node2D

signal animation_finished 

func _play_fx(fx):
	add_child(fx)
	fx.play()
	await fx.animation_finished
	fx.queue_free()
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
