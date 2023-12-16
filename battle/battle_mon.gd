class_name BattleMon
extends CharacterBody2D

# emitted when this mon's ap has been increased to max
signal ready_to_take_action

# emitted when this mon performs an escape action
signal try_to_escape

# emitted when this mon is defeated
signal zero_health 

# emitted after this mon takes an action in battle - generally after animation ends
signal action_completed

# emitted after this mon's animation completes
signal action_animation_completed

# emitted after this mon's health, ap, or status has changed
signal health_or_ap_changed
# emitted after this mon's status conditions change (passes the modified status)
signal status_changed
# emitted after this mon's atk/def/spd stage is changed (buff/debuffs)
signal stats_changed

const MOVING_TEXT_SCENE = preload("res://battle/moving_text.tscn")

const ACTION_POINTS_PER_TURN := 100.0

# Multiplier to delta to control speed of battles
var speed_scale = 1.0

# The underlying Mon Object this battle mon scene represents
# Set this with init_mon before doing anything else with this scene
var base_mon: MonData.Mon = null

# The name and color used for this mon's entries into the battle log
var log_name: String = ""
var log_color: Color = Color.BLACK
# Reference to the battle log
var battle_log: BattleLog

# current action points - increases by speed each tick
# when this reaches 100, signals to take a turn
var action_points := 0.0

# how many turns this mon has taken this battle
var turn_count := 0

var is_defending := false
var escaped_from_battle := false

# whether this mon's AP should be reset after this action ends
# for example, the pass action sets this to false
var reset_AP_after_action := true

var max_health := -1
var current_health := -1
var _base_speed := -1
var _base_attack := -1
var _base_defense := -1

var atk_buff_stage := 0
var def_buff_stage := 0
var spd_buff_stage := 0

var original_position: Vector2
var is_shaking := false
var shake_timer: Timer
const SHAKE_TIME := 0.10
const shake_amount := 3
const shake_speed := 0.8
var shake_direction := 1

# a dictionary that anything can be stored in that needs to be tracked
# for example, some moves will store information in here to use later
var metadata = {}

 
const MAX_BUFF_STAGE = 4 # the maximum positive buff stage
const MIN_DEBUFF_STAGE = -4 # the minimum negative debuff stage
# map a stage to its modification amount for that stat
# an additional +4 - -4 is applied to the final result after multipliers as well based on stage
# this players a bit nicer at lower levels
const _BUFF_STAGE_TO_MODIFIER = {
	-4 : 0.36,
	-3 : 0.68,
	-2 : 0.84,
	-1 : 0.92,
	 0 : 1.0,
	 1 : 1.08,
	 2 : 1.16,
	 3 : 1.32,
	 4 : 1.64
}

enum BuffableStat {
	ATK, DEF, SPD
}

enum Status {
	LEAK, SLEEP
}

var statuses = {
	Status.LEAK : false,
	Status.SLEEP : false
}

func _ready() -> void:
	original_position = position
	shake_timer = Timer.new()
	shake_timer.wait_time = SHAKE_TIME
	shake_timer.timeout.connect(_stop_shaking)
	add_child(shake_timer)

# Initializes this battle_mon with an underlying mon object
func init_mon(mon: MonData.Mon) -> void:
	base_mon = mon
	current_health = mon.get_max_health()
	max_health = mon.get_max_health()
	_base_attack = mon.get_attack()
	_base_defense = mon.get_defense()
	_base_speed = mon.get_speed()
	is_defending = false
	escaped_from_battle = false
	reset_AP_after_action = true
	log_name = mon.get_name()
	emit_signal("health_or_ap_changed")

# returns attack modified by buffs/debuffs
func get_attack() -> int:
	return _base_attack * _BUFF_STAGE_TO_MODIFIER[atk_buff_stage]

# returns defense modified by buffs/debuffs
func get_defense() -> int:
	return _base_defense * _BUFF_STAGE_TO_MODIFIER[atk_buff_stage]

# returns speed modified by buffs/debuffs
func get_speed() -> int:
	return _base_speed * _BUFF_STAGE_TO_MODIFIER[spd_buff_stage]

# Called once for each mon by battle.gd at a regular time interval
func battle_tick(unscaled_delta: float) -> void:
	var delta = unscaled_delta * speed_scale
	assert(base_mon != null, "Didn't add a mon with init_mon!")
	assert(_base_attack != -1 and _base_speed != -1 and _base_defense != -1 and max_health != -1, "Stats were never initialized?")
	if not is_defeated():
		action_points += max(get_speed(), 1) * delta
		action_points = clamp(action_points, 0.0, ACTION_POINTS_PER_TURN)
		emit_signal("health_or_ap_changed")
		
		if action_points >= ACTION_POINTS_PER_TURN:
			# TODO $BattleComponents/ActionPointsBar.modulate = Global.COLOR_RED
			turn_count += 1
			emit_signal("ready_to_take_action", self) # signal that it's time for this mon to act

# Take a single turn in battle
func take_action(friends: Array, foes: Array, animator: BattleAnimator, escaping: bool) -> void:
	assert(friends.size() != 0, "No friends?")
	assert(foes.size() != 0, "No foes?")
	is_defending = false
	
	# if we're asleep, just wake up and that's our turn
	if statuses[Status.SLEEP]:
		heal_status(Status.SLEEP)
		alert_turn_over()
		return
	
	# tell our script to go ahead and execute an action
	base_mon.get_active_monscript().execute(self, friends, foes, battle_log, animator, escaping)
	# don't do anything after here, the turn is over when we hit alert_turn_over
	# todo - maybe alert_turn_over is useless and we can just cram more info here...?

