extends Node2D

signal _continue_tutorial

@onready var BLOCKER = $Blocker
const FADED_ALPHA = 0.6

@onready var POPUPS = $Popup
@onready var TOP_POPUP = $Popup/Top
@onready var MIDDLE_POPUP = $Popup/Middle
@onready var MONBLOCK_POPUP = $Popup/Monblock
@onready var RESULTS_POPUP = $Popup/Results

var accepting_click = false

func _ready():
	assert(BLOCKER)
	assert(TOP_POPUP)
	assert(MIDDLE_POPUP)
	assert(MONBLOCK_POPUP)
	assert(RESULTS_POPUP)
	BLOCKER.modulate.a = 0.0
	BLOCKER.hide()
	
	assert(POPUPS)
	for popup in POPUPS.get_children():
		popup.hide()

func fade_blocker_in() -> void:
	BLOCKER.show()
	var tween = create_tween()
	tween.tween_property(BLOCKER, "modulate:a", FADED_ALPHA, 0.5)
	await tween.finished

func fade_blocker_out() -> void:
	var tween = create_tween()
	tween.tween_property(BLOCKER, "modulate:a", 0.0, 0.5)
	await tween.finished
	BLOCKER.hide()

func show_popup(popup: HBoxContainer, text: String) -> void:
	popup.show()
	popup.modulate.a = 0
	
	var label = popup.find_child("Text")
	label.text = ""
	label.custom_minimum_size = Vector2.ZERO
	label.text = "[center]%s[/center]" % text
	
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 1.0, 0.3)
	await tween.finished

func hide_popup(popup: HBoxContainer) -> void:
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 0.3)
	await tween.finished
	popup.hide()

func wait_for_click() -> void:
	accepting_click = true
	await _continue_tutorial
	accepting_click = false

func popup_and_wait(popup: HBoxContainer, text: String) -> void:
	await show_popup(popup, text)
	await wait_for_click()
	await hide_popup(popup)

var _reset_z_map = {}

func bring_to_front_z(node: Node) -> void:
	assert(not _reset_z_map.has(node))
	_reset_z_map[node] = node.z_index
	node.z_index = z_index + 1

func reset_to_normal_z(node: Node) -> void:
	assert(_reset_z_map.has(node))
	node.z_index = _reset_z_map[node]
	_reset_z_map.erase(node)

