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
	

func _on_battle_started(overworld_mon_battling_with):
	print("Start battle!!!")
	
	state = State.BATTLE
	
	# switch to battle scene
	$Scenes.call_deferred("remove_child", overworld_scene)
	$Scenes.call_deferred("add_child", battle_scene)
	
	# todo - call some battle update here; setting up mons in battle scene before switch
	# use overworld_mon_battling_with for this


func _on_battle_ended(won_battle):
	print("End battle...")
	
	state = State.OVERWORLD
	
	overworld_scene.handle_battle_results(won_battle)
	
	if not won_battle:
		assert(false, "Need to handle this case somehow")
	
	# switch back to overworld scene
	$Scenes.call_deferred("remove_child", battle_scene)
	$Scenes.call_deferred("add_child", overworld_scene)
