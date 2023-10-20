extends Interactable

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "test"

func _onInteract():
	# don't open a new dialogue if we're already talking
	if not Dialogue.is_dialogue_active():
		_INTERACTION_AREA.get_overlapping_bodies()[0].disable_movement() # disable player movement
		await Dialogue.play(dialogue_resource, dialogue_start) # play the dialogue
		_INTERACTION_AREA.get_overlapping_bodies()[0].enable_movement() # enable player movement
