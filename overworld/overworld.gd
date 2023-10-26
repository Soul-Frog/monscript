extends Node2D

@onready var current_area = $Area

func _ready():
	Events.area_changed.connect(_on_area_changed)

func handle_battle_results(battle_end_condition) -> void:
	assert(battle_end_condition != Global.BattleEndCondition.NONE, "Battle end condition was not set.")
	
	current_area.handle_battle_results(battle_end_condition)
	
	print("TODO - HANDLE BATTLE LOSS")

# Loads a new area and move the player to their spawn point.
# new_spawn_point may be a String (a point in the new area) or a Vector2 (a position)
func _on_area_changed(new_area: GameData.Area, new_spawn_point: Variant) -> void:
	# if new area is the different from current area...
	if current_area.scene_file_path != GameData.path_for_area(new_area):
		# create the new area scene, move player to point
		var old_area = current_area
		old_area.name = "old" # clear old area name before adding new area; since they share names
		current_area = load(GameData.path_for_area(new_area)).instantiate()
		# add new area
		call_deferred("add_child", current_area) 
		# remove and free old area
		old_area.call_deferred("queue_free")
	
	# either way, move player to new point
	current_area.move_player_to(new_spawn_point)
