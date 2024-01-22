class_name Area
extends Node2D

@export var area_enum := GameData.Area.NONE
@export var battle_background := BattleData.Background.UNDEFINED
@export var camera_zoom := 1.0

var _overworld_encounter_battling_with = null

@onready var PLAYER = $Entities/Player
@onready var CAMERA = $Entities/Player/Camera2D
@onready var _MAP = $Base/Map
@onready var OVERWORLD_ENCOUNTERS = $Entities/OverworldEncounters
@onready var POINTS = $Data/Points

func _ready():
	assert(not area_enum == GameData.Area.NONE, "Did not assign area_enum in editor.")
	assert(not battle_background == BattleData.Background.UNDEFINED, "Did not assign battle background in editor.")
	assert(camera_zoom > 0 and camera_zoom <= 5, "Be sane with the camera zoom level. (ok 5 is NOT sane BUT..)")
	assert(PLAYER)
	assert(CAMERA)
	assert(_MAP)
	assert(OVERWORLD_ENCOUNTERS)
	assert(POINTS)
	
	CAMERA.set_limits(_MAP)
	CAMERA.zoom.x = camera_zoom
	CAMERA.zoom.y = camera_zoom
	Events.battle_started.connect(_on_battle_started)
	
	if find_child("Data") and find_child("Data").find_child("CutsceneTriggers"):
		for child in $Data/CutsceneTriggers.get_children():
			child.play_cutscene.connect(_on_play_cutscene)

func _on_battle_started(overworld_encounter_collided_with, battle_mons):
	_overworld_encounter_battling_with = overworld_encounter_collided_with

func handle_battle_results(battle_end_condition):
	assert(_overworld_encounter_battling_with != null, "Must be battling against an overworld mon!")
	assert(battle_end_condition != BattleData.BattleEndCondition.NONE, "Battle end condition was not set.")
	if battle_end_condition == BattleData.BattleEndCondition.WIN:
		if OVERWORLD_ENCOUNTERS.get_children().has(_overworld_encounter_battling_with):
			OVERWORLD_ENCOUNTERS.remove_child(_overworld_encounter_battling_with)
			_overworld_encounter_battling_with.queue_free()
	
	if battle_end_condition == BattleData.BattleEndCondition.ESCAPE or battle_end_condition == BattleData.BattleEndCondition.WIN:
		PLAYER.activate_invincibility(battle_end_condition)

# new_spawn_point may be a String (a point in the new area) or a Vector2 (a position)
func move_player_to(destination_point: Variant) -> void:
	assert(destination_point is String or destination_point is Vector2)
	
	if destination_point is String:
		var found_destination_point = false
		# These $ paths need to be hardcoded to work during area transitions for some reason
		for point in $Data/Points.get_children():
			if point.name.to_lower().strip_edges() == destination_point.to_lower().strip_edges():
				$Entities/Player.position = point.position
				found_destination_point = true
		assert(found_destination_point, "Could not find point %s!" % [destination_point])
	else:
		$Entities/Player.position = destination_point

func get_player():
	# needs to be hardcoded to work during area transitions
	return $Entities/Player

func _on_play_cutscene(id: CutscenePlayer.CutsceneID) -> void:
	CutscenePlayer.play_cutscene(id, self)
