# Stores information about the game world, such as areas, story flags, and other flags. 

extends Node

enum Area
{
	DEBUG1, DEBUG2, NONE
}

# MonType -> int; maps MonType to unlock progress
var compilation_progress_per_mon := {}

var _area_enum_to_path: Dictionary = {
	Area.DEBUG1 : "res://overworld/areas/debug_area.tscn",
	Area.DEBUG2 : "res://overworld/areas/debug_area2.tscn"
}

func _ready():
	# populate the compilation progress map
	for montype in MonData.MonType.values():
		if montype == MonData.MonType.NONE:
			continue
		compilation_progress_per_mon[montype] = 100

# function to get script for enum
func path_for_area(area_enum: GameData.Area) -> String:
	assert(area_enum != Area.NONE, "Area enum is none!")
	return _area_enum_to_path[area_enum]
