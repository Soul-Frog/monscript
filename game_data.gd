# Stores information about the game world, such as areas, story flags, and other flags. 
extends Node

# Constants
const MONS_PER_STORAGE_PAGE = 8
const SAVE_FILE_NAME = "save.monsave"

# Area stuff
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

# Gamestate Flags
# During the intro, the computer needs to be examined twice to progress. This tracks if the first examine has occured.
var FLAG_INTRO_EXAMINED_COMPUTER_ONCE = false
# During the intro, after examining the computer twice and playing the game, this is enabled so we can sleep at the bed.
var FLAG_INTRO_READY_TO_SLEEP = false

var PLAYER_NAME = "???"
var team = []
var storage = []

# the maximum number of lines the player can use to build scripts
var line_limit = 3
# the number of available storage pages 
var storage_pages = 3

# MonType -> int; maps MonType to unlock progress
var compilation_progress_per_mon := {}

# tracks which blocks have been unlocked for use in the script editor
var _block_unlock_map = {}

func _ready():
	# populate the compilation progress map
	for montype in MonData.MonType.values():
		if montype == MonData.MonType.NONE:
			continue
		if montype == MonData.MonType.MAGNETFROG:
			compilation_progress_per_mon[montype] = 100
		else:
			compilation_progress_per_mon[montype] = 0
	# mark the initial mon as compiled
	# TODO - Bitleon starts as compiled
	
	# populate the block unlock map
	for block in ScriptData.IF_BLOCK_LIST:
		_block_unlock_map[block] = false
	for block in ScriptData.DO_BLOCK_LIST:
		_block_unlock_map[block] = false
	for block in ScriptData.TO_BLOCK_LIST:
		_block_unlock_map[block] = false
	# mark the initial blocks as unlocked
	assert(ScriptData.get_block_by_name("Always"))
	assert(ScriptData.get_block_by_name("Attack"))
	assert(ScriptData.get_block_by_name("RandomFoe"))
	_block_unlock_map[ScriptData.get_block_by_name("Always")] = true
	_block_unlock_map[ScriptData.get_block_by_name("Attack")] = true
	_block_unlock_map[ScriptData.get_block_by_name("RandomFoe")] = true
	
	# create the default team
	team = [MonData.create_mon(MonData.MonType.MAGNETFROG, 1), null, null, null]
	
	# create the mon storage, empty by default
	for i in storage_pages:
		for j in MONS_PER_STORAGE_PAGE:
			storage.append(null)
		
	assert(team.size() == Global.MONS_PER_TEAM)
	assert(storage.size() == storage_pages * MONS_PER_STORAGE_PAGE)
	
	# TODO - remove this debug code
	storage[0] = MonData.create_mon(MonData.MonType.MAGNETFROG, 10)
	storage[5] = MonData.create_mon(MonData.MonType.MAGNETFROG, 11)
	storage[4] = MonData.create_mon(MonData.MonType.MAGNETFROG, 12)
	storage[9] = MonData.create_mon(MonData.MonType.MAGNETFROG, 13)
	storage[13] = MonData.create_mon(MonData.MonType.MAGNETFROG, 14)
	storage[18] = MonData.create_mon(MonData.MonType.MAGNETFROG, 64)
	

# saves the game state to file
func save_game():
	# store everything we care about in a big dictionary
	var save_dict := {
		"player_name" : PLAYER_NAME
	}
	
	# convert to json
	var json = JSON.stringify(save_dict)
	
	# write it all to a special file
	Global.string_to_file(SAVE_FILE_NAME, json)

# returns whether a saved game exists
func does_save_exist() -> bool:
	return Global.does_file_exist(SAVE_FILE_NAME)

# loads the stored save file
func load_game():
	var json = JSON.new()
	var result = json.parse(Global.file_to_string(SAVE_FILE_NAME))
	if not result == OK:
		assert(false, "Save corruption!")
		return
	var save_dict = json.data()
	
	print(save_dict)
	print(save_dict["player_name"])
	
	PLAYER_NAME = save_dict["player_name"]


func is_block_unlocked(block: ScriptData.Block) -> bool:
	if not _block_unlock_map.has(block):
		return false
	return _block_unlock_map[block]
