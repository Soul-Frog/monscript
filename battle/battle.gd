extends Node2D

signal battle_ended

var player_mons
var computer_mons

# Called when the node enters the scene tree for the first time.
func _ready():
	# later, this needs to be updated; when battle loads, update these
	player_mons = [$magnetFrog]
	computer_mons = [$"magnetFrog (Enemy)"]
	
	var timer = Timer.new()
	timer.autostart = true
	add_child(timer)
	timer.wait_time = 0.05
	timer.timeout.connect(_battle_tick)

func _battle_tick():
	# let everyone update/action
	for player_mon in player_mons:
		player_mon.battle_tick()
	for computer_mon in computer_mons:
		computer_mon.battle_tick()

	# check if the battle is over
	var player_mons_alive = _are_any_player_mons_alive()
	var computer_mons_alive = _are_any_computer_mons_alive()
	
	if player_mons_alive and not computer_mons_alive:
		emit_signal("battle_ended", true)
	elif not player_mons_alive and computer_mons_alive:
		emit_signal("battle_ended", false)
	elif not player_mons_alive and not computer_mons_alive:
		emit_signal("battle_ended", true) #for now a tie counts as a win

func _are_any_computer_mons_alive():
	for computer_mon in computer_mons:
		if not computer_mon.is_defeated():
			return true
	return false

func _are_any_player_mons_alive():
	for player_mon in player_mons:
		if not player_mon.is_defeated():
			return true
	return false


func _on_mon_ready_to_take_turn(mon):
	if mon in player_mons: 
		mon.take_action(player_mons, computer_mons)
	else:
		mon.take_action(computer_mons, player_mons)
