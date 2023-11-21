class_name DialogueInteractable
extends Interactable

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "NULL"

func _ready():
	assert(dialogue_resource, "No dialogue assigned!")
	assert(dialogue_start != "NULL", "No dialogue assigned!")
	super()

func _on_interact():
	# don't open a new dialogue if we're already talking
	if not Dialogue.is_dialogue_active():
		await Dialogue.play(dialogue_resource, dialogue_start) # play the dialogue
