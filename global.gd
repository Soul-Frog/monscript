extends Node

var RNG = RandomNumberGenerator.new()

# change this to turn debug tool (debug_tool.tscn) functionality on/off
# also enables/disables the debug console
var DEBUG = true

# represents the result of a battle
enum BattleEndCondition {
	WIN, # the player on the battle
	LOSE, # the player lost the battle
	RUN, # player ran away from battle
	NONE # default/error condition; should be set before battle ends
}

func file_to_string(file_path):
	return FileAccess.open(file_path, FileAccess.READ).get_as_text()

func string_to_file(file_path, string):
	FileAccess.open(file_path, FileAccess.WRITE).store_string(string)
