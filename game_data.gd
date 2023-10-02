# Stores information about the game world, such as areas, story flags, and other flags. 
extends Node

# Constants
const MONS_PER_STORAGE_PAGE = 8
const SAVE_FILE_NAME = "user://save.monsave"

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
enum Flag {
	# During the intro, the computer needs to be examined twice to progress. This tracks if the first examine has occured.
	INTRO_EXAMINED_COMPUTER_ONCE, 
	# During the intro, after examining the computer twice and playing the game, this is enabled so we can sleep at the bed.
	INTRO_READY_TO_SLEEP
}

# map of flag enums to strings, used when saving so we can save actual names and not small integers which would get
# messed up easily by new flags being added or flags being shifted.
# unfortunately this must be updated manually whenever a new flag is added as GDScript does not support string based enums.
var _flag_to_str := {
	Flag.INTRO_EXAMINED_COMPUTER_ONCE : "INTRO_EXAMINED_COMPUTER_ONCE",
	Flag.INTRO_READY_TO_SLEEP : "INTRO_READY_TO_SLEEP"
}

var _flags : Dictionary = {}

func check_flag(flag: Flag) -> bool:
	assert(_flags.has(flag))
	return _flags[flag]

func set_flag(flag: Flag, value: bool) -> void:
	assert(_flags.has(flag))
	_flags[flag] = value

var PLAYER_NAME = "???"
var team = []
var storage = []

# the maximum number of lines the player can use to build scripts
const DEFAULT_LINE_LIMIT = 3 # number of line available for a new game
var line_limit = DEFAULT_LINE_LIMIT

# the number of available storage pages 
const DEFAULT_STORAGE_PAGES = 3 # number of storage pages for a new game
var storage_pages = DEFAULT_STORAGE_PAGES

# MonType -> int; maps MonType to unlock progress
var compilation_progress_per_mon := {}

# tracks which blocks have been unlocked for use in the script editor
var _block_unlock_map := {}

func _ready():
	# populate the list of flags, set to their default value of false
	for flag in Flag.values():
		_flags[flag] = false
	assert(_flag_to_str.size() == _flags.size(), "Either missing or too many string conversions for a flag! (update _flag_to_str)")
	for flag in _flags.keys():
		assert(_flag_to_str.has(flag), "Missing string conversion for a flag! (update _flag_to_str)")
	
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
	assert(team.size() == Global.MONS_PER_TEAM)
	
	# create the mon storage
	increase_storage_size(DEFAULT_STORAGE_PAGES)
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
	var save_dict := {}
	
	# save player's name
	save_dict["player_name"] = PLAYER_NAME
	
	# save line limit and storage slots
	save_dict["line_limit"] = line_limit
	save_dict["storage_pages"] = storage_pages
	
	# save each flag as str->bool
	for flag in _flags.keys():
		save_dict[_flag_to_str[flag]] = _flags[flag]
	
	# save each mon in the team
	for i in team.size():
		save_dict["team_mon_%d" % i] = team[i].to_json() if team[i] != null else "[TEAMNULL]"
	
	# save each mon in storage
	for i in storage.size():
		save_dict["storage_mon_%d" % i] = storage[i].to_json() if storage[i] != null else "[STORAGENULL]"
	
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
	var save_dict = json.data
	
	# read back the player's name
	PLAYER_NAME = save_dict["player_name"]
	
	# read back the line limit and storage size
	line_limit = save_dict["line_limit"]
	increase_storage_size(save_dict["storage_pages"]) # adjust size of storage to match loaded value
	
	# read back each flag
	for flag_enum in _flag_to_str.keys():
		_flags[flag_enum] = save_dict[_flag_to_str[flag_enum]]
	
	# read back each mon in team
	for i in team.size():
		var mon_str = save_dict["team_mon_%d" % i]
		team[i] = MonData.mon_from_json(mon_str) if mon_str != "[TEAMNULL]" else null
	
	# read back each mon in storage
	for i in storage.size():
		var mon_str = save_dict["storage_mon_%d" % i]
		storage[i] = MonData.mon_from_json(mon_str) if mon_str != "[STORAGENULL]" else null

func increase_storage_size(new_size: int):
	assert(storage_pages <= new_size, "Can't decrease storage size!")
	storage_pages = new_size
	while storage.size() < storage_pages * MONS_PER_STORAGE_PAGE:
		storage.append(null)
	assert(storage.size() == storage_pages * MONS_PER_STORAGE_PAGE)


func is_block_unlocked(block: ScriptData.Block) -> bool:
	if not _block_unlock_map.has(block):
		return false
	return _block_unlock_map[block]
