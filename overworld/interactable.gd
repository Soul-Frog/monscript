extends Node2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "test"

func _ready():
	$Label.visible = false

func _input(event):
	if event.is_action_released("interact") and $Area2D.get_overlapping_bodies().size() != 0:
		$Area2D.get_overlapping_bodies()[0].disable_movement()
		
		await Dialogue.start(dialogue_resource, dialogue_start)
		
		$Area2D.get_overlapping_bodies()[0].enable_movement()

func _on_body_entered(body):
	$Label.visible = true

func _on_body_exit(body):
	$Label.visible = false