# called after a mon takes its turn
func alert_turn_over() -> void:
	assert(action_points == 100.0 or not reset_AP_after_action)
	if reset_AP_after_action:
		action_points = 0.0
	reset_AP_after_action = true
	# TODO $BattleComponents/ActionPointsBar.modulate = Global.COLOR_YELLOW
	
	# after taking an action, if inflicted with leak, take 5% health as damage
	if statuses[Status.LEAK]:
		battle_log.add_text("%s is leaking memory!" % battle_log.MON_NAME_PLACEHOLDER, self)
		take_damage(max(ceil(max_health * 0.05), 1))
		#todo - animate this better
	
	emit_signal("action_completed")

func is_defeated() -> bool:
	assert(current_health >= 0, "Mon's health is somehow negative.")
	return current_health == 0

# apply an attack against this mon with a given attack value and damage multiplier
# this function factors in defense and defending
func apply_attack(attacker: BattleMon, multiplier: float) -> void:
	# damage taken is ATK-DEF, to a minimum of 1
	var damage_taken = max(attacker.get_attack() - get_defense(), 1)
	
	# increase damage taken by attack multiplier
	damage_taken *= multiplier
	
	# if defending, reduce the damage taken by half
	if is_defending:
		damage_taken /= 2
		
	# apply an additional constant modifier based on defense buff stage and attacker attack stage;
	# example: if our def stage is -1 and attacker's attack stage is 4, we take an additional flat 3 damage
	# example2: if our def stage is 4 and attacker's attack stage if -3, we reduce damage taken by a flat 7
	damage_taken = max(damage_taken + attacker.atk_buff_stage - def_buff_stage, 1)
	
	take_damage(damage_taken)

# deal an absolute amount of damage to a mon
# ignores defense and defending
# generally, don't call this directly in attack blocks, call apply_attack instead
func take_damage(damage_taken: int) -> void:
	current_health -= damage_taken
	current_health = max(current_health, 0);
	emit_signal("health_or_ap_changed")
	
	battle_log.add_text("%s took %d damage!" % [battle_log.MON_NAME_PLACEHOLDER, damage_taken], self)
	
	# make text effect
	self.add_child(
		MOVING_TEXT_SCENE.instantiate()
		.tx(damage_taken).direction_up().speed(40).time(0.2).color(Global.COLOR_RED))
	# make the damaged mon shake
	is_shaking = true
	shake_timer.start()
	
	# TODO - make mon glow red or something for a sec
	# when taking fire damage, glow redder; chill glow blue, volt glow yellow; white on normal damage?
	
	if current_health == 0:
		action_points = 0.0
		emit_signal("zero_health", self)

func heal_damage(heal: int) -> void:
	var heal_amt = heal
	if current_health + heal >= max_health:
		heal_amt = max_health - current_health
	current_health += heal_amt
	
	battle_log.add_text("%s healed %d HP!" % [battle_log.MON_NAME_PLACEHOLDER, heal_amt], self)
	
	emit_signal("health_or_ap_changed")
	
	# make text effect
	self.add_child(
		MOVING_TEXT_SCENE.instantiate()
		.tx(heal_amt).direction_up().speed(40).time(0.2).color(Global.COLOR_GREEN))
	
	# TODO - make self glow green or something for a sec

func inflict_status(status: Status) -> void:
	# only display inflicted message if don't actually have this status
	match status:
		Status.LEAK:
			if not statuses[status]:
				battle_log.add_text("%s is suffering from a memory leak!" % battle_log.MON_NAME_PLACEHOLDER, self)
				emit_signal("status_changed", status, true)
			else:
				battle_log.add_text("%s is already leaking memory!" % battle_log.MON_NAME_PLACEHOLDER, self)
		Status.SLEEP:
			if not statuses[status]:
				battle_log.add_text("%s has been put to sleep!" % battle_log.MON_NAME_PLACEHOLDER, self)
				emit_signal("status_changed", status, true)
			else:
				battle_log.add_text("%s is already asleep!" % battle_log.MON_NAME_PLACEHOLDER, self)
		_:
			assert(false, "No message for status!")
			
	statuses[status] = true
	
	# todo - play some effect here

func heal_status(status: Status) -> void:
	# only display 'healed status!' message if we actually had that status
	if statuses[status]:
		match status:
			Status.LEAK:
				battle_log.add_text("%s is no longer leaking memory!" % battle_log.MON_NAME_PLACEHOLDER, self)
				emit_signal("status_changed", status, false)
			Status.SLEEP:
				battle_log.add_text("%s has resumed execution!" % battle_log.MON_NAME_PLACEHOLDER, self)
				emit_signal("status_changed", status, false)
			_:
				assert(false, "No message for status!")
	
	statuses[status] = false
	
	# todo - play some effect here

func heal_all_statuses() -> void:
	for status in statuses.keys():
		statuses[status] = false

# apply a buff/debuff
func apply_stat_change(stat: BuffableStat, mod: int):
	match stat:
		BuffableStat.ATK:
			atk_buff_stage = clamp(atk_buff_stage + mod, MIN_DEBUFF_STAGE, MAX_BUFF_STAGE)
		BuffableStat.DEF:
			def_buff_stage = clamp(def_buff_stage + mod, MIN_DEBUFF_STAGE, MAX_BUFF_STAGE)
			print(def_buff_stage)
		BuffableStat.SPD:
			spd_buff_stage = clamp(spd_buff_stage + mod, MIN_DEBUFF_STAGE, MAX_BUFF_STAGE)
	emit_signal("stats_changed")

func _process(delta: float) -> void:
	if is_shaking:
		if position.x >= (original_position.x + shake_amount) or position.x <= (original_position.x - shake_amount):
			shake_direction = -shake_direction
		position.x += shake_direction * shake_speed

func _stop_shaking() -> void:
	is_shaking = false
	position = original_position
	shake_direction = 1
