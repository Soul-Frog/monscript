extends Interactable

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "test"

func _onInteract():
	# disable player movement
	_INTERACTION_AREA.get_overlapping_bodies()[0].disable_movement()
	
	# play the dialogue
	await Dialogue.play(dialogue_resource, dialogue_start)
	
	# enable player movement
	_INTERACTION_AREA.get_overlapping_bodies()[0].enable_movement()
