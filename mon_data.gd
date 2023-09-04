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
	var _species_name: String
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
	var _special_block: ScriptData.Block
	var _passive_name: String
	var _passive_description: String
	
	func _init(monSpecies: String, mon_scene: String, default_script_file_path: String,
		healthAt0: int, healthAt64: int, attackAt0: int, attackAt64: int, 
		defenseAt0: int, defenseAt64: int, speedAt0: int, speedAt64: int,
		specialBlock: ScriptData.Block, passiveName: String, passiveDesc: String) -> void:
		self._species_name = monSpecies
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
		self._special_block = specialBlock
		self._passive_name = passiveName
		self._passive_description = passiveDesc
	
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
	
	# if this mon can use this block
	# right now, it just checks if the mon's base uses this block
	# in the future when you can customize mon specials, 
	# this function will also check that.
	func is_block_a_special(block: ScriptData.Block):
		return _base._special_block == block
	
	func get_name() -> String:
		if _nickname == "":
			return _base._species_name
		return _nickname
	
	func get_monscript() -> ScriptData.MonScript:
		return _monscript
	
	func set_monscript(script: ScriptData.MonScript) -> void:
		_monscript = script
	
	func get_level() -> int:
		return _level
	
	func get_species_name() -> String:
		return _base._species_name
	
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
	40, 200, 10, 110, 5, 100, 6, 40,
	ScriptData.get_block_by_name("Shellbash"), 
	"Passive", "Passive desc")
var _MAGNETFROGBLUE_BASE = MonBase.new("magnetFrogBLUE", "res://mons/magnetfrogblue.tscn", "res://monscripts/attack.txt", 
	40, 250, 10, 100, 5, 50, 6, 20,
	ScriptData.get_block_by_name("Shellbash"), 
	"Bluenatism", "MagnetFrog Blue's passive ability information!")

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


func get_texture_for(montype: MonType) -> Texture2D:
	assert(montype != MonType.NONE)
	# make an instance of the mon's scene
	var mon_scene = load(_MON_MAP[montype]._scene_path).instantiate()
	# get texture from scene
	var tex = mon_scene.get_texture()
	# free the scene
	mon_scene.free()
	return tex

func get_name_for(montype: MonType) -> String:
	assert(montype != MonType.NONE)
	return _MON_MAP[montype]._species_name

func get_special_name_for(montype: MonType) -> String:
	assert(montype != MonType.NONE)
	return _MON_MAP[montype]._special_block.name

func get_special_description_for(montype: MonType) -> String:
	assert(montype != MonType.NONE)
	return _MON_MAP[montype]._special_block.description

func get_passive_name_for(montype: MonType) -> String:
	assert(montype != MonType.NONE)
	return _MON_MAP[montype]._passive_name

func get_passive_description_for(montype: MonType) -> String:
	assert(montype != MonType.NONE)
	return _MON_MAP[montype]._passive_description

#TODO - update these so that they calculate the number of mons better/worse and use that as percentile, not raw stats
func get_health_percentile_for(montype: MonType) -> int:
	assert(montype != MonType.NONE)
	
	var lowest_health = Global.INT_MAX
	var highest_health = Global.INT_MIN
	for monbase in _MON_MAP.values():
		var health = monbase.health_for_level(MAX_LEVEL)
		lowest_health = min(health, lowest_health)
		highest_health = max(health, highest_health)
	
	return float(_MON_MAP[montype].health_for_level(MAX_LEVEL) - lowest_health) / (highest_health- lowest_health) * 100

func get_attack_percentile_for(montype: MonType) -> int:
	assert(montype != MonType.NONE)
	
	var lowest_attack = Global.INT_MAX
	var highest_attack = Global.INT_MIN
	for monbase in _MON_MAP.values():
		var attack = monbase.attack_for_level(MAX_LEVEL)
		lowest_attack = min(attack, lowest_attack)
		highest_attack = max(attack, highest_attack)
	
	return float(_MON_MAP[montype].attack_for_level(MAX_LEVEL) - lowest_attack) / (highest_attack- lowest_attack) * 100

func get_defense_percentile_for(montype: MonType) -> int:
	assert(montype != MonType.NONE)
	
	var lowest_defense = Global.INT_MAX
	var highest_defense = Global.INT_MIN
	for monbase in _MON_MAP.values():
		var defense = monbase.defense_for_level(MAX_LEVEL)
		lowest_defense = min(defense, lowest_defense)
		highest_defense = max(defense, highest_defense)
	
	return float(_MON_MAP[montype].defense_for_level(MAX_LEVEL) - lowest_defense) / (highest_defense- lowest_defense) * 100

func get_speed_percentile_for(montype: MonType) -> int:
	assert(montype != MonType.NONE)
	
	var lowest_speed = Global.INT_MAX
	var highest_speed = Global.INT_MIN
	for monbase in _MON_MAP.values():
		var speed = monbase.speed_for_level(MAX_LEVEL)
		lowest_speed = min(speed, lowest_speed)
		highest_speed = max(speed, highest_speed)
	
	return float(_MON_MAP[montype].speed_for_level(MAX_LEVEL) - lowest_speed) / (highest_speed- lowest_speed) * 100

func create_mon(montype: MonType, level: int) -> Mon:
	assert(montype != MonType.NONE)
	return Mon.new(_MON_MAP[montype], level)

