class_name PlayerOverhead
extends CharacterBody2D

const SPEED = 125 # Movement speed

const INVINCIBILITY_AFTER_ESCAPE_SECS = 2
const INVINCIBILITY_AFTER_WIN_SECS = 1
const DASH_DURATION = 0.05
const DASH_SPEED = SPEED * 4

var is_invincible = false


var orientation = Vector2.ZERO # direction the player last moved; used for dash direction
var dashing = false # if the player is currently dashing

var can_move = true # if the player can move

func _input(event):
	if event.is_action_released("dash"):
		dashing = true
		await Global.delay(DASH_DURATION)
		dashing = false

func _ready():
	assert(SPEED > 0)

func update_velocity(_delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = SPEED * input_direction
	if dashing:
		velocity = DASH_SPEED * orientation
	if input_direction != Vector2.ZERO and not dashing:
		orientation = input_direction

func _physics_process(delta):
	if can_move:
		update_velocity(delta)
		move_and_slide()

func _on_area_2d_body_entered(overworld_encounter_collided_with):
	if not is_invincible: 
		Events.emit_signal("collided_with_overworld_encounter", overworld_encounter_collided_with)
		Events.emit_signal("battle_started", overworld_encounter_collided_with.mons)

func activate_invincibility(battle_end_condition):
	is_invincible = true
	
	var length = INVINCIBILITY_AFTER_ESCAPE_SECS if battle_end_condition == Global.BattleEndCondition.ESCAPE else INVINCIBILITY_AFTER_WIN_SECS
	if Global.DEBUG_NO_INVINCIBLE:
		length = 0
	
	await Global.delay(length)
	is_invincible = false

func enable_movement():
	can_move = true
	$Area2D.monitoring = true
	$Area2D.monitorable = true
	
func disable_movement():
	can_move = false
	$Area2D.monitoring = false
	$Area2D.monitorable = false
