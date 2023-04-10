extends Node2D

signal battle_ended

var friends
var foes

# Called when the node enters the scene tree for the first time.
func _ready():
	# later, this needs to be updated; when battle loads, update these
	friends = [$magnetFrog]
	foes = [$"magnetFrog (Enemy)"]
	
	var timer = Timer.new()
	timer.autostart = true
	add_child(timer)
	timer.wait_time = 1.0
	timer.timeout.connect(_battle_tick)

func _battle_tick():
	# let everyone update/action
	for friend in friends:
		friend.battle_tick()
	for foe in foes:
		foe.battle_tick()

	# check if the battle is over
	var friends_alive = _are_any_friends_alive()
	var foes_alive = _are_any_foes_alive()
	
	if friends_alive and not foes_alive:
		print("Battle Win") # player wins
		emit_signal("battle_ended")
	elif not friends_alive and foes_alive:
		print("Battle Lose") # player loses
		emit_signal("battle_ended")
	else:
		print("Battle Win") # player ties?
		emit_signal("battle_ended")

func _are_any_foes_alive():
	for foe in foes:
		if not foe.is_defeated():
			return false
	return true

func _are_any_friends_alive():
	for friend in friends:
		if not friend.is_defeated():
			return false
	return true
