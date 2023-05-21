extends Node2D

@onready var current_area = $Area

func _ready():
	Events.area_changed.connect(_on_change_area)

func handle_battle_results(battle_end_condition):
	assert(battle_end_condition != Global.BattleEndCondition.NONE, "Battle end condition was not set.")
	
	current_area.handle_battle_results(battle_end_condition)
	
	print("TODO - HANDLE BATTLE LOSS")

func _on_change_area(new_area, new_spawn_point):
	Global.p(self, "Changing Area!\tArea: %s\tPoint: %s" % [new_area, new_spawn_point])
	
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

