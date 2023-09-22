class_name VisualNovel
extends Node2D

signal completed

const _DIALOGUE_FILE = preload("res://dialogue/intro.dialogue")

@onready var BUS_SCENE = $Subscenes/Bus
@onready var CLASSROOM_SCENE = $Subscenes/Classroom
@onready var FADE = $FadeDecorator

@onready var _active_subscene = $Subscenes/Classroom
var _dialogue_active := false

# Called when the node enters the scene tree for the first time.
func _ready():
	for subscene in $Subscenes.get_children():
		# disable all interactables except for the active subscene
		_set_interactables_disabled(subscene, subscene != _active_subscene) 
		
		# set visibility of active/non-active scenes appropriately
		subscene.find_child("Background").visible = subscene == _active_subscene
		
		# connect so we can see when a clickable is clicked to launch a dialogue
		for clickable in subscene.find_child("Clickables").get_children():
			clickable.clicked.connect(_open_dialogue)

func play_intro_cutscene():
	# start the intro cutscene
	await CutscenePlayer.play_cutscene(CutscenePlayer.CutsceneID.INTRO, self)
	emit_signal("completed")

func _set_interactables_disabled(scene: Node, disabled: bool):
	for clickable in scene.find_child("Clickables").get_children():
		clickable.get_children()[0].disabled = disabled

func _open_dialogue(dialogue: String):
	if _dialogue_active:
		return
	
	_set_interactables_disabled(_active_subscene, true)
	_dialogue_active = true
	
	DialogueManager.show_example_dialogue_balloon(_DIALOGUE_FILE, dialogue)
	await DialogueManager.dialogue_ended
	
	
	_dialogue_active = false
	_set_interactables_disabled(_active_subscene, false)

# switch to a new scene
# fade controls whether we do a fading transition or not
func _switch_subscene(new_subscene: Node):
	assert(new_subscene.get_parent() == $Subscenes)
	
	await fade_out()
	
	# change the background
	_active_subscene.find_child("Background").visible = false
	new_subscene.find_child("Background").visible = true
	# change which interactables are active
	_set_interactables_disabled(_active_subscene, true)
	_set_interactables_disabled(new_subscene, false)
	
	_active_subscene = new_subscene
	
	FADE.fade_in()

func fade_out():
	FADE.fade_out()
	await FADE.fade_out_done
