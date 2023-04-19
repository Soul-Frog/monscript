extends Node2D

enum State
{
	OVERWORLD, BATTLE
}

@onready var overworld_scene = $Scenes/Overworld
@onready var battle_scene = $Scenes/Battle
var state

func _ready():
	$Scenes.remove_child(battle_scene)
	state = State.OVERWORLD

func _on_debug_console_debug_console_opened():
	assert(get_tree().paused == false)
	get_tree().paused = true

func _on_debug_console_debug_console_closed():
	assert(get_tree().paused == true)
	get_tree().paused = false

func _on_battle_started(computer_encounter_team):
	state = State.BATTLE
	battle_scene.setup_battle(PlayerData.team, computer_encounter_team);
	
	# switch to battle scene
	$Scenes.call_deferred("remove_child", overworld_scene)
	$Scenes.call_deferred("add_child", battle_scene)

func _on_battle_ended(won_battle):
	state = State.OVERWORLD
	
	overworld_scene.handle_battle_results(won_battle)
	
	# todo: give XP to the player's mons here
	
	if not won_battle:
		assert(false, "Need to handle this case somehow") #todo
	
	# clean up the battle scene
	battle_scene.clear_battle();
	
	# switch back to overworld scene
	$Scenes.call_deferred("remove_child", battle_scene)
	$Scenes.call_deferred("add_child", overworld_scene)
