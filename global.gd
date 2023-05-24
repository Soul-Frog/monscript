extends Node

const INT_MAX = 9223372036854775806
const INT_MIN = -9223372036854775807

const MONS_PER_TEAM = 4

var RNG = RandomNumberGenerator.new()

const COLOR_WHITE = Color.WHITE
const COLOR_RED = Color.RED

# turns various debug functionality on and off
var DEBUG_DRAW = true
var DEBUG_NO_INVINCIBLE = true
var DEBUG_CONSOLE = true

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

# this function is very dangerous, make sure you know what you are doing.
func call_after_delay(delay_in_secs, arg, function):
	await get_tree().create_timer(delay_in_secs).timeout
	function.call(arg)

# print that also includes the object being printed from
func p(node, s):
	print("%s: %s" % [node, s])

# prints a tree of node and its children
func dump(node):
	_dump_helper(node, 0)

func _dump_helper(node, indent_level):
	print(repeat_str("  ", indent_level), node.name) 
	for child in node.get_children():
		_dump_helper(child, indent_level + 1)

# returns a string of s repeated n times
func repeat_str(s, n):
	var r = ""
	for i in range(0, n):
		r += s
	return r
