# MonData stores global information about Mons, such as the Mon class
# and static instances of each MonBase

extends Node

enum Passive {
	NONE, 
	COURAGE, REGENERATE, MODERNIZE, BOURNE_AGAIN, PIERCER, THORNS, EXPLOIT, PASCALICAN_PASSIVE
}

class PassiveInfo:
	var passive: Passive
	var name: String
	var description: String
	
	func _init(passiveEnum: Passive, passiveName: String, passiveDescription: String):
		self.passive = passiveEnum
		self.name = passiveName
		self.description = passiveDescription

# dictionary of Passive -> PassiveInfo
var _PASSIVE_INFO = {
	Passive.NONE : PassiveInfo.new(Passive.NONE, "None", "This passive ability does nothing."),
	Passive.COURAGE : PassiveInfo.new(Passive.COURAGE, "Courage", "Increases damage dealt and reduces damage taken by 50% when fighting alone or against strong foes."),
	Passive.REGENERATE : PassiveInfo.new(Passive.REGENERATE, "Regenerate", "Heal 5% of your maximum health after taking an action."),
	Passive.MODERNIZE : PassiveInfo.new(Passive.MODERNIZE, "Modernize", "After 5 turns, increase your SPD and damage dealt by 50% for the rest of the battle."),
	Passive.BOURNE_AGAIN : PassiveInfo.new(Passive.BOURNE_AGAIN, "Bourne-Again", "The first time you would be defeated, endure and heal to 10% of your HP instead."),
	Passive.PIERCER : PassiveInfo.new(Passive.PIERCER, "Piercer", "Your attacks have a 25% to decrease DEF by 1 stage."),
	Passive.THORNS : PassiveInfo.new(Passive.THORNS, "Thorns", "When attacked, reflect 5% of the damage dealt with a 35% chance to inflict LEAK."),
	Passive.EXPLOIT : PassiveInfo.new(Passive.EXPLOIT, "Exploit", "Your attacks deal 30% increased damage against mons with LEAK."),
	Passive.PASCALICAN_PASSIVE : PassiveInfo.new(Passive.PASCALICAN_PASSIVE, "IDK", "We don't know what this does yet.")
}

func _ready() -> void:
	# make sure the _PASSIVE_INFO is fully populated
	for passive in Passive.values():
		assert(_PASSIVE_INFO.has(passive))

enum DamageType {
	NORMAL, 
	HEAT, CHILL, VOLT, 
	TYPELESS, 
	LEAK
}

const MIN_LEVEL: int = 0
const MAX_LEVEL: int = 64

# A mon's stats scale linearly as it levels.
# Instead of starting at level 0 and scaling to 64, 
# we start at level 10 and scale to level 74. (we still show the level to the player in a 0-64 range though)
# This means mons haev slightly higher stats at the start of the game.
# It smooths out the math a bit.
# This constant is used for that.
const PHANTOM_STARTING_LEVEL: int = 10

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
	var _mon_type: MonType
	var _species_name: String
	var _scene_path: String # the scene that represents this mon
	var _default_script_path: String
	var _health64: int
	var _attack64: int
	var _defense64: int
	var _speed64: int
	var _innate_block: ScriptData.Block
	var _innate_passive: Passive
	var _colors: Array[Color]
	var _decompilation_progress_required
	var _damage_type_multipliers: Dictionary
	var _xp_multiplier: float # affects the amount of XP this mon gives
	var _bits_multiplier: float # affects the amount of bits this mon drops
	var _bug_drops: Array[BugData.Type] # list of all possible bug drops for this mon
	var _is_virus: bool # if this mon is a virus (boss) type monster
	
	func _init(monType: MonType, monSpecies: String, mon_scene: String, default_script_file_path: String,
		healthAt64: int, attackAt64: int, defenseAt64: int, speedAt64: int,
		decompilationRequired: int, isVirus: bool,
		normal_damage_mult: float, heat_damage_mult: float, chill_damage_mult: float, volt_damage_mult: float,
		innateBlock: ScriptData.Block, innatePassive: Passive,
		colors: Array[Color],
		xpMult: float, bitsMult: float, bugDrops: Array[BugData.Type]) -> void:
		self._mon_type = monType
		self._species_name = monSpecies
		self._scene_path = mon_scene
		assert(Global.does_file_exist(_scene_path))
		self._default_script_path = default_script_file_path
		assert(Global.does_file_exist(_default_script_path))
		self._health64 = healthAt64
		self._attack64 = attackAt64
		self._defense64 = defenseAt64
		self._speed64 = speedAt64
		self._is_virus = isVirus
		self._innate_block = innateBlock
		self._innate_passive = innatePassive
		self._colors = colors
		self._decompilation_progress_required = decompilationRequired
		self._damage_type_multipliers[DamageType.NORMAL] = normal_damage_mult
		self._damage_type_multipliers[DamageType.HEAT] = heat_damage_mult
		self._damage_type_multipliers[DamageType.CHILL] = chill_damage_mult
		self._damage_type_multipliers[DamageType.VOLT] = volt_damage_mult
		self._damage_type_multipliers[DamageType.TYPELESS] = 1.0
		self._damage_type_multipliers[DamageType.LEAK] = 1.0
		self._xp_multiplier = xpMult
		self._bits_multiplier = bitsMult
		self._bug_drops = bugDrops
		assert(_bug_drops.size() != 0)
	
	# functions to determine a mon's stat value for a given level
	func health_for_level(level: int) -> int:
		var hp_per_level = float(_health64) / (MAX_LEVEL + PHANTOM_STARTING_LEVEL)
		return hp_per_level * (level + PHANTOM_STARTING_LEVEL)
	
	func attack_for_level(level: int) -> int:
		var atk_per_level = float(_attack64) / (MAX_LEVEL + PHANTOM_STARTING_LEVEL)
		return atk_per_level * (level + PHANTOM_STARTING_LEVEL)
		
	func defense_for_level(level: int) -> int:
		var def_per_level = float(_defense64) / (MAX_LEVEL + PHANTOM_STARTING_LEVEL)
		return def_per_level * (level + PHANTOM_STARTING_LEVEL)
		
	func speed_for_level(level: int) -> int:
		var spd_per_level = float(_speed64) / (MAX_LEVEL + PHANTOM_STARTING_LEVEL)
		return spd_per_level * (level + PHANTOM_STARTING_LEVEL)
	

