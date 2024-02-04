# Stores information about bugs
extends Node

class Bug:
	var sprite: Texture2D
	var name: String
	var hp_mod: int
	var atk_mod: int
	var def_mod: int
	var spd_mod: int
	
	const _TOOLTIP_FORMAT = "%s\n%s"
	
	func _init(bugSprite: Texture2D, bugName: String, hpMod: int, atkMod: int, defMod: int, spdMod: int) -> void:
		self.sprite = bugSprite
		self.name = bugName
		self.hp_mod = hpMod
		self.atk_mod = atkMod
		self.def_mod = defMod
		self.spd_mod = spdMod

	func tooltip():
		var stats_info = ""
		if hp_mod != 0:
			stats_info += ("+" if hp_mod > 0 else "") + str(hp_mod) + " HP "
		if atk_mod != 0:
			stats_info += ("+" if atk_mod > 0 else "") + str(atk_mod) + " ATK "
		if def_mod != 0:
			stats_info += ("+" if def_mod > 0 else "") + str(def_mod) + " DEF "
		if spd_mod != 0:
			stats_info += ("+" if spd_mod > 0 else "") + str(spd_mod) + " SPD "
		stats_info = stats_info.strip_edges()
		return _TOOLTIP_FORMAT % [name, stats_info]

enum Type {
	NONE = 0,
	RED_ATK_BUG = 1, 
	BLUE_DEF_BUG = 2, 
	GREEN_SPD_BUG = 3, 
	YELLOW_HP_BUG = 4
}

# dictionary of bugs
var _BUGS = {
	Type.RED_ATK_BUG : Bug.new(load("res://assets/bugs/bug_red.png"), "Red Beetle", 0, 2, 0, 0),
	Type.BLUE_DEF_BUG : Bug.new(load("res://assets/bugs/bug_blue.png"), "Blue Slug", 0, 0, 1, 0),
	Type.GREEN_SPD_BUG : Bug.new(load("res://assets/bugs/bug_green.png"), "Green Grasshopper", 0, 0, 0, 1),
	Type.YELLOW_HP_BUG : Bug.new(load("res://assets/bugs/bug_yellow.png"), "Yellow Snail", 3, 0, 0, 0)
}

func _ready():
	# make sure the dictionary has all types of bugs...
	assert(_BUGS.size() == Type.size()-1)
	for type in Type.values():
		if type == Type.NONE:
			continue
		assert(_BUGS.has(type))

func get_bug(type: Type) -> Bug:
	return _BUGS[type]
