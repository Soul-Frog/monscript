extends Node2D

@onready var overworld_scene = $Overworld
@onready var battle_scene = $Battle

func _ready():
	remove_child(battle_scene)

func _on_debug_console_debug_console_opened():
	assert(get_tree().paused == false)
	get_tree().paused = true

func _on_debug_console_debug_console_closed():
	assert(get_tree().paused == true)
	get_tree().paused = false

func _on_battle_started():
	print("Start battle!!!")
	
	# switch to battle scene
	call_deferred("remove_child", overworld_scene)
	call_deferred("add_child", battle_scene)
	
	# todo - call some battle update here; setting up mons in battle scene before switch


func _on_battle_ended():
	print("End battle...")
	
	# switch back to overworld scene
	call_deferred("remove_child", battle_scene)
	call_deferred("add_child", overworld_scene)
	
	# todo - call some overworld update based on battle result here; removing overworld mon for ex
	# and updating with battle results
