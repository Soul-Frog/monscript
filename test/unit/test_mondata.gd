extends GutTest

func before_each():
	gut.p("ran setup", 2)

func after_each():
	gut.p("ran teardown", 2)

func before_all():
	gut.p("ran run setup", 2)

func after_all():
	gut.p("ran run teardown", 2)

func test_reality():
	assert_true(true, "I sure hope so.")

func test_create_mon():
	pass

func test_stats_for_level():
	pass

func test_get_name():
	pass

# verify that all mons have a scene that exists
func test_get_scenes():
	pass


func test_gain_XP():
	pass
