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

const ACTION_POINTS_PER_TURN = 100
const HEALTH_LABEL_FORMAT = "[center]%d/%d[/center]"
const AP_LABEL_FORMAT = "[center]%d/100[/center]"

# The underlying Mon Object this battle mon scene represents
# Set this with init_mon before doing anything else with this scene
var base_mon = null

# current action points - increases by speed each tick
# when this reaches 100, signals to take a turn
var action_points = 0

var is_defending = false
var escaped_from_battle = false

# whether this mon's AP should be reset after this action ends
# for example, the pass action sets this to false
var reset_AP_after_action = true

var max_health = -1
var current_health = -1
var speed = -1
var attack = -1
var defense = -1

func _ready():
	assert($Sprite.texture != null, "No sprite texture assigned in editor!")
	assert($CollisionHitbox.shape != null, "No collision shape assigned in editor!")

# Initializes this battle_mon with an underlying mon object
func init_mon(mon):
	base_mon = mon
	current_health = mon.get_max_health()
	max_health = mon.get_max_health()
	attack = mon.get_attack()
	defense = mon.get_defense()
	speed = mon.get_speed()
	is_defending = false
	escaped_from_battle = false
	reset_AP_after_action = true
	_update_labels();

# Called once for each mon by battle.gd at a regular time interval
func battle_tick():
	assert(base_mon != null, "Didn't add a mon with init_mon!")
	assert(attack != -1 and speed != -1 and defense != -1 and max_health != -1, "Stats were never initialized?")
	if not is_defeated():
		action_points += speed
		action_points = clamp(action_points, 0, ACTION_POINTS_PER_TURN)
		_update_labels();
		if action_points >= ACTION_POINTS_PER_TURN:
			emit_signal("ready_to_take_action", self) # signal that it's time for this mon to act

# Take a single turn in battle
func take_action(friends, foes, animator):
	assert(friends.size() != 0, "No friends?")
	assert(foes.size() != 0, "No foes?")
	is_defending = false
	
	# tell our script to go ahead and execute an action
	base_mon.monscript.execute(self, friends, foes, animator)

func alert_turn_over():
	assert(action_points == 100 or not reset_AP_after_action)
	if reset_AP_after_action:
		action_points = 0
	reset_AP_after_action = true
	_update_labels();
	emit_signal("action_completed")

func is_defeated():
	assert(current_health >= 0, "Mon's health is somehow negative.")
	return current_health == 0

# Called when this mon is attacked
# Damage taken is reduced by defense, then further divided by 2 if defending
func take_damage(raw_damage):
	var damage_taken = max(raw_damage - defense, 0)
	if is_defending:
		damage_taken /= 2
	current_health -= damage_taken
	current_health = max(current_health, 0);
	
	# make text effect
	self.add_child(
		load("res://battle/moving_text.tscn").instantiate()
		.tx(damage_taken).direction_up().speed(40).time(0.2).color(Global.COLOR_RED))

	if current_health == 0:
		action_points = 0
		emit_signal("zero_health", self)
	
	_update_labels();

func _update_labels():
	$BattleComponents/ActionPointsLabel.text = AP_LABEL_FORMAT % [action_points]
	$BattleComponents/HealthLabel.text = HEALTH_LABEL_FORMAT % [current_health, max_health]