# Represents an actual Mon in the game, in the player's party or in an overworld formation
class Mon:
	var _base: MonBase
	var _level: int
	var _nickname: String
	var _xp: float
	var _monscripts: Array[ScriptData.MonScript]
	var _active_monscript_index: int
	
	func _init(mon_base: MonBase, starting_level: int, mon_nickname := ""):
		self._base = mon_base
		self._level = starting_level
		self._xp = 0
		self._nickname = mon_nickname
		self._monscripts = [get_default_monscript(), get_default_monscript(), get_default_monscript()]
		assert(_monscripts.size() == 3) # would need to change a ton of stuff to change this...
		self._active_monscript_index = 0
	
	func to_json() -> String:
		var save = {
			"species" : _base._species_name,
			"nickname" : _nickname,
			"level" : _level,
			"xp" : _xp,
			"monscript1" : _monscripts[0].as_string(),
			"monscript2" : _monscripts[1].as_string(),
			"monscript3" : _monscripts[2].as_string(),
			"active_monscript" : _active_monscript_index
		}
		return JSON.stringify(save)
	
	func get_name() -> String:
		if _nickname == "":
			return _base._species_name
		return _nickname
	
	# creates and returns the default script for this mon
	func get_default_monscript() -> ScriptData.MonScript:
		return ScriptData.MonScript.new(Global.file_to_string(_base._default_script_path))
	
	# gets the currently active script for this mon
	func get_active_monscript() -> ScriptData.MonScript:
		return _monscripts[_active_monscript_index]
	
	# overwrites the current script with the given script
	func set_active_monscript(script: ScriptData.MonScript) -> void:
		_monscripts[_active_monscript_index] = script
	
	# gets a script for this mon by index
	func get_monscript(index: int) -> ScriptData.MonScript:
		assert(index > -1 and index < _monscripts.size())
		return _monscripts[index]
	
	# overwrites a script for this mon by index with the given script
	func set_monscript(index: int, script: ScriptData.MonScript) -> void:
		_monscripts[index] = script
		
	# gets the index of the active script
	func get_active_monscript_index() -> int:
		return _active_monscript_index
	
	# change the index of the active script (change which script is active)
	func set_active_monscript_index(index: int) -> void:
		assert(index > -1 and index < _monscripts.size())
		_active_monscript_index = index
		
	func get_possible_do_blocks() -> Array:
		# in the future, return customized DOs
		var possible_dos = []
		for doBlock in ScriptData.DO_BLOCK_LIST:
			if GameData.is_block_unlocked(doBlock) or _base._innate_block == doBlock:
				possible_dos.append(doBlock)
		return possible_dos
	
	func get_passives() -> Array:
		# in the future, return customized passives
		return [_base._innate_passive]
	
	func has_passive(passive: Passive) -> bool:
		return get_passives().has(passive)
	
	func get_mon_type() -> MonType:
		return _base._mon_type
	
	func get_level() -> int:
		return _level
	
	func get_colors() -> Array[Color]:
		return _base._colors
	
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
	
	# how much XP this mon gives when defeated
	func get_xp_for_defeating() -> int:
		return max(1, ceil(_level * _base._xp_multiplier))
	
	# how much bits this mon gives when defeated
	func get_bits_for_defeating() -> int:
		return ceil(2 * (_level + 1) * _base._bits_multiplier)
	
	# try to get a random bug drop; returns a Bug or null if no drop
	func roll_bug_drop():
		if Global.RNG.randi_range(0, 3) == 1: #25% chance
			return Global.choose_one(_base._bug_drops)
		return null
	
	func get_current_XP() -> float:
		return _xp
	
	func get_damage_multiplier_for_type(damageType: DamageType) -> float:
		return _base._damage_type_multipliers[damageType]
	
	# adds XP and potentially applies level up
	func gain_XP(xp_gained: float) -> void:
		assert(xp_gained >= 0)
		if _level == MonData.MAX_LEVEL: # don't try to level past MAX
			return
		
		_xp += xp_gained
		_check_level_up()
	
	func set_XP(xp_amt: int) -> void:
		assert(xp_amt >= 0)
		if _level == MonData.MAX_LEVEL: # don't try to level past MAX
			return
		_xp = xp_amt
		_check_level_up()
	
	func _check_level_up() -> void:
		while _xp >= MonData.XP_for_level(_level + 1):
			_xp -= MonData.XP_for_level(_level + 1)
			_level += 1
			if _level == MonData.MAX_LEVEL: # if we hit MAX, done
				_xp = MonData.XP_for_level(_level + 1)
				return

