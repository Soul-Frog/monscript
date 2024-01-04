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

func _ready():
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

func perform_results(battle_results: Battle.BattleResult, bugs_earned: Array, mon_blocks: Array, player_team: Array, computer_team: Array):
	# calculate XP/Bits earned and update labels
	var xp_earned = 0
	var bits_earned = 0
	for battlemon in computer_team:
		xp_earned += battlemon.underlying_mon.get_xp_for_defeating()
		bits_earned +=  battlemon.underlying_mon.get_bits_for_defeating()
	XP_LABEL.text = XP_BITS_FORMAT % xp_earned
	BITS_LABEL.text = XP_BITS_FORMAT % bits_earned
	
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
	
	# grant XP to mons
	# TODO ANIMATE
	for battlemon in player_team: 
		if battlemon != null:
			battlemon.underlying_mon.gain_XP(xp_earned)
			# TODO
			
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
	# TODO - probably need to actually grant the XP here instead of outside
	# we'll need a way to detect levels and stuff too, kind of a pain tbh
	# probably have to do this in a _process instead of tweens

func _on_exit_pressed():
	# todo - immediately reward remaining XP/compilation progress
	
	modulate.a = 0
	_exit_button.disabled = true
	emit_signal("exit")
