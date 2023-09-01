# ScriptData stores information about the scripts used in battle
# Every Mon has a MonScript
# A script has some number of Lines
# Each Line has three Blocks (If, Dd, and To)

extends Node

const SCRIPT_START := "START"	# all scripts must start with
const SCRIPT_END := "END"		# all scripts must end with
const LINE_DELIMITER := "\n"		# all lines are separated by
const BLOCK_DELIMITER := " "		# the 3 blocks on a line are separated by

class MonScript:
	var lines: Array[Line]
	
	func _init(string: String) -> void:
		lines = []
		_from_string(string.strip_edges())
	
	func execute(mon: BattleMon, friends: Array[BattleMon], foes: Array[BattleMon], animator: BattleAnimator) -> void:
		assert(not mon.is_defeated())
		assert(not friends.is_empty())
		assert(not foes.is_empty())
		for line in lines:
			if await line.try_execute(mon, friends, foes, animator):
				return
	
	func as_string() -> String:
		var string = "%s%s" % [SCRIPT_START, LINE_DELIMITER]
		for line in lines:
			string += "%s%s" % [line.as_string(), LINE_DELIMITER]
		string += SCRIPT_END
		return string
	
	func _from_string(string: String) -> void:
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
	var blocks := []
	var ifBlock: Block = null
	var doBlock: Block = null
	var toBlock: Block = null
	
	func _init(string: String) -> void:
		# break into blocks
		var block_strings = string.split(BLOCK_DELIMITER)
		
		for block_string in block_strings:
			var block = ScriptData.get_block_by_name(block_string)
			assert(block != null, "Block name is invalid! %s " % block_string)
			blocks.append(block)
		
		assert(blocks.size() == 2 or blocks.size() == 3, "Invalid number of blocks!")
		
		ifBlock = blocks[0]
		assert(ifBlock.type == Block.Type.IF, "Given if_block_string is not an IF block!")
		doBlock = blocks[1]
		assert(doBlock.type == Block.Type.DO, "Given do_block_string is not a DO block!")
		if blocks.size() == 3:
			assert(doBlock.next_block_type == Block.Type.TO, "This DO shouldn't have a TO!")
			toBlock = blocks[2]
			assert(doBlock.type == Block.Type.DO, "Given do_block_string is not a DO block!")
		else:
			assert(doBlock.next_block_type == Block.Type.NONE, "This DO should have a TO!")

	func try_execute(mon: BattleMon, friends: Array[BattleMon], foes: Array[BattleMon], animator: BattleAnimator) -> bool:
		# check if this line should be executed
		var conditionIsMet = ifBlock.function.call(mon, friends, foes)
		if conditionIsMet:
			# get list of targets
			var targets = null if toBlock == null else toBlock.function.call(mon, friends, foes)
			# perform the battle action
			await doBlock.function.call(mon, friends, foes, targets, animator)
			mon.alert_turn_over()
		
		# return if this line was executed, so script knows not to 
		# attempt to execute other lines if this one took an action
		return conditionIsMet
	
	func as_string() -> String:
		var s = ""
		for block in blocks:
			s += "%s " % block.name
		return s.strip_edges()

class Block:
	enum Type{
		IF, DO, TO, NONE
	}
	
	var type: Type
	var name: String
	var next_block_type: Type
	var tooltip: String # used for the tooltip in script editor
	var function # this should be a :Callable, but Godot is bugged and make a warning...
	
	func _init(blockType: Type, blockName: String, nextBlockType: Type, blockTooltip: String, blockFunction):
		self.type = blockType
		self.name = blockName
		self.next_block_type = nextBlockType
		self.tooltip = blockTooltip
		self.function = blockFunction
	
	func as_string() -> String:
		return name

# utility function used to search a list of blocks for a given block by name
func get_block_by_name(block_name: String) -> Block:
	for block_list in [IF_BLOCK_LIST, DO_BLOCK_LIST, TO_BLOCK_LIST]:
		for block in block_list:
			if block.name == block_name:
				return block
	return null

# IF FUNCTIONS
# Determine whether a line should be executed
#      self       friends      foes            whether to execute line or not
# func(BattleMon, [BattleMon], [BattleMon]) -> bool
var IF_BLOCK_LIST := [
	Block.new(Block.Type.IF, "Always", Block.Type.DO, "This condition always triggers.",
	func(mon: BattleMon, friends: Array[BattleMon], foes: Array[BattleMon]) -> bool: 
		return true
		),
	
	Block.new(Block.Type.IF, "FoeHasLowHP", Block.Type.DO,  "Triggers if a foe has <20% health remaining.",
	func(mon: BattleMon, friends: Array[BattleMon], foes: Array[BattleMon]) -> bool: 
		for foe in foes:
			if float(foe.current_health)/float(foe.max_health) <= 0.20:
				return true
		return false
		),
	
	Block.new(Block.Type.IF, "PalDamaged", Block.Type.DO,  "Triggers if a pal is damaged.",
	func(mon: BattleMon, friends: Array[BattleMon], foes: Array[BattleMon]) -> bool: 
		for friend in friends:
			if friend.current_health < friend.max_health:
				return true
		return false
		),
	Block.new(Block.Type.IF, "PalHasLowHP", Block.Type.DO, "Triggers if a pal has <20% health remaining.",
	func(mon, friends, foes): 
		for friend in friends:
			if float(friend.current_health)/float(friend.max_health) <= 0.20:
				return true
		return false
		)
]

