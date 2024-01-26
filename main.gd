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

func _ready() -> void:
	assert(OVERWORLD != null)
	assert(BATTLE != null)
	assert(PAUSE_MENU != null)
	assert(SCRIPT_MENU != null)
	assert(DATABASE_MENU != null)
	assert(VISUAL_NOVEL != null)
	assert(MAIN_MENU != null)	
	
	# remove all but Overworld scene
	for scene in $Scene/Scenes.get_children():
		if scene != active_scene:
			$Scene/Scenes.remove_child(scene)
	
	# hook up some signals
	Events.battle_started.connect(_on_battle_started)
	Events.battle_ended.connect(_on_battle_ended)

func _input(_event) -> void:
	if Input.is_action_just_released("toggle_menu") and not TransitionPlayer.is_playing():
		if active_scene == OVERWORLD:
			PAUSE_MENU.setup()
			await _switch_to_scene(PAUSE_MENU, TransitionPlayer.Effect.QUICK_FADE_OUT, TransitionPlayer.Effect.QUICK_FADE_IN)
		elif active_scene == PAUSE_MENU and PAUSE_MENU.is_closable():
			await _on_pause_menu_closed()

# Switch to a new scene with a fade effect.
func _switch_to_scene(new_scene: Node, fade_out_effect, fade_in_effect) -> void:
	assert(active_scene != new_scene)
	var old_scene = active_scene
	
	# disable the old scene during the fade transition
	Global.recursive_set_processes(old_scene, false)
	
	# fade out and wait for that to complete
	await TransitionPlayer.play(fade_out_effect)
	
	$Scene/Scenes.call_deferred("remove_child", active_scene)
	$Scene/Scenes.call_deferred("add_child", new_scene)
	active_scene = new_scene
	
	# re-enable the old scene, we just disabled it while fading
	Global.recursive_set_processes(old_scene, true)
	
	# fade back in
	TransitionPlayer.play(fade_in_effect)

func _on_debug_console_debug_console_opened() -> void:
	assert(get_tree().paused == false)
	get_tree().paused = true

func _on_debug_console_debug_console_closed() -> void:
	assert(get_tree().paused == true)
	get_tree().paused = false

func _on_battle_started(_overworld_encounter, computer_encounter_team: Array) -> void:
	# this check is necessary to prevent bugs when
	# multiple battle start on the same frame (stacked enemies)
	if active_scene != BATTLE: 
		await _switch_to_scene(BATTLE, TransitionPlayer.Effect.FADE_OUT, TransitionPlayer.Effect.FADE_IN)
		
		# not quite sure why this needs to be behind _switch_to_scene, sorta a $HACK$ tbh
		BATTLE.setup_battle(GameData.team, computer_encounter_team, OVERWORLD.current_area.battle_background)

func _on_battle_ended(battle_result: BattleData.BattleResult) -> void:
	assert(battle_result.end_condition != BattleData.BattleEndCondition.NONE, "End condition was not set before battle ended.")
	assert(active_scene == BATTLE)
	
	# delete overworld encounter if win; respawn player if lose; handle escaping
	OVERWORLD.handle_battle_results(battle_result.end_condition)
	
	await _switch_to_scene(OVERWORLD, TransitionPlayer.Effect.FADE_OUT, TransitionPlayer.Effect.FADE_IN)
	
	BATTLE.clear_battle(); # clean up the battle scene

func _on_script_menu_opened(mon: MonData.Mon) -> void:
	await _switch_to_scene(SCRIPT_MENU, TransitionPlayer.Effect.QUICK_FADE_OUT, TransitionPlayer.Effect.QUICK_FADE_IN)
	SCRIPT_MENU.setup(mon) # not quite sure why this needs to be behind _switch_to_scene, sorta a $HACK$ tbh

func _on_database_menu_opened() -> void:
	DATABASE_MENU.setup()
	await _switch_to_scene(DATABASE_MENU, TransitionPlayer.Effect.QUICK_FADE_OUT, TransitionPlayer.Effect.QUICK_FADE_IN)

func _on_pause_menu_closed():
	await _switch_to_scene(OVERWORLD, TransitionPlayer.Effect.QUICK_FADE_OUT, TransitionPlayer.Effect.QUICK_FADE_IN)

func _on_submenu_closed() -> void:
	await _switch_to_scene(PAUSE_MENU, TransitionPlayer.Effect.QUICK_FADE_OUT, TransitionPlayer.Effect.QUICK_FADE_IN)

func _on_visual_novel_completed() -> void:
	await _switch_to_scene(OVERWORLD, TransitionPlayer.Effect.SLOW_FADE_OUT_AND_WAIT, TransitionPlayer.Effect.FADE_IN)

func _on_main_menu_clicked_new_game():
	await _switch_to_scene(OVERWORLD, TransitionPlayer.Effect.SLOW_FADE_OUT_AND_WAIT, TransitionPlayer.Effect.NONE)
	CutscenePlayer.play_cutscene(Cutscene.ID.CAVE1_INTRO, OVERWORLD.current_area)

func _on_main_menu_clicked_continue():
	if Global.DEBUG_FAST_START:
		if GameData.does_save_exist():
			GameData.load_game()
	else:
		assert(GameData.does_save_exist())
		GameData.load_game()
	await _switch_to_scene(OVERWORLD, TransitionPlayer.Effect.SLOW_FADE_OUT_AND_WAIT if not Global.DEBUG_FAST_START else TransitionPlayer.Effect.QUICK_FADE_OUT, TransitionPlayer.Effect.FADE_IN) #for now

func _on_main_menu_clicked_settings():
	print("TODO - Settings")

# Fetch the player; used when saving/loading
func get_player():
	assert(OVERWORLD.current_area)
	assert(OVERWORLD.current_area.get_player())
	return OVERWORLD.current_area.get_player()

# Fetch the current area; used when saving
func get_current_area() -> GameData.Area:
	assert(OVERWORLD.current_area)
	return OVERWORLD.current_area.area_enum
