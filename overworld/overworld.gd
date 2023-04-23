extends Node2D

signal battle_started

var overworld_encounter_battling_with = null

func _on_overworld_mon_collided_with_player_start_battle(overworld_encounter_collided_with):
	overworld_encounter_battling_with = overworld_encounter_collided_with
	emit_signal("battle_started", overworld_encounter_collided_with.mons)

func handle_battle_results(battle_end_condition):
	assert(overworld_encounter_battling_with != null, "Must be battling against an overworld mon!")
	assert(battle_end_condition != Global.BattleEndCondition.NONE, "Battle end condition was not set.")
	if battle_end_condition == Global.BattleEndCondition.WIN:
		remove_child(overworld_encounter_battling_with)
	
	# todo: handle Lose and Run cases here
