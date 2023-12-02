extends LineEdit

signal debug_console_opened
signal debug_console_closed

var active
const SUCCESS_COLOR = Color.GREEN
const FAIL_COLOR = Color.RED
const DEFAULT_COLOR = Color.WHITE

var main_scene: Main = null
var last_command = null

func _ready():
	active = false
	self.visible = false
	self.set("theme_override_colors/font_color", DEFAULT_COLOR)
	main_scene = get_tree().get_root().get_node("Main")
	assert(main_scene != null)

func _input(event):
	if Global.DEBUG_CONSOLE:
		if Input.is_action_just_released("open_debug_console"):
			_toggle()

func _toggle():
	self.text = ""
	active = not active
	self.visible = active
	if active:
		emit_signal("debug_console_opened")
		self.grab_focus()
	else:
		emit_signal("debug_console_closed")

# map containing destination points for the warp command
var _WARP_MAP = {
	"cave1" : [GameData.Area.COOLANT_CAVE1_BEACH, "Cave1Entrance"],
	"cave2" : [GameData.Area.COOLANT_CAVE2_ENTRANCE, "Cave2Top"],
	"cave3" : [GameData.Area.COOLANT_CAVE3_LAKE, "Cave3TopLeft"],
	"cave4" : [GameData.Area.COOLANT_CAVE4_PLAZA, "Cave4BottomRight"],
	"cave5" : [GameData.Area.COOLANT_CAVE5_2DRUINS, "Cave5Right"],
	"cave6" : [GameData.Area.COOLANT_CAVE6_TEMPLE, "Cave6Right"],
	"cave7" : [GameData.Area.COOLANT_CAVE7_WHIRLCAVERN, "Cave7Top"],
	"cave8" : [GameData.Area.COOLANT_CAVE8_SEAFLOOR, "Cave8Ladder"],
	"cave9" : [GameData.Area.COOLANT_CAVE9_TIDALCHAMBER, "Cave9Bottom"],
	"cave10" : [GameData.Area.COOLANT_CAVE10_RIVER, "Cave10Right"],
	"cave11" : [GameData.Area.COOLANT_CAVE11_2DWATERFALL, "Cave11Right"],
	"cave12" : [GameData.Area.COOLANT_CAVE12_BOSSROOM, "Cave12Bottom"]
}

# this param is 'txt' on purpose; because 'text' is already a field of the LineEdit
func _on_text_submitted(txt):
	assert(active)
	
	# perform some checks to ensure certain nodes are findable by debug console
	# these checks will fail if certain nodes are renamed or moved
	# in that case... modify either debug console or undo those changes
	assert(main_scene.OVERWORLD != null, "Debug Console can't get Overworld scene; was it renamed/moved?")
	assert(main_scene.OVERWORLD.get_node("Area") != null, "Debug Console can't get Area from Overworld; was it renamed/moved?")	
	assert(main_scene.OVERWORLD.get_node("Area").get_node("Entities/Player") != null, "Debug Console can't get Player from Overworld->Area; was it renamed/moved?")
	assert(main_scene.OVERWORLD.get_node("Area").get_node("Entities/OverworldEncounters") != null, "Debug Console can't get Area->OverworldEncounters, was it renamed/moved?")
	assert(main_scene.BATTLE != null, "Debug Console can't get Battle scene; was it renamed/moved?")
	assert(main_scene.BATTLE.get_node("PlayerMons") != null, "Debug Console can't get PlayerMons from battle scene; was it renamed/moved?")
	assert(main_scene.BATTLE.get_node("ComputerMons") != null, "Debug Console can't get ComputerMons from battle scene; was it renamed/moved?")
	assert(main_scene.BATTLE.get_node("Animator") != null, "Debug Console can't get Animator from battle scene; was it renamed/moved?")	
	
	# collect some variables that are likely to be useful...
	var OVERWORLD = main_scene.OVERWORLD
	var current_area = main_scene.OVERWORLD.get_node("Area")
	var player = current_area.get_node("Entities/Player")
	var overworld_encounters = current_area.get_node("Entities/OverworldEncounters")
	var BATTLE = main_scene.BATTLE
	var animator = BATTLE.get_node("Animator")
	
	
	assert(OVERWORLD)
	assert(current_area)
	assert(player)
	assert(overworld_encounters)
	assert(BATTLE)
	assert(animator)
	
	var args = txt.to_lower().split(" ")
	var cmd = args[0]
	print("Debug Command: " + str(args))
	
	var success = true
	
	# close the application immediately
	if cmd == "exit" or cmd == "quit" or cmd == "q":
		get_tree().quit()
	# cause an immediate breakpoint
	elif cmd == "break" or cmd == "breakpoint" or cmd == "b" or cmd == "brk":
		breakpoint
	# print hello world :)
	elif cmd == "helloworld" or cmd == "hello":
		print("Hello World!")
	# clears all overworld enemies
	elif cmd == "wipe" or cmd == "clear":
		for child in overworld_encounters.get_children():
			overworld_encounters.remove_child(child)
	# wins a battle instantly
	elif cmd == "winbattle"  or cmd == "win" or cmd == "w":
		if main_scene.active_scene != main_scene.BATTLE:
			print("Not in a battle!")
			success = false
		else:
			_toggle() # close the debug console
			# end the current animation, otherwise something weird might happen if the animation
			# ends after the target (or user) of the action has been freed from memory
			animator.emit_signal("animation_finished")
			# if that attack ended battle, just return
			if BATTLE.state != BATTLE.BattleState.BATTLING:
				return
			# hack - remove/free current animator and make a new one to 'cancel' active animation
			animator.name = "OLDANIMATOR"
			animator.queue_free()
			BATTLE.add_child(load("res://battle/animator.tscn").instantiate())
			# kill all the computer mons
			for computer_mon in BATTLE.get_node("ComputerMons").get_children():
				computer_mon.take_damage(88888888)
	# loses a battle instantly
	elif cmd == "losebattle" or cmd == "lose" or cmd == "l":
		if main_scene.active_scene != main_scene.BATTLE:
			print("Not in a battle!")
			success = false
		else:
			_toggle()
			animator.emit_signal("animation_finished")
			# if that attack ended battle, just return
			if BATTLE.state != BATTLE.BattleState.BATTLING:
				return
			# hack - remove/free current animator and make a new one to 'cancel' active animation
			animator.name = "OLDANIMATOR"
			animator.queue_free()
			BATTLE.add_child(load("res://battle/animator.tscn").instantiate())
			# kill all the player mons
			for player_mon in BATTLE.get_node("PlayerMons").get_children():
				player_mon.take_damage(88888888)
	# in the overworld, warp to a new area
	elif cmd == "warp":
		if not args.size() >= 2:
			print("Need to provide second argument representing area to warp to;\nList of warp destinations: " + str(_WARP_MAP.keys()))
			return
		if not _WARP_MAP.has(args[1]):
			print("Invalid area.\nList of warp destinations: " + str(_WARP_MAP.keys()))
			return
		var pair = _WARP_MAP[args[1]]
		Events.area_changed.emit(pair[0], pair[1], true)
		_toggle() # close the debug console


	# repeat the previous command
	elif last_command != null and (cmd == "r" or cmd == "repeat"):
		_on_text_submitted(last_command)
	else:
		success = false
	
	if cmd != "r" and cmd != "repeat":
		self.last_command = txt
	self.set("theme_override_colors/font_color", SUCCESS_COLOR if success else FAIL_COLOR)
	self.clear()
