class_name Chest
extends DialogueInteractable

enum ID { 
	NONE = 0,
	CAVE1_BITS = 100,
	CAVE2 = 200,
	CAVE3_LOWEST_HP_FOE = 300,
	CAVE3_1 = 301,
	CAVE3_2 = 302
}

enum Type {
	NONE, BLOCK, BITS, BUGS
}

@export var chest_id = ID.NONE # A unique identifier for this chest, used for persistence
@export var chest_type = Type.NONE
@export var block = "NONE"
@export var bits = -1
@export var bug_type = BugData.Type.NONE
@export var bug_number = -1

func _ready():
	assert(chest_id != ID.NONE)
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
	_update_chest_state()
	
	Events.save_loaded.connect(_on_save_loaded)

func _on_save_loaded():
	_update_chest_state()

func _update_chest_state() -> void:
	if GameData.is_chest_opened(chest_id):
		_SPRITE.play("opened")
		disable_interaction()
	else:
		_SPRITE.play("closed")
		enable_interaction()

func _on_interact():
	if not GameData.is_chest_opened(chest_id) and not Dialogue.is_dialogue_active():
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
		GameData.mark_chest_opened(chest_id)
		_update_chest_state()

