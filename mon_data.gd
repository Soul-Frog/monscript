# MonData stores global information about Mons, such as the Mon class
# and static instances of each MonBase

extends Node

const MIN_LEVEL: int = 0
const MAX_LEVEL: int = 64

# Calculates the amount of experience needed to gain a level
func XP_for_level(level: int) -> int:
	return level * level

# The base type (for example, magnetFrog) of a Mon instance.
# One MonBase exists for each type of mon. It is shared amongst all Mons of that type.
# For example, EACH magnetFrog Mon shares the magnetFrog MonBase.
# The MonBase stores information such as the sprites and base stats of a magnetFrog.
# These sprites and base characteristics can then be shared amongst all magnetFrog instances.
# MonBases are basically constants, so you should NEVER update the values here during gameplay.
class MonBase:
	var _speciesName: String
	var _scene_path: String # the scene that represents this mon
	var _default_script_path: String
	var _attack0: int
	var _attack64: int
	var _defense0: int
	var _defense64: int
	var _health0: int
	var _health64: int
	var _speed0: int
	var _speed64: int
	#todo: var special_action
	#todo: var passive_ability
	
	func _init(monSpecies: String, mon_scene: String, default_script_file_path: String,
		healthAt0: int, healthAt64: int, attackAt0: int, attackAt64: int, 
		defenseAt0: int, defenseAt64: int, speedAt0: int, speedAt64: int) -> void:
		self._speciesName = monSpecies
		self._scene_path = mon_scene
		assert(Global.does_file_exist(_scene_path))
		self._default_script_path = default_script_file_path
		assert(Global.does_file_exist(_default_script_path))
		self._health0 = healthAt0
		self._health64 = healthAt64
		self._attack0 = attackAt0
		self._attack64 = attackAt64
		self._defense0 = defenseAt0
		self._defense64 = defenseAt64
		self._speed0 = speedAt0
		self._speed64 = speedAt64
	
	# functions to determine a mon's stat value for a given level
	func health_for_level(level: int) -> int:
		return int((float(level) / MAX_LEVEL * (_health64 - _health0)) + _health0)
	
	func attack_for_level(level: int) -> int:
		return int((float(level) / MAX_LEVEL * (_attack64 - _attack0)) + _attack0)
		
	func defense_for_level(level: int) -> int:
		return int((float(level) / MAX_LEVEL * (_defense64 - _defense0)) + _defense0)
		
	func speed_for_level(level: int) -> int:
		return int((float(level) / MAX_LEVEL * (_speed64 - _speed0)) + _speed0)
	

# Represents an actual Mon in the game, in the player's party or in an overworld formation
class Mon:
	var _base: MonBase
	var _level: int
	var _nickname: String
	var _xp: int
	var _monscript: ScriptData.MonScript
	
	func _init(mon_base: MonBase, starting_level: int, mon_nickname := ""):
		self._base = mon_base
		self._level = starting_level
		self._xp = 0
		self._nickname = mon_nickname
		self._monscript = ScriptData.MonScript.new(Global.file_to_string(mon_base._default_script_path))
	
	func get_name() -> String:
		if _nickname == "":
			return _base._speciesName
		return _nickname
	
	func get_monscript() -> ScriptData.MonScript:
		return _monscript
	
	func set_monscript(script: ScriptData.MonScript) -> void:
		_monscript = script
	
	func get_level() -> int:
		return _level
	
	func get_species_name() -> String:
		return _base._speciesName
	
	func get_scene_path() -> String:
		return _base._scene_path
	
	func get_max_health() -> int:
		return _base.health_for_level(_level)
	
	func get_attack() -> int:
		return _base.attack_for_level(_level)
	
	func get_defense() -> int:
		return _base.defense_for_level(_level)
	
	func get_speed() -> int:
		return _base.speed_for_level(_level)
	
	# adds XP and potentially applies level up
	func gain_XP(xp_gained: int) -> void:
		if _level == MonData.MAX_LEVEL: # don't try to level past MAX
			return
		
		_xp += xp_gained
		while _xp >= MonData.XP_for_level(_level + 1):
			_xp -= MonData.XP_for_level(_level + 1)
			_level += 1
			if _level == MonData.MAX_LEVEL: # if we hit MAX, done
				_xp = 0
				return

# List of MonBases, each is a static and constant representation of a Mon's essential characteristics
var _MAGNETFROG_BASE = MonBase.new("magnetFrog", "res://mons/magnetfrog.tscn", "res://monscripts/attack.txt", 
	40, 200, 10, 100, 5, 50, 6, 20)
var _MAGNETFROGBLUE_BASE = MonBase.new("magnetFrogBLUE", "res://mons/magnetfrogblue.tscn", "res://monscripts/attack.txt", 
	40, 200, 10, 100, 5, 50, 6, 20)

# dictionary mapping MonTypes -> MonBases
var _MON_MAP := {
	MonType.MAGNETFROG : _MAGNETFROG_BASE,
	MonType.MAGNETFROGBLUE : _MAGNETFROGBLUE_BASE
}

# This enum is used by the overworld_encounter.tscn, so don't delete it
enum MonType
{
	NONE, MAGNETFROG, MAGNETFROGBLUE
}


func get_texture_for_mon(montype: MonType) -> Texture2D:
	assert(montype != MonType.NONE)
	# make an instance of the mon's scene
	var mon_scene = load(_MON_MAP[montype]._scene_path).instantiate()
	# get texture from scene
	var tex = mon_scene.get_texture()
	# free the scene
	mon_scene.free()
	return tex

func create_mon(montype: MonType, level: int) -> Mon:
	assert(montype != MonType.NONE)
	return Mon.new(_MON_MAP[montype], level)
