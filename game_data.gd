# Stores information about the game world, such as areas, story flags, and other flags. 

extends Node

enum Area
{
	DEBUG1, DEBUG2, NONE
}

# MonType -> int; maps MonType to unlock progress
var compilation_progress_per_mon := {}

# the maximum number of lines the player can use to build scripts
var line_limit = 3

var _area_enum_to_path: Dictionary = {
	Area.DEBUG1 : "res://overworld/areas/debug_area.tscn",
	Area.DEBUG2 : "res://overworld/areas/debug_area2.tscn"
}

var _unlocked_blocks = [
	ScriptData.get_block_by_name("Always"),
	#ScriptData.get_block_by_name("FoeHasLowHP"),
	#ScriptData.get_block_by_name("PalDamaged"),
	#ScriptData.get_block_by_name("PalHasLowHP"),
	#ScriptData.get_block_by_name("Pass"),
	ScriptData.get_block_by_name("Attack"),
	#ScriptData.get_block_by_name("Defend"),
	ScriptData.get_block_by_name("Escape"),
	#ScriptData.get_block_by_name("Shellbash"),
	ScriptData.get_block_by_name("RandomFoe"),
	#ScriptData.get_block_by_name("LowestHPFoe"),
	#ScriptData.get_block_by_name("LowestHPPal")
]

func _ready():
	# populate the compilation progress map
	for montype in MonData.MonType.values():
		if montype == MonData.MonType.NONE:
			continue
		if montype == MonData.MonType.MAGNETFROG:
			compilation_progress_per_mon[montype] = 100
		else:
			compilation_progress_per_mon[montype] = 0

# function to get script for enum
func path_for_area(area_enum: GameData.Area) -> String:
	assert(area_enum != Area.NONE, "Area enum is none!")
	return _area_enum_to_path[area_enum]

func is_block_unlocked(block: ScriptData.Block) -> bool:
	return _unlocked_blocks.has(block)
