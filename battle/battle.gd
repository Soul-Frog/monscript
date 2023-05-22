extends Node2D

class BattleResult:
	var end_condition
	var xp_earned
	
	func _init():
		end_condition = Global.BattleEndCondition.NONE
		xp_earned = 0

var state
enum BattleState {
	EMPTY, # this battle scene has no mons; it's ready for a call to setup_battle
	BATTLING, # this battle scene is ready to go (after setup_battle, before battle has ended)
	FINISHED # this battle scene is over; it's ready for a call to clear_battle
}

const BATTLE_MON_SCRIPT = preload("res://battle/battle_mon.gd")

@onready var timer = $Timer

# positions of mons in battle scene
@onready var PLAYER_MON_POSITIONS = [$PlayerMons/Mon1.position, $PlayerMons/Mon2.position, $PlayerMons/Mon3.position, $PlayerMons/Mon4.position]
@onready var COMPUTER_MON_POSITIONS = [$ComputerMons/Mon1.position, $ComputerMons/Mon2.position, $ComputerMons/Mon3.position, $ComputerMons/Mon4.position]

# Returned at the end of battle; update with battle results and add XP when mons are defeated
var battle_result

# Queue of mons ready to take actions, in order that turns should be taken
var action_queue = []

# Tracks whether a mon is currently taking an action
# Only one mon can take an action at a time (due to animations, etc)
var is_a_mon_taking_action = false

# Called when the node enters the scene tree for the first time.
func _ready():
	state = BattleState.FINISHED
	battle_result = BattleResult.new()
	clear_battle();

# Helper function which creates and connects signals for BattleMon
func _create_and_setup_mon(base_mon, teamNode, pos):
	var new_mon = load(base_mon.get_scene()).instantiate()
	for battle_component in new_mon.get_node("BattleComponents").get_children():
		battle_component.visible = true
	new_mon.set_script(BATTLE_MON_SCRIPT)
	new_mon.init_mon(base_mon)
	teamNode.add_child(new_mon)
	new_mon.ready_to_take_action.connect(self._on_mon_ready_to_take_action)
	new_mon.try_to_escape.connect(self._on_mon_try_to_escape)
	new_mon.zero_health.connect(self._on_mon_zero_health)
	new_mon.action_completed.connect(self._on_mon_action_completed)
	new_mon.position = pos

# Sets up a new battle scene
func setup_battle(player_team, computer_team):
	assert(state == BattleState.EMPTY) # Make sure previous battle was cleaned up
	assert($PlayerMons.get_child_count() == 0, "Shouldn't have any mons at start of setup! (forgot to clear_battle()?)")
	assert($ComputerMons.get_child_count() == 0, "Shouldn't have any mons at start of setup! (forgot to clear_battle()?)")
	
	# add mons for the new battle
	for i in player_team.size():
		assert(i < PLAYER_MON_POSITIONS.size(), "Too many mons in player team!")
		_create_and_setup_mon(player_team[i], $PlayerMons, PLAYER_MON_POSITIONS[i])
	for i in computer_team.size():
		assert(i < COMPUTER_MON_POSITIONS.size(), "Too many mons in computer team!")
		_create_and_setup_mon(computer_team[i], $ComputerMons, COMPUTER_MON_POSITIONS[i])
	action_queue.clear()
	is_a_mon_taking_action = false
	
	assert($PlayerMons.get_child_count() != 0, "No player mons!")
	assert($ComputerMons.get_child_count() != 0, "No computer mons!")
	assert(action_queue.size() == 0)
	assert(not is_a_mon_taking_action)
	state = BattleState.BATTLING

# Should be called after a battle ends, before the next call to setup_battle
func clear_battle():
	assert(state == BattleState.FINISHED) 
	for mon in $PlayerMons.get_children():
		mon.queue_free()
	for mon in $ComputerMons.get_children():
		mon.queue_free();
	state = BattleState.EMPTY
	battle_result = BattleResult.new()
	timer.start() # sets timer to 0 again

