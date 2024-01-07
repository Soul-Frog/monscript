extends Node2D

signal exit

@onready var _exit_button = $Exit

@onready var XP_LABEL = $XP
@onready var BITS_LABEL = $Bits
const XP_BITS_FORMAT = "+%d"

@onready var DECOMPILATIONS = $Decompilations
const DECOMPILATION_SPRITE_PATH = "HeadshotSprite"
const DECOMPILATION_BAR_PATH = "Bar"
const DECOMPILATION_PERCENTAGE_PATH = "Percentage"

@onready var BUGS = $Bugs
const BUGS_SPRITE_PATH = "Sprite"

# time in seconds to spend increasing xp/decompile bars
const DECOMPILE_TIME = 2.5 
const XP_TIME = 2.0

# how far off-screen the results should be placed
const _SLIDE_IN_DISTANCE = 200 

var _granting_xp_and_decompile = false
var _mon_blocks = []
var _mons_to_xp = []
var _xp_earned = 0.0
var _xp_remaining = 0.0
var _montypes_to_decompile = []
var _decompile_mons_to_nodes = {}
var _decompile_remaining = 0.0

func _ready() -> void:
	assert(XP_LABEL)
	assert(BITS_LABEL)
	assert(DECOMPILATIONS)
	for child in DECOMPILATIONS.get_children():
		assert(child.has_node(DECOMPILATION_SPRITE_PATH))
		assert(child.has_node(DECOMPILATION_BAR_PATH))
	assert(BUGS)
	for child in BUGS.get_children():
		assert(child.has_node(BUGS_SPRITE_PATH))
	
	position.x += _SLIDE_IN_DISTANCE
	
	_exit_button.disabled = true

func _process(delta: float) -> void:
	if _granting_xp_and_decompile:
		if _xp_remaining != 0:
			var xp_to_give = _xp_earned / XP_TIME * delta
			xp_to_give = min(_xp_remaining, xp_to_give)
			_xp_remaining -= xp_to_give
			
			for i in _mons_to_xp.size():
				_mons_to_xp[i].gain_XP(xp_to_give) # give xp
				
				if _xp_remaining == 0: # do some extra handling on the last xp grant step to handle float rounding errors
					_mons_to_xp[i].set_XP(int(_mons_to_xp[i].get_current_XP() + 0.1))
				
				# TODO - this is broken if there are empty mons above...
				_mon_blocks[i].on_mon_xp_changed() # update xp bars
		
		if _decompile_remaining != 0:
			var decompile_to_give = 1.0 / DECOMPILE_TIME * delta
			decompile_to_give = min(_decompile_remaining, decompile_to_give)
			_decompile_remaining -= decompile_to_give
			
			for mon_type in _montypes_to_decompile:
				# add progress
				var maxProgress = MonData.get_decompilation_progress_required_for(mon_type)
				GameData.decompilation_progress_per_mon[mon_type] = min(maxProgress, GameData.decompilation_progress_per_mon[mon_type] + decompile_to_give)
				
				if _decompile_remaining == 0: # float rounding fix
					GameData.decompilation_progress_per_mon[mon_type] = int(GameData.decompilation_progress_per_mon[mon_type] + 0.1)
				
				# update appearance
				var decompilation_slot = _decompile_mons_to_nodes[mon_type] 
				var bar = decompilation_slot.find_child(DECOMPILATION_BAR_PATH)
				bar.value = GameData.decompilation_progress_per_mon[mon_type] * 100
				decompilation_slot.find_child(DECOMPILATION_PERCENTAGE_PATH).text = "%d%%" % int(100 * bar.value / bar.max_value)

