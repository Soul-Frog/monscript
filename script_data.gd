# ScriptData stores information about the scripts used in battle
# Every Mon has a MonScript
# A script has some number of Lines
# Each Line has three Blocks (If, Dd, and To)

extends Node

const SCRIPT_START := "START"	# all scripts must start with
const SCRIPT_END := "END"		# all scripts must end with
const LINE_DELIMITER := "\n"	# all lines are separated by
const BLOCK_DELIMITER := " "	# the 3 blocks on a line are separated by

class MonScript:
	var lines: Array[Line] = []
	
	func _init(string: String) -> void:
		_from_string(string.strip_edges())
	
	func execute(mon: BattleMon, friends: Array, foes: Array, animator: BattleAnimator) -> void:
		assert(not mon.is_defeated())
		assert(not friends.is_empty())
		assert(not foes.is_empty())
		if lines.size() == 0: #empty script, just run error
			await ScriptData._ERROR_DO.function.call(mon, friends, foes, null, animator)
			mon.alert_turn_over()
		for line in lines:
			if await line.try_execute(mon, friends, foes, animator):
				return
	
	func is_valid() -> bool:
		if lines.size() == 0: #if there are no lines, it's invalid
			return false
		
		for line in lines: #if any line is invalid, it's invalid
			if not line.is_valid():
				return false
		
		return true
	
	func as_string() -> String:
		var string = "%s%s" % [SCRIPT_START, LINE_DELIMITER]
		for line in lines:
			string += "%s%s" % [line.as_string(), LINE_DELIMITER]
		string += SCRIPT_END
		return string
	
	func _from_string(string: String) -> void:
		# break into lines
		var line_strings = string.split(LINE_DELIMITER)
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
		var block_strings = string.split(BLOCK_DELIMITER, false)
		
		for block_string in block_strings:
			var block = ScriptData.get_block_by_name(block_string)
			assert(block != null, "Block name is invalid! %s " % block_string)
			blocks.append(block)
		
		# parse the blocks one at a time
		for i in blocks.size():
			assert(i < 3, "More than 3 blocks in line?")
			var currentBlock: Block = blocks[i]
			if currentBlock.type == Block.Type.IF:
				assert(i == 0, "IF must be first block!")
				assert(ifBlock == null, "Somehow multiple IF?")
				ifBlock = currentBlock
			elif currentBlock.type == Block.Type.DO:
				assert(i == 0 or (i == 1 and ifBlock != null), "DO block must be first or second after an IF!")
				assert(doBlock == null, "Somehow multiple DO?")
				doBlock = currentBlock
			elif currentBlock.type == Block.Type.TO:
				assert(doBlock != null and doBlock.next_block_type == Block.Type.TO and (i == 1 or i == 2), "TO must be after")
				assert(toBlock == null, "Somehow multiple TO?")
				toBlock = currentBlock
			else:
				assert(false, "Something really weird has happened.")

	func is_valid() -> bool:
		# Invalid cases:
		# 1: DO does not exist
		if doBlock == null: 
			return false
			
		# 2: TO does not exist AND DO requires a TO
		if doBlock.next_block_type == Block.Type.TO and toBlock == null:
			return false
		return true

	func try_execute(mon: BattleMon, friends: Array, foes: Array, animator: BattleAnimator) -> bool:
		# if this line is invalid, terminate with error
		if not is_valid(): 
			await ScriptData._ERROR_DO.function.call(mon, friends, foes, null, animator)
			mon.alert_turn_over()
			return true #we 'executed' this line, so return false to stop execution
		
		# this line is valid, so do normal processing
		# check if this line should be executed
		# if there is no ifBlock, the line is just a DO-TO, the IF is implicitly true
		var conditionIsMet = ifBlock.function.call(mon, friends, foes) if ifBlock != null else true
		if conditionIsMet:
			# get list of targets
			# if there is no TO block, this must be a DO which does not require one
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
	var description: String # used for the tooltip in script editor and as description in database
	var function # this should be a :Callable, but Godot is bugged and make a warning...
	
	func _init(blockType: Type, blockName: String, nextBlockType: Type, blockDescription: String, blockFunction):
		self.type = blockType
		self.name = blockName
		self.next_block_type = nextBlockType
		self.description = blockDescription
		self.function = blockFunction
	
	func as_string() -> String:
		return name

