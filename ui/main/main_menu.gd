extends Node2D

signal clicked_new_game
signal clicked_continue
signal clicked_settings

@onready var CONTINUE = $Options/Continue

func _ready():
	assert(CONTINUE)
	if not Global.DEBUG_FAST_START:
		CONTINUE.visible = GameData.does_save_exist()

func _on_continue_clicked():
	emit_signal("clicked_continue")

func _on_new_game_clicked():
	emit_signal("clicked_new_game")

func _on_settings_clicked():
	emit_signal("clicked_settings")

func _on_quit_clicked():
	get_tree().quit()
