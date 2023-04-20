extends Node2D

signal battle_ended

enum {
	EMPTY, # this battle scene has no mons; it's ready for a call to setup_battle
	BATTLING, # this battle scene is ready to go (after setup_battle, before battle has ended)
	FINISHED # this battle scene is over; it's ready for a call to clear_battle
}

var state
@onready var timer = $Timer

# positions of mons in battle scene
var PLAYER_MON_POSITIONS
var COMPUTER_MON_POSITIONS

# Called when the node enters the scene tree for the first time.
func _ready():
	PLAYER_MON_POSITIONS = [$PlayerMons/Mon1.position, $PlayerMons/Mon2.position, $PlayerMons/Mon3.position, $PlayerMons/Mon4.position]
	COMPUTER_MON_POSITIONS = [$ComputerMons/Mon1.position, $PlayerMons/Mon2.position, $PlayerMons/Mon3.position, $PlayerMons/Mon4.position]
	state = FINISHED
	clear_battle();

func _create_and_setup_mon(mon, teamNode, position):
	var new_mon = load("res://battle/battle_mon.tscn").instantiate()
	new_mon.init_mon(mon)
	teamNode.add_child(new_mon)
	new_mon.ready_to_take_turn.connect(self._on_mon_ready_to_take_turn)
	new_mon.try_to_escape.connect(self._on_mon_ready_to_take_turn)
	new_mon.position = position

# Sets up a new battle scene
func setup_battle(player_team, computer_team):
	assert(state == EMPTY) # Make sure previous battle was cleaned up
	assert($PlayerMons.get_child_count() == 0, "Shouldn't have any mons at start of setup! (forgot to clear_battle()?)")
	assert($ComputerMons.get_child_count() == 0, "Shouldn't have any mons at start of setup! (forgot to clear_battle()?)")
	
	# add mons for the new battle
	for i in player_team.size():
		assert(i < PLAYER_MON_POSITIONS.size(), "Too many mons in player team!")
		_create_and_setup_mon(player_team[i], $PlayerMons, PLAYER_MON_POSITIONS[i])
	for i in computer_team.size():
		assert(i < COMPUTER_MON_POSITIONS.size(), "Too many mons in computer team!")
		_create_and_setup_mon(computer_team[i], $ComputerMons, COMPUTER_MON_POSITIONS[i])
	
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
