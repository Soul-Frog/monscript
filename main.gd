extends Node2D

@onready var OVERWORLD := $Scenes/Overworld
@onready var BATTLE := $Scenes/Battle
@onready var PAUSE_MENU := $Scenes/PauseMenu
@onready var SCRIPT_MENU := $Scenes/ScriptMenu
@onready var DATABASE_MENU := $Scenes/DatabaseMenu
@onready var VISUAL_NOVEL := $Scenes/VisualNovel
@onready var active_scene := VISUAL_NOVEL

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
		if active_scene == OVERWORLD:
			PAUSE_MENU.setup()
			_switch_to_scene(PAUSE_MENU)
		elif active_scene == PAUSE_MENU:
			_switch_to_scene(PAUSE_MENU)

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

func _on_battle_started(computer_encounter_team: Array) -> void:
	# this check is necessary to prevent bugs when
	# multiple battle start on the same frame (stacked enemies)
	if active_scene != BATTLE: 
		BATTLE.setup_battle(PlayerData.team, computer_encounter_team);
		_switch_to_scene(BATTLE)

func _on_battle_ended(battle_result: Battle.BattleResult) -> void:
	assert(battle_result.end_condition != Global.BattleEndCondition.NONE, "End condition was not set before battle ended.")
	assert(active_scene == BATTLE)
	
	# delete overworld encounter if win; respawn player if lose; handle escaping
	OVERWORLD.handle_battle_results(battle_result.end_condition)
	
	# give experience to player's mons who participated in battle
	for mon in PlayerData.team: 
		if mon != null:
			mon.gain_XP(battle_result.xp_earned)
	
	# clean up the battle scene
	BATTLE.clear_battle();
	
	_switch_to_scene(OVERWORLD)

func _on_script_menu_opened(mon: MonData.Mon) -> void:
	_switch_to_scene(SCRIPT_MENU)
	SCRIPT_MENU.setup(mon)

func _on_database_menu_opened() -> void:
	DATABASE_MENU.setup()
	_switch_to_scene(DATABASE_MENU)

func _on_submenu_closed() -> void:
	_switch_to_scene(PAUSE_MENU)

func _on_visual_novel_completed() -> void:
	_switch_to_scene(OVERWORLD)
