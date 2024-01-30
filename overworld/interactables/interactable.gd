# To create a new type of interactable, 
# 1) make an inherited scene based off of this interactable_base.tscn
# Then, to give it custom behavior on interaction, 
# 2) create a new script (.gd file) which extends Interctable
# 3) override the _on_interact function.

class_name Interactable
extends CharacterBody2D

@export var LABEL_TEXT = "Interact"

#godot thinks _SPRITE is unused, but it can be used by subclasses, so suppress the warning...
@warning_ignore("unused_private_class_variable") 
@onready var _SPRITE = $Sprite
@warning_ignore("unused_private_class_variable")  #ditto
@onready var _INTERACTION_AREA = $InteractionArea
@onready var _LABEL = $Label
@onready var _LABEL_FADE = $Label/FadeDecorator

const _LABEL_FORMAT = "[center]%s %s[/center]"

var _player_in_range = false

func _ready():
	_LABEL.modulate.a = 0
	InputMap.get_actions()
	_LABEL.text = _LABEL_FORMAT % ["[%s]" % [Global.key_for_action("interact")], LABEL_TEXT]

func _input(event):
	if event.is_action_released("interact") and _player_in_range:
		_on_interact()

func _on_interact():
	pass #no-op

func _on_player_interaction_area_entered(area):
	_LABEL_FADE.fade_in()
	_player_in_range = true

func _on_player_interaction_area_exited(area):
	_LABEL_FADE.fade_out()
	_player_in_range = false
