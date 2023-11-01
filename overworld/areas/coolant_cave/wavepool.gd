# Used in cave9-tidal chamber to control the waves that move down the central corridor
extends Node2D

@onready var TOP = $Top
@onready var BOTTOM = $Bottom
@onready var WAVES = $Waves

func _ready():
	assert(TOP)
	assert(BOTTOM)
	assert(TOP.position.y < BOTTOM.position.y)
	
	for wave in WAVES.get_children():
		wave.set_top(TOP.position.y)
		wave.set_bottom(BOTTOM.position.y)
