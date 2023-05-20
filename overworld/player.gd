extends CharacterBody2D

const SPEED = 200
const INVINCIBILITY_AFTER_ESCAPE_SECS = 5
const INVINCIBILITY_AFTER_WIN_SECS = 2
const DASH_DURATION = 0.05
const DASH_SPEED = SPEED * 4

var is_invincible = false
var escaped_recently = false

var orientation = Vector2.ZERO
var dashing = false

func dash():
	if Input.is_action_just_pressed("dash"):
		dashing = true
		await get_tree().create_timer(DASH_DURATION).timeout
		dashing = false
		print("DASH")

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
	dash()
	update_velocity(delta)
	move_and_slide()

func _on_area_2d_body_entered(overworld_encounter_collided_with):
	if not is_invincible: 
		Events.emit_signal("collided_with_overworld_encounter", overworld_encounter_collided_with)
		Events.emit_signal("battle_started", overworld_encounter_collided_with.mons)

func activate_invincibility(battle_end_condition):
	is_invincible = true
	if battle_end_condition == Global.BattleEndCondition.ESCAPE:
		Global.call_after_delay(INVINCIBILITY_AFTER_ESCAPE_SECS, func(): is_invincible = false)
	elif battle_end_condition == Global.BattleEndCondition.WIN:
		Global.call_after_delay(INVINCIBILITY_AFTER_WIN_SECS, func(): is_invincible = false)