func play_tutorial_for(tutorial: Battle.Cutscene, battle: Battle) -> void:
	# grab some necessary variables
	var results = battle._results
	var _speed_controls = battle._speed_controls
	var _inject_layer = battle._inject_layer
	var player_mon_blocks = battle._player_mon_blocks
	var player_mons = battle._player_mons
	var computer_mon_blocks = battle._computer_mon_blocks
	var _computer_mons = battle._computer_mons
	var script_line_viewer = battle._script_line_viewer

	# set the speed for the tutorial scene
	battle._set_mon_speed(Battle.Speed.PAUSE_CUTSCENE)
	battle._set_label_speed(Battle.Speed.NORMAL)
	_speed_controls.disable()
	
	await fade_blocker_in()
	
	match tutorial:
		Battle.Cutscene.TUTORIAL_INTRO:
			# introduction at start of battle
			await popup_and_wait(TOP_POPUP, "This is your first battle, right?\n[color=%s](click to continue)[/color]" % Color.LIGHT_YELLOW.to_html())
			await popup_and_wait(TOP_POPUP, "Don't worry, I can teach you the basics!")
			bring_to_front_z(player_mon_blocks)
			await popup_and_wait(MONBLOCK_POPUP, "The green bar here is my health points, or HP for short.")
			await popup_and_wait(MONBLOCK_POPUP, "If I ever hit 0 HP, I'll be terminated. That would be... not good.")
			await popup_and_wait(MONBLOCK_POPUP, "This yellow bar is my action points, or AP!")
			await popup_and_wait(MONBLOCK_POPUP, "My AP bar fills up automatically. Once it's full, I get to take a turn.")
			await popup_and_wait(MONBLOCK_POPUP, "It might be easier for me to just show you.")
			await fade_blocker_out()
			reset_to_normal_z(player_mon_blocks)
			
			# wait for bitleons to attack
			battle._set_mon_speed(Battle.Speed.NORMAL)
			await battle.turn_ended
			battle._set_mon_speed(Battle.Speed.PAUSE_CUTSCENE)
			await fade_blocker_in()
			await popup_and_wait(MIDDLE_POPUP, "Did you see that? I just attacked that Gelif!")
			# show the computer's damaged hp bar
			bring_to_front_z(computer_mon_blocks)
			await popup_and_wait(MIDDLE_POPUP, "It's HP bar has taken damage, like you might expect.")
			bring_to_front_z(script_line_viewer)
			await popup_and_wait(MIDDLE_POPUP, "You can see the script line I just executed, too.")
			await popup_and_wait(MIDDLE_POPUP, "What's a script? Uh...  don't worry about that.")
			await popup_and_wait(MIDDLE_POPUP, "You'll just have to wait for that part of the game to be explained later!")
			await popup_and_wait(MIDDLE_POPUP, "In the meantime... let's get back to the battling!")
			await fade_blocker_out()
			reset_to_normal_z(computer_mon_blocks)
			reset_to_normal_z(script_line_viewer)
			
			# wait for bitleon to take a hit
			battle._set_mon_speed(Battle.Speed.NORMAL)
			await battle.turn_ended
			battle._set_mon_speed(Battle.Speed.PAUSE_CUTSCENE)
			await fade_blocker_in()
			await popup_and_wait(MIDDLE_POPUP, "Ouch! That wasn't very nice...\nAre you getting the hang of this now?")
			await popup_and_wait(MIDDLE_POPUP, "Well, it should be pretty simple; you don't need to do anything at all!")
			await popup_and_wait(MIDDLE_POPUP, "So sit back, and I'll finish off this Gelif! Here I go!")
			await fade_blocker_out()
			
			# hide the results continue button for now
			results._EXIT_BUTTON.modulate.a = 0.0
			
			# wait for the battle to end...
			battle._set_mon_speed(Battle.Speed.NORMAL)
			await results.shown
			results._granting_xp = false
			results._granting_decompile = false
			
			await fade_blocker_in()
			await popup_and_wait(RESULTS_POPUP, "Did you see that?\nI won!")
			await popup_and_wait(RESULTS_POPUP, "After winning a battle, you'll get a few types of rewards!")
			
			# show the Xp and level up
			bring_to_front_z(results.XP_PANEL)
			await popup_and_wait(RESULTS_POPUP, "First off, experience points, or XP! XP makes me stronger!")
			bring_to_front_z(player_mon_blocks)
			bring_to_front_z(player_mons)
			results._granting_xp = true
			await results.done_granting_xp
			await popup_and_wait(RESULTS_POPUP, "I leveled up! That increases my HP, ATK, DEF, and SPD!")
			reset_to_normal_z(player_mon_blocks)
			reset_to_normal_z(player_mons)
			reset_to_normal_z(results.XP_PANEL)
			
			# show the Bits
			bring_to_front_z(results.BITS_PANEL)
			await popup_and_wait(RESULTS_POPUP, "Next up, Bits! Bits are our local currency!")
			await popup_and_wait(RESULTS_POPUP, "...you do use Bits back where you came from, right?")
			reset_to_normal_z(results.BITS_PANEL)
			
			# show decompile
			bring_to_front_z(results.DECOMPILATION_PANEL)
			await popup_and_wait(RESULTS_POPUP, "Over here is decompilation progress.")
			await popup_and_wait(RESULTS_POPUP, "It's basically a measure of how much you know about this type of mon.") 
			await popup_and_wait(RESULTS_POPUP, "Once this bar is full, you can view  information about this mon in the Database!")
			results._granting_decompile = true
			await results.done_granting_decompile
			reset_to_normal_z(results.DECOMPILATION_PANEL)
			
			# show bugs
			bring_to_front_z(results.BUGS_PANEL)
			await popup_and_wait(RESULTS_POPUP, "And lastly, bugs! I'm not quite sure what these are good for yet...")
			await popup_and_wait(RESULTS_POPUP, "But it can't hurt to collect them, right?")
			reset_to_normal_z(results.BUGS_PANEL)
			
			# show the full panel
			bring_to_front_z(results)
			create_tween().tween_property(results._EXIT_BUTTON, "modulate:a", 1.0, 0.5)
			await popup_and_wait(RESULTS_POPUP, "And that's everything! Go ahead and press continue whenever you're ready.")
			await fade_blocker_out()
			reset_to_normal_z(results)
		_:
			assert(false, "Condition passed in does not have an associated tutorial!")
			fade_blocker_out()
			battle._set_speed(Battle.Speed.NORMAL)
			return
	
	assert(_reset_z_map.size() == 0)
	
	await fade_blocker_out()
	_speed_controls.enable()

func _input(event) -> void: 
	if event is InputEventMouseButton and event.is_pressed() and accepting_click:
		emit_signal("_continue_tutorial")
