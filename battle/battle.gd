class_name Battle
extends Node2D

const BATTLE_MON_SCRIPT := preload("res://battle/battle_mon.gd")

class BattleResult:
	var end_condition
	var xp_earned
	
	func _init():
		end_condition = Global.BattleEndCondition.NONE
		xp_earned = 0

var state = BattleState.FINISHED
enum BattleState {
	EMPTY, # this battle scene has no mons; it's ready for a call to setup_battle
	BATTLING, # this battle scene is ready to go (after setup_battle, before battle has ended)
	FINISHED # this battle scene is over; it's ready for a call to clear_battle
}

enum Team {
	PLAYER, COMPUTER
}

enum Speed {
	NORMAL, SPEEDUP, PAUSE
}
var _speed_to_speed = {
	Speed.NORMAL : 1.0,
	Speed.SPEEDUP : 5.0,
	Speed.PAUSE : 0.0
}
@onready var _speed_controls = $SpeedControls

# positions of mons in battle scene
var MON_Z
var PLAYER_MON_POSITIONS = []
var COMPUTER_MON_POSITIONS = []
# Returned at the end of battle; update with battle results and add XP when mons are defeated
var battle_result

# Queue of mons ready to take actions, in order that turns should be taken
var action_queue = []

# Tracks whether a mon is currently taking an action
# Only one mon can take an action at a time (due to animations, etc)
var is_a_mon_taking_action = false

# If mons are being commanded to escape
@onready var _escape_controls = $EscapeControls
var trying_to_escape = false

@onready var _action_name_box = $ActionNameBox

@onready var _mon_action_queue = $Queue

@onready var _inject_battery = $InjectBattery

@onready var _inject_layer = $InjectLayer

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(_speed_controls)
	assert(_action_name_box)
	assert(_mon_action_queue)
	assert(_inject_battery)
	assert(_inject_layer)
	assert($PlayerMons.get_children().size() == GameData.MONS_PER_TEAM, "Wrong number of player placeholder positions!")
	assert($ComputerMons.get_children().size() == GameData.MONS_PER_TEAM, "Wrong number of computer placeholder positions!")
	for placeholder in $PlayerMons.get_children():
		PLAYER_MON_POSITIONS.append(placeholder.position)
	for placeholder in $ComputerMons.get_children():
		COMPUTER_MON_POSITIONS.append(placeholder.position)
	MON_Z = $PlayerMons.z_index
	state = BattleState.FINISHED
	battle_result = BattleResult.new()
	clear_battle();

# Helper function which creates and connects signals for BattleMon
func _create_and_setup_mon(base_mon, teamNode, pos, monblock, team):
	var new_mon = load(base_mon.get_scene_path()).instantiate()
	new_mon.z_index = MON_Z
	new_mon.add_to_group("battle_speed_scaled")
	new_mon.set_script(BATTLE_MON_SCRIPT)
	new_mon.init_mon(base_mon, team)
	monblock.assign_mon(new_mon)
	teamNode.add_child(new_mon)
	new_mon.ready_to_take_action.connect(self._on_mon_ready_to_take_action)
	new_mon.try_to_escape.connect(self._on_mon_try_to_escape)
	new_mon.zero_health.connect(self._on_mon_zero_health)
	new_mon.action_completed.connect(self._on_mon_action_completed)
	new_mon.position = pos
	new_mon.battle_log = $Log
	new_mon.action_name_box = _action_name_box
	return new_mon

