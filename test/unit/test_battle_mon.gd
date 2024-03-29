extends GutTest

const MON_SCENE_PATH := "res://mons/bitleon.tscn"
const BATTLE_MON_SCRIPT := preload("res://battle/battle_mon.gd")

# creates and returns a battlemon
func make_battlemon() -> BattleMon:
	var mon := MonData.create_mon(MonData.MonType.BITLEON, 5)
	var bmon = load(MON_SCENE_PATH).instantiate()
	bmon.set_script(BATTLE_MON_SCRIPT)
	bmon.init_mon(mon, Battle.Team.PLAYER)
	return bmon

func test_make_battlemon():
	var bmon = make_battlemon()
	assert_not_null(bmon)
	bmon.free()

func test_battle_tick():
	var sigcounter = TestingUtils.SignalCounter.new()
	
	var battlemon = make_battlemon()
	battlemon.ready_to_take_action.connect(sigcounter.callback1)
	
	var speed = battlemon.get_speed()
	var ctr = 0
	
	while ctr < battlemon.ACTION_POINTS_PER_TURN:
		battlemon.battle_tick(1.0, battlemon.get_speed(), 1.0)
		ctr += speed
	
	assert_eq(sigcounter.count(), 6)
	
	sigcounter.free()
	battlemon.free()