# List of MonBases, each is a static and constant representation of a Mon's essential characteristics
# Bitleons
var _BITLEON_BASE = MonBase.new(MonType.BITLEON, "Bitleon", "res://mons/bitleon.tscn", "res://mons/monscripts/attack.txt",
	256, 128, 64, 96,
	1, false,
	1.0, 1.0, 1.0, 1.0,
	ScriptData.get_block_by_name("Repair"),
	Passive.COURAGE,
	[Color.WHITE, Color.WHITE_SMOKE, Color.LIGHT_GRAY],
	2.0, 0.0, [BugData.Type.YELLOW_HP_BUG, BugData.Type.RED_ATK_BUG, BugData.Type.BLUE_DEF_BUG, BugData.Type.GREEN_SPD_BUG])

# Coolant Cave
var _GELIF_BASE = MonBase.new(MonType.GELIF, "Gelif", "res://mons/gelif.tscn", "res://mons/monscripts/attack.txt",
	540, 98, 14, 74,
	12, false,
	1.0, 2.0, 0.2, 2.0,
	ScriptData.get_block_by_name("Transfer"),
	Passive.REGENERATE,
	[Color("#26a69a"), Color("#009688"), Color("#00796b")],
	1.0, 0.5, [BugData.Type.YELLOW_HP_BUG])
	
var _CHORSE_BASE = MonBase.new(MonType.CHORSE, "C-horse", "res://mons/chorse.tscn", "res://mons/monscripts/attack.txt",
	220, 100, 42, 95,
	10, false,
	1.0, 1.5, 0.5, 1.0,
	ScriptData.get_block_by_name("C-gun"),
	Passive.MODERNIZE, 
	[Color("#ff7043"), Color("#f4511e"), Color("#d84315")],
	1.0, 1.0, [BugData.Type.GREEN_SPD_BUG])
	
var _PASCALICAN_BASE = MonBase.new(MonType.PASCALICAN, "Pascalican", "res://mons/pascalican.tscn", "res://mons/monscripts/attack.txt",
	210, 84, 56, 126,
	8, false,
	1.0, 1.0, 0.5, 1.5,
	ScriptData.get_block_by_name("Triangulate"),
	Passive.PASCALICAN_PASSIVE,
	[Color("#ffffff"), Color("#eeeeee"), Color("#bdbdbd")],
	1.0, 1.5, [BugData.Type.GREEN_SPD_BUG, BugData.Type.RED_ATK_BUG])
	
var _ORCHIN_BASE = MonBase.new(MonType.ORCHIN, "Orchin", "res://mons/orchin.tscn", "res://mons/monscripts/attack.txt",
	198, 115, 86, 65,
	12, false,
	1.0, 1.5, 0.7, 0.7,
	ScriptData.get_block_by_name("SpikOR"),
	Passive.THORNS,
	[Color("#4a5462"), Color("#333941"), Color("#242234")],
	1.0, 0.75, [BugData.Type.BLUE_DEF_BUG])
	