# Sets up a new battle scene
func setup_battle(player_team, computer_team):
	assert(state == BattleState.EMPTY) # Make sure previous battle was cleaned up; this can also happen if 2 battle start at once (accidentally layered overworld mons)
	assert($PlayerMons.get_child_count() == 0, "Shouldn't have any mons at start of setup! (forgot to clear_battle()?)")
	assert($ComputerMons.get_child_count() == 0, "Shouldn't have any mons at start of setup! (forgot to clear_battle()?)")
	assert(player_team.size() == GameData.MONS_PER_TEAM, "Wrong num of mons in player team!")
	assert(computer_team.size() == COMPUTER_MON_POSITIONS.size(), "Wrong num of mons in computer team!")
	
	# fancy lambda which makes the log_name of each mon unique
	# if a mon has no shared name, does nothing
	# otherwise changes it to "Bitleon1", "Bitleon2", "Bitleon3", etc
	# name_map is a dictionary of names (string) -> array[battlemons with that name]
	var make_unique_log_names = func(name_map):
		for mon_name in name_map.keys():
			if name_map[mon_name].size() == 1:
				continue # don't append numbers if name is not shared
			for i in name_map[mon_name].size():
				name_map[mon_name][i].log_name = "%s%d" % [mon_name, i+1]
	
	# add mons for the new battle
	var name_map = {} # store all mon names to handle duplicates for the battle log
	for i in GameData.MONS_PER_TEAM:
		if player_team[i] != null:
			var new_mon = _create_and_setup_mon(player_team[i], $PlayerMons, PLAYER_MON_POSITIONS[i], $PlayerMonBlocks.get_child(i), Team.PLAYER)
			
			# set up log name and color for this mon
			new_mon.log_color = $Log.PLAYER_TEAM_COLOR
			var mon_name = new_mon.log_name
			if name_map.has(mon_name):
				name_map[mon_name].append(new_mon) 
			else:
				name_map[mon_name] = [new_mon]
	
	# handle any duplicate names
	make_unique_log_names.call(name_map)
	name_map.clear()
	
	for i in GameData.MONS_PER_TEAM:
		if computer_team[i] != null:
			var new_mon = _create_and_setup_mon(computer_team[i], $ComputerMons, COMPUTER_MON_POSITIONS[i], $ComputerMonBlocks.get_child(i), Team.COMPUTER)
			
			# set up log name and color for this mon
			new_mon.log_color = $Log.ENEMY_TEAM_COLOR
			var mon_name = new_mon.log_name
			if name_map.has(mon_name):
				name_map[mon_name].append(new_mon) 
			else:
				name_map[mon_name] = [new_mon]

	# handle any duplicate names
	make_unique_log_names.call(name_map)
	
	action_queue.clear()
	is_a_mon_taking_action = false
	trying_to_escape = false
	
	_speed_controls.reset()
	_escape_controls.reset()
	_action_name_box.reset()
	
	_inject_battery.update()
	
	assert($PlayerMons.get_child_count() != 0, "No valid player mons!")
	assert($ComputerMons.get_child_count() != 0, "No valid computer mons!")
	assert(action_queue.size() == 0)
	assert(not is_a_mon_taking_action)
	state = BattleState.BATTLING
	
	_mon_action_queue.update_queue(action_queue, $PlayerMons, $ComputerMons)
	
	$Log.add_text("Executing battle!")

# Should be called after a battle ends, before the next call to setup_battle
func clear_battle():
	assert(state == BattleState.FINISHED) 
	for mon in $PlayerMons.get_children():
		mon.queue_free()
	for mon in $ComputerMons.get_children():
		mon.queue_free();
	for block in $PlayerMonBlocks.get_children():
		block.remove_mon()
	for block in $ComputerMonBlocks.get_children():
		block.remove_mon()
		
	state = BattleState.EMPTY
	battle_result = BattleResult.new()
	$Log.clear()

func _get_living_mons(mons: Array) -> Array:
	var living = []
	for m in mons:
		if not m.is_defeated():
			living.append(m)
	return living

func _process(delta: float):
	assert(state == BattleState.BATTLING) 	# make sure battle was set up properly
	
	# if nobody is moving and we aren't in an inject, update the mons
	if not is_a_mon_taking_action and not $InjectLayer.is_injecting():
		# let everyone update/action
		# mons already in action queue are waiting to take a turn and 
		# don't need to recieve updates
		for player_mon in $PlayerMons.get_children():
			if not player_mon in action_queue:
				player_mon.battle_tick(delta)
		for computer_mon in $ComputerMons.get_children():
			if not computer_mon in action_queue:
				computer_mon.battle_tick(delta)
	
		# and if someone is ready to move, go ahead and let them take an action
		if not action_queue.is_empty():
			var active_mon = action_queue.front()
			is_a_mon_taking_action = true
			
			# get living player mons
			var player_mons = _get_living_mons($PlayerMons.get_children())
			# get living computer mons
			var computer_mons = _get_living_mons($ComputerMons.get_children())
			
			var friends = player_mons if active_mon in player_mons else computer_mons
			var foes = computer_mons if active_mon in player_mons else player_mons
			var force_escape =  active_mon in player_mons and trying_to_escape
			active_mon.take_action(friends, foes, $Animator, force_escape)

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
	
	$Log.add_text("%s is trying to escape..." % $Log.MON_NAME_PLACEHOLDER, battle_mon)
	
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
			$Log.add_text("Escaped successfully!")
			Events.emit_signal("battle_ended", battle_result)
		else:
			$Log.add_text("Escape failed.")
	else:
		assert(battle_mon in $ComputerMons.get_children(), "Escaping enemy mon isn't in ComputerMons?")
		$Log.add_text("%s ran away!" % $Log.MON_NAME_PLACEHOLDER, battle_mon)
		$ComputerMons.remove_child(battle_mon)
		battle_mon.queue_free()
		_check_battle_end_condition()
		

