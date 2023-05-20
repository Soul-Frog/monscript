extends Node2D

func _ready():
	$Label.visible = false

func _input(event):
	if event.is_action_released("interact") and $Area2D.get_overlapping_bodies().size() != 0:
		print("Player is interacting")

func _on_body_entered(body):
	$Label.visible = true

func _on_body_exit(body):
	$Label.visible = false
