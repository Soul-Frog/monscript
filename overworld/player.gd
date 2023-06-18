extends CharacterBody2D

const SPEED = 200
const INVINCIBILITY_AFTER_ESCAPE_SECS = 2
const INVINCIBILITY_AFTER_WIN_SECS = 1
const DASH_DURATION = 0.05
const DASH_SPEED = SPEED * 4

var is_invincible = false
var escaped_recently = false

var orientation = Vector2.ZERO
var dashing = false

var can_move = true

func _input(event):
	if event.is_action_released("dash"):
		dashing = true
		Global.call_after_delay(DASH_DURATION, self, func(node): 
			if is_instance_valid(node):
				node.dashing = false)

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
	Global.call_after_delay(length, self, func(player): 
		if is_instance_valid(player):
			is_invincible = false)

func enable_movement():
	print("enabled")
	can_move = true
	$Area2D.monitoring = true
	$Area2D.monitorable = true
	
func disable_movement():
	print("disabled")
	can_move = false
	$Area2D.monitoring = false
	$Area2D.monitorable = false
