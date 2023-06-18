extends Node2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "test"

func _ready():
	$Label.visible = false

func _input(event):
	if event.is_action_released("interact") and $Area2D.get_overlapping_bodies().size() != 0:
		$Area2D.get_overlapping_bodies()[0].disable_movement()
		print("Player is interacting")
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialogue_start)
		await DialogueManager.dialogue_ended
		$Area2D.get_overlapping_bodies()[0].enable_movement()

func _on_body_entered(body):
	$Label.visible = true

func _on_body_exit(body):
	$Label.visible = false
