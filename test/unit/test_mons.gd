# tests the mon instances inside of the /mons folder
extends GutTest

const MON_PATH = "res://mons/"
const EXCLUDE_BASE_SCENE = "mon.tscn"
var mons := []

func before_all():
	var scenes: Array = Global.files_in_folder_with_extension(MON_PATH, ".tscn")
	for scene in scenes:
		if scene == EXCLUDE_BASE_SCENE:
			continue
		mons.append(load(MON_PATH + scene).instantiate())

func after_all():
	for mon in mons:
		mon.free()

# make sure the mon folder hasn't moved
func test_location():
	assert_not_null(DirAccess.open(MON_PATH), "Mon folder moved, update MON_PATH.")

# make sure each mon has a hitbox
func test_has_hitbox():
	for mon in mons:
		assert_true(mon.find_child("CollisionHitbox").shape != null)

# make sure each mon has a sprite
func test_has_sprite():
	for mon in mons:
		assert_true(mon.get_texture() != null)
		assert_true(mon.get_headshot() != null)