func perform_results(battle_results: BattleData.BattleResult, bugs_earned: Array, mon_blocks: Array, player_team: Array, computer_team: Array) -> void:	
	_mons_to_xp = []
	_montypes_to_decompile = []
	_decompile_mons_to_nodes = {}
	_mon_blocks = mon_blocks
	
	# calculate XP/Bits earned and update labels
	_xp_earned = 0
	var bits_earned = 0
	if battle_results.end_condition == BattleData.BattleEndCondition.WIN:
		for battlemon in computer_team:
			_xp_earned += battlemon.underlying_mon.get_xp_for_defeating()
			bits_earned +=  battlemon.underlying_mon.get_bits_for_defeating()
	
	XP_LABEL.text = XP_BITS_FORMAT % _xp_earned
	BITS_LABEL.text = XP_BITS_FORMAT % bits_earned
	
	# set up mons to recieve xp
	for battlemon in player_team: 
		if battlemon != null:
			_mons_to_xp.append(battlemon.underlying_mon)
	_xp_remaining = _xp_earned
	GameData.add_to_var(GameData.BITS, bits_earned) # give bits to the player
	
	# Show bug drops (or hide excess frames)
	for i in range(0, BUGS.get_children().size()):
		var bug_slot = BUGS.get_child(i)
		if bugs_earned.size() > i:
			bug_slot.visible = true
			bug_slot.find_child(BUGS_SPRITE_PATH).texture = BugData.get_bug(bugs_earned[i]).sprite
		else:
			bug_slot.visible = false
	
	for bugtype in bugs_earned: # give bug drops to player
		GameData.bug_inventory[bugtype] += 1
	
	# Gather a list of all unique mons to decompile to make bars
	# and a list of all mons to decompile to grant progress later
	var unique_decompiled_types = []
	for battlemon in computer_team:
		var monType = battlemon.underlying_mon.get_mon_type()
		if not unique_decompiled_types.has(monType):
			unique_decompiled_types.append(monType)
		_montypes_to_decompile.append(monType)
	
	# Show decompilation bars/headshots (or hide excess bars)
	for i in range(0, DECOMPILATIONS.get_children().size()):
		var decompilation_slot = DECOMPILATIONS.get_child(i)
		if unique_decompiled_types.size() > i:
			var mon_type = unique_decompiled_types[i]
			
			# make this bar visible and update headshot
			decompilation_slot.visible = true
			decompilation_slot.find_child(DECOMPILATION_SPRITE_PATH).texture = MonData.get_headshot_for(mon_type)
			
			# set max value and current value
			var bar = decompilation_slot.find_child(DECOMPILATION_BAR_PATH)
			bar.value = GameData.decompilation_progress_per_mon[mon_type] * 100
			bar.max_value = MonData.get_decompilation_progress_required_for(mon_type) * 100
			decompilation_slot.find_child(DECOMPILATION_PERCENTAGE_PATH).text = "%d%%" % int(100 * bar.value / bar.max_value)
			
			# store in map for later
			_decompile_mons_to_nodes[mon_type] = decompilation_slot
		else:
			decompilation_slot.visible = false
	
	if battle_results.end_condition == BattleData.BattleEndCondition.WIN:
		_decompile_remaining = 1.0
	
	# Bring ourselves in from the side
	await create_tween().tween_property(self, "position:x", position.x - _SLIDE_IN_DISTANCE, 0.6).set_trans(Tween.TRANS_CUBIC).finished
	_exit_button.disabled = false
	
	# Switch monblocks to XP bars and animate increasing XP
	for monblock in mon_blocks:
		monblock.switch_to_results_mode()
	
	await Global.delay(0.2)
	_granting_xp_and_decompile = true

func _on_exit_pressed():
	# immediately reward remaining XP
	for mon in _mons_to_xp:
		mon.gain_XP(_xp_remaining)
		mon.set_XP(int(mon.get_current_XP() + 0.1)) # then some safety rounding
	# and remaining decompile
	for mon_type in _montypes_to_decompile:
		var maxProgress = MonData.get_decompilation_progress_required_for(mon_type)
		GameData.decompilation_progress_per_mon[mon_type] = min(maxProgress, int(GameData.decompilation_progress_per_mon[mon_type] + _decompile_remaining + 0.1))
	
	_granting_xp_and_decompile = false
	_mons_to_xp = null
	_montypes_to_decompile = null
	_decompile_mons_to_nodes = null
	_decompile_remaining = 0
	_mon_blocks = null
	_xp_earned = 0
	_xp_remaining = 0
	
	position.x += _SLIDE_IN_DISTANCE
	
	_exit_button.disabled = true
	emit_signal("exit")
