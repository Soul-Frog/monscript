# Stores information about the game world, such as areas, story flags, and other flags. 

extends Node

enum Area
{
	DEBUG1, DEBUG2, NONE
}

var _area_enum_to_path: Dictionary = {
	Area.DEBUG1 : "res://overworld/areas/debug_area.tscn",
	Area.DEBUG2 : "res://overworld/areas/debug_area2.tscn"
}

# function to get script for enum
func path_for_area(area_enum: GameData.Area) -> String:
	assert(area_enum != Area.NONE, "Area enum is none!")
	return _area_enum_to_path[area_enum]
