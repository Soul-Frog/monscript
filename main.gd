extends Node2D

@onready var overworld_scene := $Scenes/Overworld
@onready var battle_scene := $Scenes/Battle
@onready var pause_menu_scene := $Scenes/PauseMenu
@onready var script_menu_scene := $Scenes/ScriptMenu
@onready var database_menu_scene := $Scenes/DatabaseMenu
@onready var active_scene := overworld_scene

func _ready() -> void:
	# remove all but Overworld scene
	for scene in $Scenes.get_children():
		if scene != active_scene:
			$Scenes.remove_child(scene)
	
	# hook up some signals
	Events.battle_started.connect(_on_battle_started)
	Events.battle_ended.connect(_on_battle_ended)

func _input(_event) -> void:
	if Input.is_action_just_released("open_pause_menu"):
		if active_scene == overworld_scene:
			pause_menu_scene.setup()
			_switch_to_scene(pause_menu_scene)
		elif active_scene == pause_menu_scene:
			_switch_to_scene(overworld_scene)

func _switch_to_scene(new_scene: Node) -> void:
	assert(active_scene != new_scene)
	$Scenes.call_deferred("remove_child", active_scene)
	$Scenes.call_deferred("add_child", new_scene)
	active_scene = new_scene

func _on_debug_console_debug_console_opened() -> void:
	assert(get_tree().paused == false)
	get_tree().paused = true

func _on_debug_console_debug_console_closed() -> void:
	assert(get_tree().paused == true)
	get_tree().paused = false

func _on_battle_started(computer_encounter_team: Array[MonData.Mon]) -> void:
	# this check is necessary to prevent bugs when
	# multiple battle start on the same frame (stacked enemies)
	if active_scene != battle_scene: 
		battle_scene.setup_battle(PlayerData.team, computer_encounter_team);
		_switch_to_scene(battle_scene)

func _on_battle_ended(battle_result: Battle.BattleResult) -> void:
	assert(battle_result.end_condition != Global.BattleEndCondition.NONE, "End condition was not set before battle ended.")
	assert(active_scene == battle_scene)
	
	# delete overworld encounter if win; respawn player if lose; handle escaping
	overworld_scene.handle_battle_results(battle_result.end_condition)
	
	# give experience to player's mons who participated in battle
	for mon in PlayerData.team: 
		if mon != null:
			mon.gain_XP(battle_result.xp_earned)
	
	# clean up the battle scene
	battle_scene.clear_battle();
	
	_switch_to_scene(overworld_scene)

func _on_script_menu_opened(mon: MonData.Mon) -> void:
	script_menu_scene.setup(mon)
	_switch_to_scene(script_menu_scene)

func _on_database_menu_opened() -> void:
	database_menu_scene.setup()
	_switch_to_scene(database_menu_scene)

func _on_submenu_closed() -> void:
	_switch_to_scene(pause_menu_scene)
