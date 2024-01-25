extends Area2D

signal play_cutscene

enum Condition {
	NONE
}

@export var id: Cutscene.ID = Cutscene.ID.UNSET
@export var triggerCondition: Condition = Condition.NONE

func _ready() -> void:
	assert(id != Cutscene.ID.UNSET)

func _check_trigger_condition() -> bool:
	match triggerCondition:
		Condition.NONE:
			return true
	assert(false, "Trigger condition doesn't have a case?")
	return true

func _on_body_entered(body):
	if not GameData.cutscenes_played.has(id) and _check_trigger_condition():
		emit_signal("play_cutscene", id)
