# MonData stores global information about Mons, such as the Mon class
# and static instances of each MonBase

extends Node

const MIN_LEVEL: int = 0
const MAX_LEVEL: int = 64

func _ready() -> void:
	# do some safety checks
	# create a mon of every type to make sure createMon isn't missing cases
	for mon_type in MonType.values():
		if mon_type == MonType.NONE:
			continue
		create_mon(mon_type, 0)

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
	var speciesName: String
	var scene_path: String # the scene that represents this mon
	var default_script_path: String
	var attack0: int
	var attack64: int
	var defense0: int
	var defense64: int
	var health0: int
	var health64: int
	var speed0: int
	var speed64: int
	#todo: var special_action
	#todo: var passive_ability
	
	func _init(monSpecies: String, mon_scene: String, default_script_file_path: String,
		healthAt0: int, healthAt64: int, attackAt0: int, attackAt64: int, 
		defenseAt0: int, defenseAt64: int, speedAt0: int, speedAt64: int) -> void:
		self.speciesName = monSpecies
		self.scene_path = mon_scene
		self.default_script_path = default_script_file_path
		self.health0 = healthAt0
		self.health64 = healthAt64
		self.attack0 = attackAt0
		self.attack64 = attackAt64
		self.defense0 = defenseAt0
		self.defense64 = defenseAt64
		self.speed0 = speedAt0
		self.speed64 = speedAt64
	
	# functions to determine a mon's stat value for a given level
	func health_for_level(level: int) -> int:
		return int((float(level) / MAX_LEVEL * (health64 - health0)) + health0)
	
	func attack_for_level(level: int) -> int:
		return int((float(level) / MAX_LEVEL * (attack64 - attack0)) + attack0)
		
	func defense_for_level(level: int) -> int:
		return int((float(level) / MAX_LEVEL * (defense64 - defense0)) + defense0)
		
	func speed_for_level(level: int) -> int:
		return int((float(level) / MAX_LEVEL * (speed64 - speed0)) + speed0)
	

# Represents an actual Mon in the game, in the player's party or in an overworld formation
class Mon:
	var base: MonBase
	var level: int
	var nickname: String
	var xp: int
	var monscript: ScriptData.MonScript
	
	func _init(mon_base: MonBase, starting_level: int, mon_nickname := ""):
		self.base = mon_base
		self.level = starting_level
		self.xp = 0
		self.monscript = ScriptData.MonScript.new(Global.file_to_string(mon_base.default_script_path))
	
	func get_name() -> String:
		if nickname == "":
			return base.speciesName
		return nickname
	
	func get_species_name() -> String:
		return base.speciesName
	
	func get_scene_path() -> String:
		return base.scene_path
	
	func get_max_health() -> int:
		return base.health_for_level(level)
	
	func get_attack() -> int:
		return base.attack_for_level(level)
	
	func get_defense() -> int:
		return base.defense_for_level(level)
	
	func get_speed() -> int:
		return base.speed_for_level(level)
	
	# adds XP and potentially applies level up
	func gain_XP(xp_gained: int) -> void:
		xp += xp_gained
		while xp >= MonData.XP_for_level(level + 1):
			xp -= MonData.XP_for_level(level + 1)
			level += 1

# List of MonBases, each is a static and constant representation of a Mon's essential characteristics
var _MAGNETFROG_BASE = MonBase.new("magnetFrog", "res://mons/magnetfrog.tscn", "res://monscripts/attack.txt", 
	40, 200, 10, 100, 5, 50, 6, 20)
var _MAGNETFROGBLUE_BASE = MonBase.new("magnetFrogBLUE", "res://mons/magnetfrogblue.tscn", "res://monscripts/attack.txt",
	40, 200, 10, 100, 5, 50, 6, 20)

# This enum is used by the overworld_encounter.tscn, so don't delete it
enum MonType
{
	NONE, MAGNETFROG, MAGNETFROGBLUE
}

func create_mon(montype: MonType, level: int):
	assert(montype != MonType.NONE)
	
	match montype:
		MonType.MAGNETFROG:
			return Mon.new(_MAGNETFROG_BASE, level)
		MonType.MAGNETFROGBLUE:
			return Mon.new(_MAGNETFROGBLUE_BASE, level)
	
	assert(false, "Missing case in create_mon match statement for %s!" % [MonType.find_key(montype)])
