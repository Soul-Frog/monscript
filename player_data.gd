# PlayerData stores global information about the player, such as the player's
# name, mon team, mon storage, and items.

extends Node

const MON_STORAGE_PAGES = 3
const MONS_PER_STORAGE_PAGE = 8

var team = []
var mon_storage = []

func _init():
	team = [MonData.create_mon(MonData.MonType.MAGNETFROG, 5), null, null, MonData.create_mon(MonData.MonType.MAGNETFROGBLUE, 5)]
	
	for i in MON_STORAGE_PAGES:
		for j in MONS_PER_STORAGE_PAGE:
			mon_storage.append(null)
		
	assert(team.size() == Global.MONS_PER_TEAM)
	assert(mon_storage.size() == MON_STORAGE_PAGES * MONS_PER_STORAGE_PAGE)
