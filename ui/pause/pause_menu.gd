extends Node2D

var MON_POSITIONS: Array[Vector2] = []
var MON_EDIT_BUTTON_POSITIONS: Array[Vector2] = []

func _ready() -> void:
	assert($Mons.get_children().size() == Global.MONS_PER_TEAM, "Wrong number of placeholder positions!")
	assert($MonEditButtons.get_children().size() == Global.MONS_PER_TEAM, "Wrong number of edit buttons!")
	for placeholder in $Mons.get_children():
		MON_POSITIONS.append(placeholder.position)

func setup() -> void:
	# remove the existing mons
	for mon in $Mons.get_children():
		mon.queue_free()
	# hide all the edit buttons
	for button in $MonEditButtons.get_children():
		button.visible = false
	
	# create instances of the mons in the player's party and position them
	assert(PlayerData.team.size() <= Global.MONS_PER_TEAM, "Too many mons in player team?")
	for i in Global.MONS_PER_TEAM:
		var mon = PlayerData.team[i]
		if mon != null:
			# create the mon and place it
			var m = load(mon.get_scene_path()).instantiate()
			m.position = MON_POSITIONS[i]
			$Mons.add_child(m)
			# make the edit button for this position visible
			$MonEditButtons.get_child(i).visible = true

func _on_teams_button_pressed() -> void:
	print("Teams!")

func _on_quicksave_button_pressed() -> void:
	print("Quicksave!")

func _on_database_button_pressed() -> void:
	print("Database!")

func _on_settings_button_pressed() -> void:
	print("Settings!")

func _on_inventory_button_pressed() -> void:
	print("Inventory!")
