class_name VisualNovel
extends Node2D

# emitted after the visual novel segment ends
signal completed

# emitted after a dialogue has completed
signal dialogue_completed

# emitted after a name is submitted into the name input field
signal name_inputted

const _DIALOGUE_FILE = preload("res://dialogue/intro.dialogue")

@onready var CLASSROOM_SCENE = $Subscenes/Classroom
@onready var BUS_SCENE = $Subscenes/Bus
@onready var BUS_STOP_SCENE = $Subscenes/BusStop
@onready var ROOM_SCENE = $Subscenes/Room
@onready var COMPUTER_SCENE = $Subscenes/Computer
@onready var BADGAME_SCENE = $Subscenes/BadGame

@onready var FADE = $FadeDecorator

@onready var _NAME_INPUT = $NameInput
@onready var _NAME_INPUT_BLACKOUT = $NameInputBlackout
@onready var _NAME_INPUT_BLACKOUT_FADE = $NameInputBlackout/FadeDecorator

@onready var _active_subscene = $Subscenes/Classroom
var _dialogue_active := false

# Called when the node enters the scene tree for the first time.
func _ready():
	for subscene in $Subscenes.get_children():
		# disable all interactables except for the active subscene
		_set_interactables_disabled(subscene, subscene != _active_subscene) 
		
		# set visibility of active/non-active scenes appropriately
		subscene.visible = subscene == _active_subscene
		
		# connect so we can see when a clickable is clicked to launch a dialogue
		for clickable in subscene.find_child("Clickables").get_children():
			clickable.clicked.connect(open_dialogue)
	_NAME_INPUT.visible = false

func play_intro_cutscene():
	# start the intro cutscene
	await CutscenePlayer.play_cutscene(CutscenePlayer.CutsceneID.INTRO_OLD, self)
	emit_signal("completed")

func display_name_input():
	_set_interactables_disabled(_active_subscene, true)
	_NAME_INPUT.visible = true
	_NAME_INPUT.grab_focus()
	_NAME_INPUT_BLACKOUT.visible = true
	_NAME_INPUT_BLACKOUT_FADE.fade_in()

func hide_name_input():
	_set_interactables_disabled(_active_subscene, false)
	_NAME_INPUT.visible = false
	_NAME_INPUT_BLACKOUT_FADE.fade_out()
	await _NAME_INPUT_BLACKOUT_FADE.fade_done
	_NAME_INPUT_BLACKOUT.visible = false

func _set_interactables_disabled(scene: Node, disabled: bool):
	for clickable in scene.find_child("Clickables").get_children():
		clickable.get_children()[0].disabled = disabled

func open_dialogue(dialogue: String):
	if _dialogue_active:
		assert(false)
	
	_set_interactables_disabled(_active_subscene, true)
	_dialogue_active = true
	
	await Dialogue.play(_DIALOGUE_FILE, dialogue)
	
	_dialogue_active = false
	_set_interactables_disabled(_active_subscene, false)
	
	emit_signal("dialogue_completed")

# switch to a new scene
# fade controls whether we do a fading transition or not
func switch_subscene(new_subscene: Node, fade := true):
	assert(new_subscene.get_parent() == $Subscenes)
	
	if fade:
		await fade_out()
	
	# change the background
	_active_subscene.visible = false
	new_subscene.visible = true
	# change which interactables are active
	_set_interactables_disabled(_active_subscene, true)
	_set_interactables_disabled(new_subscene, false)
	
	_active_subscene = new_subscene
	
	if fade:
		FADE.fade_in()

func fade_out():
	FADE.fade_out()
	await FADE.fade_out_done


func _on_name_input_text_submitted(new_text):
	emit_signal("name_inputted", new_text)
