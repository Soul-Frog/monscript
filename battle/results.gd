extends Node2D

signal shown
signal exit

@onready var XP_PANEL = $XPPanel
@onready var XP_LABEL = $XPPanel/XP
@onready var BITS_PANEL = $BitsPanel
@onready var BITS_LABEL = $BitsPanel/Bits
const XP_BITS_FORMAT = "+%d"

@onready var BUGS_PANEL = $BugsPanel
@onready var BUGS = $BugsPanel/Bugs
const BUGS_SPRITE_PATH = "Sprite"

@onready var DECOMPILATION_PANEL = $DecompilationPanel
@onready var DECOMPILATIONS = $DecompilationPanel/Decompilations
const DECOMPILATION_SPRITE_PATH = "HeadshotSprite"
const DECOMPILATION_BAR_PATH = "Bar"
const DECOMPILATION_PERCENTAGE_PATH = "Percentage"
const DECOMPILATION_TOOLTIPAREA_PATH = "TooltipArea"
@onready var _EXIT_BUTTON = $DecompilationPanel/ExitButton

# how far off-screen the results should be placed
const _SLIDE_IN_DISTANCE = 200 

const XP_TIME = 2.0 # time in seconds to spend increasing xp
var _xp_elapsed = 0.0
var _mon_blocks = []
var _mons_to_xp = []
var _xp_earned = 0.0
var _xp_given = 0.0
var _bugs_earned

var _granting_xp_and_decompile = false
const DECOMPILE_TIME = 2.0 # time in seconds to spend increasing decompile
var _montypes_to_decompile = []
var _decompile_mons_to_nodes = {}
var _decompile_remaining = 0.0

func _ready() -> void:
	assert(XP_PANEL)
	assert(XP_LABEL)
	assert(BITS_PANEL)
	assert(BITS_LABEL)
	assert(BUGS_PANEL)
	assert(BUGS)
	for child in BUGS.get_children():
		assert(child.has_node(BUGS_SPRITE_PATH))
	assert(DECOMPILATION_PANEL)
	assert(DECOMPILATIONS)
	for child in DECOMPILATIONS.get_children():
		assert(child.has_node(DECOMPILATION_SPRITE_PATH))
		assert(child.has_node(DECOMPILATION_BAR_PATH))
		assert(child.has_node(DECOMPILATION_PERCENTAGE_PATH))
		assert(child.has_node(DECOMPILATION_TOOLTIPAREA_PATH))
	assert(_EXIT_BUTTON)

	position.x += _SLIDE_IN_DISTANCE
	
	_EXIT_BUTTON.disabled = true
	
	show()

func _process(delta: float) -> void:
	if _granting_xp_and_decompile:
		if _xp_given != _xp_earned:
			_xp_elapsed += delta
			
			var xp_by_now = min(_xp_earned, Tween.interpolate_value(0.0, _xp_earned, _xp_elapsed, XP_TIME, Tween.TRANS_SINE, Tween.EASE_IN_OUT))
			assert(xp_by_now >= _xp_given)
			assert( xp_by_now <= _xp_earned)
			var xp_to_give = xp_by_now - _xp_given
			_xp_given += xp_to_give
			
			for i in _mons_to_xp.size():
				var prev_level = _mons_to_xp[i].get_level()
				
				_mons_to_xp[i].gain_XP(xp_to_give) # give xp
				
				if xp_by_now == _xp_earned: # do some extra handling on the last xp grant step to handle float rounding errors
					_mons_to_xp[i].set_XP(int(_mons_to_xp[i].get_current_XP() + 0.1))
				
				for monblock in _mon_blocks:
					if monblock.active_mon and monblock.active_mon.underlying_mon == _mons_to_xp[i]:
						monblock.on_mon_xp_changed() # update xp bars
						if _mons_to_xp[i].get_level() != prev_level: # play level up effect if leveled up
							monblock.active_mon.play_level_up_effect()
		
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
	_bugs_earned = bugs_earned
	
	# calculate XP/Bits earned and update labels
	_xp_earned = 0.0
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
	_xp_given = 0
	GameData.gain_bits(bits_earned)
	
	# Show bug drops (or hide excess frames)
	for i in range(0, BUGS.get_children().size()):
		var bug_slot = BUGS.get_child(i)
		if _bugs_earned.size() > i:
			bug_slot.visible = true
			bug_slot.find_child(BUGS_SPRITE_PATH).texture = BugData.get_bug(bugs_earned[i]).sprite
		else:
			bug_slot.visible = false
	
	for bugtype in _bugs_earned: # give bug drops to player
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
			bar.max_value = MonData.get_decompilation_progress_required_for(mon_type) * 100 #do max before value, otherwise value will cap the bar
			bar.value = GameData.decompilation_progress_per_mon[mon_type] * 100
			decompilation_slot.find_child(DECOMPILATION_PERCENTAGE_PATH).text = "%d%%" % int(100 * bar.value / bar.max_value)
			
			# store in map for later
			_decompile_mons_to_nodes[mon_type] = decompilation_slot
		else:
			decompilation_slot.visible = false
	
	if battle_results.end_condition == BattleData.BattleEndCondition.WIN:
		_decompile_remaining = 1.0
		
		# fade back in any defeated mons and their monblock
		for block in mon_blocks:
			if block.active_mon != null:
				create_tween().tween_property(block, "modulate:a", 1.0, 0.4)
		for battlemon in player_team:
			create_tween().tween_property(battlemon, "modulate:a", 1.0, 0.4)
	
	# Bring ourselves in from the side, piece by piece
	var slide_in = create_tween()
	slide_in.parallel().tween_property(XP_PANEL, "position:x", XP_PANEL.position.x - _SLIDE_IN_DISTANCE, 0.4).set_trans(Tween.TRANS_CUBIC)
	slide_in.parallel().tween_property(BITS_PANEL, "position:x", BITS_PANEL.position.x - _SLIDE_IN_DISTANCE, 0.45).set_trans(Tween.TRANS_CUBIC)
	slide_in.parallel().tween_property(BUGS_PANEL, "position:x", BUGS_PANEL.position.x - _SLIDE_IN_DISTANCE, 0.5).set_trans(Tween.TRANS_CUBIC)
	slide_in.parallel().tween_property(DECOMPILATION_PANEL, "position:x", DECOMPILATION_PANEL.position.x - _SLIDE_IN_DISTANCE, 0.6).set_trans(Tween.TRANS_CUBIC)
	await slide_in.finished
	emit_signal("shown")
	
	_EXIT_BUTTON.disabled = false
	
	# Switch monblocks to XP bars and animate increasing XP
	for monblock in mon_blocks:
		monblock.switch_to_results_mode()
	
	await Global.delay(0.2)
	_granting_xp_and_decompile = true

