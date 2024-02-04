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
	var wasLastActionCanceled = false
	var lines: Array[Line] = []
	
	func _init(string: String) -> void:
		_from_string(string.strip_edges())
	
	func execute(mon: BattleMon, friends: Array, foes: Array, battle_log: BattleLog, script_line_viewer: BattleScriptLineViewer, animator: BattleAnimator, escaping: bool) -> void:
		assert(not mon.is_defeated())
		assert(not friends.is_empty())
		assert(not foes.is_empty())
		if escaping:
			script_line_viewer.show_block(ScriptData.get_block_by_name("Escape"))
			await ScriptData.get_block_by_name("Escape").function.call(mon, friends, foes, null, battle_log, animator)
			return
		if lines.size() == 0: #empty script, just run error
			script_line_viewer.show_block(ScriptData._ERROR_DO)
			await ScriptData._ERROR_DO.function.call(mon, friends, foes, null, battle_log, animator)
		for line in lines:
			if await line.try_execute(mon, friends, foes, battle_log, script_line_viewer, animator):
				wasLastActionCanceled = line.wasLineCanceled
				return
		
		# if we reached this point, we did not perform anything at all, so error
		battle_log.add_text("No conditions were met! %s did nothing." % battle_log.MON_NAME_PLACEHOLDER, mon)
		script_line_viewer.show_block(ScriptData._ERROR_DO)
		await ScriptData._ERROR_DO.function.call(mon, friends, foes, null, battle_log, animator)
	
	func was_last_action_canceled() -> bool:
		return wasLastActionCanceled
	
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
		for i in line_strings.size():
			var line_string = line_strings[i]
			line_string = line_string.strip_edges() #be a little lenient with whitespace
			if line_string == SCRIPT_START or line_string == SCRIPT_END:
				continue
			lines.append(Line.new(i, line_string))

class Line:
	var blocks := []
	var lineNumber: int = -1
	var ifBlock: Block = null
	var doBlock: Block = null
	var toBlock: Block = null
	var wasLineCanceled = false
	
	func _init(number: int, string: String) -> void:
		lineNumber = number
		
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

	func try_execute(mon: BattleMon, friends: Array, foes: Array, battle_log: BattleLog, script_line_viewer: BattleScriptLineViewer, animator: BattleAnimator) -> bool:
		# if this line is invalid, terminate with error
		if not is_valid(): 
			script_line_viewer.show_block(ScriptData._ERROR_DO)
			await ScriptData._ERROR_DO.function.call(mon, friends, foes, null, battle_log, animator)
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
			script_line_viewer.show_line(lineNumber, ifBlock, doBlock, toBlock)
			wasLineCanceled = not await doBlock.function.call(mon, friends, foes, targets, battle_log, animator)
		
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
	if block_name == _ERROR_DO.name:
		return _ERROR_DO
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
	Block.new(Block.Type.IF, "SelfDamaged", Block.Type.DO, "Triggers if this mon is damaged.",
	func(mon: BattleMon, friends: Array, foes: Array) -> bool: 
		if mon.current_health != mon.max_health:
			return true
		return false
		),
	
	Block.new(Block.Type.IF, "PalDamaged", Block.Type.DO, "Triggers if a pal (not including this mon) is damaged.",
	func(mon: BattleMon, friends: Array, foes: Array) -> bool: 
		for friend in friends:
			if friend.current_health < friend.max_health:
				return true
		return false
		),
	
	Block.new(Block.Type.IF, "PalLowHP", Block.Type.DO, "Triggers if any pal (not including this mon) has <30% health remaining.",
	func(mon, friends, foes): 
		for friend in friends:
			if friend == mon:
				continue
			if float(friend.current_health)/float(friend.max_health) <= 0.3:
				return true
		return false
		),
	
	Block.new(Block.Type.IF, "SelfLowHP", Block.Type.DO, "Triggers if you have <30% health remaining.",
	func(mon, friends, foes): 
		if float(mon.current_health)/float(mon.max_health) <= 0.3:
			return true
		return false
		),
	
	Block.new(Block.Type.IF, "FoeLowHP", Block.Type.DO,  "Triggers if any foe has <30% health remaining.",
	func(mon: BattleMon, friends: Array, foes: Array) -> bool: 
		for foe in foes:
			if float(foe.current_health)/float(foe.max_health) <= 0.25:
				return true
		return false
		),
]

