extends CharacterBody2D

signal ready_to_take_turn
signal try_to_escape

const ACTION_POINTS_PER_TURN = 100
const HEALTH_LABEL_FORMAT = "[center]%d/%d[/center]"
const AP_LABEL_FORMAT = "[center]%d/100[/center]"

# how many action points are accured each tick (how often you get to take a turn)
@export var speed = 10
# base damage for attacks
@export var attack = 10
# reduces amount of damage taken
@export var defense = 5
# health pool
@export var max_health = 20


# current action points - increases by SPEED each tick
# when this reaches 100, signals to take a turn
var action_points
var current_health
var is_defending

var rng = RandomNumberGenerator.new()

func _ready():
	action_points = 0;
	current_health = max_health;
	is_defending = false
	_update_labels();

# Called once for each mon by battle.gd at a regular time interval
func battle_tick():
	if not is_defeated():
		action_points += speed
		_update_labels();
		if action_points >= ACTION_POINTS_PER_TURN:
			emit_signal("ready_to_take_turn", self) # signal that it's time for this mon to act

func is_defeated():
	assert(current_health >= 0, "Mon's health is somehow negative")
	return current_health == 0

func take_action(friends, foes):
	action_points = 0
	is_defending = false
	# eventually, logic here will use script to determine action
	# for now, target a random foe with basic attack
	var attack_target = foes[rng.randi() % foes.size()]
	perform_attack(attack_target)
	_update_labels();

# perform this mon's special action 
func special():
	@warning_ignore("integer_division")
	current_health += max_health / 10
	current_health = min(current_health, max_health)

# perform an attack at the given target
func perform_attack(target):
	target.take_attack(attack)

# Called when this mon is attacked
# Damage taken is reduced by defense, then further divided by 2 if defending
func take_attack(raw_damage):
	var damage_taken = raw_damage - defense
	if is_defending:
		damage_taken /= 2
	current_health -= damage_taken
	current_health = max(current_health, 0);
	
	if current_health == 0:
		action_points = 0
	
	_update_labels();

# A defend action reduces the damage taken by this mon by half until their next action
func perform_defend():
	assert(not is_defeated())
	is_defending = true

# Signal to battle.gd to try to escape the battle
func perform_run():
	assert(not is_defeated())
	emit_signal("try_to_escape")

func _update_labels():
	$ActionPointsLabel.text = AP_LABEL_FORMAT % [action_points]
	$HealthLabel.text = HEALTH_LABEL_FORMAT % [current_health, max_health]


