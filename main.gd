extends Node2D

@onready var overworld_scene = $Scenes/Overworld
@onready var battle_scene = $Scenes/Battle
@onready var pause_menu_scene = $Scenes/PauseMenu
var active_scene

func _ready():
	$Scenes.remove_child(battle_scene)
	$Scenes.remove_child(pause_menu_scene)
	active_scene = overworld_scene
	Events.battle_started.connect(_on_battle_started)
	Events.battle_ended.connect(_on_battle_ended)

func _input(event):
	if Input.is_action_just_released("open_pause_menu"):
		if active_scene == overworld_scene:
			pause_menu_scene.setup()
			_switch_to_scene(pause_menu_scene)
		elif active_scene == pause_menu_scene:
			_switch_to_scene(overworld_scene)

func _switch_to_scene(new_scene):
	assert(active_scene != new_scene)
	$Scenes.call_deferred("remove_child", active_scene)
	$Scenes.call_deferred("add_child", new_scene)
	active_scene = new_scene

func _on_debug_console_debug_console_opened():
	assert(get_tree().paused == false)
	get_tree().paused = true

func _on_debug_console_debug_console_closed():
	assert(get_tree().paused == true)
	get_tree().paused = false

func _on_battle_started(computer_encounter_team):
	battle_scene.setup_battle(PlayerData.team, computer_encounter_team);
	_switch_to_scene(battle_scene)

func _on_battle_ended(battle_result):
	assert(battle_result.end_condition != Global.BattleEndCondition.NONE, "End condition was not set before battle ended.")
	assert(active_scene == battle_scene)
	
	# delete overworld encounter if win; respawn player if lose; handle escaping
	overworld_scene.handle_battle_results(battle_result.end_condition)
	
	# give experience to player's mons who participated in battle
	for mon in PlayerData.team: 
		mon.gain_XP(battle_result.xp_earned)
	
	# clean up the battle scene
	battle_scene.clear_battle();
	
	_switch_to_scene(overworld_scene)
