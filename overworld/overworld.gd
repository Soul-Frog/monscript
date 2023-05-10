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
	print(new_area)
	print(new_spawn_point)