var _TURTMINAL_BASE = MonBase.new(MonType.TURTMINAL, "Turtminal", "res://mons/turtminal.tscn", "res://mons/monscripts/attack.txt",
	328, 98, 88, 28,
	5, false,
	1.0, 1.0, 1.3, 0.7,
	ScriptData.get_block_by_name("ShellBash"),
	Passive.BOURNE_AGAIN,
	[Color("#2baf2b"), Color("#0a8f08"), Color("#0d5302")],
	1.5, 0.75, [BugData.Type.BLUE_DEF_BUG, BugData.Type.YELLOW_HP_BUG])
	
var _STINGARRAY_BASE = MonBase.new(MonType.STINGARRAY, "Stingarray", "res://mons/stingarray.tscn", "res://mons/monscripts/attack.txt",
	212, 144, 58, 89,
	5, false,
	1.0, 1.5, 1.5, 0.3,
	ScriptData.get_block_by_name("Multitack"),
	Passive.PIERCER,
	[Color("#795548"), Color("#5d4037"), Color("#3e2723")],
	1.5, 0.5, [BugData.Type.RED_ATK_BUG])
	
var _ANGLERPHISH_BASE = MonBase.new(MonType.ANGLERPHISH, "Anglerphish", "res://mons/anglerphish.tscn", "res://mons/monscripts/attack.txt",
	328, 170, 44, 59,
	5, false,
	1.0, 2.0, 0.5, 0.5,
	ScriptData.get_block_by_name("Spearphishing"),
	Passive.EXPLOIT,
	[Color("#5677fc"), Color("#455ede"), Color("#2a36b1")],
	1.5, 1.0, [BugData.Type.RED_ATK_BUG, BugData.Type.YELLOW_HP_BUG])

# health attack def spd
# decompilation_required is_virus
# normal_dmg heat chill volt
# innateBlock innatePassive
# colors
# xpMult bitsMult [bugDrops]
var _LEVIATHAN_BASE = MonBase.new(MonType.LEVIATHAN, "L3V14TH4N", "res://mons/leviathan.tscn", "res://mons/monscripts/leviathan.txt",
	720, 250, 90, 65,
	1, true,
	1.0, 1.5, 0.1, 1.5,
	ScriptData.get_block_by_name("HYDR0"),
	Passive.NONE,
	[Color("#91a7ff"), Color("#738ffe"), Color("#4e6cef")],
	1.5, 1.0, [BugData.Type.RED_ATK_BUG, BugData.Type.BLUE_DEF_BUG])

# dictionary mapping MonTypes -> MonBases
var _MON_MAP := {
	MonType.BITLEON : _BITLEON_BASE,
	
	MonType.GELIF : _GELIF_BASE,
	MonType.CHORSE : _CHORSE_BASE,
	MonType.PASCALICAN : _PASCALICAN_BASE,
	MonType.ORCHIN : _ORCHIN_BASE,
	MonType.TURTMINAL : _TURTMINAL_BASE,
	MonType.STINGARRAY : _STINGARRAY_BASE,
	MonType.ANGLERPHISH : _ANGLERPHISH_BASE,
	
	MonType.LEVIATHAN : _LEVIATHAN_BASE
}

# This enum is used by the overworld_encounter.tscn, so don't delete it
enum MonType
{
	NONE = 0, 
	BITLEON = 1, 
	GELIF = 2, 
	CHORSE = 3, 
	PASCALICAN = 4, 
	ORCHIN = 5, 
	TURTMINAL = 6, 
	STINGARRAY = 7, 
	ANGLERPHISH = 8,
	LEVIATHAN = 1000
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

func get_headshot_for(montype: MonType) -> Texture2D:
	assert(montype != MonType.NONE)
	# make an instance of the mon's scene
	var mon_scene = load(_MON_MAP[montype]._scene_path).instantiate()
	# get texture from scene
	var tex = mon_scene.get_headshot()
	# free the scene
	mon_scene.free()
	return tex

func get_type_for(monname: String) -> MonType:
	for montype in _MON_MAP.keys():
		if _MON_MAP[montype]._species_name == monname:
			return montype
	return MonType.NONE

func is_virus(montype: MonType) -> bool:
	assert(montype != MonType.NONE)
	return _MON_MAP[montype]._is_virus

func get_name_for(montype: MonType) -> String:
	assert(montype != MonType.NONE)
	return _MON_MAP[montype]._species_name

func get_special_name_for(montype: MonType) -> String:
	assert(montype != MonType.NONE)
	return _MON_MAP[montype]._innate_block.name

func get_special_description_for(montype: MonType) -> String:
	assert(montype != MonType.NONE)
	return _MON_MAP[montype]._innate_block.description

func get_passive_name_for(montype: MonType) -> String:
	assert(montype != MonType.NONE)
	return get_passive_name(_MON_MAP[montype]._innate_passive)

func get_passive_description_for(montype: MonType) -> String:
	assert(montype != MonType.NONE)
	return get_passive_description(_MON_MAP[montype]._innate_passive)

func get_passive_name(passive: Passive):
	return _PASSIVE_INFO[passive].name

func get_passive_description(passive: Passive):
	return _PASSIVE_INFO[passive].description

func get_decompilation_progress_required_for(montype: MonType) -> int:
	assert(montype != MonType.NONE)
	return _MON_MAP[montype]._decompilation_progress_required

func get_health_percentile_for(montype: MonType) -> float:
	assert(montype != MonType.NONE)
	
