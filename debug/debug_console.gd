extends LineEdit

signal debug_console_opened
signal debug_console_closed

var active
const SUCCESS_COLOR = Color.GREEN
const FAIL_COLOR = Color.RED
const DEFAULT_COLOR = Color.BLACK

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

# this param is 'txt' on purpose; because 'text' is already a field of the LineEdit
func _on_text_submitted(txt):
	assert(active)
	
	# perform some checks to ensure certain nodes are findable by debug console
	# these checks will fail if certain nodes are renamed or moved
	# in that case... modify either debug console or undo those changes
	assert(main_scene.OVERWORLD != null, "Debug Console can't get Overworld scene; was it renamed/moved?")
	assert(main_scene.OVERWORLD.get_node("Area")!= null, "Debug Console can't get Area from Overworld; was it renamed/moved?")	
	assert(main_scene.OVERWORLD.get_node("Area").get_node("Player") != null, "Debug Console can't get Player from Overworld->Area; was it renamed/moved?")
	assert(main_scene.OVERWORLD.get_node("Area").get_node("OverworldEncounters") != null, "Debug Console can't get Area->OverworldEncounters, was it renamed/moved?")
	assert(main_scene.BATTLE != null, "Debug Console can't get Battle scene; was it renamed/moved?")
	assert(main_scene.BATTLE.get_node("PlayerMons") != null, "Debug Console can't get PlayerMons from battle scene; was it renamed/moved?")
	assert(main_scene.BATTLE.get_node("ComputerMons") != null, "Debug Console can't get ComputerMons from battle scene; was it renamed/moved?")
	assert(main_scene.BATTLE.get_node("Animator") != null, "Debug Console can't get Animator from battle scene; was it renamed/moved?")	
	
	# collect some variables that are likely to be useful...
	var OVERWORLD = main_scene.OVERWORLD
	var current_area = main_scene.OVERWORLD.get_node("Area")
	var _player = current_area.get_node("Player")
	var overworld_encounters = current_area.get_node("OverworldEncounters")
	var BATTLE = main_scene.BATTLE
	var animator = BATTLE.get_node("Animator")
	
	txt = txt.to_lower().replace(" ", "").replace("_", "")
	print("Debug Command: " + txt)
	
	var success = true
	
	# close the application immediately
	if txt == "exit" or txt == "quit" or txt == "q":
		get_tree().quit()
	# cause an immediate breakpoint
	elif txt == "break" or txt == "breakpoint" or txt == "b" or txt == "brk":
		breakpoint
	# print hello world :)
	elif txt == "helloworld" or txt == "hello":
		print("Hello World!")
	# clears all overworld enemies
	elif txt == "wipe" or txt == "clear":
		for child in overworld_encounters.get_children():
			overworld_encounters.remove_child(child)
	# wins a battle instantly
	elif txt == "winbattle"  or txt == "win" or txt == "w":
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
	elif txt == "losebattle" or txt == "lose" or txt == "l":
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
			
	# repeat the previous command
	elif last_command != null and (txt == "r" or txt == "repeat"):
		_on_text_submitted(last_command)
	else:
		success = false
	
	if txt != "r" and txt != "repeat":
		self.last_command = txt
	self.set("theme_override_colors/font_color", SUCCESS_COLOR if success else FAIL_COLOR)
	self.clear()
