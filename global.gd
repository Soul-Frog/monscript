extends Node

const INT_MAX = 9223372036854775806
const INT_MIN = -9223372036854775807

const MONS_PER_TEAM = 4

var RNG = RandomNumberGenerator.new()

const COLOR_PINK = Color.PINK
const COLOR_YELLOW = Color.YELLOW
const COLOR_GREEN = Color.GREEN
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

# returns one of the items in the input array at random
func choose_one(options: Array):
	assert(options.size() != 0, "No options in array!")
	return options[RNG.randi_range(0, options.size()-1)]

# read a file on the filesystem as a string
func file_to_string(file_path: String) -> String:
	assert(does_file_exist(file_path), "File does not exist!")
	return FileAccess.open(file_path, FileAccess.READ).get_as_text()

# write a string to a file on the filesystem
# overwrites previous content in that file
func string_to_file(file_path: String, string: String) -> void:
	FileAccess.open(file_path, FileAccess.WRITE).store_string(string)

func delete_file(file_path: String) -> void:
	assert(does_file_exist(file_path), "File does not exist!")
	DirAccess.remove_absolute(file_path)

# check if a file exists at file_path
func does_file_exist(file_path: String) -> bool:
	return FileAccess.file_exists(file_path)

# call a given function after a delay
# this function is very dangerous, make sure you know what you are doing.
# often your function will need to check if that object it originated from
# hasn't been freed!
func call_after_delay(delay_in_secs: float, arg, function: Callable) -> void:
	await get_tree().create_timer(delay_in_secs).timeout
	function.call(arg)

# print that also includes the object being printed from
func p(node: Node, s: String) -> void:
	print("%s: %s" % [node, s])

# returns a string of s repeated n times
func repeat_str(s: String, n: int) -> String:
	assert(n >= 1, "Can't repeat a non-positive number of times!")
	var r = ""
	for i in range(0, n):
		r += s
	return r

# prints a tree of node and its children
func dump(node: Node) -> void:
	_dump_helper(node, 0)

func _dump_helper(node: Node, indent_level: int) -> void:
	print(repeat_str("  ", indent_level), node.name) 
	for child in node.get_children():
		_dump_helper(child, indent_level + 1)
