extends Node2D

signal completed

const _DIALOGUE_FILE = preload("res://dialogue/intro.dialogue")

@onready var BUS_SCENE = $Scenes/Bus
@onready var CLASSROOM_SCENE = $Scenes/Classroom

@onready var _active_scene = $Scenes/Classroom
var _dialogue_active := false

# Called when the node enters the scene tree for the first time.
func _ready():
	for scene in $Scenes.get_children():
		# disable all interactables except for the active scene
		_set_interactables_disabled(scene, scene != _active_scene) 
		
		# set visibility of active/non-active scenes appropriately
		scene.find_child("Background").visible = scene == _active_scene
		
		# connect so we can see when a clickable is clicked to launch a dialogue
		for clickable in scene.find_child("Clickables").get_children():
			clickable.clicked.connect(_open_dialogue)
	
	call_deferred("_open_dialogue", "start")

func _set_interactables_disabled(scene: Node, disabled: bool):
	for clickable in scene.find_child("Clickables").get_children():
		clickable.get_children()[0].disabled = disabled

func _open_dialogue(dialogue: String):
	assert(not _dialogue_active)
	
	_set_interactables_disabled(_active_scene, true)
	_dialogue_active = true
	
	DialogueManager.show_example_dialogue_balloon(_DIALOGUE_FILE, dialogue)
	await DialogueManager.dialogue_ended
	
	_dialogue_active = false
	_set_interactables_disabled(_active_scene, false)
	
	_switch_scene(BUS_SCENE)
	
	emit_signal("completed")

func _switch_scene(new_scene: Node):
	# TODO - fade transition
	
	# change the background
	_active_scene.find_child("Background").visible = false
	new_scene.find_child("Background").visible = true
	# change which interactables are active
	_set_interactables_disabled(_active_scene, true)
	_set_interactables_disabled(new_scene, false)
	
	_active_scene = new_scene
