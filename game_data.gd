# Stores information about the game world, such as areas and persistant variables.
extends Node

## Constants ##
const MONS_PER_TEAM = 4 # how many mons in a team
const MONS_PER_STORAGE_PAGE = 8 # how many mons are on a single page of pause menu storage
const SAVE_FILE_NAME = "user://save.monsave" # path to the save file
const MAX_BITS = 65536

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
# Amount of bits (currency)
const BITS = "BITS"
# Key for the player's name.
const PLAYER_NAME = "PlAYER_NAME"
# Maximum number of lines in a script
const LINE_LIMIT = "LINE_LIMIT"
# Number of pages of mon storage in pause menu
const STORAGE_PAGES = "STORAGE_PAGES"
# Save area and position
const RESPAWN_AREA = "RESPAWN_AREA"
const RESPAWN_X = "RESPAWN_X"
const RESPAWN_Y = "RESPAWN_Y"
# if the player has unlocked various battle features
const BATTLE_COUNT = "BATTLE_COUNT" #number of battles the player has done
const BATTLES_TO_UNLOCK_QUEUE_AND_SPEED = 3 #on the third battle; show the queue and speed
const BATTLE_SHOW_QUEUE = "BATTLE_SHOW_QUEUE"
const BATTLE_SHOW_SPEED = "BATTLE_SHOW_SPEED"
const BATTLE_SHOW_ESCAPE = "BATTLE_SHOW_ESCAPE"
# Number of segments of the inject bar
const MAX_INJECTS = "MAX_INJECTS"
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
	BITS : 0,
	PLAYER_NAME : "???", #default name is displayed in intro dialogue before the player enters the real name
	LINE_LIMIT : 3, #default number of lines in a script is 3
	STORAGE_PAGES : 2, #default number of storage pages is 2 (16 mons storage)
	
	BATTLE_COUNT : 0,
	MAX_INJECTS : 0, #default injects is 0; this also hide inject battery
	BATTLE_SHOW_QUEUE : false, 
	BATTLE_SHOW_SPEED : false,
	BATTLE_SHOW_ESCAPE : false,
	
	# starting area/position
	RESPAWN_AREA : GameData.Area.COOLANT_CAVE1_BEACH,
	RESPAWN_X : 8,
	RESPAWN_Y : 87,
	
	INTRO_EXAMINED_COMPUTER_ONCE : false,
	INTRO_READY_TO_SLEEP : false,
	
	COOLANT_CAVE_WATER_RAISED : true #default: water is up
}

var team = [] # player's active team
var storage = []  # player's mon storage
var decompilation_progress_per_mon := {} # MonType -> int; maps MonType to unlock progress
var _block_unlock_map := {} # tracks which blocks have been unlocked for use in the script editor
var inject_points = 0
var bug_inventory = {} # dictionary of owned bugs (BugData.Type -> int)
var cutscenes_played = [] # array of cutscene IDs that have already been played
var queued_battle_cutscene = Battle.Cutscene.NONE

func queue_battle_cutscene(cutscene: Battle.Cutscene) -> void:
	assert(queued_battle_cutscene == Battle.Cutscene.NONE)
	queued_battle_cutscene = cutscene

# returns a variable, or null if that variable is not set
func get_var(variable_name: String):
	if not _variables.has(variable_name):
		return null
	return _variables[variable_name]

# sets the value of or adds a new variable to the game data map
func set_var(variable_name: String, value) -> void:
	assert(value is bool or value is String or value is int or value is float, "Can't store values besides bools, Strings, ints, floats.")
	_variables[variable_name] = value

func add_to_var(variable_name: String, value) -> void:
	assert(value is float or value is int)
	assert(_variables[variable_name] is float or _variables[variable_name] is int)
	_variables[variable_name] += value

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
			decompilation_progress_per_mon[montype] = 0.0
	
	# mark Bitleon as compiled
	decompilation_progress_per_mon[MonData.MonType.BITLEON] = MonData.get_decompilation_progress_required_for(MonData.MonType.BITLEON)
	
	# populate the bug inventory map
	for bugtype in BugData.Type.values():
		bug_inventory[bugtype] = 0
	
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
	assert(team.size() == GameData.MONS_PER_TEAM)
	
	# create the mon storage
	increase_storage_size(_variables[STORAGE_PAGES])
	
	inject_points = get_var(MAX_INJECTS) * BattleData.POINTS_PER_INJECT


