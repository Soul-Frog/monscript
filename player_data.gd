# PlayerData stores global information about the player, such as the player's
# name, mon team, mon storage, and items.

extends Node

const STORAGE_PAGES = 3
const MONS_PER_STORAGE_PAGE = 8

var team = []
var storage = []

func _init():
	team = [MonData.create_mon(MonData.MonType.MAGNETFROG, 5), null, null, MonData.create_mon(MonData.MonType.MAGNETFROGBLUE, 5)]
	
	for i in STORAGE_PAGES:
		for j in MONS_PER_STORAGE_PAGE:
			storage.append(null)
		
	assert(team.size() == Global.MONS_PER_TEAM)
	assert(storage.size() == STORAGE_PAGES * MONS_PER_STORAGE_PAGE)
	
	storage[0] = MonData.create_mon(MonData.MonType.MAGNETFROG, 10)
	storage[5] = MonData.create_mon(MonData.MonType.MAGNETFROG, 11)
	storage[4] = MonData.create_mon(MonData.MonType.MAGNETFROG, 12)
	storage[9] = MonData.create_mon(MonData.MonType.MAGNETFROG, 13)
	storage[13] = MonData.create_mon(MonData.MonType.MAGNETFROG, 14)
	storage[18] = MonData.create_mon(MonData.MonType.MAGNETFROG, 64)