# DO FUNCTIONS
# Perform a battle action 
#      self       friends      foes         target		battle_log		animation helper      function should perform a battle action; return if the action was canceled
# func(BattleMon, [BattleMon], [BattleMon], BattleMon	battle_log		Animator]) -> 		  bool
var DO_BLOCK_LIST := [
	Block.new(Block.Type.DO, "Pass", Block.Type.NONE, "Do nothing, but conserve half of your AP.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator) -> bool:
		battle_log.add_text("%s passed." % battle_log.MON_NAME_PLACEHOLDER, mon)
		mon.set_action_points(mon.action_points / 2.0)
		mon.reset_AP_after_action = false # don't reset to 0 after this action
		return true
		),
		
	Block.new(Block.Type.DO, "Attack", Block.Type.TO, "Attack a mon for 100% damage.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator) -> bool:
		assert(not target.is_defeated())
		battle_log.add_text("%s attacked!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		
		# play the animation and wait for it to finish
		animator.slash(target)
		await animator.animation_finished
		if animator.was_animation_canceled:
			return false
		
		# then apply the actual damage from this attack
		target.apply_attack(mon, 1, MonData.DamageType.NORMAL)
		
		return true
		),
	
	Block.new(Block.Type.DO, "Defend", Block.Type.NONE, "Do nothing, but reduce damage taken by 50% until your next turn.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator) -> bool:
		battle_log.add_text("%s is defending!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		mon.is_defending = true
		return true
		),
	
	Block.new(Block.Type.DO, "Escape", Block.Type.NONE, "Attempt to escape the battle. Chance of success depends on SPEED.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator) -> bool:
		mon.emit_signal("try_to_escape", mon)
		return true
		),
		
	Block.new(Block.Type.DO, "ShellBash", Block.Type.TO, "Attack a mon for 70% damage, and defend until your next turn.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator) -> bool:
		battle_log.add_text("%s used ShellBash!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		animator.slash(target)
		await animator.animation_finished
		if animator.was_animation_canceled:
			return false
		
		target.apply_attack(mon, 0.7, MonData.DamageType.NORMAL)
		mon.is_defending = true
		return true
		),
		
	Block.new(Block.Type.DO, "Repair", Block.Type.NONE, "Heal 40% of your own HP and clear status conditions.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator) -> bool:
		battle_log.add_text("%s used Repair!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		mon.heal_damage(int(mon.max_health * 0.4))
		mon.heal_all_statuses()
		return true
		),
		
	Block.new(Block.Type.DO, "C-gun", Block.Type.TO, "Attack a mon for 80% Chill damage. (140% Chill damage instead if this is your 5th turn or later).",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator) -> bool:
		battle_log.add_text("%s used C-Gun!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		
		#todo - animation
		animator.slash(target)
		await animator.animation_finished
		if animator.was_animation_canceled:
			return false
		
		var dmg_mult = 0.8
		if mon.turn_count >= 4:
			dmg_mult = 1.4
		
		target.apply_attack(mon, dmg_mult, MonData.DamageType.CHILL)
		
		return true
		),
	
	Block.new(Block.Type.DO, "Triangulate", Block.Type.TO, "Attack a mon for 50% damage. Increases by +10%/20%/30%/60%/100% on repeated uses.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator) -> bool:
		battle_log.add_text("%s used Triangulate!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		
		#todo - animation
		animator.slash(target)
		await animator.animation_finished
		if animator.was_animation_canceled:
			return false
		
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
		
		target.apply_attack(mon, dmg_mult, MonData.DamageType.NORMAL)
		
		return true
		),
	
	Block.new(Block.Type.DO, "SpikOR", Block.Type.TO, "Attack a mon for 60% damage (125% damage instead if that mon has LEAK or is above 80% HP.)",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, action_name_box: BattleActionNameBox, animator: BattleAnimator) -> bool:
		var leak_condition = target.statuses[BattleMon.Status.LEAK]
		var health_condition = float(target.current_health) / target.max_health >= 0.8
		
		battle_log.add_text("%s used SpikOR!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		
		if leak_condition:
			battle_log.add_text("It dealt bonus damage to the LEAKY target!")
		elif health_condition:
			battle_log.add_text("It dealt bonus damage to the high HP target!")
		
		#todo - animation
		animator.slash(target)
		await animator.animation_finished
		if animator.was_animation_canceled:
			return false
		
		var dmg_mult = 0.6
		if leak_condition or health_condition:
			dmg_mult = 1.25
		
		target.apply_attack(mon, dmg_mult, MonData.DamageType.VOLT)
		
		return true
		),
	
	Block.new(Block.Type.DO, "Multitack", Block.Type.NONE, "Four times, attack a random foe for 25% damage.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator) -> bool:
		battle_log.add_text("%s used Multitack!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		for i in range(0, 4):
			var rand_target = Global.choose_one(foes)
			animator.slash(rand_target) #todo - animation
			await animator.animation_finished
			if animator.was_animation_canceled:
				return false
			
			rand_target.apply_attack(mon, 0.25, MonData.DamageType.NORMAL)
			
			# if we killed the target, don't let it be a target for future attacks
			if rand_target.current_health == 0:
				foes.erase(rand_target)
				if foes.size() == 0: # if everyone is dead, don't keep attacking
					break
		
		return true
		),
		
	Block.new(Block.Type.DO, "Spearphishing", Block.Type.TO, "Inflict LEAK on a mon.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator) -> bool:
		battle_log.add_text("%s used Spearphishing!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		animator.slash(target) #todo - animation
		await animator.animation_finished
		if animator.was_animation_canceled:
			return false
		target.inflict_status(BattleMon.Status.LEAK)
		
		return true
		),
		
	Block.new(Block.Type.DO, "Transfer", Block.Type.TO, "Heal by transfering up to 50% of the user's HP to a mon.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator) -> bool:
		battle_log.add_text("%s used Transfer!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		
		# heal amount is up to 50% of user's health; if not enough health, use all but 1
		var heal_possible = min(mon.max_health * 0.5, mon.current_health - 1)
		# heal amount is ideally the previous value, but if we don't need to heal that much, use the diff between target's
		# current and max health instead (basically, don't overheal)
		var heal_used = min(heal_possible, target.max_health - target.current_health)
		
		#todo animation
		
		# apply the heal
		target.heal_damage(heal_used)
		# and damage ourself
		mon.take_damage(heal_used, MonData.DamageType.TYPELESS)
		
		return true
		),
	
	Block.new(Block.Type.DO, "HYDR0", Block.Type.NONE, "Attack all foes for 500% Chill damage.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator) -> bool:
		battle_log.add_text("%s US3D HYDR0!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		
		#todo - animation
		animator.slash(target)
		await animator.animation_finished
		if animator.was_animation_canceled:
			return false
		
		for foe in foes:
			foe.apply_attack(mon, 5.0, MonData.DamageType.CHILL)
		
		return true
		),
	
	Block.new(Block.Type.DO, "B1T3", Block.Type.TO, "Attack a mon for 95% damage and inflict LEAK.",
	func(mon: BattleMon, friends: Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator) -> bool:
		battle_log.add_text("%s US3D B1T3!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		
		#todo - animation
		animator.slash(target)
		await animator.animation_finished
		if animator.was_animation_canceled:
			return false
		
		target.apply_attack(mon, 0.95, MonData.DamageType.NORMAL)
		target.inflict_status(BattleMon.Status.LEAK)
		
		return true
		),
]

# TO FUNCTIONS
# Returns a list of targets
#      self       friends      foes            function should return targets
# func(BattleMon, [BattleMon], [BattleMon]) -> [BattleMon]
var TO_BLOCK_LIST := [
	Block.new(Block.Type.TO, "Self", Block.Type.NONE, "Targets this mon.",
	func(mon: BattleMon, friends: Array, foes: Array) -> BattleMon:
		return mon
		),
	
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
	
	Block.new(Block.Type.TO, "LowestHPPal", Block.Type.NONE, "Targets the pal (not including this mon) with the least health remaining.",
	func(mon: BattleMon, friends: Array, foes: Array) -> BattleMon:
		var lowestHealthFriend = null
		var lowestHealthFound = Global.INT_MAX
		for friend in friends:
			if friend.current_health < lowestHealthFound:
				lowestHealthFound = friend.current_health
				lowestHealthFriend = friend
		assert(lowestHealthFound > 0)
		assert(lowestHealthFriend != null)
		return lowestHealthFriend
		)	
]

# Godot warns here but it's wrong, this is being used by an internal class.
@warning_ignore("unused_private_class_variable")
var _ERROR_DO := Block.new(Block.Type.DO, "ERROR!!", Block.Type.NONE, "ERROR - do nothing.",
	func (mon: BattleMon, friends:Array, foes: Array, target: BattleMon, battle_log: BattleLog, animator: BattleAnimator):
		battle_log.add_text("%s has an script [color=red]ERROR[/color]!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		battle_log.add_text("%s could not move!" % battle_log.MON_NAME_PLACEHOLDER, mon)
		#todo - animation
		await Global.delay(0.2) # small delay when erroring
)
