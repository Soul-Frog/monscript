# MonData stores global information about Mons, such as the Mon class
# and static instances of each MonBase

extends Node

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
	var _species_name: String
	var _scene_path: String # the scene that represents this mon
	var _default_script_path: String
	var _health64: int
	var _attack64: int
	var _defense64: int
	var _speed64: int
	var _special_block: ScriptData.Block
	var _passive_name: String
	var _passive_description: String
	var _colors: Array[Color]
	
	func _init(monSpecies: String, mon_scene: String, default_script_file_path: String,
		healthAt64: int, attackAt64: int, defenseAt64: int, speedAt64: int,
		specialBlock: ScriptData.Block, passiveName: String, passiveDesc: String,
		colors: Array[Color]) -> void:
		self._species_name = monSpecies
		self._scene_path = mon_scene
		assert(Global.does_file_exist(_scene_path))
		self._default_script_path = default_script_file_path
		assert(Global.does_file_exist(_default_script_path))
		self._health64 = healthAt64
		self._attack64 = attackAt64
		self._defense64 = defenseAt64
		self._speed64 = speedAt64
		self._special_block = specialBlock
		self._passive_name = passiveName
		self._passive_description = passiveDesc
		self._colors = colors
	
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
	var _xp: int
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
	
	func get_current_XP() -> int:
		return _xp
	
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

# Bitleons
var _BITLEON_BASE = MonBase.new("Bitleon", "res://mons/bitleon.tscn", "res://monscripts/attack.txt",
	256, 128, 64, 96,
	ScriptData.get_block_by_name("Repair"),
	"Passive", "Bitleon passive",
	[Color.WHITE, Color.WHITE_SMOKE, Color.LIGHT_GRAY])

# Coolant Cave
var _GELIF_BASE = MonBase.new("Gelif", "res://mons/gelif.tscn", "res://monscripts/attack.txt",
	540, 98, 14, 74,
	ScriptData.get_block_by_name("Transfer"),
	"Passive", "Gelif passive",
	[Color("#26a69a"), Color("#009688"), Color("#00796b")])
var _CHORSE_BASE = MonBase.new("C-horse", "res://mons/chorse.tscn", "res://monscripts/attack.txt",
	220, 100, 42, 95,
	ScriptData.get_block_by_name("C-gun"),
	"Passive", "C-horse passive",
	[Color("#ff7043"), Color("#f4511e"), Color("#d84315")])
var _PASCALICAN_BASE = MonBase.new("Pascalican", "res://mons/pascalican.tscn", "res://monscripts/attack.txt",
	210, 84, 56, 126,
	ScriptData.get_block_by_name("Triangulate"),
	"Passive", "Pascalican passive",
	[Color("#ffffff"), Color("#eeeeee"), Color("#bdbdbd")])
var _ORCHIN_BASE = MonBase.new("Orchin", "res://mons/orchin.tscn", "res://monscripts/attack.txt",
	198, 115, 86, 65,
	ScriptData.get_block_by_name("SpikOR"),
	"Passive", "Orchin passive",
	[Color("#4a5462"), Color("#333941"), Color("#242234")])
var _TURTMINAL_BASE = MonBase.new("Turtminal", "res://mons/turtminal.tscn", "res://monscripts/attack.txt",
	328, 98, 88, 28,
	ScriptData.get_block_by_name("ShellBash"),
	"Passive", "Turtminal passive",
	[Color("#2baf2b"), Color("#0a8f08"), Color("#0d5302")])
var _STINGARRAY_BASE = MonBase.new("Stringarray", "res://mons/stingarray.tscn", "res://monscripts/attack.txt",
	212, 144, 58, 89,
	ScriptData.get_block_by_name("Multitack"),
	"Passive", "Stingarray passive",
	[Color("#795548"), Color("#5d4037"), Color("#3e2723")])
var _ANGLERPHISH_BASE = MonBase.new("Anglerphish", "res://mons/anglerphish.tscn", "res://monscripts/attack.txt",
	328, 170, 44, 59,
	ScriptData.get_block_by_name("Spearphishing"),
	"Passive", "Anglerphish passive",
	[Color("#5677fc"), Color("#455ede"), Color("#2a36b1")])

# Extras
#var _MAGNETFROG_BASE = MonBase.new("magnetFrog", "res://mons/magnetfrog.tscn", "res://monscripts/attack.txt", 
#	500, 500, 500, 500,
#	ScriptData.get_block_by_name("Shellbash"), 
#	"Passive", "Passive desc")
#var _MAGNETFROGBLUE_BASE = MonBase.new("magnetFrogBLUE", "res://mons/magnetfrogblue.tscn", "res://monscripts/attack.txt", 
#	500, 500, 500, 500,
#	ScriptData.get_block_by_name("Shellbash"), 
#	"Bluenatism", "MagnetFrog Blue's passive ability information!")

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
	
	#MonType.MAGNETFROG : _MAGNETFROG_BASE,
	#MonType.MAGNETFROGBLUE : _MAGNETFROGBLUE_BASE,
}

# This enum is used by the overworld_encounter.tscn, so don't delete it
enum MonType
{
	NONE, BITLEON, GELIF, CHORSE, PASCALICAN, ORCHIN, TURTMINAL, STINGARRAY, ANGLERPHISH,
	#MagnetFrog, MagnetFrogBlue
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

# used in mon_from_json - convert the name of a species into the monbase
func _species_str_to_montype(species_str: String) -> MonType:
	for montype in _MON_MAP.keys():
		if _MON_MAP[montype]._species_name == species_str:
			return montype
	assert(false, "No base found for %s." % species_str)
	return MonType.BITLEON #error case

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
	
