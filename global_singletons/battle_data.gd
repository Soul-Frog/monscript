# Stores information relating to the battle system
extends Node

const POINTS_PER_INJECT = 10
const BATTLE_MON_SCRIPT := preload("res://battle/battle_mon.gd")

class BattleResult:
	var end_condition
	
	func _init():
		end_condition = BattleEndCondition.NONE

# represents the result of a battle
enum BattleEndCondition {
	WIN, # the player won the battle
	LOSE, # the player lost the battle
	ESCAPE, # player escaped from battle
	NONE # default/error condition; should be set before battle ends
}

class BattleBackground:
	var _map_texture_path: String
	var matrix_rain_color
	var background_color
	
	func _init(map_path: String, rain_color: Color, bg_color: Color):
		self._map_texture_path = map_path
		self.matrix_rain_color = rain_color
		self.background_color = bg_color
	
	func get_map_texture() -> Texture2D:
		return load(_map_texture_path)

enum Background {
	UNDEFINED,
	COOLANT_CAVE, COOLANT_RUINS
}

var _background_map = {
	Background.COOLANT_CAVE : BattleBackground.new("res://assets/maps/battle/coolant_cave.png", Color(69.0/255.0, 90.0/255.0, 100.0/255.0), Color(7.0/255.0, 19.0/255.0, 32.0/255.0)),
	Background.COOLANT_RUINS : BattleBackground.new("res://assets/maps/battle/coolant_ruins.png", Color("4a6c96"), Color("a0d2ff"))
}

func get_background(background: Background):
	return _background_map[background]

func _ready():
	for value in Background.values():
		if value != Background.UNDEFINED:
			_background_map.has(value)
			assert(Global.does_file_exist(_background_map[value]._map_texture_path))