# saves the game state to file
func save_game():
	# store everything we care about in a big dictionary
	var save_dict := {}
	
	# save the player's current position, area, mask, and layer
	set_var(RESPAWN_AREA, get_tree().get_first_node_in_group("main").get_current_area())
	set_var(RESPAWN_X, get_tree().get_first_node_in_group("main").get_player().position.x)
	set_var(RESPAWN_Y, get_tree().get_first_node_in_group("main").get_player().position.y)
	
	# save each variable as str->Variant
	for var_key in _variables.keys():
		save_dict[var_key] = _variables[var_key]
	
	save_dict["player_collision_mask"] = get_tree().get_first_node_in_group("main").get_player().collision_mask
	save_dict["player_collision_layer"] = get_tree().get_first_node_in_group("main").get_player().collision_layer
	
	# save each mon in the team
	for i in team.size():
		save_dict["team_mon_%d" % i] = team[i].to_json() if team[i] != null else "[TEAMNULL]"
	
	# save each mon in storage
	for i in storage.size():
		save_dict["storage_mon_%d" % i] = storage[i].to_json() if storage[i] != null else "[STORAGENULL]"
	
	# save the decompilation progress of each mon
	for mon in decompilation_progress_per_mon.keys():
		save_dict["decompilation_progress_for_%s" % mon] = decompilation_progress_per_mon[mon]
	
	#save bug inventory
	for bug in bug_inventory.keys():
		save_dict["bug_inventory_for_%s" % bug] = bug_inventory[bug]
	
	# save which blocks have been unlocked
	for block in _block_unlock_map:
		save_dict["block_unlocked_%s" % block.name] = _block_unlock_map[block]
	
	# save the cutscenes that have been played
	for scene_name in CutscenePlayer.CutsceneID.keys():
		save_dict["played_cutscene_%s" % scene_name] = cutscenes_played.has(CutscenePlayer.CutsceneID[scene_name])
	
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
		if _variables.has(var_key):
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
	
	# read back the decompilation progress of each mon
	for mon in decompilation_progress_per_mon:
		var key = "decompilation_progress_for_%s" % mon
		if save_dict.has(key):
			decompilation_progress_per_mon[mon] = save_dict[key]
	
	# read back the bug inventory
	for bug in bug_inventory:
		var key = "bug_inventory_for_%s" % bug
		if save_dict.has(key):
			bug_inventory[bug] = save_dict[key]
	
	# unlock all unlocked blocks
	for block in _block_unlock_map:
		var key = "block_unlocked_%s" % block.name
		if save_dict.has(key):
			_block_unlock_map[ScriptData.get_block_by_name(block.name)] = save_dict[key]
	
	# mark cutscenes which have already been played
	for scene_name in CutscenePlayer.CutsceneID.keys():
		var key = "played_cutscene_%s" % scene_name
		if save_dict.has(key) and save_dict[key] != false:
			cutscenes_played.append(CutscenePlayer.CutsceneID[scene_name])
	
	# set the player's position and area
	#Events.area_changed.emit(save_dict["current_area"], Vector2(save_dict["player_x"], save_dict["player_y"]), true)
	
	# set the player's position and mask
	respawn_player()
	get_tree().get_first_node_in_group("main").get_player().collision_mask = save_dict["player_collision_mask"]
	get_tree().get_first_node_in_group("main").get_player().collision_layer = save_dict["player_collision_layer"]
	
	# start with full injects on game load
	inject_points = get_var(MAX_INJECTS) * BattleData.POINTS_PER_INJECT

# place the player at their spawn point; 
# for example when loading the game or
# when defeated in battle
func respawn_player() -> void:
	var area = get_var(RESPAWN_AREA)
	var pos = Vector2(get_var(RESPAWN_X), get_var(RESPAWN_Y))
	
	# $HACK$ if the player saves deep in coolant cave, goes to the entrance, then raises the water and dies...
	# they respawn deeper, but the water is up, when it should be drained.
	# lets just make sure the water is down when that happens...
	var hack_areas = [Area.COOLANT_CAVE5_2DRUINS, Area.COOLANT_CAVE6_TEMPLE, Area.COOLANT_CAVE7_WHIRLCAVERN, Area.COOLANT_CAVE8_SEAFLOOR,
		Area.COOLANT_CAVE9_TIDALCHAMBER, Area.COOLANT_CAVE10_RIVER, Area.COOLANT_CAVE11_2DWATERFALL, Area.COOLANT_CAVE12_BOSSROOM]
	if hack_areas.has(area) and GameData.get_var(GameData.COOLANT_CAVE_WATER_RAISED):
		GameData.set_var(GameData.COOLANT_CAVE_WATER_RAISED, false)
		Events.emit_signal("coolant_cave_water_level_changed")
	
	Events.area_changed.emit(area, pos, true)

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

func unlock_block(block: ScriptData.Block) -> void:
	_block_unlock_map[block] = true

func gain_bits(bit_amount: int) -> void:
	GameData.add_to_var(GameData.BITS, bit_amount) # give bits to the player
	if GameData.get_var(GameData.BITS) > MAX_BITS:
		GameData.set_var(GameData.BITS, MAX_BITS)
