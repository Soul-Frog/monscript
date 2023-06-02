# ScriptData stores information about the scripts used in battle
# Every Mon has a MonScript
# A script has some number of Lines
# Each Line has three Blocks (If, Dd, and To)

extends Node

const SCRIPT_START = "START"	# all scripts must start with
const SCRIPT_END = "END"		# all scripts must end with
const LINE_DELIMITER = "\n"		# all lines are separated by
const BLOCK_DELIMITER = " "		# the 3 blocks on a line are separated by

class MonScript:
	var lines
	
	func _init(string):
		lines = []
		_from_string(string.strip_edges())
	
	func execute(mon, friends, foes, animator):
		assert(not mon.is_defeated())
		assert(not friends.is_empty())
		assert(not foes.is_empty())
		for line in lines:
			if await line.try_execute(mon, friends, foes, animator):
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
		assert(len(line_strings) > 2, "No lines in script")
		assert(line_strings[0] == SCRIPT_START, "Invalid script start")
		assert(line_strings[len(line_strings)-1] == SCRIPT_END, "Invalid script end")
		
		# parse each line
		for line_string in line_strings:
			line_string = line_string.strip_edges() #be a little lenient with whitespace
			if line_string == SCRIPT_START or line_string == SCRIPT_END:
				continue
			lines.append(Line.new(line_string))

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

	func try_execute(mon, friends, foes, animator):
		# check if this line should be executed
		var conditionIsMet = ifBlock.function.call(mon, friends, foes)
		if conditionIsMet:
			# get list of targets
			var targets = toBlock.function.call(mon, friends, foes)
			# perform the battle action
			await doBlock.function.call(mon, friends, foes, targets, animator)
			mon.alert_turn_over()
		
		# return if this line was executed, so script knows not to 
		# attempt to execute other lines if this one took an action
		return conditionIsMet
	
	func as_string():
		return "%s %s %s" % [ifBlock.name, doBlock.name, toBlock.name]

class Block:
	enum Type{
		IF, DO, TO
	}
	
	var type
	var name
	var function
	
	func _init(blockType, blockName, blockFunction):
		self.type = blockType
		self.name = blockName
		self.function = blockFunction

# utility function used to search a list of blocks for a given block by name
func get_block_by_name(block_list, block_name):
	for block in block_list:
		if block.name == block_name:
			return block
	assert(false, "No block found for name %s (likely a typo, or forgot to add new Block to correct list)" % [block_name])


# IF FUNCTIONS
# Determine whether a line should be executed
#      self       friends      foes            whether to execute line or not
# func(BattleMon, [BattleMon], [BattleMon]) -> bool
var IF_BLOCK_LIST = [
	Block.new(Block.Type.IF, "IfAlways", 
	func(mon, friends, foes): 
		return true
		)
]

# DO FUNCTIONS
# Perform a battle action 
#      self       friends      foes         animation helper      function should perform a battle action
# func(BattleMon, [BattleMon], [BattleMon], [Battle/Animator]) -> void
var DO_BLOCK_LIST = [
	Block.new(Block.Type.DO, "DoPass", 
	func(mon, friends, foes, target, animator):
		mon.action_points = mon.action_points / 2
		mon.reset_AP_after_action = false # don't reset to 0 after this action
		),
		
	Block.new(Block.Type.DO, "DoAttack", 
	func(mon, friends, foes, target, animator):
		assert(not target.is_defeated())
		
		# play the animation and wait for it to finish
		animator.slash(target)
		await animator.animation_finished
		
		# then apply the actual damage from this attack
		target.take_damage(mon.attack)
		),
	
	Block.new(Block.Type.DO, "DoDefend", 
	func(mon, friends, foes, target, animator):
		mon.is_defending = true
		),
		
	Block.new(Block.Type.DO, "DoEscape", 
	func(mon, friends, foes, target, animator):
		mon.emit_signal("try_to_escape", mon)
		)
]

# TO FUNCTIONS
# Returns a list of targets
#      self       friends      foes            function should return targets
# func(BattleMon, [BattleMon], [BattleMon]) -> [BattleMon]
var TO_BLOCK_LIST = [
	Block.new(Block.Type.TO, "ToRandomFoe", 
	func(mon, friends, foes):
		return foes[Global.RNG.randi() % foes.size()]
		),
		
	Block.new(Block.Type.TO, "ToRandomFriend", 
	func(mon, friends, foes):
		return friends[Global.RNG.randi() % friends.size()]
		),
		
	Block.new(Block.Type.TO, "ToLowestHealthFoe", 
	func(mon, friends, foes):
		var lowestHealthFoe = null
		var lowestHealthFound = Global.INT_MAX
		for foe in foes:
			if foe.current_health < lowestHealthFound:
				lowestHealthFound = foe.current_health
				lowestHealthFoe = foe
		assert(lowestHealthFound > 0)
		assert(lowestHealthFoe != null)
		return lowestHealthFoe
		)
]
