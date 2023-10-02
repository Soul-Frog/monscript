class_name Main
extends Node2D

@onready var OVERWORLD := $Scene/Scenes/Overworld
@onready var BATTLE := $Scene/Scenes/Battle
@onready var PAUSE_MENU := $Scene/Scenes/PauseMenu
@onready var SCRIPT_MENU := $Scene/Scenes/ScriptMenu
@onready var DATABASE_MENU := $Scene/Scenes/DatabaseMenu
@onready var VISUAL_NOVEL: VisualNovel = $Scene/Scenes/VisualNovel
@onready var MAIN_MENU := $Scene/Scenes/MainMenu

@onready var active_scene: Node = MAIN_MENU

# the normal fade used to transition between scenes in the game
@onready var FADE: FadeDecorator = $Scene/StandardFade

# a slower, longer fade used to transition to the game from the main menu
@onready var MAIN_MENU_FADE: FadeDecorator = $Scene/MainMenuFade

func _ready() -> void:
	assert(OVERWORLD != null)
	assert(BATTLE != null)
	assert(PAUSE_MENU != null)
	assert(SCRIPT_MENU != null)
	assert(DATABASE_MENU != null)
	assert(VISUAL_NOVEL != null)
	assert(MAIN_MENU != null)	
	assert(FADE != null)
	assert(MAIN_MENU_FADE != null)
	
	# remove all but Overworld scene
	for scene in $Scene/Scenes.get_children():
		if scene != active_scene:
			$Scene/Scenes.remove_child(scene)
	
	# hook up some signals
	Events.battle_started.connect(_on_battle_started)
	Events.battle_ended.connect(_on_battle_ended)

func _input(_event) -> void:
	if Input.is_action_just_released("open_pause_menu") and not FADE.active:
		if active_scene == OVERWORLD:
			PAUSE_MENU.setup()
			await _switch_to_scene(PAUSE_MENU, FADE)
		elif active_scene == PAUSE_MENU:
			await _on_pause_menu_closed()

# Switch to a new scene with a fade effect.
func _switch_to_scene(new_scene: Node, fade_effect: FadeDecorator) -> void:
	assert(active_scene != new_scene)
	var old_scene = active_scene
	
	# disable the old scene during the fade transition
	Global.recursive_set_processes(old_scene, false)
	
	# fade out and wait for that to complete
	fade_effect.fade_out()
	await fade_effect.fade_out_done
	
	$Scene/Scenes.call_deferred("remove_child", active_scene)
	$Scene/Scenes.call_deferred("add_child", new_scene)
	active_scene = new_scene
	
	# re-enable the old scene, we just disabled it while fading
	Global.recursive_set_processes(old_scene, true)
	
	# fade back in
	fade_effect.fade_in()

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
		BATTLE.setup_battle(GameData.team, computer_encounter_team);
		await _switch_to_scene(BATTLE, FADE)

func _on_battle_ended(battle_result: Battle.BattleResult) -> void:
	assert(battle_result.end_condition != Global.BattleEndCondition.NONE, "End condition was not set before battle ended.")
	assert(active_scene == BATTLE)
	
	# delete overworld encounter if win; respawn player if lose; handle escaping
	OVERWORLD.handle_battle_results(battle_result.end_condition)
	
	# give experience to player's mons who participated in battle
	for mon in GameData.team: 
		if mon != null:
			mon.gain_XP(battle_result.xp_earned)
	
	await _switch_to_scene(OVERWORLD, FADE)
	
	# clean up the battle scene
	BATTLE.clear_battle();

func _on_script_menu_opened(mon: MonData.Mon) -> void:
	await _switch_to_scene(SCRIPT_MENU, FADE)
	SCRIPT_MENU.setup(mon)

func _on_database_menu_opened() -> void:
	DATABASE_MENU.setup()
	await _switch_to_scene(DATABASE_MENU, FADE)

func _on_submenu_closed() -> void:
	await _switch_to_scene(PAUSE_MENU, FADE)

func _on_visual_novel_completed() -> void:
	await _switch_to_scene(OVERWORLD, FADE)

func _on_pause_menu_closed():
	await _switch_to_scene(OVERWORLD, FADE)

func _on_main_menu_clicked_new_game():
	await _switch_to_scene(VISUAL_NOVEL, MAIN_MENU_FADE)
	VISUAL_NOVEL.play_intro_cutscene()

func _on_main_menu_clicked_continue():
	if Global.DEBUG_FAST_START:
		if GameData.does_save_exist():
			GameData.load_game()
	else:
		assert(GameData.does_save_exist())
		GameData.load_game()
	await _switch_to_scene(OVERWORLD, MAIN_MENU_FADE if not Global.DEBUG_FAST_START else FADE) #for now

func _on_main_menu_clicked_settings():
	print("TODO - Settings")
