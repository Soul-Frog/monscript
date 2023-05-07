extends Node2D

signal collided_with_encounter

var overworld_encounter_battling_with = null

func _ready():
	$Player/Camera2D.set_limits($TileMap)

func _on_overworld_encounter_collided_with_player(overworld_encounter_collided_with):
	overworld_encounter_battling_with = overworld_encounter_collided_with
	emit_signal("collided_with_encounter", overworld_encounter_collided_with.mons)

func handle_battle_results(battle_end_condition):
	assert(overworld_encounter_battling_with != null, "Must be battling against an overworld mon!")
	assert(battle_end_condition != Global.BattleEndCondition.NONE, "Battle end condition was not set.")
	if battle_end_condition == Global.BattleEndCondition.WIN:
		remove_child(overworld_encounter_battling_with)
	
	print("TODO - HANDLE ESCAPE FROM BATTLE")
