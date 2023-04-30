extends CharacterBody2D

signal ready_to_take_turn
signal try_to_escape
signal zero_health

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

var max_health = -1
var current_health = -1
var speed = -1
var attack = -1
var defense = -1

func _ready():
	assert($Sprite2D.texture != null, "No sprite texture assigned in editor!")
	assert($CollisionShape2D.shape != null, "No collision shape assigned in editor!")

# Initializes this battle_mon with an underlying mon object
func init_mon(mon):
	base_mon = mon
	current_health = mon.get_max_health()
	max_health = mon.get_max_health()
	attack = mon.get_attack()
	defense = mon.get_defense()
	speed = mon.get_speed()
	_update_labels();

# Called once for each mon by battle.gd at a regular time interval
func battle_tick():
	assert(base_mon != null, "Didn't add a mon with init_mon!")
	assert(attack != -1 and speed != -1 and defense != -1 and max_health != -1, "Stats were never initialized?")
	if not is_defeated():
		action_points += speed
		_update_labels();
		if action_points >= ACTION_POINTS_PER_TURN:
			emit_signal("ready_to_take_turn", self) # signal that it's time for this mon to act

func is_defeated():
	assert(current_health >= 0, "Mon's health is somehow negative.")
	return current_health == 0

# Take a single turn in battle
func take_action(friends, foes):
	assert(friends.size() != 0, "No friends?")
	assert(foes.size() != 0, "No foes?")
	action_points = 0
	is_defending = false
	# eventually, logic here will use script to determine action
	# for now, target a random foe with basic attack
	var attack_target = foes[Global.RNG.randi() % foes.size()]
	perform_attack(attack_target)
	_update_labels();

# perform this mon's special action 
func perform_special():
	assert(not is_defeated())
	@warning_ignore("integer_division")
	current_health += max_health / 10
	current_health = min(current_health, max_health)

# perform an attack at the given target
func perform_attack(target):
	assert(not is_defeated())
	assert(not target.is_defeated())
	target.take_damage(attack)

# Called when this mon is attacked
# Damage taken is reduced by defense, then further divided by 2 if defending
func take_damage(raw_damage):
	var damage_taken = raw_damage - defense
	if is_defending:
		damage_taken /= 2
	current_health -= damage_taken
	current_health = max(current_health, 0);
	
	if current_health == 0:
		action_points = 0
		emit_signal("zero_health", self)
	
	_update_labels();

# A defend action reduces the damage taken by this mon by half until their next action
func perform_defend():
	assert(not is_defeated())
	is_defending = true

# Signal to battle.gd to try to escape the battle
func perform_run():
	assert(not is_defeated())
	emit_signal("try_to_escape")

# Pass, which skips the turn but keeps half of the action points
func perform_pass():
	assert(not is_defeated())
	action_points = 50

func _update_labels():
	$ActionPointsLabel.text = AP_LABEL_FORMAT % [action_points]
	$HealthLabel.text = HEALTH_LABEL_FORMAT % [current_health, max_health]


