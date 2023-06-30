extends Control

var MON_POSITIONS = []

func _ready():
	assert($Mons.get_children().size() == Global.MONS_PER_TEAM, "Wrong number of placeholder positions!")
	for placeholder in $Mons.get_children():
		MON_POSITIONS.append(placeholder.position)

func setup():
	# remove the existing mons
	for mon in $Mons.get_children():
		mon.queue_free()
	
	# create instances of the mons in the player's party and position them
	assert(PlayerData.team.size() <= Global.MONS_PER_TEAM, "Too many mons in player team?")
	for i in Global.MONS_PER_TEAM:
		var mon = PlayerData.team[i]
		if mon != null:
			var m = load(mon.get_scene()).instantiate()
			m.position = MON_POSITIONS[i]
			$Mons.add_child(m)

func _on_teams_button_pressed():
	print("Teams!")

func _on_quicksave_button_pressed():
	print("Quicksave!")

func _on_database_button_pressed():
	print("Database!")

func _on_settings_button_pressed():
	print("Settings!")

func _on_inventory_button_pressed():
	print("Inventory!")