# DO FUNCTIONS
# Perform a battle action 
#      self       friends      foes         target		animation helper      function should perform a battle action
# func(BattleMon, [BattleMon], [BattleMon], BattleMon	Animator]) -> void
var DO_BLOCK_LIST := [
	Block.new(Block.Type.DO, "Pass", Block.Type.NONE, "Do nothing, but conserve half of your AP.",
	func(mon: BattleMon, friends: Array[BattleMon], foes: Array[BattleMon], target: BattleMon, animator: BattleAnimator) -> void:
		mon.action_points = int(mon.action_points / 2.0)
		mon.reset_AP_after_action = false # don't reset to 0 after this action
		),
		
	Block.new(Block.Type.DO, "Attack", Block.Type.TO, "Deals 100% damage to a single target.",
	func(mon: BattleMon, friends: Array[BattleMon], foes: Array[BattleMon], target: BattleMon, animator: BattleAnimator) -> void:
		assert(not target.is_defeated())
		
		# play the animation and wait for it to finish
		animator.slash(target)
		await animator.animation_finished
		
		# then apply the actual damage from this attack
		target.take_damage(mon.attack)
		),
	
	Block.new(Block.Type.DO, "Defend", Block.Type.NONE, "Do nothing, but reduce damage taken by 50% until your next turn.",
	func(mon: BattleMon, friends: Array[BattleMon], foes: Array[BattleMon], target: BattleMon, animator: BattleAnimator) -> void:
		mon.is_defending = true
		),
		
	Block.new(Block.Type.DO, "Escape", Block.Type.NONE, "Attempt to escape the battle. Chance of success depends on SPEED.",
	func(mon: BattleMon, friends: Array[BattleMon], foes: Array[BattleMon], target: BattleMon, animator: BattleAnimator) -> void:
		mon.emit_signal("try_to_escape", mon)
		),
		
	Block.new(Block.Type.DO, "Shellbash", Block.Type.TO, "Attack an enemy for 70% damage, and defend until your next turn.",
	func(mon: BattleMon, friends: Array[BattleMon], foes: Array[BattleMon], target: BattleMon, animator: BattleAnimator) -> void:
		animator.slash(target)
		await animator.animation_finished
		
		target.take_damage(int(mon.attack * 0.7))
		mon.is_defending = true
		),
]

# TO FUNCTIONS
# Returns a list of targets
#      self       friends      foes            function should return targets
# func(BattleMon, [BattleMon], [BattleMon]) -> [BattleMon]
var TO_BLOCK_LIST := [
	Block.new(Block.Type.TO, "RandomFoe", Block.Type.NONE, "Targets a random foe.",
	func(mon: BattleMon, friends: Array[BattleMon], foes: Array[BattleMon]) -> BattleMon:
		return foes[Global.RNG.randi() % foes.size()]
		),
		
	Block.new(Block.Type.TO, "LowestHPFoe", Block.Type.NONE, "Targets the foe with the least health remaining.",
	func(mon: BattleMon, friends: Array[BattleMon], foes: Array[BattleMon]) -> BattleMon:
		var lowestHealthFoe = null
		var lowestHealthFound = Global.INT_MAX
		for foe in foes:
			if foe.current_health < lowestHealthFound:
				lowestHealthFound = foe.current_health
				lowestHealthFoe = foe
		assert(lowestHealthFound > 0)
		assert(lowestHealthFoe != null)
		return lowestHealthFoe
		),
	
	Block.new(Block.Type.TO, "LowestHPPal", Block.Type.NONE, "Targets the pal with the least health remaining.",
	func(mon: BattleMon, friends: Array[BattleMon], foes: Array[BattleMon]) -> BattleMon:
		var lowestHealthFriend = null
		var lowestHealthFound = Global.INT_MAX
		for friend in friends:
			if friend.current_health < lowestHealthFriend:
				lowestHealthFound = friend.current_health
				lowestHealthFriend = friend
		assert(lowestHealthFound > 0)
		assert(lowestHealthFriend != null)
		return lowestHealthFriend
		)
	
]
