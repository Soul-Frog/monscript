extends Node

const MIN_LEVEL = 0
const MAX_LEVEL = 64

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
	
	func _init(species, 
		health0, health64, attack0, attack64, defense0, defense64, speed0, speed64):
		self.species = species
		self.health0 = health0
		self.health64 = health64
		self.attack0 = attack0
		self.attack64 = attack64
		self.defense0 = defense0
		self.defense64 = defense64
		self.speed0 = speed0
		self.speed64 = speed64
	
	# functions to determine a mon's stat value for a given level
	func health_for_level(level):
		return (level / MAX_LEVEL * (attack64 - attack0)) + attack0
	
	func attack_for_level(level):
		return (level / MAX_LEVEL * (attack64 - attack0)) + attack0
		
	func defense_for_level(level):
		return (level / MAX_LEVEL * (attack64 - attack0)) + attack0
		
	func speed_for_level(level):
		return (level / MAX_LEVEL * (attack64 - attack0)) + attack0
	

# List of MonBases, each is a static and constant representation of a Mon's essential characteristics
var MAGNETFROG = MonBase.new("magnetFrog", 40, 200, 10, 100, 10, 100, 6, 20)

# Represents an actual Mon in the game, for example in the player's party or in an overworld formation
class Mon:
	var base
	var level
	var nickname
	#todo other stuff
	
	func _init(base, level, nickname):
		self.base = base
	
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
