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
	assert(main_scene.BATTLE.get_node("Mons/PlayerMons") != null, "Debug Console can't get PlayerMons from battle scene; was it renamed/moved?")
	assert(main_scene.BATTLE.get_node("Mons/ComputerMons") != null, "Debug Console can't get ComputerMons from battle scene; was it renamed/moved?")
	assert(main_scene.BATTLE.get_node("Mons/Animator") != null, "Debug Console can't get Animator from battle scene; was it renamed/moved?")	
	
	# collect some variables that are likely to be useful...
	var OVERWORLD = main_scene.OVERWORLD
	var current_area = main_scene.OVERWORLD.get_node("Area")
	var player = current_area.get_node("Entities/Player")
	var overworld_encounters = current_area.get_node("Entities/OverworldEncounters")
	var BATTLE = main_scene.BATTLE
	var animator = BATTLE.get_node("Mons/Animator")
	
	
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
	# print hello world :)
	elif cmd == "helloworld" or cmd == "hello":
		print("Hello World!") 
	# cause an immediate breakpoint
	elif cmd == "break" or cmd == "breakpoint" or cmd == "b" or cmd == "brk":
		breakpoint
	# immedately respawn at last save point
	elif cmd == "respawn":
		GameData.respawn_player()
	# recharge the inject battery
	elif cmd == "recharge" or cmd == "rechargebattery" or cmd == "battery" or cmd == "inject" or cmd == "rechargeinject":
		GameData.inject_points = GameData.get_var(GameData.MAX_INJECTS) * BattleData.POINTS_PER_INJECT
	# unlock all the stuff
	elif cmd == "unlock":
		_on_text_submitted("unlockcompilation")
		_on_text_submitted("unlockallblocks")
	# unlock all compilation progress
	elif cmd == "unlockcompilation" or cmd == "unlockallmons" or cmd == "unlockmons":
		for mon_type in GameData.decompilation_progress_per_mon.keys():
			GameData.decompilation_progress_per_mon[mon_type] = MonData.get_decompilation_progress_required_for(mon_type)
	# unlocks all IF/TO blocks
	elif cmd == "unlockallblocks":
		for block in ScriptData.IF_BLOCK_LIST + ScriptData.TO_BLOCK_LIST:
			GameData.unlock_block(block)
	#also unlocks DO, which would not normally be possible
	elif cmd == "unlockallallblocks":
		for block in ScriptData.IF_BLOCK_LIST + ScriptData.TO_BLOCK_LIST + ScriptData.DO_BLOCK_LIST:
			GameData.unlock_block(block) 
	# clears all overworld enemies
	elif cmd == "wipe" or cmd == "clear":
		for child in overworld_encounters.get_children():
			overworld_encounters.remove_child(child)
	elif cmd == "save":
		GameData.save_game()
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
			# kill all the computer mons
			for computer_mon in BATTLE.get_node("Mons/ComputerMons").get_children():
				computer_mon.take_damage(88888888, MonData.DamageType.TYPELESS)
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
			# kill all the player mons
			for player_mon in BATTLE.get_node("Mons/PlayerMons").get_children():
				player_mon.take_damage(88888888, MonData.DamageType.TYPELESS)
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
	# give myself some mons to work with
	elif cmd == "mons":
		GameData.storage[0] = MonData.create_mon(MonData.MonType.GELIF, 0)
		GameData.storage[1] = MonData.create_mon(MonData.MonType.CHORSE, 0)
		GameData.storage[2] = MonData.create_mon(MonData.MonType.PASCALICAN, 0)
		GameData.storage[3] = MonData.create_mon(MonData.MonType.ORCHIN, 0)
		GameData.storage[4] = MonData.create_mon(MonData.MonType.TURTMINAL, 0)
		GameData.storage[5] = MonData.create_mon(MonData.MonType.STINGARRAY, 0)
		GameData.storage[6] = MonData.create_mon(MonData.MonType.ANGLERPHISH, 0)
	elif cmd == "mon":
		if not args.size() >= 2:
			print("Need to provide a mon name to create.")
			return
			
		var type = MonData.get_type_for(args[1].capitalize())
		
		if type == MonData.MonType.NONE:
			print("Invalid name!")	
			return
		
		# make the mon
		var new_mon = MonData.create_mon(type, 0 if args.size() != 3 else int(args[2]))
		
		# try to put it into empty storage slot
		var inserted = false
		for i in GameData.storage.size():
			if GameData.storage[i] == null:
				GameData.storage[i] = new_mon
				inserted = true
				break
		# if none empty, overwrite the first slot
		if not inserted: 
			GameData.storage[0] = new_mon
	elif cmd == "wipestorage" or cmd == "clearstorage":
		for i in GameData.storage.size():
			GameData.storage[i] = null

	# repeat the previous command
	elif last_command != null and (cmd == "r" or cmd == "repeat"):
		_on_text_submitted(last_command)
	else:
		success = false
	
	if cmd != "r" and cmd != "repeat":
		self.last_command = txt
	self.set("theme_override_colors/font_color", SUCCESS_COLOR if success else FAIL_COLOR)
	self.clear()