func _on_mon_action_completed():
	assert(is_a_mon_taking_action)
	
	# if this action was performed by a player mon, make progress towards inject
	if action_queue[0].team == Team.PLAYER:
		# add 1 point, but not more than the maximum amount for the bars
		GameData.inject_points = min(GameData.inject_points + 1, GameData.get_var(GameData.MAX_INJECTS) * GameData.POINTS_PER_INJECT)
		_inject_battery.update() # and update the graphic
	
	action_queue.remove_at(0)
	is_a_mon_taking_action = false
	_mon_action_queue.update_queue(action_queue, $PlayerMons, $ComputerMons)
	
	

func _on_mon_zero_health(mon):
	assert(state == BattleState.BATTLING)
	
	$Log.add_text("%s has been terminated!" % $Log.MON_NAME_PLACEHOLDER, mon)
	
	# increment xp earned from battle if this was a computer mon
	# min exp earn is 1; so level 0 mons still provide 1 xp
	if mon in $ComputerMons.get_children():
		battle_result.xp_earned += max(mon.base_mon.get_level(), 1)
	# hide this mon to 'remove' it from the scene
	# removing from scene here with something like queue_free would cause errors
	mon.visible = false
	
	# remove this mon from the action queue if needed
	# don't remove from front of queue; since if this mon died performing an action, it will remove itself
	# and if it died from another mon's action, it must not have been at the front
	for i in range(1, action_queue.size()):
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
		$Log.add_text("Battle terminated.")
		Events.emit_signal("battle_ended", battle_result)
	elif not player_mons_alive and computer_mons_alive:
		state = BattleState.FINISHED
		battle_result.end_condition = Global.BattleEndCondition.LOSE
		$Log.add_text("Battle terminated.")
		Events.emit_signal("battle_ended", battle_result)
	elif not player_mons_alive and not computer_mons_alive:
		state = BattleState.FINISHED
		battle_result.end_condition = Global.BattleEndCondition.WIN
		$Log.add_text("Battle terminated.")
		Events.emit_signal("battle_ended", battle_result) # tie also counts as a win

func _on_speed_changed():
	if is_inside_tree():
		var new_speed = _speed_to_speed[_speed_controls.speed]
		
		for node in get_tree().get_nodes_in_group("battle_speed_scaled"):
			node.set_speed_scale(new_speed)
		
		# if we paused, make the log scrollable, otherwise make it unscrollable again
		if new_speed == 0:
			$Log.make_scrollable_and_expandable()
		else:
			$Log.make_unscrollable_and_unexpandable()

func _on_escape_state_changed(is_escaping: bool):
	trying_to_escape = is_escaping
	if trying_to_escape:
		$Log.add_text("Your mons will try to escape!")

# returns whether an inject is possible
func _can_inject() -> bool:
	return GameData.inject_points >= GameData.POINTS_PER_INJECT

func _input(event: InputEvent):
	if not $InjectLayer.is_injecting():
		if Input.is_action_just_pressed("battle_run"):
			_speed_controls.run()
		elif Input.is_action_just_pressed("battle_speedup"):
			_speed_controls.speedup()
		elif Input.is_action_just_pressed("battle_pause"):
			_speed_controls.pause()
		
		if Input.is_action_just_pressed("battle_toggle_escape"):
			_escape_controls.toggle_escape()
		
		if Input.is_action_just_pressed("battle_log_expand_or_shrink") and $Log.can_expand():
			$Log.toggle_expand()
		
		if Input.is_action_just_pressed("battle_inject") and _can_inject():
			# reduce inject points and update bar
			assert(GameData.inject_points >= GameData.POINTS_PER_INJECT)
			GameData.inject_points -= GameData.POINTS_PER_INJECT
			_inject_battery.update()
			_toggle_controls_visibility_for_inject() # hide the speeds, escape, and action queue
			_inject_layer.start_inject($Log, $PlayerMons.get_children(), $ComputerMons.get_children())

func _on_inject_completed():
	_toggle_controls_visibility_for_inject()

func _toggle_controls_visibility_for_inject():
	_speed_controls.visible = not _speed_controls.visible
	_escape_controls.visible = not _escape_controls.visible
	_mon_action_queue.visible = not _mon_action_queue.visible
