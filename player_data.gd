# PlayerData stores global information about the player, such as the player's
# name, mon team, mon storage, and items.

extends Node

var team = []
var mon_storage = []

func _init():
	team = [MonData.createMon(MonData.MonType.MAGNETFROG, 0), MonData.createMon(MonData.MonType.MAGNETFROG, 0), MonData.createMon(MonData.MonType.MAGNETFROG, 0), MonData.createMon(MonData.MonType.MAGNETFROG, 0)]
