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

const MOVING_TEXT_SCENE = preload("res://battle/moving_text.tscn")

const ACTION_POINTS_PER_TURN := 100

# The underlying Mon Object this battle mon scene represents
# Set this with init_mon before doing anything else with this scene
var base_mon: MonData.Mon = null

# current action points - increases by speed each tick
# when this reaches 100, signals to take a turn
var action_points := 0

# how many turns this mon has taken this battle
var turn_count := 0

var is_defending := false
var escaped_from_battle := false

# whether this mon's AP should be reset after this action ends
# for example, the pass action sets this to false
var reset_AP_after_action := true

var max_health := -1
var current_health := -1
var speed := -1
var attack := -1
var defense := -1

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

enum Status {
	LEAK
}

var statuses = {
	Status.LEAK : false
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
	attack = mon.get_attack()
	defense = mon.get_defense()
	speed = mon.get_speed()
	is_defending = false
	escaped_from_battle = false
	reset_AP_after_action = true
	$BattleComponents/ActionPointsBar.max_value = ACTION_POINTS_PER_TURN
	$BattleComponents/HealthBar.max_value = max_health
	$BattleComponents/ActionPointsBar.modulate = Global.COLOR_YELLOW
	$BattleComponents/HealthBar.modulate = Global.COLOR_GREEN
	_update_labels();

# Called once for each mon by battle.gd at a regular time interval
func battle_tick() -> void:
	assert(base_mon != null, "Didn't add a mon with init_mon!")
	assert(attack != -1 and speed != -1 and defense != -1 and max_health != -1, "Stats were never initialized?")
	if not is_defeated():
		action_points += speed
		action_points = clamp(action_points, 0, ACTION_POINTS_PER_TURN)
		_update_labels();
		if action_points >= ACTION_POINTS_PER_TURN:
			$BattleComponents/ActionPointsBar.modulate = Global.COLOR_RED
			turn_count += 1
			emit_signal("ready_to_take_action", self) # signal that it's time for this mon to act

# Take a single turn in battle
func take_action(friends: Array, foes: Array, animator: BattleAnimator) -> void:
	assert(friends.size() != 0, "No friends?")
	assert(foes.size() != 0, "No foes?")
	is_defending = false
	
	# tell our script to go ahead and execute an action
	base_mon.get_active_monscript().execute(self, friends, foes, animator)
	# don't do anything after here, the turn is over when we hit alert_turn_over
	# todo - maybe alert_turn_over is useless and we can just cram more info here...?

# called after a mon takes its turn
func alert_turn_over() -> void:
	assert(action_points == 100 or not reset_AP_after_action)
	if reset_AP_after_action:
		action_points = 0
	reset_AP_after_action = true
	$BattleComponents/ActionPointsBar.modulate = Global.COLOR_YELLOW
	
	# after taking an action, if inflicted with leak, take 5% health as damage
	if statuses[Status.LEAK]:
		take_damage(int(max_health * 0.05), true)
		#todo - animate this better
	
	_update_labels();
	emit_signal("action_completed")

func is_defeated() -> bool:
	assert(current_health >= 0, "Mon's health is somehow negative.")
	return current_health == 0

# Called when this mon is attacked
# Damage taken is reduced by defense, then further divided by 2 if defending
func take_damage(raw_damage: int, ignore_defense: bool = false) -> void:
	var damage_taken = raw_damage
	
	if not ignore_defense: # if we aren't ignoring defense (ie, leak status ignores defense), apply it
		damage_taken = raw_damage - defense
		if is_defending: # defending reduces damage by half
			damage_taken /= 2
	
	current_health -= int(max(damage_taken, 1)) # deal a minimum of 1 damage
	current_health = max(current_health, 0);
	
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
		action_points = 0
		emit_signal("zero_health", self)
	
	_update_labels();

func heal_damage(heal: int) -> void:
	var heal_amt = heal
	if current_health + heal >= max_health:
		heal_amt = max_health - current_health
	
	current_health += heal_amt
	
	# make text effect
	self.add_child(
		MOVING_TEXT_SCENE.instantiate()
		.tx(heal_amt).direction_up().speed(40).time(0.2).color(Global.COLOR_GREEN))
	
	# TODO - make self glow green or something for a sec
	
	_update_labels()

func inflict_status(status: Status) -> void:
	statuses[status] = true
	
	# todo - play some effect here, add some icons, idk

func heal_status(status: Status) -> void:
	statuses[status] = false
	
	# todo - play some effect here

func heal_all_statuses() -> void:
	for status in statuses.keys():
		statuses[status] = false
	
	#todo - play some effect here

func _update_labels() -> void:
	$BattleComponents/ActionPointsBar.value = action_points
	$BattleComponents/HealthBar.value = current_health

func _process(delta: float) -> void:
	if is_shaking:
		if position.x >= (original_position.x + shake_amount) or position.x <= (original_position.x - shake_amount):
			shake_direction = -shake_direction
		position.x += shake_direction * shake_speed

func _stop_shaking() -> void:
	is_shaking = false
	position = original_position
	shake_direction = 1
