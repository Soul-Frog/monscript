extends GutTest

var mons := []

func before_each():
	mons.clear()
	for mon_type in MonData.MonType.values():
		if mon_type == MonData.MonType.NONE:
			continue
		var mon := MonData.create_mon(mon_type, 0)
		mons.append(mon)

func test_create_mon():
	for mon in mons:
		assert_not_null(mon)

func test_stats_for_level():
	for mon in mons:
		
func test_get_name():
	pass

# verify that all mons have a scene that exists
func test_get_scenes():
	pass


func test_gain_XP():
	pass
