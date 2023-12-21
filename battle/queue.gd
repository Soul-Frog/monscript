class_name BattleQueue
extends Node2D

@onready var backgrounds = $Backgrounds
@onready var headshots = $Headshots
const _team_to_color = {
	Battle.Team.PLAYER : Color.AQUAMARINE,
	Battle.Team.COMPUTER : Color.PALE_VIOLET_RED
}
const SIZE = 6

class MonWithTime:
	var mon: BattleMon
	var time_til_action: float
	func _init(battleMon, time_until_action):
		self.mon = battleMon
		self.time_til_action = time_until_action

func _ready() -> void:
	assert(backgrounds.get_child_count() == SIZE)
	assert(headshots.get_child_count() == SIZE)
	for team in Battle.Team.values():
		assert(_team_to_color.has(team))

func update_queue(action_queue: Array, player_mons: Node2D, computer_mons: Node2D) -> void:
	_update_queue_display(_get_next_six_mons(action_queue, player_mons, computer_mons))

func _get_next_six_mons(action_queue: Array, player_mons: Node2D, computer_mons: Node2D) -> Array:
	var queue = []
	
	# anyone in the action_queue must be going next
	for mon in action_queue:
		queue.append(mon)
	
	var CALC = func(mon: BattleMon, results: Array):
		var cumulative_time = 0
		for i in range(0, 6):
			var ap_until_turn = (mon.ACTION_POINTS_PER_TURN if i != 0 else mon.ACTION_POINTS_PER_TURN - mon.action_points)
			var time_for_action = (ap_until_turn/mon.get_speed())
			cumulative_time += time_for_action
			results.append(MonWithTime.new(mon, cumulative_time))
	
	# for each mon, calculate its next 6 times and add to an array
	var results = []
	for mon in player_mons.get_children():
		if not mon.is_defeated():
			CALC.call(mon, results)
	for mon in computer_mons.get_children():
		if not mon.is_defeated():
			CALC.call(mon, results)
	
	# now sort results by time to go...
	var SORT = func(mwt1: MonWithTime, mwt2: MonWithTime):
		if mwt1.time_til_action == mwt2.time_til_action:
			# in the case of a tie, the first tiebreaker is player mons go before computer mons
			if mwt1.mon.team == Battle.Team.PLAYER and mwt2.mon.team == Battle.Team.COMPUTER: #mwt1 is player, has prio over computer
				return true
			elif mwt1.mon.team == Battle.Team.COMPUTER and mwt2.mon.team == Battle.Team.PLAYER: #mwt2 is player, has prio over computer
				return false
			# if on the same team, order in parent is next tiebreaker
			elif mwt1.mon.team == Battle.Team.PLAYER and mwt2.mon.team == Battle.Team.PLAYER: #both player mons
				# iterate over playermons; if we find mwt1 first, it comes earlier and has prio, or vice versa for mwt2
				for mon in player_mons.get_children():
					if mon == mwt1.mon:
						return true
					if mon == mwt2.mon:
						return false
				assert(false, "Teams are seriously messed up.")
			elif mwt1.mon.team == Battle.Team.COMPUTER and mwt2.mon.team == Battle.Team.COMPUTER: #both player mons
				for mon in computer_mons.get_children():
					if mon == mwt1.mon:
						return true
					if mon == mwt2.mon:
						return false
				assert(false, "Teams are seriously messed up.")
			else:
				assert(false, "Teams are seriously messed up.")
		if mwt1.time_til_action < mwt2.time_til_action:
			return true
		return false
	
	results.sort_custom(SORT)
	
	# iterate over results, delete any mon that is already in the action queue 
	# (and has been added already to our queue)
	# this fixes a bug where mons may show twice
	for result in results:
		if result.time_til_action == 0 and action_queue.has(result.mon):
			results.erase(result)
		if result.time_til_action != 0:
			break
	
	# add 6 of these to the queue...
	for i in range(0, 6):
		queue.append(results[i].mon)

	assert(queue.size() >= 6)
	
	queue = queue.slice(0, 6)
	
	return queue.slice(0, 6) # return the first 6 mons in the queue

func _update_queue_display(mons: Array):
	assert(mons.size() == SIZE)
	
	for i in range(0, SIZE):
		var mon = mons[i]
		
		# update headshot
		var headshot = headshots.get_child(i)
		headshot.texture = MonData.get_texture_for(mon.base_mon.get_mon_type())
		
		# update background color based on mon team
		var bg = backgrounds.get_child(i)
		bg.modulate = _team_to_color[mon.team]
