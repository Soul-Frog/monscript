# ScriptData stores information about the scripts used in battle
# Every Mon has a Script
# A script has some number of Lines
# Each Line has three Blocks (IF, DO, and TO)

extends Node

# TODO - remove this lol
@onready var TEST_SCRIPT = MonScript.new(Global.file_to_string("res://monscripts/attack.txt"))

const SCRIPT_START = "START"
const SCRIPT_END = "END"
const LINE_DELIMITER = "\n"
const BLOCK_DELIMITER = " "

class MonScript:
	var lines
	
	func _init(string):
		lines = []
		_from_string(string.strip_edges())
	
	func execute(mon, friends, foes):
		for line in lines:
			if line.try_execute(mon, friends, foes):
				return
	
	func as_string():
		var string = "%s%s" % [SCRIPT_START, LINE_DELIMITER]
		for line in lines:
			string += "%s%s" % [line.as_string(), LINE_DELIMITER]
		string += SCRIPT_END
		return string
	
	func _from_string(string):
		# break into lines
		var line_strings = string.split(LINE_DELIMITER)
		assert(len(line_strings) > 1, "No lines in script")
		assert(line_strings[0] == SCRIPT_START, "Invalid script start")
		assert(line_strings[len(line_strings)-1] == SCRIPT_END, "Invalid script end")
		
		# parse each line
		for line_string in line_strings:
			if line_string == SCRIPT_START or line_string == SCRIPT_END:
				continue
			lines.append(Line.new(line_string))
		print(self.as_string())

class Line:
	var ifBlock
	var doBlock
	var toBlock
	
	func _init(string):
		# break into blocks
		var block_strings = string.split(BLOCK_DELIMITER)
		assert(len(block_strings) == 3, "Parsed line does not have exactly 3 blocks")
		
		# pull out the 3 blocks
		var if_block_string = block_strings[0]
		var do_block_string = block_strings[1]
		var to_block_string = block_strings[2]
		
		# search the block lists for these blocks
		ifBlock = ScriptData.get_block_by_name(ScriptData.IF_BLOCK_LIST, if_block_string)
		assert(ifBlock.type == Block.Type.IF, "Given if_block_string is not an IF block!")
		
		doBlock = ScriptData.get_block_by_name(ScriptData.DO_BLOCK_LIST, do_block_string)
		assert(doBlock.type == Block.Type.DO, "Given do_block_string is not a DO block!")
		
		toBlock = ScriptData.get_block_by_name(ScriptData.TO_BLOCK_LIST, to_block_string)
		assert(toBlock.type == Block.Type.TO, "Given to_block_string is not a TO block!")

	func try_execute(mon, friends, foes):
		# check if this line should be executed
		var conditionIsMet = ifBlock.function.call(mon, friends, foes)
		if conditionIsMet:
			# get list of targets
			var targets = toBlock.function.call(mon, friends, foes)
			# perform the battle action
			doBlock.function.call(mon, friends, foes, targets)
		
		# return if this line was executed, so script knows not to 
		# attempt to execute other lines if this one took an action
		return conditionIsMet
	
	func as_string():
		return "%s %s %s" % [ifBlock.name, doBlock.name, toBlock.name]

# utility function used to search a list of blocks for a given block by name
func get_block_by_name(block_list, block_name):
	for block in block_list:
		if block.name == block_name:
			return block
	assert(false, "No block found for name %s (likely a typo, or forgot to add new Block to correct list)" % [block_name])

class Block:
	enum Type{
		IF, DO, TO
	}
	
	var type
	var function
	var name
	
	func _init(blockType, blockName, blockFunction):
		self.type = blockType
		self.name = blockName
		self.function = blockFunction

# IF FUNCTIONS
#      self       friends      foes            whether to execute line or not
# func(BattleMon, [BattleMon], [BattleMon]) -> bool
var IF_BLOCK_LIST = [
	Block.new(Block.Type.IF, "IfAlways", func(mon, friends, foes): 
		return true
		)
]

# DO FUNCTIONS
# Perform a battle action 
var DO_BLOCK_LIST = [
	Block.new(Block.Type.DO, "DoPass", func(mon, friends, foes, target):
		mon.perform_pass()
		),
		
	Block.new(Block.Type.DO, "DoAttack", func(mon, friends, foes, target):
		mon.perform_attack(target)
		),
	
	Block.new(Block.Type.DO, "DoDefend", func(mon, friends, foes, target):
		mon.perform_defend()
		),
		
	Block.new(Block.Type.DO, "DoRun", func(mon, friends, foes, target):
		mon.perform_run()
		)
]

# TO FUNCTIONS
# Returns a list of targets
var TO_BLOCK_LIST = [
	Block.new(Block.Type.TO, "ToRandomFoe", 
	func(mon, friends, foes):
		return foes[Global.RNG.randi() % foes.size()]
		),
		
	Block.new(Block.Type.TO, "ToRandomFriend", 
	func(mon, friends, foes):
		return friends[Global.RNG.randi() % foes.size()]
		),
		
	Block.new(Block.Type.TO, "ToLowestHealthFoe", 
	func(mon, friends, foes):
		var lowestHealthFoe = null
		var lowestHealthFound = -1
		for foe in foes:
			if foe.health < lowestHealthFound:
				lowestHealthFound = foe.health
				lowestHealthFoe = foe
		assert(lowestHealthFound > 0)
		assert(lowestHealthFoe != null)
		return lowestHealthFoe
		)
]
