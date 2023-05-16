extends Node

const INT_MAX = 9223372036854775806
const INT_MIN = -9223372036854775807

var RNG = RandomNumberGenerator.new()

# change this to turn debug tool (debug_tool.tscn) functionality on/off
# also enables/disables the debug console
var DEBUG = true

# represents the result of a battle
enum BattleEndCondition {
	WIN, # the player won the battle
	LOSE, # the player lost the battle
	ESCAPE, # player escaped from battle
	NONE # default/error condition; should be set before battle ends
}

func file_to_string(file_path):
	return FileAccess.open(file_path, FileAccess.READ).get_as_text()

func string_to_file(file_path, string):
	FileAccess.open(file_path, FileAccess.WRITE).store_string(string)

func does_file_exist(file_path):
	return FileAccess.file_exists(file_path)

func call_after_delay(delay_in_secs, function):
	await get_tree().create_timer(delay_in_secs).timeout
	function.call()
	