# utility function used to search a list of blocks for a given block by name
func get_block_by_name(block_name: String) -> Block:
	for block_list in [IF_BLOCK_LIST, DO_BLOCK_LIST, TO_BLOCK_LIST]:
		for block in block_list:
			if block.name == block_name:
				return block
	assert(false, "No block with name %s!" % block_name)
	return null

# IF FUNCTIONS
# Determine whether a line should be executed
#      self       friends      foes            whether to execute line or not
# func(BattleMon, [BattleMon], [BattleMon]) -> bool
var IF_BLOCK_LIST := [
	Block.new(Block.Type.IF, "Always", Block.Type.DO, "This condition always triggers.",
	func(mon: BattleMon, friends: Array, foes: Array) -> bool: 
		return true
		),
	
	Block.new(Block.Type.IF, "FoeHasLowHP", Block.Type.DO,  "Triggers if a foe has <20% health remaining.",
	func(mon: BattleMon, friends: Array, foes: Array) -> bool: 
		for foe in foes:
			if float(foe.current_health)/float(foe.max_health) <= 0.20:
				return true
		return false
		),
	
	Block.new(Block.Type.IF, "PalDamaged", Block.Type.DO,  "Triggers if a pal is damaged.",
	func(mon: BattleMon, friends: Array, foes: Array) -> bool: 
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
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, animator: BattleAnimator) -> void:
		mon.action_points = int(mon.action_points / 2.0)
		mon.reset_AP_after_action = false # don't reset to 0 after this action
		),
		
	Block.new(Block.Type.DO, "Attack", Block.Type.TO, "Deals 100% damage to a single target.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, animator: BattleAnimator) -> void:
		assert(not target.is_defeated())
		
		# play the animation and wait for it to finish
		animator.slash(target)
		await animator.animation_finished
		
		# then apply the actual damage from this attack
		target.apply_attack(mon.attack, 1)
		),
	
	Block.new(Block.Type.DO, "Defend", Block.Type.NONE, "Do nothing, but reduce damage taken by 50% until your next turn.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, animator: BattleAnimator) -> void:
		mon.is_defending = true
		),
		
	Block.new(Block.Type.DO, "Escape", Block.Type.NONE, "Attempt to escape the battle. Chance of success depends on SPEED.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, animator: BattleAnimator) -> void:
		mon.emit_signal("try_to_escape", mon)
		),
		
	Block.new(Block.Type.DO, "ShellBash", Block.Type.TO, "Attack an enemy for 70% damage, and defend until your next turn.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, animator: BattleAnimator) -> void:
		animator.slash(target)
		await animator.animation_finished
		
		target.apply_attack(mon.attack, 0.7)
		mon.is_defending = true
		),
		
	Block.new(Block.Type.DO, "Repair", Block.Type.NONE, "Heal 40% of your HP and clear status conditions.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, animator: BattleAnimator) -> void:
		mon.heal_damage(int(mon.max_health * 0.4))
		mon.heal_all_statuses()
		),
		
	Block.new(Block.Type.DO, "C-gun", Block.Type.TO, "Deals 80% Chill damage to a single target (140% Chill damage instead if this is your 5th turn or later).",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, animator: BattleAnimator) -> void:
		#todo - animation
		animator.slash(target)
		await animator.animation_finished
		
		var dmg_mult = 0.8
		if mon.turn_count >= 5:
			dmg_mult = 1.4
		
		target.apply_attack(mon.attack, dmg_mult) #todo - chill damage
		),
	
	Block.new(Block.Type.DO, "Triangulate", Block.Type.TO, "Deals 50% damage to a single target. Increases by +10%/20%/30%/60%/100% each use in the same battle.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, animator: BattleAnimator) -> void:
		#todo - animation
		animator.slash(target)
		await animator.animation_finished
		
		const metadata_key = "TRIANGULATE_USES"
		
		var dmg_mult = 0.5
		if mon.metadata.has(metadata_key):
			var previous_uses = mon.metadata[metadata_key]
			assert(previous_uses > 0)
			if previous_uses == 1:
				dmg_mult += 0.1
			elif previous_uses == 2:
				dmg_mult += 0.2
			elif previous_uses == 3:
				dmg_mult += 0.3
			elif previous_uses == 4:
				dmg_mult += 0.6
			else:
				dmg_mult += 1
			mon.metadata[metadata_key] += 1
		else:
			mon.metadata[metadata_key] = 1
		
		target.apply_attack(mon.attack, dmg_mult)
		),
	
	Block.new(Block.Type.DO, "SpikOR", Block.Type.TO, "Deals 60% damage to a single target (125% damage instead if target is leaky or above 80% HP.)",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, animator: BattleAnimator) -> void:
		#todo - animation
		animator.slash(target)
		await animator.animation_finished
		
		var dmg_mult = 0.6
		if mon.statuses[BattleMon.Status.LEAK] or float(mon.current_health) / mon.max_health >= 0.8:
			dmg_mult = 1.25
		
		target.apply_attack(mon.attack, dmg_mult) #todo - volt damage
		),
	
	Block.new(Block.Type.DO, "Multitack", Block.Type.NONE, "Four times, deal 25% damage to a random target.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, animator: BattleAnimator) -> void:
		for i in range(0, 4):
			var rand_target = Global.choose_one(foes)
			animator.slash(rand_target) #todo - animation
			await animator.animation_finished
			rand_target.apply_attack(mon.attack, 0.25)
		),
		
	Block.new(Block.Type.DO, "Spearphish", Block.Type.TO, "Inflict leak on a single target.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, animator: BattleAnimator) -> void:
		animator.slash(target) #todo - animation
		await animator.animation_finished
		target.inflict_status(BattleMon.Status.LEAK)
		),
		
	Block.new(Block.Type.DO, "Transfer", Block.Type.TO, "Heal a mon by transfering up to 50% of the user's HP to a single target.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, animator: BattleAnimator) -> void:
		# heal amount is up to 50% of user's health; if not enough health, use all but 1
		var heal_possible = min(mon.max_health * 0.5, mon.current_health - 1)
		# heal amount is ideally the previous value, but if we don't need to heal that much, use the diff between target's
		# current and max health instead (basically, don't overheal)
		var heal_used = min(heal_possible, target.max_health - target.current_health)
		
		#todo animation
		
		# apply the heal
		target.heal_damage(heal_used)
		# and damage ourself
		mon.take_damage(heal_used)
		),
]

# TO FUNCTIONS
# Returns a list of targets
#      self       friends      foes            function should return targets
# func(BattleMon, [BattleMon], [BattleMon]) -> [BattleMon]
var TO_BLOCK_LIST := [
	Block.new(Block.Type.TO, "RandomFoe", Block.Type.NONE, "Targets a random foe.",
	func(mon: BattleMon, friends: Array, foes: Array) -> BattleMon:
		return foes[Global.RNG.randi() % foes.size()]
		),
		
	Block.new(Block.Type.TO, "LowestHPFoe", Block.Type.NONE, "Targets the foe with the least health remaining.",
	func(mon: BattleMon, friends: Array, foes: Array) -> BattleMon:
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
	func(mon: BattleMon, friends: Array, foes: Array) -> BattleMon:
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

# Godot warns here but it's wrong, this is being used by an internal class.
@warning_ignore("unused_private_class_variable")
var _ERROR_DO := Block.new(Block.Type.DO, "ERROR", Block.Type.NONE, "ERROR - do nothing.",
	func (mon: BattleMon, friends:Array, foes: Array, target: BattleMon, animator: BattleAnimator):
		# TODO - something better here
		print("ERROR")
)
