# Stores information about the game world, such as areas and persistant variables.
extends Node

## Constants ##
const MONS_PER_STORAGE_PAGE = 8 # how many mons are on a single page of pause menu storage
const SAVE_FILE_NAME = "user://save.monsave" # path to the save file

## Areas ##
enum Area
{
	COOLANT_CAVE1_BEACH, COOLANT_CAVE2_ENTRANCE, COOLANT_CAVE3_LAKE, COOLANT_CAVE4_PLAZA, COOLANT_CAVE5_2DRUINS,
	COOLANT_CAVE6_TEMPLE, COOLANT_CAVE7_WHIRLCAVERN, COOLANT_CAVE8_SEAFLOOR, COOLANT_CAVE9_TIDALCHAMBER, COOLANT_CAVE10_RIVER,
	COOLANT_CAVE11_2DWATERFALL, COOLANT_CAVE12_BOSSROOM,
	NONE
}

# Map of areas to their scenes
var _area_enum_to_path: Dictionary = {
	Area.COOLANT_CAVE1_BEACH : "res://overworld/areas/coolant_cave/cave1_beach.tscn",
	Area.COOLANT_CAVE2_ENTRANCE : "res://overworld/areas/coolant_cave/cave2_entrance.tscn",
	Area.COOLANT_CAVE3_LAKE : "res://overworld/areas/coolant_cave/cave3_lake.tscn",
	Area.COOLANT_CAVE4_PLAZA : "res://overworld/areas/coolant_cave/cave4_plaza.tscn",
	Area.COOLANT_CAVE5_2DRUINS : "res://overworld/areas/coolant_cave/cave5_platformerruins.tscn",
	Area.COOLANT_CAVE6_TEMPLE : "res://overworld/areas/coolant_cave/cave6_temple.tscn",
	Area.COOLANT_CAVE7_WHIRLCAVERN : "res://overworld/areas/coolant_cave/cave7_whirlcavern.tscn",
	Area.COOLANT_CAVE8_SEAFLOOR : "res://overworld/areas/coolant_cave/cave8_seafloor.tscn",
	Area.COOLANT_CAVE9_TIDALCHAMBER : "res://overworld/areas/coolant_cave/cave9_tidalchamber.tscn",
	Area.COOLANT_CAVE10_RIVER : "res://overworld/areas/coolant_cave/cave10_river.tscn",
	Area.COOLANT_CAVE11_2DWATERFALL : "res://overworld/areas/coolant_cave/cave11_platformerwaterfall.tscn",
	Area.COOLANT_CAVE12_BOSSROOM : "res://overworld/areas/coolant_cave/cave12_bossroom.tscn",
}

func path_for_area(area_enum: GameData.Area) -> String: # function to get script for enum
	assert(area_enum != Area.NONE, "Area enum is none!")
	return _area_enum_to_path[area_enum]


## Persistent Variables. ##
# Key for the player's name.
const PLAYER_NAME = "PlAYER_NAME"
# Maximum number of lines in a script
const LINE_LIMIT = "LINE_LIMIT"
# Number of pages of mon storage in pause menu
const STORAGE_PAGES = "STORAGE_PAGES"
# During the intro, the computer needs to be examined twice to progress. This tracks if the first examine has occurred.
const INTRO_EXAMINED_COMPUTER_ONCE = "INTRO_EXAMINED_COMPUTER_ONCE"
# During the intro, after examining the computer twice and playing the game, this is enabled so we can sleep at the bed.
const INTRO_READY_TO_SLEEP = "INTRO_READY_TO_SLEEP"
# Whether the water in coolant cave is up or down. This persists across saves (since player may save in an area with lowered water)
const COOLANT_CAVE_WATER_RAISED = "COOLANT_CAVE_WATER_RAISED"

# Variables which are persisted.
# Anything in this dictionary will automatically be saved/loaded when the game is saved/loaded.
# Do not access this directly, use get_var(String) and set_var(String, Variant) instead.
# Variables can be bools, floats, Strings, or ints. Anything else will trigger an assertion for now.
var _variables : Dictionary = {
	PLAYER_NAME : "???", #default name is displayed in intro dialogue before the player enters the real name
	LINE_LIMIT : 3, #default number of lines in a script is 3
	STORAGE_PAGES : 2, #default number of storage pages is 2 (16 mons storage)
	
	INTRO_EXAMINED_COMPUTER_ONCE : false,
	INTRO_READY_TO_SLEEP : false,
	
	COOLANT_CAVE_WATER_RAISED : true #default: water is up
}

var team = [] # player's active team
var storage = []  # player's mon storage
var compilation_progress_per_mon := {} # MonType -> int; maps MonType to unlock progress
var _block_unlock_map := {} # tracks which blocks have been unlocked for use in the script editor

