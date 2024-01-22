class_name Player
extends CharacterBody2D

signal reached_point

@onready var _BATTLE_COLLISION = $BattleCollision
@onready var _SPRITE = $Sprite

const _INVINCIBILITY_AFTER_ESCAPE_SECS := 2
const _INVINCIBILITY_AFTER_WIN_SECS := 1
var _is_invincible := false
var _can_move := true # if the player can move

var _in_cutscene := false
var _cutscene_movement_point = null

var _external_velocity := Vector2.ZERO # external forces acting upon the player (ie water currents/whirlpool)
var _forced_movement := false # if a certain direction should be forced (ie, while sliding on ice, you can't stop holding a direction)
var _forced_direction_vector := Vector2(0, 0) # the direction that is forced if _forced_movement is true

func _ready():
	assert(_SPRITE)
	assert(_SPRITE.sprite_frames)
	assert(_SPRITE.sprite_frames.has_animation("walk"))
	assert(_SPRITE.sprite_frames.has_animation("stand"))
	assert(_BATTLE_COLLISION)

func _on_area_2d_body_entered(overworld_encounter_collided_with):
	if not overworld_encounter_collided_with is OverworldMon:
		return
	
	if not _is_invincible: 
		Events.emit_signal("battle_started", overworld_encounter_collided_with, overworld_encounter_collided_with.mons)

func activate_invincibility(battle_end_condition) -> void:
	_is_invincible = true
	
	var length = _INVINCIBILITY_AFTER_ESCAPE_SECS if battle_end_condition == BattleData.BattleEndCondition.ESCAPE else _INVINCIBILITY_AFTER_WIN_SECS
	if Global.DEBUG_NO_INVINCIBLE:
		length = 0
	
	await Global.delay(length)
	_is_invincible = false

func enable_movement() -> void:
	_can_move = true
	
func disable_movement() -> void:
	_can_move = false
	if _SPRITE:
		_SPRITE.play("stand") #make sprite stand still while disabled

func enable_battle_collision() -> void:
	_BATTLE_COLLISION.monitoring = true
	_BATTLE_COLLISION.monitorable = true

func disable_battle_collision() -> void:
	_BATTLE_COLLISION.monitoring = false
	_BATTLE_COLLISION.monitorable = false

func apply_velocity(velo):
	_external_velocity += velo

func apply_forced_movement(forced_direction: Vector2):
	_forced_movement = true
	_forced_direction_vector = forced_direction

func disable_forced_movement():
	_forced_movement = false
	_forced_direction_vector = Vector2(0, 0)

func enable_cutscene_mode():
	_in_cutscene = true

func disable_cutscene_mode():
	_in_cutscene = false

func move_to_point(point: Node2D):
	assert(_in_cutscene)
	_cutscene_movement_point = point.position

func face_left() -> void:
	_SPRITE.flip_h = true

func face_right() -> void:
	_SPRITE.flip_h = false
	
