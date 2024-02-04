class_name Chest
extends DialogueInteractable

enum ID { 
	NONE = 0,
	
	CAVE1_BITS1 = 100,
	
	CAVE2_BITS1 = 200,
	CAVE2_BUGS1 = 201,
	
	CAVE3_BITS1 = 300,
	CAVE3_BITS2= 301,
	CAVE3_BITS3 = 303,
	CAVE3_BITS4= 304,
	CAVE3_TO_HIGHEST_ATK_FOE = 302,
	
	CAVE5_BITS1 = 500,
	CAVE5_TO_LOWEST_DEF_FOE = 501,
	
	CAVE6_BITS1 = 600, 
	CAVE6_TO_LOWEST_HP_FOE = 601, 
	
	CAVE7_BITS1 = 700,
	CAVE7_BUGS1 = 701, 
	CAVE7_BUGS2 = 702, 
	
	CAVE8_IF_SELF_LEAKY = 800,
	CAVE8_BITS1 = 801,
	
	CAVE9_BITS1 = 900,

	CAVE10_TO_FIRST_FOE = 1000, 
	CAVE10_BITS1 = 1001,
	CAVE10_BITS2 = 1002,
	CAVE10_BUGS1 = 1003,
	
	CAVE12_BITS1 = 1200, # Bits
	CAVE12_DO_DEFEND = 1201, # DoDefend
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
		# record that this chest has been opened in GameData.
		GameData.mark_chest_opened(chest_id)
		_update_chest_state()
		
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

