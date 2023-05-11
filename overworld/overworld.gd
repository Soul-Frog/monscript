extends Node2D

signal battle_started

@onready var current_area = $Area

func _on_area_collided_with_encounter(overworld_encounter_mons):
	emit_signal("battle_started", overworld_encounter_mons)

func handle_battle_results(battle_end_condition):
	assert(battle_end_condition != Global.BattleEndCondition.NONE, "Battle end condition was not set.")
	
	current_area.handle_battle_results(battle_end_condition)
	
	print("TODO - HANDLE BATTLE LOSS")

func _on_change_area(new_area, new_spawn_point):
	$DebugTool.p("Changing Area!\tArea: %s\tPoint: %s" % [new_area, new_spawn_point])
	
	# create the new area scene, move player to point
	var old_area = current_area
	current_area = load(GameData.path_for_area(new_area)).instantiate()
	current_area.move_player_to(new_spawn_point)
	
	# add new area
	call_deferred("add_child", current_area) 
	# remove and free old area
	call_deferred("queue_free", old_area) 
