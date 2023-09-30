extends Node2D

# emitted when the script menu should be opened, sends a Mon
signal script_menu_opened

# emitted when the database menu should be opened
signal database_menu_opened


signal save

signal settings_menu_opened

var MON_POSITIONS: Array[Vector2] = []
var MON_EDIT_BUTTON_POSITIONS: Array[Vector2] = []

@onready var ACTIVE_MONS = $ActiveMons

func _ready() -> void:
	assert(ACTIVE_MONS.get_children().size() == Global.MONS_PER_TEAM, "Wrong number of placeholder positions!")
	
	setup()

func setup() -> void:
	# put the player's mons into the active slots
	for i in Global.MONS_PER_TEAM:
		ACTIVE_MONS.get_child(i).set_mon(PlayerData.team[i])

func _on_database_button_pressed() -> void:
	emit_signal("database_menu_opened")

func _on_save_button_pressed():
	#TODO save
	print("Save!")
	emit_signal("save")

func _on_settings_button_pressed() -> void:
	#TODO settings
	print("Settings!")
	emit_signal("settings_menu_opened")

func _on_mon_edit_button_1_pressed() -> void:
	assert(PlayerData.team[0] != null, "Shouldn't be possible to click this...")
	emit_signal("script_menu_opened", PlayerData.team[0])

func _on_mon_edit_button_2_pressed():
	assert(PlayerData.team[1] != null, "Shouldn't be possible to click this...")
	emit_signal("script_menu_opened", PlayerData.team[1])

func _on_mon_edit_button_3_pressed():
	assert(PlayerData.team[2] != null, "Shouldn't be possible to click this...")
	emit_signal("script_menu_opened", PlayerData.team[2])

func _on_mon_edit_button_4_pressed():
	assert(PlayerData.team[3] != null, "Shouldn't be possible to click this...")
	emit_signal("script_menu_opened",  PlayerData.team[3])


func _on_x_button_pressed():
	#TODO
	pass

