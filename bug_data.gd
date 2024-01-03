# Stores information about bugs
extends Node

class Bug:
	var sprite: Texture2D
	var hp_mod: int
	var atk_mod: int
	var def_mod: int
	var spd_mod: int
	
	func _init(bugSprite: Texture2D, hpMod: int, atkMod: int, defMod: int, spdMod: int) -> void:
		self.sprite = bugSprite
		self.hp_mod = hpMod
		self.atk_mod = atkMod
		self.def_mod = defMod
		self.spd_mod = spdMod

enum Type {
	RED_ATK_BUG, BLUE_DEF_BUG, GREEN_SPD_BUG, YELLOW_HP_BUG
}

# dictionary of bugs
var _BUGS = {
	Type.RED_ATK_BUG : Bug.new(load("res://assets/bugs/bug_red.png"), 0, 2, 0, 0),
	Type.BLUE_DEF_BUG : Bug.new(load("res://assets/bugs/bug_blue.png"), 0, 0, 1, 0),
	Type.GREEN_SPD_BUG : Bug.new(load("res://assets/bugs/bug_green.png"), 0, 0, 0, 1),
	Type.YELLOW_HP_BUG : Bug.new(load("res://assets/bugs/bug_yellow.png"), 3, 0, 0, 0)
}

func _ready():
	# make sure the dictionary has all types of bugs...
	assert(_BUGS.size() == Type.size())
	for type in Type.values():
		assert(_BUGS.has(type))

func get_bug(type: Type) -> Bug:
	return _BUGS[type]
