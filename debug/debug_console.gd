extends LineEdit

signal debug_console_opened
signal debug_console_closed

var active
const SUCCESS_COLOR = Color.GREEN
const FAIL_COLOR = Color.RED
const DEFAULT_COLOR = Color.BLACK

var main_scene = null

func _ready():
	active = false
	self.visible = false
	self.set("theme_override_colors/font_color", DEFAULT_COLOR)
	main_scene = get_tree().get_root().get_child(0)	

func _input(event):
	if event.is_action_released("open_debug_console"):
		if active:
			emit_signal("debug_console_closed")
		else:
			emit_signal("debug_console_opened")
			self.grab_focus()
		self.text = ""
		active = not active
		self.visible = active


func _on_text_submitted(new_text):
	assert(active)
	
	# perform some checks to ensure certain nodes are findable by debug console
	# these checks will fail if certain nodes are renamed or moved
	# in that case... modify either debug console or undo those changes
	assert(main_scene != null)
	assert(main_scene.overworld_scene != null, "Debug Console can't get Overworld scene; was it renamed/moved?")
	assert(main_scene.overworld_scene.get_node("Player") != null, "Debug Console can't get Player from Overworld; was it renamed/moved?")
	assert(main_scene.battle_scene != null, "Debug Console can't get Battle scene; was it renamed/moved?")
	assert(main_scene.battle_scene.get_node("PlayerMons") != null, "Debug Console can't get PlayerMons from battle scene; was it renamed/moved?")
	assert(main_scene.battle_scene.get_node("ComputerMons") != null, "Debug Console can't get ComputerMons from battle scene; was it renamed/moved?")
	
	# collect some variables that are likely to be useful...
	var overworld_scene = main_scene.overworld_scene
	var player = overworld_scene.get_node("Player")
	var battle_scene = main_scene.battle_scene
	var battle_player_mons = battle_scene.get_node("PlayerMons").get_children()
	var battle_computer_mons = battle_scene.get_node("ComputerMons").get_children()
	
	new_text = new_text.to_lower().replace(" ", "").replace("_", "")
	
	print("Debug Command: " + new_text)
	var success = true
	
	# cause an immediate breakpoint
	if text == "break" or text == "breakpoint" or text == "b" or text == "brk":
		breakpoint
	# print hello world :)
	elif text == "helloworld" or text == "hello":
		print("Hello World!")
	# spawns an overworld enemy
	elif text == "spawn":
		# load the mon from a script file and make an instance; set position
		var new_mon = load("res://overworld/overworld_mon.tscn").instantiate()
		new_mon.position = Vector2(player.position + Vector2(30, 30)) # make this more clever someday
		# this mon is being added... abnormally, so we must also hook up the signal causing collisions to start a battle
		# without this next part, the enemies still collide but don't start battles (overworld doesn't see the collisions)
		new_mon.collided_with_player_start_battle.connect(overworld_scene._on_overworld_mon_collided_with_player_start_battle)
		# finally, add mon to scene
		overworld_scene.add_child(new_mon)
	# clears all overworld enemies
	elif text == "wipe" or text == "clear":
		for child in overworld_scene.get_children():
			if child is OverworldMon:
				overworld_scene.remove_child(child)
	# wins a battle instantly
	elif text == "winbattle" or text == "winbattle"  or text == "win":
		if main_scene.state != main_scene.State.BATTLE:
			print("Not in a battle!")
			success = false
		else:
			for computer_mon in battle_computer_mons:
				computer_mon.current_health = 0
	# loses a battle instantly
	elif text == "losebattle" or text == "losebattle" or text == "lose":
		if main_scene.state != main_scene.State.BATTLE:
			print("Not in a battle!")
			success = false
		else:
			for player_mon in battle_player_mons:
				player_mon.current_health = 0
	else:
		success = false
	
	self.set("theme_override_colors/font_color", SUCCESS_COLOR if success else FAIL_COLOR)
	
	self.text = ""