func _on_exit_pressed() -> void:
	# immediately reward remaining XP
	for mon in _mons_to_xp:
		mon.gain_XP(_xp_earned - _xp_given)
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
	_xp_given = 0
	_xp_elapsed = 0
	_bugs_earned = null
	
	position.x += _SLIDE_IN_DISTANCE
	
	_EXIT_BUTTON.disabled = true
	emit_signal("exit")

func _input(event: InputEvent) -> void:
	if not _EXIT_BUTTON.disabled:
		if Input.is_action_just_pressed("exit_battle_results"):
			_on_exit_pressed()

func _on_bug_1_mouse_entered():
	assert(_bugs_earned.size() >= 1)
	UITooltip.create(BUGS.get_child(0), BugData.get_bug(_bugs_earned[0]).tooltip(), get_global_mouse_position(), get_tree().root)

func _on_bug_2_mouse_entered():
	assert(_bugs_earned.size() >= 2)
	UITooltip.create(BUGS.get_child(1), BugData.get_bug(_bugs_earned[1]).tooltip(), get_global_mouse_position(), get_tree().root)

func _on_bug_3_mouse_entered():
	assert(_bugs_earned.size() >= 3)
	UITooltip.create(BUGS.get_child(2), BugData.get_bug(_bugs_earned[2]).tooltip(), get_global_mouse_position(), get_tree().root)

func _on_bug_4_mouse_entered():
	assert(_bugs_earned.size() == 4)
	UITooltip.create(BUGS.get_child(3), BugData.get_bug(_bugs_earned[3]).tooltip(), get_global_mouse_position(), get_tree().root)

func _on_decompilation1_mouse_entered():
	assert(_montypes_to_decompile.size() >= 1)
	var control = DECOMPILATIONS.get_child(0).find_child(DECOMPILATION_TOOLTIPAREA_PATH)
	var tooltip = MonData.get_name_for(_montypes_to_decompile[0])
	UITooltip.create(control, tooltip, get_global_mouse_position(), get_tree().root)

func _on_decompilation2_mouse_entered():
	assert(_montypes_to_decompile.size() >= 2)
	var control = DECOMPILATIONS.get_child(1).find_child(DECOMPILATION_TOOLTIPAREA_PATH)
	var tooltip = MonData.get_name_for(_montypes_to_decompile[1])
	UITooltip.create(control, tooltip, get_global_mouse_position(), get_tree().root)
	
func _on_decompilation3_mouse_entered():
	assert(_montypes_to_decompile.size() >= 3)
	var control = DECOMPILATIONS.get_child(2).find_child(DECOMPILATION_TOOLTIPAREA_PATH)
	var tooltip = MonData.get_name_for(_montypes_to_decompile[2])
	UITooltip.create(control, tooltip, get_global_mouse_position(), get_tree().root)
	
func _on_decompilation4_mouse_entered():
	assert(_montypes_to_decompile.size() == 4)
	var control = DECOMPILATIONS.get_child(3).find_child(DECOMPILATION_TOOLTIPAREA_PATH)
	var tooltip = MonData.get_name_for(_montypes_to_decompile[3])
	UITooltip.create(control, tooltip, get_global_mouse_position(), get_tree().root)
