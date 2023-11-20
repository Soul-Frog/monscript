extends Node2D

@onready var _ICE_AREA = $IceArea
@onready var _TOP = $Top
@onready var _BOTTOM = $Bottom

func _ready():
	_ICE_AREA.body_exited.connect(_on_ice_exited)
	_TOP.body_entered.connect(_on_top_entered)
	_BOTTOM.body_entered.connect(_on_bottom_entered)

func _on_bottom_entered(body):
	if body is Player:
		body.apply_forced_movement(Vector2(0, -1)) #force slide up
		_TOP.monitoring = false

func _on_top_entered(body):
	if body is Player:
		body.apply_forced_movement(Vector2(0, 1)) #force slide down
		_BOTTOM.monitoring = false

func _on_ice_exited(body):
	if body is Player:
		body.disable_forced_movement()
		_BOTTOM.monitoring = true
		_TOP.monitoring = true