	var mon_health = _MON_MAP[montype].health_for_level(MAX_LEVEL)
	var mons_better_than = 0
	
	for monbase in _MON_MAP.values():
		if mon_health >= monbase.health_for_level(MAX_LEVEL):
			mons_better_than += 1
	
	return float(mons_better_than) / _MON_MAP.size() * 100.0

func get_attack_percentile_for(montype: MonType) -> float:
	assert(montype != MonType.NONE)
	
	var mon_attack = _MON_MAP[montype].attack_for_level(MAX_LEVEL)
	var mons_better_than = 0
	
	for monbase in _MON_MAP.values():
		if mon_attack >= monbase.attack_for_level(MAX_LEVEL):
			mons_better_than += 1
	
	return float(mons_better_than) / _MON_MAP.size() * 100.0

func get_defense_percentile_for(montype: MonType) -> float:
	assert(montype != MonType.NONE)
	
	var mon_defense = _MON_MAP[montype].defense_for_level(MAX_LEVEL)
	var mons_better_than = 0
	
	for monbase in _MON_MAP.values():
		if mon_defense >= monbase.defense_for_level(MAX_LEVEL):
			mons_better_than += 1
	
	return float(mons_better_than) / _MON_MAP.size() * 100.0

func get_speed_percentile_for(montype: MonType) -> float:
	assert(montype != MonType.NONE)
	
	var mon_speed = _MON_MAP[montype].speed_for_level(MAX_LEVEL)
	var mons_better_than = 0
	
	for monbase in _MON_MAP.values():
		if mon_speed >= monbase.speed_for_level(MAX_LEVEL):
			mons_better_than += 1
	
	return float(mons_better_than) / _MON_MAP.size() * 100.0

func get_damage_multiplier_for(montype: MonType, damagetype: DamageType) -> float:
	assert(montype != MonType.NONE)
	return _MON_MAP[montype]._damage_type_multipliers[damagetype]

# used in mon_from_json - convert the name of a species into the monbase
func _species_str_to_montype(species_str: String) -> MonType:
	for montype in _MON_MAP.keys():
		if _MON_MAP[montype]._species_name == species_str:
			return montype
	assert(false, "No base found for %s." % species_str)
	return MonType.BITLEON #error case

func get_mon_scene_path(montype: MonType) -> String:
	assert(montype != MonType.NONE)
	return _MON_MAP[montype]._scene_path

func create_mon(montype: MonType, level: int) -> Mon:
	assert(montype != MonType.NONE)
	return Mon.new(_MON_MAP[montype], level)

func mon_from_json(json_string: String) -> Mon:
	# read in the string as json
	var json = JSON.new()
	var result = json.parse(json_string)
	if result != OK:
		assert(false, "Mon corruption!")
		return create_mon(MonType.BITLEON, 0) #error case - just return a bitleon
	
	var save = json.data
	
	# recreate the mon
	var type: MonType = _species_str_to_montype(save["species"])
	var level: int = save["level"]
	var mon: Mon = create_mon(type, level)
	
	# set some fields on this mon
	mon._nickname = save["nickname"]
	mon._xp = save["xp"]
	
	# remake the scripts for this mon
	mon.set_monscript(0, ScriptData.MonScript.new(save["monscript1"]))
	mon.set_monscript(1, ScriptData.MonScript.new(save["monscript2"]))
	mon.set_monscript(2, ScriptData.MonScript.new(save["monscript3"]))
	
	mon.set_active_monscript_index(save["active_monscript"])
	
	return mon
	
func feed_bug_to_mon(mon: Mon, bug: BugData.Bug) -> void:
	#TODO EP2
	pass
