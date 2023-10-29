class_name PlayerPlatformer
extends CharacterBody2D

const SPEED = 110 # Movement speed
var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")
var MAX_FALL_SPEED = GRAVITY/2 #maximum speed the player can be falling
const JUMP_VELOCITY = -271.0 #this is ~56 pixels high with current gravity

const INVINCIBILITY_AFTER_ESCAPE_SECS = 2
const INVINCIBILITY_AFTER_WIN_SECS = 1

var is_invincible = false

var can_move = true # if the player can move

func _physics_process(delta):
	if can_move:
		# Add the gravity.
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		
		# Cap maximum fall speed
		if velocity.y >= MAX_FALL_SPEED:
			velocity.y = MAX_FALL_SPEED

		# Handle Jump on space or up.
		if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("up"))and is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		# pass through 1ways
		if is_on_floor() and Input.is_action_just_pressed("down"):
			position.y += 1

		# Get the input direction and handle the movement/deceleration.
		var direction = Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
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
	
func disable_movement():
	can_move = false

func enable_battle_collision():
	$BattleCollision.monitoring = true
	$BattleCollision.monitorable = true

func disable_battle_collsiion():
	$BattleCollision.monitoring = false
	$BattleCollision.monitorable = false
