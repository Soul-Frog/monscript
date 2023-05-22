extends Node2D

@onready var MON_POSITIONS = [$Mons/Mon1.position, $Mons/Mon2.position, $Mons/Mon3.position, $Mons/Mon4.position]

func setup():
	# remove the existing mons
	for mon in $Mons.get_children():
		mon.queue_free()
	
	# create instances of the mons in the player's party and position them
	for i in PlayerData.team.size():
		assert(i < PlayerData.team.size(), "Too many mons in player team!")
		var mon = PlayerData.team[i]
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
