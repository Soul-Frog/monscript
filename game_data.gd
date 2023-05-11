# Stores information about the game world, such as areas, story flags, and other flags. 

extends Node

enum Area
{
	DEBUG1, DEBUG2, NONE
}

var area_enum_to_path = {
	Area.DEBUG1 : "res://overworld/areas/debug_area.tscn",
	Area.DEBUG2 : "res://overworld/areas/debug_area2.tscn"
}

func _ready():
	# do some safety checks
	for area_enum in Area.values():
		if area_enum == Area.NONE:
			continue
		assert(area_enum_to_path.has(area_enum), "No path in dictionary for %s!" % [Area.find_key(area_enum)])
		assert(Global.does_file_exist(area_enum_to_path[area_enum]), "Path %s is invalid!" % [area_enum_to_path[area_enum]])

# function to get script for enum
func path_for_area(area_enum):
	assert(area_enum != Area.NONE, "Area enum is none!")
	return area_enum_to_path[area_enum]
