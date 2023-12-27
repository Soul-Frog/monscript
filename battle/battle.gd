class_name Battle
extends Node2D

const BATTLE_MON_SCRIPT := preload("res://battle/battle_mon.gd")

class BattleResult:
	var end_condition
	var xp_earned
	
	func _init():
		end_condition = Global.BattleEndCondition.NONE
		xp_earned = 0

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

# positions of mons in battle scene
var MON_Z
var PLAYER_MON_POSITIONS = []
var COMPUTER_MON_POSITIONS = []

var state = BattleState.FINISHED

# Returned at the end of battle; update with battle results and add XP when mons are defeated
var battle_result

# Queue of mons ready to take actions, in order that turns should be taken
var action_queue = []

# Tracks whether a mon is currently taking an action
# Only one mon can take an action at a time (due to animations, etc)
var is_a_mon_taking_action = false

# If mons are being commanded to escape
var trying_to_escape = false

@onready var _player_mons = $Mons/PlayerMons
@onready var _computer_mons = $Mons/ComputerMons
@onready var _animator = $Mons/Animator

@onready var _speed_controls = $UI/SpeedControls
@onready var _escape_controls = $UI/EscapeControls
@onready var _action_name_box = $UI/ActionNameBox
@onready var _mon_action_queue = $UI/Queue
@onready var _inject_battery = $UI/InjectBattery
@onready var _inject_layer = $UI/InjectLayer
@onready var _log = $UI/Log
@onready var _player_mon_blocks = $UI/PlayerMonBlocks
@onready var _computer_mon_blocks = $UI/ComputerMonBlocks
@onready var _results = $UI/Results

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(_player_mons)
	assert(_computer_mons)
	assert(_animator)
	assert(_player_mons.get_children().size() == GameData.MONS_PER_TEAM, "Wrong number of player placeholder positions!")
	assert(_computer_mons.get_children().size() == GameData.MONS_PER_TEAM, "Wrong number of computer placeholder positions!")
	
	assert(_speed_controls)
	assert(_action_name_box)
	assert(_mon_action_queue)
	assert(_inject_battery)
	assert(_inject_layer)
	assert(_player_mon_blocks)
	assert(_computer_mon_blocks)
	for placeholder in _player_mons.get_children():
		PLAYER_MON_POSITIONS.append(placeholder.position)
	for placeholder in _computer_mons.get_children():
		COMPUTER_MON_POSITIONS.append(placeholder.position)
	MON_Z = _player_mons.z_index
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
	new_mon.battle_log = _log
	new_mon.action_name_box = _action_name_box
	return new_mon

# Sets up a new battle scene
func setup_battle(player_team, computer_team):
	assert(state == BattleState.EMPTY) # Make sure previous battle was cleaned up; this can also happen if 2 battle start at once (accidentally layered overworld mons)
	assert(_player_mons.get_child_count() == 0, "Shouldn't have any mons at start of setup! (forgot to clear_battle()?)")
	assert(_computer_mons.get_child_count() == 0, "Shouldn't have any mons at start of setup! (forgot to clear_battle()?)")
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
			var new_mon = _create_and_setup_mon(player_team[i], _player_mons, PLAYER_MON_POSITIONS[i], _player_mon_blocks.get_child(i), Team.PLAYER)
			
			# set up log name and color for this mon
			new_mon.log_color = _log.PLAYER_TEAM_COLOR
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
			var new_mon = _create_and_setup_mon(computer_team[i], _computer_mons, COMPUTER_MON_POSITIONS[i], _computer_mon_blocks.get_child(i), Team.COMPUTER)
			
			# set up log name and color for this mon
			new_mon.log_color = _log.ENEMY_TEAM_COLOR
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
	
	assert(_player_mons.get_child_count() != 0, "No valid player mons!")
	assert(_computer_mons.get_child_count() != 0, "No valid computer mons!")
	assert(action_queue.size() == 0)
	assert(not is_a_mon_taking_action)
	state = BattleState.BATTLING
	
	_mon_action_queue.update_queue(action_queue, _player_mons, _computer_mons)
	
	_log.add_text("Executing battle!")

