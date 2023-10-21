# To create a new type of interactable, 
# 1) make an inherited scene based off of this interactable_base.tscn
# Then, to give it custom behavior on interaction, 
# 2) create a new script (.gd file) which extends Interctable
# 3) override the _on_interact function.

class_name Interactable
extends Node2D

#godot thinks _SPRITE is unused, but it can be used by subclasses, so suppress the warning...
@warning_ignore("unused_private_class_variable") 
@onready var _SPRITE = $Sprite
@onready var _INTERACTION_AREA = $InteractionArea
@onready var _LABEL = $Label

func _ready():
	_LABEL.visible = false

func _input(event):
	if event.is_action_released("interact") and _INTERACTION_AREA.get_overlapping_bodies().size() != 0:
		_on_interact()

func _on_interact():
	pass #no-op

func _on_body_entered(body):
	_LABEL.visible = true

func _on_body_exit(body):
	_LABEL.visible = false
