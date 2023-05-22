# PlayerData stores global information about the player, such as the player's
# name, mon team, mon storage, and items.

extends Node

var team = []
var mon_storage = []

func _init():
	team = [MonData.create_mon(MonData.MonType.MAGNETFROG, 5), MonData.create_mon(MonData.MonType.MAGNETFROGBLUE, 5), MonData.create_mon(MonData.MonType.MAGNETFROGBLUE, 5), MonData.create_mon(MonData.MonType.MAGNETFROG, 5)]
