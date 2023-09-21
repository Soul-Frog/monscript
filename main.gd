extends Node2D

@onready var OVERWORLD := $Scene/Scenes/Overworld
@onready var BATTLE := $Scene/Scenes/Battle
@onready var PAUSE_MENU := $Scene/Scenes/PauseMenu
@onready var SCRIPT_MENU := $Scene/Scenes/ScriptMenu
@onready var DATABASE_MENU := $Scene/Scenes/DatabaseMenu
@onready var VISUAL_NOVEL: VisualNovel = $Scene/Scenes/VisualNovel
@onready var active_scene: Node = VISUAL_NOVEL

@onready var FADE: FadeDecorator = $Scene/FadeDecorator

func _ready() -> void:
	assert(OVERWORLD != null)
	assert(BATTLE != null)
	assert(PAUSE_MENU != null)
	assert(SCRIPT_MENU != null)
	assert(DATABASE_MENU != null)
	assert(VISUAL_NOVEL != null)
	assert(FADE != null)
	
	# remove all but Overworld scene
	for scene in $Scene/Scenes.get_children():
		if scene != active_scene:
			$Scene/Scenes.remove_child(scene)
	
	# hook up some signals
	Events.battle_started.connect(_on_battle_started)
	Events.battle_ended.connect(_on_battle_ended)
	
	# give all nodes a frame to get set up
	call_deferred("start_game")

func start_game():
	VISUAL_NOVEL.play_intro_cutscene()

func _input(_event) -> void:
	if Input.is_action_just_released("open_pause_menu") and not FADE.active:
		if active_scene == OVERWORLD:
			PAUSE_MENU.setup()
			await _switch_to_scene(PAUSE_MENU)
		elif active_scene == PAUSE_MENU:
			await _switch_to_scene(OVERWORLD)

func _switch_to_scene(new_scene: Node) -> void:
	assert(active_scene != new_scene)
	
	# fade out and wait for that to complete
	FADE.fade_out()
	await FADE.fade_out_done
	
	$Scene/Scenes.call_deferred("remove_child", active_scene)
	$Scene/Scenes.call_deferred("add_child", new_scene)
	active_scene = new_scene
	
	# fade back in
	FADE.fade_in()

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
		await _switch_to_scene(BATTLE)

func _on_battle_ended(battle_result: Battle.BattleResult) -> void:
	assert(battle_result.end_condition != Global.BattleEndCondition.NONE, "End condition was not set before battle ended.")
	assert(active_scene == BATTLE)
	
	# delete overworld encounter if win; respawn player if lose; handle escaping
	OVERWORLD.handle_battle_results(battle_result.end_condition)
	
	# give experience to player's mons who participated in battle
	for mon in PlayerData.team: 
		if mon != null:
			mon.gain_XP(battle_result.xp_earned)
	
	await _switch_to_scene(OVERWORLD)
	
	# clean up the battle scene
	BATTLE.clear_battle();

func _on_script_menu_opened(mon: MonData.Mon) -> void:
	await _switch_to_scene(SCRIPT_MENU)
	SCRIPT_MENU.setup(mon)

func _on_database_menu_opened() -> void:
	DATABASE_MENU.setup()
	await _switch_to_scene(DATABASE_MENU)

func _on_submenu_closed() -> void:
	await _switch_to_scene(PAUSE_MENU)

func _on_visual_novel_completed() -> void:
	await _switch_to_scene(OVERWORLD)
