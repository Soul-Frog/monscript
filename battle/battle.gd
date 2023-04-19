extends Node2D

signal battle_ended

enum {
	EMPTY, # this battle scene has no mons; it's ready for a call to setup_battle
	BATTLING, # this battle scene is ready to go (after setup_battle, before battle has ended)
	FINISHED # this battle scene is over; it's ready for a call to clear_battle
}

var state
@onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	state = EMPTY

# Sets up a new battle scene
func setup_battle(player_team, computer_team):
	assert(state == EMPTY) # Make sure previous battle was cleaned up
	assert($PlayerMons.get_child_count() == 0, "Shouldn't have any mons at start of setup! (forgot to clear_battle()?)")
	assert($ComputerMons.get_child_count() == 0, "Shouldn't have any mons at start of setup! (forgot to clear_battle()?)")
	
	# add mons for the new battle
	for mon in player_team:
		var new_mon = load("res://battle/battle_mon.tscn").instantiate()
		new_mon.init_mon(mon)
		$PlayerMons.add_child(new_mon)
		new_mon.ready_to_take_turn.connect(self._on_mon_ready_to_take_turn)
		new_mon.try_to_escape.connect(self._on_mon_ready_to_take_turn)
		new_mon.position = Vector2(121, 91)
	
	for mon in computer_team:
		var new_mon = load("res://battle/battle_mon.tscn").instantiate()
		new_mon.init_mon(mon)
		$ComputerMons.add_child(new_mon)
		new_mon.ready_to_take_turn.connect(self._on_mon_ready_to_take_turn)
		new_mon.try_to_escape.connect(self._on_mon_ready_to_take_turn)
		new_mon.position = Vector2(199, 91)
	
	assert($PlayerMons.get_child_count() != 0, "No player mons!")
	assert($ComputerMons.get_child_count() != 0, "No computer mons!")
	state = BATTLING

# Should be called after a battle ends, before the next call to setup_battle
func clear_battle():
	assert(state == FINISHED) 
	for mon in $PlayerMons.get_children():
		mon.queue_free()
	for mon in $ComputerMons.get_children():
		mon.queue_free();
	state = EMPTY
	timer.start() # sets timer to 0 again

func _battle_tick():
	assert(state == BATTLING) 	# make sure battle was set up properly
	
	# let everyone update/action
	for player_mon in $PlayerMons.get_children():
		player_mon.battle_tick()
	for computer_mon in $ComputerMons.get_children():
		computer_mon.battle_tick()

	# check if the battle is over
	var player_mons_alive = _are_any_player_mons_alive()
	var computer_mons_alive = _are_any_computer_mons_alive()
	
	if player_mons_alive and not computer_mons_alive:
		state = FINISHED
		emit_signal("battle_ended", true)
	elif not player_mons_alive and computer_mons_alive:
		state = FINISHED
		emit_signal("battle_ended", false)
	elif not player_mons_alive and not computer_mons_alive:
		state = FINISHED
		emit_signal("battle_ended", true) #for now a tie counts as a win

func _are_any_computer_mons_alive():
	for computer_mon in $ComputerMons.get_children():
		if not computer_mon.is_defeated():
			return true
	return false

func _are_any_player_mons_alive():
	for player_mon in $PlayerMons.get_children():
		if not player_mon.is_defeated():
			return true
	return false


func _on_mon_ready_to_take_turn(mon):
	assert(state == BATTLING)
	if mon in $PlayerMons.get_children(): 
		mon.take_action($PlayerMons.get_children(), $ComputerMons.get_children())
	else:
		mon.take_action($ComputerMons.get_children(), $PlayerMons.get_children())

func _on_mon_try_to_escape(mon):
	assert(state == BATTLING)
	pass #todo lol