# Should be called after a battle ends, before the next call to setup_battle
func clear_battle():
	assert(state == BattleState.FINISHED) 
	for mon in _player_mons.get_children():
		mon.queue_free()
	for mon in _computer_mons.get_children():
		mon.queue_free();
	for block in _player_mon_blocks.get_children():
		block.remove_mon()
	for block in _computer_mon_blocks.get_children():
		block.remove_mon()
		
	state = BattleState.EMPTY
	battle_result = BattleResult.new()
	_log.clear()

func _get_living_mons(mons: Array) -> Array:
	var living = []
	for m in mons:
		if not m.is_defeated():
			living.append(m)
	return living

func _process(delta: float):
	if state == BattleState.FINISHED: #viewing results, so no need to update
		return
	
	# if nobody is moving and we aren't in an inject, update the mons
	if not is_a_mon_taking_action and not _inject_layer.is_injecting():
		assert(state == BattleState.BATTLING) 	# make sure battle was set up properly
		# let everyone update/action
		# mons already in action queue are waiting to take a turn and 
		# don't need to recieve updates
		for player_mon in _player_mons.get_children():
			if not player_mon in action_queue:
				player_mon.battle_tick(delta)
		for computer_mon in _computer_mons.get_children():
			if not computer_mon in action_queue:
				computer_mon.battle_tick(delta)
	
		# and if someone is ready to move, go ahead and let them take an action
		if not action_queue.is_empty():
			var active_mon = action_queue.front()
			is_a_mon_taking_action = true
			
			# get living player mons
			var player_mons = _get_living_mons(_player_mons.get_children())
			# get living computer mons
			var computer_mons = _get_living_mons(_computer_mons.get_children())
			
			var friends = player_mons if active_mon in player_mons else computer_mons
			var foes = computer_mons if active_mon in player_mons else player_mons
			var force_escape =  active_mon in player_mons and trying_to_escape
			active_mon.take_action(friends, foes, _animator, force_escape)

func _are_any_computer_mons_alive():
	for computer_mon in _computer_mons.get_children():
		if not computer_mon.is_defeated():
			return true
	return false

func _are_any_player_mons_alive():
	for player_mon in _player_mons.get_children():
		if not player_mon.is_defeated():
			return true
	return false

func _on_mon_ready_to_take_action(mon):
	assert(state == BattleState.BATTLING)
	assert(not mon in action_queue, "Mon is already in queue?")
	action_queue.append(mon); # add to queue

func _on_mon_try_to_escape(battle_mon):
	assert(state == BattleState.BATTLING)
	
	_log.add_text("%s is trying to escape..." % _log.MON_NAME_PLACEHOLDER, battle_mon)
	
	var mon = battle_mon.base_mon
	
	# if a player's mon is trying to escape
	if battle_mon in _player_mons.get_children():
		var my_speed = mon.get_speed()
		
		var computer_avg_speed = 0
		for computer_mon in _computer_mons.get_children():
			computer_avg_speed += computer_mon.base_mon.get_speed()
		computer_avg_speed /= _computer_mons.get_child_count()
		
		var escape_chance = clamp(50 + 3 * (my_speed - computer_avg_speed), 10, 100)
		
		if escape_chance >= Global.RNG.randi_range(1, 100):
			_log.add_text("Escaped successfully!")
			battle_result.end_condition = Global.BattleEndCondition.ESCAPE
			_end_battle_and_show_results()
		else:
			_log.add_text("Escape failed.")
	else:
		assert(battle_mon in _computer_mons.get_children(), "Escaping enemy mon isn't in ComputerMons?")
		_log.add_text("%s ran away!" % _log.MON_NAME_PLACEHOLDER, battle_mon)
		_computer_mons.remove_child(battle_mon)
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
	_mon_action_queue.update_queue(action_queue, _player_mons, _computer_mons)

