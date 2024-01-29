class_name Customization

extends Node2D

signal customization_complete

@onready var BUNTON = $CharacterCustomizationScreen/Bunton
@onready var PLAYER_PREVIEW = $CharacterCustomizationScreen/PlayerOverhead
@onready var NAME_INPUT = $CharacterCustomizationScreen/NameInput

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(BUNTON)
	assert(PLAYER_PREVIEW)
	assert(NAME_INPUT)
	PLAYER_PREVIEW.disable_movement()

func _input(event: InputEvent):
	if event is InputEventKey:
		NAME_INPUT.grab_focus()

func _on_bunton_state_changed():
	GameData.set_var(GameData.BUN_CUSTOMIZATION, BUNTON.selected)
	Events.emit_signal("update_player_sprite")


func _on_submit_button_pressed():
	emit_signal("customization_complete")
