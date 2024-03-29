class_name Customization
extends CanvasLayer

signal customization_complete

@onready var PANEL = $CharacterCustomizationPanel
@onready var BUNTON = $CharacterCustomizationPanel/Bunton
@onready var PLAYER_PREVIEW = $CharacterCustomizationPanel/PlayerOverhead
@onready var NAME_INPUT = $CharacterCustomizationPanel/NameInput
@onready var SUBMIT_BUTTON = $CharacterCustomizationPanel/SubmitButton

func _ready():
	assert(BUNTON)
	assert(PLAYER_PREVIEW)
	assert(NAME_INPUT)
	assert(PANEL)
	assert(SUBMIT_BUTTON)
	PLAYER_PREVIEW.disable_movement()

func _input(event: InputEvent):
	if event is InputEventKey:
		NAME_INPUT.grab_focus()
	SUBMIT_BUTTON.disabled = NAME_INPUT.text.length() == 0

func _on_bunton_state_changed():
	GameData.set_var(GameData.BUN_CUSTOMIZATION, BUNTON.selected)
	Events.emit_signal("update_player_sprite")

func _on_submit_button_pressed():
	GameData.set_var(GameData.PLAYER_NAME, NAME_INPUT.text.strip_edges())
	emit_signal("customization_complete")
