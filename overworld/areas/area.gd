extends Node2D

@export var camera_zoom := 1.0

signal change_area

var overworld_encounter_battling_with = null

func _ready():
	$Player/Camera2D.set_limits($Map)
	$Player/Camera2D.zoom.x = camera_zoom
	$Player/Camera2D.zoom.y = camera_zoom
	Events.collided_with_overworld_encounter.connect(_on_overworld_encounter_collided_with_player)

func _on_overworld_encounter_collided_with_player(overworld_encounter_collided_with):
	overworld_encounter_battling_with = overworld_encounter_collided_with

func handle_battle_results(battle_end_condition):
	assert(overworld_encounter_battling_with != null, "Must be battling against an overworld mon!")
	assert(battle_end_condition != Global.BattleEndCondition.NONE, "Battle end condition was not set.")
	if battle_end_condition == Global.BattleEndCondition.WIN:
		$OverworldEncounters.remove_child(overworld_encounter_battling_with)
		overworld_encounter_battling_with.queue_free()
	
	if battle_end_condition == Global.BattleEndCondition.ESCAPE or battle_end_condition == Global.BattleEndCondition.WIN:
		$Player.activate_invincibility(battle_end_condition)

func move_player_to(destination_point):
	var found_destination_point = false
	for point in $Points.get_children():
		if point.name.to_lower().strip_edges() == destination_point.to_lower().strip_edges():
			$Player.position = point.position
			found_destination_point = true
	assert(found_destination_point, "Could not find point %s!" % [destination_point])