func _battle_tick():
	assert(state == BattleState.BATTLING) 	# make sure battle was set up properly
	
	# let everyone update/action
	# mons already in action queue are waiting to take a turn and 
	# don't need to recieve updates
	for player_mon in $PlayerMons.get_children():
		if not player_mon in action_queue:
			player_mon.battle_tick()
	for computer_mon in $ComputerMons.get_children():
		if not computer_mon in action_queue:
			computer_mon.battle_tick()
	
	# if no other mon is active, let the mon in front of queue take action
	if not is_a_mon_taking_action and not action_queue.is_empty():
		var active_mon = action_queue.front()
		is_a_mon_taking_action = true
		
		# get living player mons
		var player_mons = []
		for m in $PlayerMons.get_children():
			if not m.is_defeated():
				player_mons.append(m)
		
		# get living computer mons
		var computer_mons = []
		for m in $ComputerMons.get_children():
			if not m.is_defeated():
				computer_mons.append(m)
		
		var friends = player_mons if active_mon in player_mons else computer_mons
		var foes = computer_mons if active_mon in player_mons else player_mons
		active_mon.take_action(friends, foes, $Animator)

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

func _on_mon_ready_to_take_action(mon):
	assert(state == BattleState.BATTLING)
	assert(not mon in action_queue, "Mon is already in queue?")
	action_queue.append(mon); # add to queue

func _on_mon_try_to_escape(battle_mon):
	assert(state == BattleState.BATTLING)
	
	var mon = battle_mon.base_mon
	
	# if a player's mon is trying to escape
	if battle_mon in $PlayerMons.get_children():
		var my_speed = mon.get_speed()
		
		var computer_avg_speed = 0
		for computer_mon in $ComputerMons.get_children():
			computer_avg_speed += computer_mon.base_mon.get_speed()
		computer_avg_speed /= $ComputerMons.get_child_count()
		
		var escape_chance = clamp(50 + 3 * (my_speed - computer_avg_speed), 10, 100)
		
		if escape_chance >= Global.RNG.randi_range(1, 100):
			battle_result.end_condition = Global.BattleEndCondition.ESCAPE
			state = BattleState.FINISHED
			Events.emit_signal("battle_ended", battle_result)
	else:
		print("Enemy mon tried to escape!")

func _on_mon_action_completed():
	assert(is_a_mon_taking_action)
	action_queue.remove_at(0)
	is_a_mon_taking_action = false

func _on_mon_zero_health(mon):
	assert(state == BattleState.BATTLING)
	# increment xp earned from battle if this was a computer mon
	# min exp earn is 1; so level 0 mons still provide 1 xp
	if mon in $ComputerMons.get_children():
		battle_result.xp_earned += max(mon.base_mon.level, 1)
	# hide this mon to 'remove' it from the scene
	# removing from scene here with something like queue_free would cause errors
	mon.visible = false
	
	# remove this mon from the action queue if needed
	for i in range(0, action_queue.size()):
		if action_queue[i] == mon:
			action_queue.remove_at(i)
			break
	
	# a mon was defeated, so is the battle now over?
	_check_battle_end_condition()
	
# Checks if the battle is over and signals if that is the case
func _check_battle_end_condition():
	var player_mons_alive = _are_any_player_mons_alive()
	var computer_mons_alive = _are_any_computer_mons_alive()
	
	if player_mons_alive and not computer_mons_alive:
		state = BattleState.FINISHED
		battle_result.end_condition = Global.BattleEndCondition.WIN
		Events.emit_signal("battle_ended", battle_result)
	elif not player_mons_alive and computer_mons_alive:
		state = BattleState.FINISHED
		battle_result.end_condition = Global.BattleEndCondition.LOSE
		Events.emit_signal("battle_ended", battle_result)
	elif not player_mons_alive and not computer_mons_alive:
		state = BattleState.FINISHED
		battle_result.end_condition = Global.BattleEndCondition.WIN
		Events.emit_signal("battle_ended", battle_result) # tie also counts as a win