func _on_mon_zero_health(mon):
	assert(state == BattleState.BATTLING)
	
	_log.add_text("%s has been terminated!" % _log.MON_NAME_PLACEHOLDER, mon)
	
	# increment xp earned from battle if this was a computer mon
	# min exp earn is 1; so level 0 mons still provide 1 xp
	if mon in _computer_mons.get_children():
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
		battle_result.end_condition = Global.BattleEndCondition.WIN
		_end_battle_and_show_results()
	elif not player_mons_alive and computer_mons_alive:
		battle_result.end_condition = Global.BattleEndCondition.LOSE
		_end_battle_and_show_results()
	elif not player_mons_alive and not computer_mons_alive:
		battle_result.end_condition = Global.BattleEndCondition.WIN
		_end_battle_and_show_results()

func _end_battle_and_show_results():
	assert(battle_result)
	assert(battle_result.end_condition != Global.BattleEndCondition.NONE)
	state = BattleState.FINISHED
	_log.add_text("Battle terminated.")
	_results.show_results(battle_result)

func _on_results_exited():
	Events.emit_signal("battle_ended", battle_result)

func _on_speed_controls_changed():
	if not _inject_layer.is_injecting(): # can't update speed during inject
		_set_speed(_speed_controls.speed)

func _set_speed(speed):
	if is_inside_tree():
		var new_speed_multiplier = _speed_to_speed[speed]
		
		for node in get_tree().get_nodes_in_group("battle_speed_scaled"):
			node.set_speed_scale(new_speed_multiplier)
		
		# if we paused, make the log scrollable, otherwise make it unscrollable again
		if new_speed_multiplier == 0:
			_log.make_scrollable_and_expandable()
		else:
			_log.make_unscrollable_and_unexpandable()

func _on_escape_state_changed(is_escaping: bool):
	trying_to_escape = is_escaping
	if trying_to_escape:
		_log.add_text("Your mons will try to escape!")

# returns whether an inject is possible
func _can_inject() -> bool:
	return GameData.inject_points >= GameData.POINTS_PER_INJECT

func _input(event: InputEvent):
	if not _inject_layer.is_injecting():
		if Input.is_action_just_pressed("battle_run"):
			_speed_controls.run()
		elif Input.is_action_just_pressed("battle_speedup"):
			_speed_controls.speedup()
		elif Input.is_action_just_pressed("battle_pause"):
			_speed_controls.pause()
		
		if Input.is_action_just_pressed("battle_toggle_escape"):
			_escape_controls.toggle_escape()
		
		if Input.is_action_just_pressed("battle_log_expand_or_shrink") and _log.can_expand():
			_log.toggle_expand()
		
		if Input.is_action_just_pressed("battle_inject") and _can_inject():
			# reduce inject points and update bar
			assert(GameData.inject_points >= GameData.POINTS_PER_INJECT)
			GameData.inject_points -= GameData.POINTS_PER_INJECT
			_inject_battery.update()
			
			# hide the speed and escape controls while we inject
			var tween = create_tween()
			tween.tween_property(_speed_controls, "modulate:a", 0, 0.2)
			tween.parallel().tween_property(_escape_controls, "modulate:a", 0, 0.2)
			
			_set_speed(Speed.NORMAL)
			_inject_layer.start_inject(_log, _animator, _get_living_mons(_player_mons.get_children()), _get_living_mons(_computer_mons.get_children()))

func _on_inject_completed():
	# show the controls
	var tween = create_tween()
	tween.tween_property(_speed_controls, "modulate:a", 1, 0.2)
	tween.parallel().tween_property(_escape_controls, "modulate:a", 1, 0.2)
	
	# update the speed post-inject to match the buttons
	_set_speed(_speed_controls.speed)