# returns a variable, or null if that variable is not set
func get_var(variable_name: String):
	if not _variables.has(variable_name):
		return null
	return _variables[variable_name]

# sets the value of or adds a new variable to the game data map
func set_var(variable_name: String, value) -> void:
	assert(value is bool or value is String or value is int or value is float, "Can't store values besides bools, Strings, ints, floats.")
	_variables[variable_name] = value

func has_var(variable_name: String) -> void:
	return _variables.has(variable_name)

# Set up the initial gamestate (for a new game)
func _ready():
	# make sure all the paths to areas go to files that exist
	for path in _area_enum_to_path.values():
		assert(Global.does_file_exist(path), "%s is not a file!" % path)
	for areaenum in Area.values():
		if areaenum == Area.NONE:
			continue
		assert(_area_enum_to_path.has(areaenum), "No area for enum in dictionary!")
	
	# populate the compilation progress map
	for montype in MonData.MonType.values():
		if montype == MonData.MonType.NONE:
			continue
		else:
			compilation_progress_per_mon[montype] = 0
	
	# mark the initial mon as compiled
	compilation_progress_per_mon[MonData.MonType.BITLEON] = 100
	
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
	team = [MonData.create_mon(MonData.MonType.BITLEON, 0), null, null, null]
	assert(team.size() == Global.MONS_PER_TEAM)
	
	# create the mon storage
	increase_storage_size(_variables[STORAGE_PAGES])
	
	# TODO - remove this debug code
	storage[0] = MonData.create_mon(MonData.MonType.GELIF, 0)
	storage[1] = MonData.create_mon(MonData.MonType.CHORSE, 0)
	storage[2] = MonData.create_mon(MonData.MonType.PASCALICAN, 0)
	storage[3] = MonData.create_mon(MonData.MonType.ORCHIN, 0)
	storage[4] = MonData.create_mon(MonData.MonType.TURTMINAL, 0)
	storage[5] = MonData.create_mon(MonData.MonType.STINGARRAY, 0)
	storage[6] = MonData.create_mon(MonData.MonType.ANGLERPHISH, 0)
	

# saves the game state to file
func save_game():
	# store everything we care about in a big dictionary
	var save_dict := {}
	
	# save each variable as str->Variant
	for var_key in _variables.keys():
		save_dict[var_key] = _variables[var_key]
		
	# save the player's current position, area, mask, and layer
	save_dict["current_area"] = get_tree().get_first_node_in_group("main").get_current_area()
	save_dict["player_x"] = get_tree().get_first_node_in_group("main").get_player().position.x
	save_dict["player_y"] = get_tree().get_first_node_in_group("main").get_player().position.y
	save_dict["player_collision_mask"] = get_tree().get_first_node_in_group("main").get_player().collision_mask
	save_dict["player_collision_layer"] = get_tree().get_first_node_in_group("main").get_player().collision_layer
	
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
	
	# read back each flag
	for var_key in save_dict.keys():
		_variables[var_key] = save_dict[var_key]
	
	# increase the storage size based on the number of pages
	increase_storage_size(_variables[STORAGE_PAGES])
	
	# read back each mon in team
	for i in team.size():
		var mon_str = save_dict["team_mon_%d" % i]
		team[i] = MonData.mon_from_json(mon_str) if mon_str != "[TEAMNULL]" else null
	
	# read back each mon in storage
	for i in storage.size():
		var mon_str = save_dict["storage_mon_%d" % i]
		storage[i] = MonData.mon_from_json(mon_str) if mon_str != "[STORAGENULL]" else null
	
	# set the player's position and area
	Events.area_changed.emit(save_dict["current_area"], Vector2(save_dict["player_x"], save_dict["player_y"]), true)
	
	# set the player's mask
	get_tree().get_first_node_in_group("main").get_player().collision_mask = save_dict["player_collision_mask"]
	get_tree().get_first_node_in_group("main").get_player().collision_layer = save_dict["player_collision_layer"]

func increase_storage_size(new_size: int):
	assert(_variables[STORAGE_PAGES] <= new_size, "Can't decrease storage size!")
	_variables[STORAGE_PAGES] = new_size
	while storage.size() < _variables[STORAGE_PAGES] * MONS_PER_STORAGE_PAGE:
		storage.append(null)
	assert(storage.size() == _variables[STORAGE_PAGES] * MONS_PER_STORAGE_PAGE)

func is_block_unlocked(block: ScriptData.Block) -> bool:
	if not _block_unlock_map.has(block):
		return false
	return _block_unlock_map[block]
