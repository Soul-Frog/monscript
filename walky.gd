extends Sprite2D

@onready var HOP_TIMER = $HopTimer

var moving = true
const SPEED = 40
const ROTATION_SPEED = 4 * SPEED
const ROTATION_AMOUNT = 13
var target_rotation = ROTATION_AMOUNT

func _input(e) -> void:
	if Input.is_action_just_pressed("battle_inject"):
		moving = not moving
		target_rotation = ROTATION_AMOUNT if moving else 0 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if moving:
		position.x += SPEED * delta
	
	rotation_degrees = move_toward(rotation_degrees, target_rotation, ROTATION_SPEED * delta)
	
	if is_equal_approx(rotation_degrees, target_rotation):
		target_rotation = -target_rotation

func _on_hop_timer_timeout():
	position.x += 1
