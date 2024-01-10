class_name Battle
extends Node2D

enum BattleState {
	LOADING, # this battle scene has no mons; it's ready for a call to setup_battle
	BATTLING, # this battle scene is ready to go (after setup_battle, before battle has ended)
	FINISHED # this battle scene is over; it's ready for a call to clear_battle
}

enum Team {
	PLAYER, COMPUTER
}

enum Speed {
	NORMAL, SPEEDUP, PAUSE, INSTANT
}
var _speed_to_speed = {
	Speed.NORMAL : 1.0,
	Speed.SPEEDUP : 5.0,
	Speed.PAUSE : 0.0,
	Speed.INSTANT: 10000.0
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
# If an inject has been inputted but not yet started
var is_inject_queued = false
var is_inject_active = false

# If mons are being commanded to escape
var trying_to_escape = false

@onready var _player_mons = $Mons/PlayerMons
@onready var _computer_mons = $Mons/ComputerMons
@onready var _animator = $Mons/Animator

@onready var _speed_controls = $UI/SpeedControls
@onready var _SPEED_POSITION = _speed_controls.position
@onready var _SPEED_SLIDEOUT_POSITION = _SPEED_POSITION + Vector2(0, 60)

@onready var _escape_controls = $UI/EscapeControls
@onready var _ESCAPE_POSITION = _escape_controls.position
@onready var _ESCAPE_SLIDEOUT_POSITION = _ESCAPE_POSITION + Vector2(0, 60)

@onready var _log = $UI/Log
@onready var _LOG_POSITION = _log.position
@onready var _LOG_SLIDEOUT_POSITION = _log.position + Vector2(0, 60)

@onready var _mon_action_queue = $UI/Queue
@onready var _MON_ACTION_QUEUE_POSITION = _mon_action_queue.position
@onready var _MON_ACTION_QUEUE_SLIDEOUT_POSITION = _MON_ACTION_QUEUE_POSITION + Vector2(-30, 0)

@onready var _inject_battery = $UI/InjectBattery
@onready var _INJECT_BATTERY_POSITION = _inject_battery.position
@onready var _INJECT_BATTERY_SLIDEOUT_POSITION = _INJECT_BATTERY_POSITION + Vector2(30, 0)

@onready var _player_mon_blocks = $UI/PlayerMonBlocks
@onready var _computer_mon_blocks = $UI/ComputerMonBlocks
const _MONBLOCK_SLIDEOUT_DELTA = 120

@onready var _inject_layer = $UI/InjectLayer
@onready var _results = $UI/Results
@onready var _banner_label = $UI/BannerLabel
@onready var _script_line_viewer = $UI/ScriptLineViewer

@onready var _terrain = $Scene/Terrain
@onready var _background = $Scene/Background
@onready var _wireframe_terrain = $Scene/Wireframe
@onready var _matrix_rain = $Scene/MatrixRain
@onready var _inject_rain = $Scene/InjectRain
@onready var _INJECT_Z_INDEX = _inject_rain.z_index

# bugs dropped by defeating opponent mons
var _bugs_dropped = []

# used when calculating how much AP to give each turn
var _highest_mon_speed = 0
# how many seconds it should take for the FASTEST mon in the battle to reach 100 AP from 0 AP
# used to scale the speed of AP gain for all mons
const SECONDS_PER_TURN_FOR_FASTEST = 5

# tween used to fade in/out matrix rain
var _matrix_tween = null

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(_player_mons)
	assert(_computer_mons)
	assert(_animator)
	assert(_player_mons.get_children().size() == GameData.MONS_PER_TEAM, "Wrong number of player placeholder positions!")
	assert(_computer_mons.get_children().size() == GameData.MONS_PER_TEAM, "Wrong number of computer placeholder positions!")
	
	assert(_speed_controls)
	assert(_script_line_viewer)
	assert(_mon_action_queue)
	assert(_inject_battery)
	assert(_inject_layer)
	assert(_player_mon_blocks)
	assert(_computer_mon_blocks)
	
	assert(_terrain)
	assert(_wireframe_terrain)
	assert(_background)
	assert(_matrix_rain)
	assert(_inject_rain)
	assert(_banner_label)
	
	# start with all controls out of view
	_mon_action_queue.position = _MON_ACTION_QUEUE_SLIDEOUT_POSITION
	_speed_controls.position = _SPEED_SLIDEOUT_POSITION
	_escape_controls.position = _ESCAPE_SLIDEOUT_POSITION
	
	for placeholder in _player_mons.get_children():
		PLAYER_MON_POSITIONS.append(placeholder.position)
	for placeholder in _computer_mons.get_children():
		COMPUTER_MON_POSITIONS.append(placeholder.position)
	MON_Z = _player_mons.z_index
	state = BattleState.FINISHED
	battle_result = BattleData.BattleResult.new()
	clear_battle();

# Helper function which creates and connects signals for BattleMon
func _create_and_setup_mon(base_mon, teamNode, pos, monblock, team):
	var new_mon = load(base_mon.get_scene_path()).instantiate()
	new_mon.z_index = MON_Z
	new_mon.add_to_group("battle_speed_scaled")
	new_mon.set_script(BattleData.BATTLE_MON_SCRIPT)
	new_mon.init_mon(base_mon, team)
	monblock.assign_mon(new_mon)
	teamNode.add_child(new_mon)
	new_mon.ready_to_take_action.connect(self._on_mon_ready_to_take_action)
	new_mon.try_to_escape.connect(self._on_mon_try_to_escape)
	new_mon.zero_health.connect(self._on_mon_zero_health)
	new_mon.action_completed.connect(self._on_mon_action_completed)
	new_mon.position = pos
	new_mon.battle_log = _log
	new_mon.script_line_viewer = _script_line_viewer
	return new_mon

# Sets up a new battle scene
func setup_battle(player_team, computer_team, battle_background: BattleData.Background):
	assert(state == BattleState.LOADING) # Make sure previous battle was cleaned up; this can also happen if 2 battle start at once (accidentally layered overworld mons)
	assert(battle_background != BattleData.Background.UNDEFINED)
	assert(_player_mons.get_child_count() == 0, "Shouldn't have any mons at start of setup! (forgot to clear_battle()?)")
	assert(_computer_mons.get_child_count() == 0, "Shouldn't have any mons at start of setup! (forgot to clear_battle()?)")
	assert(player_team.size() == GameData.MONS_PER_TEAM, "Wrong num of mons in player team!")
	assert(computer_team.size() == COMPUTER_MON_POSITIONS.size(), "Wrong num of mons in computer team!")
	
	is_a_mon_taking_action = false
	is_inject_queued = false
	is_inject_active = false
	trying_to_escape = false
	_bugs_dropped = []
	
	action_queue.clear()
	_mon_action_queue.reset()
	
	_speed_controls.reset()
	_escape_controls.reset()
	_inject_battery.update()
	_highest_mon_speed = -1
	
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
			
			_highest_mon_speed = max(_highest_mon_speed, new_mon.get_base_speed())
	
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
			
			_highest_mon_speed = max(_highest_mon_speed, new_mon.get_base_speed())			

	# handle any duplicate names
	make_unique_log_names.call(name_map)
	
	assert(_player_mons.get_child_count() != 0, "No valid player mons!")
	assert(_computer_mons.get_child_count() != 0, "No valid computer mons!")
	assert(action_queue.size() == 0)
	assert(not is_a_mon_taking_action)
	
	# set up the queue
	_mon_action_queue.update_queue(action_queue, _player_mons, _computer_mons)
	
	# set up the background/matrix rain
	var background := BattleData.get_background(battle_background) as BattleData.BattleBackground
	_terrain.texture = background.get_map_texture()
	_matrix_rain.color = background.matrix_rain_color
	_background.color = background.background_color
	
	# perform the battle intro
	_log.add_text("Initializing battle...")
	
	# move the monblocks out of view
	for player_block in _player_mon_blocks.get_children():
		player_block.position.x -= _MONBLOCK_SLIDEOUT_DELTA
	for computer_block in _computer_mon_blocks.get_children():
		computer_block.position.x += _MONBLOCK_SLIDEOUT_DELTA

	_log.position = _LOG_SLIDEOUT_POSITION
	_inject_battery.position = _INJECT_BATTERY_SLIDEOUT_POSITION

	# hide mons
	for mon in _computer_mons.get_children() + _player_mons.get_children():
		mon.modulate.a = 0
		
	# hide rain
	if _matrix_tween:
		_matrix_tween.kill()
		_matrix_tween = null
	_matrix_rain.modulate.a = 0 
	
	await Global.delay(0.2)
	_banner_label.display_text("INITIALIZING!")
	await _banner_label.zoom_in()
	
	# fade in the mons
	var fade_in_mon_tween = create_tween()
	for mon in _computer_mons.get_children() + _player_mons.get_children():
		mon.position.y -= 5
		fade_in_mon_tween.parallel().tween_property(mon, "modulate:a", 1, 0.3)
		fade_in_mon_tween.parallel().tween_property(mon, "position:y", mon.position.y + 5, 0.3)
	await fade_in_mon_tween.finished

	# move in the monblocks
	var move_in_monblocks = create_tween()
	for i in _player_mon_blocks.get_child_count():
		var player_block = _player_mon_blocks.get_child(i)
		player_block.show() #unhide; hidden if we escaped last battle
		move_in_monblocks.parallel().tween_property(player_block, "position:x", player_block.position.x + _MONBLOCK_SLIDEOUT_DELTA, 0.3 + (0.05 * i)).set_trans(Tween.TRANS_CUBIC)
	for i in _computer_mon_blocks.get_child_count():
		var computer_block = _computer_mon_blocks.get_child(i)
		move_in_monblocks.parallel().tween_property(computer_block, "position:x", computer_block.position.x - _MONBLOCK_SLIDEOUT_DELTA, 0.3 + (0.05 * i)).set_trans(Tween.TRANS_CUBIC)
	#await move_in_monblocks.finished
	
	# move in the queue/battery/speed/log/escape
	var move_in_ui = create_tween()
	move_in_ui.parallel().tween_property(_mon_action_queue, "position", _MON_ACTION_QUEUE_POSITION, 0.5).set_trans(Tween.TRANS_CUBIC)
	move_in_ui.parallel().tween_property(_inject_battery, "position", _INJECT_BATTERY_POSITION, 0.5).set_trans(Tween.TRANS_CUBIC)
	move_in_ui.parallel().tween_property(_speed_controls, "position", _SPEED_POSITION, 0.5).set_trans(Tween.TRANS_CUBIC)
	move_in_ui.parallel().tween_property(_escape_controls, "position", _ESCAPE_POSITION, 0.5).set_trans(Tween.TRANS_CUBIC)
	move_in_ui.parallel().tween_property(_log, "position", _LOG_POSITION, 0.3).set_trans(Tween.TRANS_CUBIC)
	await move_in_ui.finished

	_log.clear()
	_log.add_text("Executing battle!")
	_banner_label.display_text("EXECUTING!")
	_banner_label.zoom_in()
	assert(not _matrix_tween)
	_matrix_tween = create_tween()
	_matrix_tween.tween_property(_matrix_rain, "modulate:a", 1, 3.0)
	await Global.delay(0.1)
	state = BattleState.BATTLING
	
	await Global.delay(0.7)
	_banner_label.zoom_out()

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
		
	state = BattleState.LOADING
	battle_result = BattleData.BattleResult.new()
	_log.clear()

func _get_living_mons(mons: Array) -> Array:
	var living = []
	for m in mons:
		if not m.is_defeated():
			living.append(m)
	return living

func _process(delta: float):
	if state != BattleState.BATTLING:
		return
	
	if not is_a_mon_taking_action and is_inject_queued and not is_inject_active:
		_start_inject()
	
	# if nobody is moving and we aren't in an inject, update the mons
	if not is_a_mon_taking_action and not is_inject_active:
		assert(state == BattleState.BATTLING) 	# make sure battle was set up properly
		
		# let everyone update/action
		# mons already in action queue are waiting to take a turn and 
		# don't need to recieve updates
		for player_mon in _player_mons.get_children():
			if not player_mon in action_queue:
				player_mon.battle_tick(delta, _highest_mon_speed, SECONDS_PER_TURN_FOR_FASTEST)
		for computer_mon in _computer_mons.get_children():
			if not computer_mon in action_queue:
				computer_mon.battle_tick(delta, _highest_mon_speed, SECONDS_PER_TURN_FOR_FASTEST)
	
		# and if someone is ready to move, go ahead and let them take an action
		if not action_queue.is_empty():
			var active_mon = action_queue.front()
			is_a_mon_taking_action = true
			
			# hide the EXECUTING text if needed, since the action name box overlaps it
			_banner_label.zoom_out_instant()
			
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
	
	var mon = battle_mon.underlying_mon
	
	# if a player's mon is trying to escape
	if battle_mon in _player_mons.get_children():
		var my_speed = mon.get_speed()
		
		var computer_avg_speed = 0
		for computer_mon in _computer_mons.get_children():
			computer_avg_speed += computer_mon.underlying_mon.get_speed()
		computer_avg_speed /= _computer_mons.get_child_count()
		
		var escape_chance = clamp(50 + 3 * (my_speed - computer_avg_speed), 10, 100)
		
		if escape_chance >= Global.RNG.randi_range(1, 100):
			_log.add_text("Escaped successfully!")
			battle_result.end_condition = BattleData.BattleEndCondition.ESCAPE
			_end_battle_and_show_results()
			
			# escape animation
			var escape_tween = create_tween()
			for escaped_mon in _player_mons.get_children():
				escape_tween.parallel().tween_property(escaped_mon, "modulate:a", 0.0, 0.3)
			# hide the monblocks since there's no XP to give or anything
			for block in _player_mon_blocks.get_children():
				block.hide()
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
		GameData.inject_points = min(GameData.inject_points + 1, GameData.get_var(GameData.MAX_INJECTS) * BattleData.POINTS_PER_INJECT)
		_inject_battery.update() # and update the graphic
	
	action_queue.remove_at(0)
	is_a_mon_taking_action = false
	_mon_action_queue.update_queue(action_queue, _player_mons, _computer_mons)

func _on_mon_zero_health(mon):
	assert(state == BattleState.BATTLING)
	
	_log.add_text("%s has been terminated!" % _log.MON_NAME_PLACEHOLDER, mon)
	
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
		battle_result.end_condition = BattleData.BattleEndCondition.WIN
		_end_battle_and_show_results()
	elif not player_mons_alive and computer_mons_alive:
		battle_result.end_condition = BattleData.BattleEndCondition.LOSE
		_end_battle_and_show_results()
	elif not player_mons_alive and not computer_mons_alive:
		battle_result.end_condition = BattleData.BattleEndCondition.WIN
		_end_battle_and_show_results()

func _end_battle_and_show_results():
	assert(battle_result)
	assert(battle_result.end_condition != BattleData.BattleEndCondition.NONE)
	state = BattleState.FINISHED
	_log.add_text("Battle terminated.")
	
	# hide the script line viewer so it doesn't cover the TERMINATED text...
	_script_line_viewer.reset()
	
	# hide escape, speed, and queue
	var hide_tween = create_tween()
	hide_tween.tween_property(_speed_controls, "position", _SPEED_SLIDEOUT_POSITION, 0.5).set_trans(Tween.TRANS_CUBIC)
	hide_tween.parallel().tween_property(_escape_controls, "position", _ESCAPE_SLIDEOUT_POSITION, 0.5).set_trans(Tween.TRANS_CUBIC)
	hide_tween.parallel().tween_property(_mon_action_queue, "position", _MON_ACTION_QUEUE_SLIDEOUT_POSITION, 0.5).set_trans(Tween.TRANS_CUBIC)
	if _matrix_tween:
		_matrix_tween.kill()
		_matrix_tween = null
	_matrix_tween = create_tween()
	_matrix_tween.tween_property(_matrix_rain, "modulate:a", 0, 3.0)
	_speed_controls.fade_out_filters()
	
	_set_speed(Speed.NORMAL) # set speed to normal while matrix rain fades out
	_log.make_scrollable_and_expandable() # make the log expandable
	
	if battle_result.end_condition == BattleData.BattleEndCondition.WIN:
		for mon in _computer_mons.get_children():
			var bug_drop = mon.underlying_mon.roll_bug_drop()
			if bug_drop != null:
				_bugs_dropped.append(bug_drop)
	
	_results.perform_results(battle_result, _bugs_dropped, _player_mon_blocks.get_children(), _player_mons.get_children(), _computer_mons.get_children())
	
	await Global.delay(0.2)
	match battle_result.end_condition:
		BattleData.BattleEndCondition.WIN:
			_banner_label.display_text("VICTORY!")
		BattleData.BattleEndCondition.LOSE:
			_banner_label.display_text("DEFEAT...")
		BattleData.BattleEndCondition.ESCAPE:
			_banner_label.display_text("ESCAPED.")
	_banner_label.zoom_in()

func _on_results_exited():
	Events.emit_signal("battle_ended", battle_result)
	_banner_label.zoom_out_instant()

func _on_speed_controls_changed():
	if not is_inject_active and not is_inject_queued: # can't update speed during inject
		_set_speed(_speed_controls.speed)

func _set_speed(speed: Speed):
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
	return GameData.inject_points >= BattleData.POINTS_PER_INJECT and not is_inject_queued and not is_inject_active

func _input(event: InputEvent):
	if not is_inject_active and state == BattleState.BATTLING:
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
		
		if Input.is_action_just_pressed("battle_inject"):
			_attempt_inject()

# attempts to queue an inject; called whenever the battery is clicked or the hotkey is pressed
# does not always actually do an inject, just checks if the condition is possible and queues one if so
func _attempt_inject():
	if _can_inject():
		is_inject_queued = true
		# speed up any animation (such as a mon moving back into place)
		_set_speed(Speed.INSTANT)
		# tell the active mon their move is canceled
		if action_queue.size() != 0:
			action_queue.front().cancel_action()
		# cancel any active animation
		_animator.cancel_animation()

# actually launch a queued inject
func _start_inject():
	assert(is_inject_queued)
	assert(not is_inject_active)
	is_inject_queued = false
	is_inject_active = true
	
	_log.add_text("Launching code injection!")
	
	# reduce inject points and update bar
	assert(GameData.inject_points >= BattleData.POINTS_PER_INJECT)
	GameData.inject_points -= BattleData.POINTS_PER_INJECT
	_inject_battery.update()
	
	_set_speed(Speed.NORMAL)
	_speed_controls.fade_out_filters() # hide the red/blue filters
	
	# hide the speed and escape controls while we inject
	var tween = create_tween()
	tween.tween_property(_speed_controls, "position", _SPEED_SLIDEOUT_POSITION, 0.2).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(_escape_controls, "position", _ESCAPE_SLIDEOUT_POSITION, 0.2).set_trans(Tween.TRANS_CUBIC)
	
	# show the INJECT text!
	_banner_label.display_text("INJECTION!")
	_banner_label.zoom_in()
	
	# switch to wireframe terrain
	tween.parallel().tween_property(_terrain, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(_wireframe_terrain, "modulate:a", 1.0, 0.2)
	
	# show the inject rain effect and fade out the normal rain
	_inject_rain.start()
	_inject_rain.z_index = _INJECT_Z_INDEX
	if _matrix_tween:
		_matrix_tween.kill()
		_matrix_tween = null
	tween.parallel().tween_property(_matrix_rain, "modulate:a", 0.0, 0.1)
	tween.parallel().tween_property(_inject_rain, "modulate:a", 1.0, 0.1)
	
	# delay for sec to let this all play out
	await Global.delay(0.5)
	
	# move inject rain to background and fade it slightly
	var tween2 := create_tween()
	tween2.tween_property(_inject_rain, "modulate:a", 0.4, 0.3)
	tween2.tween_callback(_inject_rain.stop)
	await tween2.finished
	_inject_rain.z_index = _matrix_rain.z_index
	
	#create_tween().tween_property(_inject_rain, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_banner_label.zoom_out()
	
	# remove matrix rain animation
	_inject_layer.start_inject(_log, _animator, _get_living_mons(_player_mons.get_children()), _get_living_mons(_computer_mons.get_children()))

func _on_inject_completed():
	assert(is_inject_active)
	
	# show the controls, unless the battle is over
	# if the battle is over, the inject ended the battle - leave them slid out
	if not state == BattleState.FINISHED:
		var controls_tween = create_tween()
		controls_tween.tween_property(_speed_controls, "position", _SPEED_POSITION, 0.2).set_trans(Tween.TRANS_CUBIC)
		controls_tween.parallel().tween_property(_escape_controls, "position", _ESCAPE_POSITION, 0.2).set_trans(Tween.TRANS_CUBIC)
	
	# regardless, swap the terrain back
	var terrain_tween = create_tween()
	terrain_tween.parallel().tween_property(_wireframe_terrain, "modulate:a", 0, 0.2)
	terrain_tween.parallel().tween_property(_terrain, "modulate:a", 1.0, 0.2)
	await terrain_tween.finished
	
	var rain_tween = create_tween()
	rain_tween.parallel().tween_property(_inject_rain, "modulate:a", 0.0, 0.1)
	if not state == BattleState.FINISHED:
		# fade in the matrix rain, fade out the inject rain
		if _matrix_tween:
			_matrix_tween.kill()
			_matrix_tween = null
		_matrix_tween = create_tween()
		_matrix_tween.tween_property(_matrix_rain, "modulate:a", 1.0, 0.1)
		
		# update the speed post-inject to match the buttons
		_set_speed(_speed_controls.speed)
		_speed_controls.update_filters() # bring back the speedup/pause filters if they were active before
	
	is_inject_active = false
