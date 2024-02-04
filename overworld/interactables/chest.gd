class_name Chest
extends DialogueInteractable

enum Type {
	BLOCK, BITS, BUGS, NONE
}

@export var chest_id = "NULL" # A unique identifier for this chest, used for persistence
@export var chest_type = Type.NONE
@export var block = "NONE"
@export var bits = -1
@export var bug_type = BugData.Type.NONE
@export var bug_number = -1

func _ready():
	assert(chest_id != "NULL")
	assert(chest_type != Type.NONE)
	match chest_type:
		Type.BLOCK:
			assert(block != "NONE")
			assert(ScriptData.get_block_by_name(block) != null)
		Type.BITS:
			assert(bits != -1)
		Type.BUGS:
			assert(bug_type != BugData.Type.NONE)
			assert(bug_number != -1)
	
	super()
	
	# check if this chest has been opened before, if so, open it and mark it as opened
	if GameData.get_var(chest_id):
		_SPRITE.play("opened")
		disable_interaction()

func _on_interact():
	if not GameData.get_var(chest_id) and not Dialogue.is_dialogue_active():
		_SPRITE.play("opened") # change our animation to opened chest
		disable_interaction()
		
		match chest_type:
			Type.BLOCK:
				await Dialogue.play(dialogue_resource, dialogue_start, "Block", block)
				GameData.unlock_block(ScriptData.get_block_by_name(block))
			Type.BITS:
				await Dialogue.play(dialogue_resource, dialogue_start, "Bits", bits)
				GameData.gain_bits(bits)
			Type.BUGS:
				await Dialogue.play(dialogue_resource, dialogue_start, "Bugs", BugData.get_bug(bug_type).name, bug_number)
				GameData.gain_bugs(bug_type, bug_number)
		
		# record that this chest has been opened in GameData.
		GameData.set_var(chest_id, true)

