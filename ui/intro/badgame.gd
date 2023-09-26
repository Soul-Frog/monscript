extends Node2D

signal fallen

@onready var CHARACTER = $PlatformerCharacter
@onready var BOTTOM_PLATFORM = $BottomPlatform
@onready var LEFT_PLATFORM = $LeftPlatform
@onready var FLOATING_PLATFORM = $FloatingPlatform
@onready var FLAG = $Flag
@onready var DESIGNED_BY_LABEL = $DesignedByLabel
@onready var CONTROLS_LABEL = $ControlsLabel
@onready var GOAL_LABEL = $GoalLabel

@onready var COLLISION_LEFT_WALL = $Collision/CollisionLeftWall

const _GIBBERISH_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890@#~+&%><"

var _buggy = true

const DESIGNED_BY_FORMAT = "Game designed by\n%s"

func update_name():
	DESIGNED_BY_LABEL.text = DESIGNED_BY_FORMAT % GameData.PLAYER_NAME

func reset():
	CHARACTER.reset()
	
func disable():
	CHARACTER.disable()

func enable():
	CHARACTER.enable()

func bug_out():
	_buggy = true
	
	#disable the left wall collision too
	COLLISION_LEFT_WALL.disabled = true

func _physics_process(delta: float):
	if _buggy:
		# character jumps around a bit randomly
		if Global.RNG.randi_range(0, 36) == 0:
			if CHARACTER.is_sprite_offset():
				CHARACTER.offset_sprite(Vector2.ZERO)
			else:
				CHARACTER.offset_sprite(Vector2(Global.RNG.randi_range(10, 130) - 55, Global.RNG.randi_range(0, 30) - 30))
		
		# flag as well
		if Global.RNG.randi_range(0, 17) == 0:
			FLAG.offset = Vector2(Global.RNG.randi_range(0, 100) - 150, Global.RNG.randi_range(0, 200) - 100)
		
		# bottom platform flickers up and down
		if Global.RNG.randi_range(0, 150) == 0:
			if BOTTOM_PLATFORM.offset == Vector2.ZERO:
				BOTTOM_PLATFORM.offset = Vector2(6, 10)
			else:
				BOTTOM_PLATFORM.offset = Vector2.ZERO
		
		# left platform spasms around and rotates
		if Global.RNG.randi_range(0, 200) == 0:
			if LEFT_PLATFORM.offset == Vector2.ZERO:
				LEFT_PLATFORM.offset = Vector2(-4, 5)
				LEFT_PLATFORM.rotation_degrees = Global.RNG.randi_range(0, 40) - 20
			else:
				LEFT_PLATFORM.offset = Vector2.ZERO
				LEFT_PLATFORM.rotation_degrees = 0
		
		# floating platform drifts left and right
		if Global.RNG.randi_range(0, 110) == 0:
			FLOATING_PLATFORM.offset = Vector2(Global.RNG.randi_range(0, 60) - 30, 0)
			FLOATING_PLATFORM.rotation_degrees = Global.RNG.randi_range(0, 15) - 7
		
		# name text gibberishes
		if Global.RNG.randi_range(0, 4) == 0:
			var gibberish_name = ""
			while gibberish_name.length() < GameData.PLAYER_NAME.length():
				gibberish_name += Global.choose_char(_GIBBERISH_CHARACTERS)
			DESIGNED_BY_LABEL.text = DESIGNED_BY_FORMAT % gibberish_name
		
		# controls text flips
		if Global.RNG.randi_range(0, 40) == 0:
			var pieces = CONTROLS_LABEL.text.split("\n")
			CONTROLS_LABEL.text = ""
			for i in range(pieces.size() - 1, -1, -1):
				CONTROLS_LABEL.text += "%s" % pieces[i]
				if i != 0:
					CONTROLS_LABEL.text += "\n"
		
		# goal text changes capitalization
		if Global.RNG.randi_range(0, 10) == 0:
			for i in GOAL_LABEL.text.length():
				if Global.RNG.randi_range(0, 1) == 0:
					GOAL_LABEL.text[i] = GOAL_LABEL.text[i].to_upper()
				else:
					GOAL_LABEL.text[i] = GOAL_LABEL.text[i].to_lower()


func _on_fallen_area_body_entered(body):
	emit_signal("fallen")
