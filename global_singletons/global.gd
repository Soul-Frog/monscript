extends Node

const INT_MAX = 9223372036854775806
const INT_MIN = -9223372036854775807

var RNG := RandomNumberGenerator.new()

const COLOR_WHITE_TEXT = Color(255.0/255.0, 255.0/255.0, 255.0/255.0, 255)
const COLOR_GRAY_TEXT = Color(179.0/255.0, 185.0/255.0, 209.0/255.0, 255)
const COLOR_GOLDEN = Color(255.0/255.0, 210.0/255.0, 130.0/255.0, 255)
const COLOR_BLACK = Color(0, 0, 0)
const COLOR_WHITE = Color.WHITE
const COLOR_PINK = Color.PINK
const COLOR_YELLOW = Color.YELLOW
const COLOR_GREEN = Color(20.0/255.0, 160.0/255.0, 46.0/255.0)
const COLOR_RED = Color.RED
const COLOR_DARK_RED = Color.DARK_RED
const COLOR_LIGHT_BLUE = Color.SKY_BLUE
const COLOR_PURPLE = Color.MEDIUM_PURPLE

# turns various debug functionality on and off
var DEBUG_DRAW = false # Draw additional debug shapes through DebugTool
var DEBUG_NO_INVINCIBLE = false # Turn off invincibility after ending a battle
var DEBUG_CONSOLE = true # Enables the debug console when typing `
var DEBUG_FAST_START = true # Continue is available even with no save file; speeds up main menu->overworld transition

func adjust_towards(current, goal, delta):
	assert(delta > 0, "Delta should be provided as a nonzero positive value")
	if current < goal:
		current = min(goal, current + delta)
	elif current > goal:
		current = max(goal, current - delta)
	return current

func choose_char(options: String):
	assert(options.length() != 0, "No options in string!")
	return options[RNG.randi_range(0, options.length()-1)]

# returns one of the items in the input array at random
func choose_one(options: Array[Variant]):
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

# returns a list of all files in a directory
func files_in_folder(directory: String) -> Array:
	return DirAccess.get_files_at(directory)

# returns a list of all file paths in a given directory with a certain extension
func files_in_folder_with_extension(directory: String, extension: String) -> Array:
	var out := []
	
	for file in files_in_folder(directory):
		if file.ends_with(extension):
			out.append(file)
	
	return out 

# creates a delay of a given time
# await on this function call
func delay(delay_in_secs: float):
	await get_tree().create_timer(delay_in_secs).timeout

# print that also includes the object being printed from
func p(node: Node, s: String) -> void:
	print("%s: %s" % [node, s])

# returns a string of s repeated n times
func repeat_str(s: String, n: int) -> String:
	assert(n >= 0, "Can't repeat a negative number of times!")
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

# Casts the given num to a string and pads the front with 0s until it
# is the given length.
# ex: int_to_str_zero_padded(53, 6) = "000053"
func int_to_str_zero_padded(num: int, length: int):
	var ret = str(num)
	while ret.length() < length:
		ret = "0" + ret
	return ret

# returns the position of this node if centered on a given point
func centered_position(node: Node, point: Vector2) -> Vector2:
	return point - Vector2(node.size.x/2, node.size.y/2)

# removes each child of a node and frees them
func free_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

# removes each child of a node but does NOT free them
func remove_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)

# used to disable a node
# recursively sets the enable status of process and physics processes and input on node and all children
func recursive_set_processes(node: Node, enable: bool) -> void:
	node.set_process(enable)
	node.set_physics_process(enable)
	node.set_process_input(enable)
	for child in node.get_children():
		recursive_set_processes(child, enable)

func value_or_default(dict: Dictionary, key, default):
	return dict[key] if dict.has(key) else default

# Returns a string representation of the hotkey for a given action (for example, "E" or "A")
func key_for_action(action: String) -> String:
	assert(InputMap.has_action(action))
	# get the first key mapped to this action; split to remove anything but the key itself
	# for example the E key as_text is "E (Physical)"; split to remove the (Physical)
	return InputMap.action_get_events(action)[0].as_text().split(" ")[0]

func to_leetspeak(string: String) -> String:
	const _leetspeak_map = {
		"A" : "4",
		"E" : "3",
		"I" : "1",
		"O" : "0",
		"S" : "$"
	}
	var leeted = ""
	string = string.to_upper()
	for c in string:
		leeted += _leetspeak_map[c] if _leetspeak_map.has(c) else c
	return leeted

# returns a normalized direction vector pointing towards the given point, from the given pos
# epsilon is the threshold of how close to get before considering to be at the correct x or y
# retursn Vector2.ZERO if pos ~= point
func direction_towards_point(pos: Vector2, destination: Vector2, epsilon = 2.0) -> Vector2:
	var direction = Vector2.ZERO
	
	var at_correct_x = abs(pos.x - destination.x) <= epsilon
	var at_correct_y = abs(pos.y - destination.y) <= epsilon
	
	if not at_correct_x:
		if pos.x < destination.x:
			direction.x = 1
		else:
			direction.x = -1
	if not at_correct_y:
		if pos.y < destination.y:
			direction.y = 1
		else:
			direction.y = -1
	
	return direction.normalized()
