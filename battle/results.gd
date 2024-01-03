extends Node2D

signal exit

@onready var _exit_button = $Exit

@onready var XP_LABEL = $XP
@onready var BITS_LABEL = $Bits
const XP_BITS_FORMAT = "+%d"

@onready var DECOMPILATIONS = $Decompilations
const DECOMPILATION_SPRITE_PATH = "HeadshotSprite"
const DECOMPILATION_BAR_PATH = "Bar"

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

func show_results(battle_results: Battle.BattleResult, xp_earned: int, bits_earned: int, bugs_earned: Array, mon_blocks: Array, player_team: Array, computer_team: Array):
	# XP and BITS labels
	XP_LABEL.text = XP_BITS_FORMAT % xp_earned
	BITS_LABEL.text = XP_BITS_FORMAT % bits_earned
	
	# Show bug drops (or hide excess frames)
	for i in range(0, BUGS.get_children().size()):
		var bug_slot = BUGS.get_child(i)
		if bugs_earned.size() > i:
			bug_slot.visible = true
			bug_slot.find_child(BUGS_SPRITE_PATH).texture = bugs_earned[i].sprite
		else:
			bug_slot.visible = false
	
	# Show decompilation bars/headshots (or hide excess bars)
	for i in range(0, DECOMPILATIONS.get_children().size()):
		var decompilation_slot = DECOMPILATIONS.get_child(i)
		if computer_team.size() > i:
			var mon_type = computer_team[i].base_mon.get_mon_type()
			decompilation_slot.visible = true
			decompilation_slot.find_child(DECOMPILATION_SPRITE_PATH).texture = MonData.get_headshot_for(mon_type)
			decompilation_slot.find_child(DECOMPILATION_BAR_PATH).value = GameData.compilation_progress_per_mon[mon_type] 
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
