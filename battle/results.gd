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

var _granting_xp = false
var _mon_blocks = []
var _mons_to_xp = []
var _xp_earned = 0.0
var _xp_remaining = 0.0

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
	
	modulate.a = 0
	_exit_button.disabled = true

const XP_TIME = 2.0 #take 2 seconds to give XP
func _process(delta: float) -> void:
	if _granting_xp:
		assert(_mons_to_xp)
		assert(_mon_blocks)
		
		var xp_to_give = _xp_earned / XP_TIME * delta
		print(xp_to_give)
		xp_to_give = min(_xp_remaining, xp_to_give)
		_xp_remaining -= xp_to_give
		if _xp_remaining == 0:
			print("0 left")
			_granting_xp = false
		
		for i in _mons_to_xp.size():
			_mons_to_xp[i].gain_XP(xp_to_give) # give xp
			_mon_blocks[i].on_mon_xp_changed()

func perform_results(battle_results: Battle.BattleResult, bugs_earned: Array, mon_blocks: Array, player_team: Array, computer_team: Array) -> void:	
	_mons_to_xp = []
	_mon_blocks = mon_blocks
	
	# calculate XP/Bits earned and update labels
	_xp_earned = 0
	var bits_earned = 0
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
	
	# Show decompilation bars/headshots (or hide excess bars)
	# TODO - duplicate enemy mons should provide double progress and only 1 bar entry
	
	# update decompilation progress (TODO ANIMATE)
	for battlemon in computer_team:
		var monType = battlemon.underlying_mon.get_mon_type()
		var maxProgress = MonData.get_decompilation_progress_required_for(monType)
		GameData.decompilation_progress_per_mon[monType] = min(maxProgress, GameData.decompilation_progress_per_mon[monType] + 1)
	
	for i in range(0, DECOMPILATIONS.get_children().size()):
		var decompilation_slot = DECOMPILATIONS.get_child(i)
		if computer_team.size() > i:
			var mon_type = computer_team[i].underlying_mon.get_mon_type()
			decompilation_slot.visible = true
			decompilation_slot.find_child(DECOMPILATION_SPRITE_PATH).texture = MonData.get_headshot_for(mon_type)
			var bar = decompilation_slot.find_child(DECOMPILATION_BAR_PATH)
			bar.value = GameData.decompilation_progress_per_mon[mon_type] 
			bar.max_value = MonData.get_decompilation_progress_required_for(mon_type)
			decompilation_slot.find_child(DECOMPILATION_PERCENTAGE_PATH).text = "%d%%" % int(100 * bar.value / bar.max_value)
		else:
			decompilation_slot.visible = false
	
	# Fade in the results
	await create_tween().tween_property(self, "modulate:a", 1, 0.2).finished
	_exit_button.disabled = false
	
	# Switch monblocks to XP bars and animate increasing XP
	for monblock in mon_blocks:
		monblock.switch_to_results_mode()
	_granting_xp = true

func _on_exit_pressed():
	# immediately reward remaining XP
	for mon in _mons_to_xp:
		mon.gain_XP(_xp_earned)
	_granting_xp = false
	_mons_to_xp = null
	_mon_blocks = null
	_xp_earned = 0
	_xp_remaining = 0
	
	modulate.a = 0
	_exit_button.disabled = true
	emit_signal("exit")
