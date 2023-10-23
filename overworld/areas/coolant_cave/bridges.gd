extends Node2D

@onready var DOWN_SPRITE = $DownSprite
@onready var UP_SPRITE = $UpSprite
@onready var DOWN_SPRITE_FADE = $DownSprite/FadeDecorator
@onready var UP_SPRITE_FADE = $UpSprite/FadeDecorator
@onready var COLLISION_WHILE_DOWN = $CollisionWhileBridgesDown

func _ready():
	assert(DOWN_SPRITE)
	assert(UP_SPRITE)
	assert(DOWN_SPRITE_FADE)
	assert(UP_SPRITE_FADE)
	assert(COLLISION_WHILE_DOWN)
	
	# connect ourself to the signal so we can update when water changes
	Events.coolant_cave_water_level_changed.connect(_on_water_level_changed)

	# set initial state of up/down
	DOWN_SPRITE.modulate.a = 0 if GameData.get_var(GameData.COOLANT_CAVE_WATER_RAISED) else 1
	UP_SPRITE.modulate.a = 1 if GameData.get_var(GameData.COOLANT_CAVE_WATER_RAISED) else 0
	
	# and collisions
	_update_collisions()

func _update_collisions():
	# if the water level is raised we want to disable the collisions so that player can cross bridges
	var collision_disabled = GameData.get_var(GameData.COOLANT_CAVE_WATER_RAISED)
	for polygon in COLLISION_WHILE_DOWN.get_children():
		polygon.disabled = collision_disabled

func _on_water_level_changed():
	# fade between bridge states
	UP_SPRITE_FADE.fade_in() if GameData.get_var(GameData.COOLANT_CAVE_WATER_RAISED) else UP_SPRITE_FADE.fade_out()
	DOWN_SPRITE_FADE.fade_out() if GameData.get_var(GameData.COOLANT_CAVE_WATER_RAISED) else DOWN_SPRITE_FADE.fade_in()
	
	# update collision
	_update_collisions()
