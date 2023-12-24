extends GutTest

var mons := []
var fakemon: MonData.Mon
var FAKE_BASE = MonData.MonBase.new(MonData.MonType.BITLEON, "FAKEMON", "res://mons/bitleon.tscn", "res://monscripts/attack.txt", 
	256, 128, 64, 96, 1, 1, 1, 1, ScriptData.get_block_by_name("Attack"), "passive", "passivedesc", [Color.WHITE, Color.WHITE, Color.WHITE])

func before_each():
	mons.clear()
	for mon_type in MonData.MonType.values():
		if mon_type == MonData.MonType.NONE:
			continue
		var mon := MonData.create_mon(mon_type, 0)
		mons.append(mon)
	
	# create a fake testmon
	fakemon = MonData.Mon.new(FAKE_BASE, 0)

func test_create_mon():
	for mon in mons:
		assert_not_null(mon)

func test_stats_for_level():
	fakemon._level = 0
	assert_eq(0, fakemon.get_level())
	assert_eq(34, fakemon.get_max_health())
	assert_eq(17, fakemon.get_attack())
	assert_eq(8, fakemon.get_defense())
	assert_eq(12, fakemon.get_speed())
	
	fakemon._level = 1
	assert_eq(1, fakemon.get_level())
	assert_eq(38, fakemon.get_max_health())
	assert_eq(19, fakemon.get_attack())
	assert_eq(9, fakemon.get_defense())
	assert_eq(14, fakemon.get_speed())
	
	fakemon._level = 2
	assert_eq(2, fakemon.get_level())
	assert_eq(41, fakemon.get_max_health())
	assert_eq(20, fakemon.get_attack())
	assert_eq(10, fakemon.get_defense())
	assert_eq(15, fakemon.get_speed())
	
	fakemon._level = 16
	assert_eq(16, fakemon.get_level())
	assert_eq(89, fakemon.get_max_health())
	assert_eq(44, fakemon.get_attack())
	assert_eq(22, fakemon.get_defense())
	assert_eq(33, fakemon.get_speed())
	
	fakemon._level = 32
	assert_eq(32, fakemon.get_level())
	assert_eq(145, fakemon.get_max_health())
	assert_eq(72, fakemon.get_attack())
	assert_eq(36, fakemon.get_defense())
	assert_eq(54, fakemon.get_speed())
	
	fakemon._level = 64
	assert_eq(64, fakemon.get_level())
	assert_eq(256, fakemon.get_max_health())
	assert_eq(128, fakemon.get_attack())
	assert_eq(64, fakemon.get_defense())
	assert_eq(96, fakemon.get_speed())


# check if nicknames work
func test_get_name():
	assert_eq(fakemon.get_name(), FAKE_BASE._species_name)
	fakemon = MonData.Mon.new(FAKE_BASE, 0, "NICKNAME")
	assert_eq(fakemon.get_name(), "NICKNAME")

func test_get_script():
	for mon in mons:
		assert_true(FileAccess.file_exists(mon._base._default_script_path))
		assert_not_null(mon.get_default_monscript())
		var active = mon.get_active_monscript()
		assert_not_null(active)
		var script1 = mon.get_monscript(0)
		assert_not_null(script1)
		assert_eq(active, script1)
		var script2 = mon.get_monscript(1)
		assert_not_null(script2)
		var script3 = mon.get_monscript(2)
		assert_not_null(script3)
		mon.set_active_monscript_index(2)
		assert_eq(mon.get_active_monscript(), script3)

# make sure that all mons have a script that exists
func test_get_scene():
	for mon in mons:
		assert_true(FileAccess.file_exists(mon._base._scene_path))
		assert_eq(mon._base._scene_path, mon.get_scene_path())

# make sure mons can level up
func test_gain_XP():
	assert_lt(MonData.MIN_LEVEL, MonData.MAX_LEVEL)
	var lvlups := 0
	var clevel := fakemon._level
	assert_eq(fakemon._level, fakemon.get_level())
	while fakemon._level != int(float(MonData.MAX_LEVEL) / 2):
		fakemon.gain_XP(1)
		if fakemon._level > clevel:
			assert_true(fakemon._level == clevel + 1)
			assert_eq(fakemon._level, fakemon.get_level())
			lvlups += 1
			clevel += 1
	assert_eq(lvlups, int(float(MonData.MAX_LEVEL) / 2))
	
	# check that giving tons of XP at once gives multiple levels
	fakemon.gain_XP(10000000000000000)
	# and that we stop leveling at cap
	assert_eq(fakemon._level, MonData.MAX_LEVEL)
	fakemon.gain_XP(10000000000000000)
	assert_eq(fakemon._level, MonData.MAX_LEVEL)
