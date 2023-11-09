class_name Player
extends CharacterBody2D

@onready var _BATTLE_COLLISION = $BattleCollision

const INVINCIBILITY_AFTER_ESCAPE_SECS = 2
const INVINCIBILITY_AFTER_WIN_SECS = 1

var is_invincible = false

var external_velocity = Vector2.ZERO

var can_move = true # if the player can move

func _ready():
	assert(_BATTLE_COLLISION)

func apply_velocity(velo):
	external_velocity += velo

func _on_area_2d_body_entered(overworld_encounter_collided_with):
	if not is_invincible: 
		Events.emit_signal("collided_with_overworld_encounter", overworld_encounter_collided_with)
		Events.emit_signal("battle_started", overworld_encounter_collided_with.mons)

func activate_invincibility(battle_end_condition) -> void:
	is_invincible = true
	
	var length = INVINCIBILITY_AFTER_ESCAPE_SECS if battle_end_condition == Global.BattleEndCondition.ESCAPE else INVINCIBILITY_AFTER_WIN_SECS
	if Global.DEBUG_NO_INVINCIBLE:
		length = 0
	
	await Global.delay(length)
	is_invincible = false

func enable_movement() -> void:
	can_move = true
	
func disable_movement() -> void:
	can_move = false

func enable_battle_collision() -> void:
	_BATTLE_COLLISION.monitoring = true
	_BATTLE_COLLISION.monitorable = true

func disable_battle_collision() -> void:
	_BATTLE_COLLISION.monitoring = false
	_BATTLE_COLLISION.monitorable = false
