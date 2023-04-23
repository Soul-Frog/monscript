# MonData stores global information about Mons, such as the Mon class
# and static instances of each MonBase

extends Node

const MIN_LEVEL = 0
const MAX_LEVEL = 64

enum MonType
{
	NONE, MAGNETFROG
}

# Calculates the amount of experience needed to gain a level
func XP_for_level(level):
	return level * level

# The base type (for example, magnetFrog) of a Mon instance.
# One MonBase exists for each type of mon. It is shared amongst all Mons of that type.
# For example, EACH magnetFrog Mon shares the magnetFrog MonBase.
# The MonBase stores information such as the sprites and base stats of a magnetFrog.
# These sprites and base characteristics can then be shared amongst all magnetFrog instances.
# MonBases are basically constants, so you should NEVER update the values here during gameplay.
class MonBase:
	var species
	#todo: var overworld_sprite
	#todo: var battle_sprite
	var attack0
	var attack64
	var defense0
	var defense64
	var health0
	var health64
	var speed0
	var speed64
	#todo: var special_action
	#todo: var passive_ability
	
	func _init(monSpecies, 
		healthAt0, healthAt64, attackAt0, attackAt64, defenseAt0, defenseAt64, speedAt0, speedAt64):
		self.species = monSpecies
		self.health0 = healthAt0
		self.health64 = healthAt64
		self.attack0 = attackAt0
		self.attack64 = attackAt64
		self.defense0 = defenseAt0
		self.defense64 = defenseAt64
		self.speed0 = speedAt0
		self.speed64 = speedAt64
	
	# functions to determine a mon's stat value for a given level
	func health_for_level(level):
		return int((float(level) / MAX_LEVEL * (health64 - health0)) + health0)
	
	func attack_for_level(level):
		return int((float(level) / MAX_LEVEL * (attack64 - attack0)) + attack0)
		
	func defense_for_level(level):
		return int((float(level) / MAX_LEVEL * (defense64 - defense0)) + defense0)
		
	func speed_for_level(level):
		return int((float(level) / MAX_LEVEL * (speed64 - speed0)) + speed0)
	

# Represents an actual Mon in the game, for example in the player's party or in an overworld formation
class Mon:
	var base
	var level
	var nickname
	var xp
	
	func _init(mon_base, starting_level, mon_nickname = ""):
		self.base = mon_base
		self.level = starting_level
		self.xp = 0
	
	func get_name():
		if nickname == "":
			return base.species
		return nickname
	
	func get_species():
		return base.species
	
	func get_max_health():
		return base.health_for_level(level)
	
	func get_attack():
		return base.attack_for_level(level)
	
	func get_defense():
		return base.defense_for_level(level)
	
	func get_speed():
		return base.speed_for_level(level)
	
	# adds XP and potentially applies level up
	func gain_XP(xp_gained):
		print("gained XP!")
		xp += xp_gained
		while xp >= MonData.XP_for_level(level + 1):
			level += 1
			xp -= MonData.XP_for_level(level + 1)
			print("Level up!")

# List of MonBases, each is a static and constant representation of a Mon's essential characteristics
var _MAGNETFROG_BASE = MonBase.new("magnetFrog", 40, 200, 10, 100, 5, 50, 6, 20)

func createMon(montype, level):
	assert(montype != MonType.NONE)
	
	match montype:
		MonType.MAGNETFROG:
			return Mon.new(_MAGNETFROG_BASE, level)
	
	assert(false, "Missing case in createMon match statement!")
