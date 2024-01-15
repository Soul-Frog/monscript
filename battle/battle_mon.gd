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
var _speed_scale = 1.0

# The underlying Mon Object this battle mon scene represents
# Set this with init_mon before doing anything else with this scene
var underlying_mon: MonData.Mon = null

# The name and color used for this mon's entries into the battle log
var log_name: String = ""
var log_color: Color = Color.BLACK
# Reference to the battle log
var battle_log: BattleLog
# Reference to the viewer used to display the running script line
var script_line_viewer: BattleScriptLineViewer

var team: Battle.Team

# current action points - increases by speed each tick
# when this reaches 100, signals to take a turn
var action_points := 50.0

# how many turns this mon has taken this battle
var turn_count := 0

var is_defending := false
var escaped_from_battle := false

# if the mon should skip trying to execute its script after moving forward
# used to prevent a mon from starting an animation if an inject is queued
var is_action_canceled := false

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

@onready var shake_animation_player = $ShakeAnimationPlayer
@onready var flash_animation_player = $FlashAnimationPlayer

# a dictionary that anything can be stored in that needs to be tracked
# for example, some moves will store information in here to use later
var metadata = {}

var _active_tweens = []
 
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

func _ready():
	assert(shake_animation_player)
	assert(flash_animation_player)

# Initializes this battle_mon with an underlying mon object
func init_mon(mon: MonData.Mon, monTeam: Battle.Team) -> void:
	underlying_mon = mon
	team = monTeam
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

func on_battle_start(pals: Array, foes: Array) -> void:
	if underlying_mon.has_passive(MonData.Passive.COURAGE):
		queue_passive_text(MonData.Passive.COURAGE)
		battle_log.add_text("%s feels Courageous!" % battle_log.MON_NAME_PLACEHOLDER, self)
		metadata[MonData.Passive.COURAGE] = true

# returns attack modified by buffs/debuffs
func get_attack() -> int:
	return _base_attack * _BUFF_STAGE_TO_MODIFIER[atk_buff_stage]

# returns defense modified by buffs/debuffs
func get_defense() -> int:
	return _base_defense * _BUFF_STAGE_TO_MODIFIER[atk_buff_stage]

# returns speed modified by buffs/debuffs
func get_speed() -> int:
	return _base_speed * _BUFF_STAGE_TO_MODIFIER[spd_buff_stage]

func get_base_speed() -> int:
	return _base_speed

# Called once for each mon by battle.gd at a regular time interval
func battle_tick(unscaled_delta: float, highest_speed: int, seconds_per_turn: float) -> void:
	var delta = unscaled_delta * _speed_scale
	assert(underlying_mon != null, "Didn't add a mon with init_mon!")
	assert(_base_attack != -1 and _base_speed != -1 and _base_defense != -1 and max_health != -1, "Stats were never initialized?")
	if not is_defeated():
		# amount of AP gained is (speed/highest_speed) * (AP_PER_TURN/seconds_per_turn) * delta
		var speed_multiplier = float(max(get_speed(), 1.0)) / float(highest_speed)
		var ap_per_second = ACTION_POINTS_PER_TURN/seconds_per_turn
		var ap_gained = speed_multiplier * ap_per_second * delta
		
		# update action points, clamp between 0-100
		set_action_points(clamp(action_points + ap_gained, 0.0, ACTION_POINTS_PER_TURN))
		
		if action_points >= ACTION_POINTS_PER_TURN:
			emit_signal("ready_to_take_action", self) # signal that it's time for this mon to act

func take_inject_action(friends: Array, foes: Array, animator: BattleAnimator, do_block: ScriptData.Block, target: BattleMon) -> void:
	assert(friends.size() != 0, "No friends?")
	assert(foes.size() != 0, "No foes?")
	
	# move forward
	var tween = create_tween()
	tween.tween_property(self, "position:x", position.x + (25 if team == Battle.Team.PLAYER else -25), 0.4).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	
	# perform the do
	await do_block.function.call(self, friends, foes, target, battle_log, animator)
	
	# move backwards
	tween = create_tween()
	tween.tween_property(self, "position:x", position.x - (25 if team == Battle.Team.PLAYER else -25), 0.4).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	
	finish_action()

# Take a single turn in battle
func take_action(friends: Array, foes: Array, animator: BattleAnimator, escaping: bool) -> void:
	assert(friends.size() != 0, "No friends?")
	assert(foes.size() != 0, "No foes?")
	is_defending = false
	
	# if we're asleep, just wake up and that's our turn
	if statuses[Status.SLEEP]:
		heal_status(Status.SLEEP)
		_on_turn_over()
		return
	
	# move forward,
	await _move_forward()
	
	# execute our action, if an inject wasn't inputted
	if is_action_canceled:
		set_action_points(0)
		await _move_backward() # move back to normal position
		finish_action()
	else:
		execute_script(friends, foes, animator, escaping)

func cancel_action():
	is_action_canceled = true

func execute_script(friends: Array, foes: Array, animator: BattleAnimator, escaping: bool):
	await underlying_mon.get_active_monscript().execute(self, friends, foes, battle_log, script_line_viewer, animator, escaping)
	_on_turn_over()

func set_action_points(points):
	action_points = points
	emit_signal("health_or_ap_changed")

func _on_turn_over():
	assert(action_points == 100.0 or not reset_AP_after_action)
	if reset_AP_after_action:
		set_action_points(0.0)
	reset_AP_after_action = true
	
	await _move_backward()
	
	script_line_viewer.hide_line()
	
	# after taking an action, if inflicted with leak, take 5% health as damage
	if statuses[Status.LEAK]:
		battle_log.add_text("%s is leaking memory!" % battle_log.MON_NAME_PLACEHOLDER, self)
		take_damage(max(ceil(max_health * 0.05), 1), MonData.DamageType.LEAK)
	
	finish_action()

func finish_action():
	if is_action_canceled:
		queue_text("[color=#%s]Cancel![/color]" % Color.INDIAN_RED.to_html()) # display Cancel!
	if not is_action_canceled:
		turn_count += 1
		
		if underlying_mon.has_passive(MonData.Passive.REGENERATE):
			queue_passive_text(MonData.Passive.REGENERATE)
			heal_damage(int(max_health * 0.05))
	
		if underlying_mon.has_passive(MonData.Passive.MODERNIZE) and turn_count == 5:
			queue_passive_text(MonData.Passive.MODERNIZE)
			metadata[MonData.Passive.MODERNIZE] = true 
			# TODO - MODERNIZE C++HORSE
	
	is_action_canceled = false
	
	emit_signal("action_completed")

func _move_forward():
	var tween = create_tween()
	_active_tweens.append(tween)
	tween.tween_property(self, "position:x", position.x + (25 if team == Battle.Team.PLAYER else -25), 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.set_speed_scale(_speed_scale)
	await tween.finished

func _move_backward():
	var tween = create_tween()
	_active_tweens.append(tween)
	tween.tween_property(self, "position:x", position.x - (25 if team == Battle.Team.PLAYER else -25), 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.set_speed_scale(_speed_scale)
	await tween.finished

func is_defeated() -> bool:
	assert(current_health >= 0, "Mon's health is somehow negative.")
	return current_health == 0

# apply an attack against this mon with a given attack value and damage multiplier
# this function factors in defense and defending
func apply_attack(attacker: BattleMon, ability_multiplier: float, damage_type: MonData.DamageType) -> void:
	# damage taken is ATK-DEF, to a minimum of 1
	var damage_taken = max(attacker.get_attack() - get_defense(), 1)
	
	## APPLY ABILITY MULTIPLIER ##
	# increase damage taken by attack multiplier
	damage_taken *= ability_multiplier
	
	## APPLY ELEMENTAL WEAKNESS/RESIST ##
	# now modify by resistances/weaknesses
	damage_taken *= underlying_mon.get_damage_multiplier_for_type(damage_type)
		
	## APPLY PASSIVES ##
	var passive_multiplier = 1.0
	
	# check for passives on this mon
	if metadata.has(MonData.Passive.COURAGE):
		assert(metadata[MonData.Passive.COURAGE])
		passive_multiplier -= 0.5 # courage makes this mon take 50% less damage

	# check for passives on the attacking mon
	if attacker.metadata.has(MonData.Passive.COURAGE):
		assert(attacker.metadata[MonData.Passive.COURAGE])
		passive_multiplier += 0.5 # courage on attacker makes attack deal 50% more
	if attacker.metadata.has(MonData.Passive.MODERNIZE):
		assert(attacker.metadata[MonData.Passive.MODERNIZE])
		passive_multiplier += 0.5 # modernize on attacker makes attack deal 50% more
	if attacker.underlying_mon.has_passive(MonData.Passive.EXPLOIT) and statuses[BattleMon.Status.LEAK]:
		passive_multiplier += 0.3 # exploit on attacker against LEAK target makes attack deal 30% more
		attacker.queue_passive_text(MonData.Passive.EXPLOIT)
	
	damage_taken *= max(0, passive_multiplier)
	
	## APPLY DEFENDING MULTIPLIER ##
	# if defending, reduce the damage taken by half
	if is_defending:
		damage_taken /= 2.0
	
	## ADDITIONAL CONSTANT MODIFIERS ##
	# apply an additional constant modifier based on defense buff stage and attacker attack stage;
	# example: if our def stage is -1 and attacker's attack stage is 4, we take an additional flat 3 damage
	# example2: if our def stage is 4 and attacker's attack stage if -3, we reduce damage taken by a flat 7
	damage_taken += attacker.atk_buff_stage - def_buff_stage
	
	# apply a further flat bonus/deduction for hitting a weakness/resist
	if underlying_mon.get_damage_multiplier_for_type(damage_type) > 1:
		damage_taken += 1 # add a further flat bonus when striking a weakness
	elif underlying_mon.get_damage_multiplier_for_type(damage_type) < 1:
		damage_taken -= 1 # add a further flat bonus when striking a weakness
	
	# deal a minimum of 1 damage
	damage_taken = max(damage_taken, 1)
	
	take_damage(damage_taken, damage_type)
	
	## PASSIVES AFTER ATTACK ##
	if attacker.underlying_mon.has_passive(MonData.Passive.PIERCER) and Global.RNG.randi_range(0, 3) == 0:
		# 25% chance to lower defense
		attacker.queue_passive_text(MonData.Passive.PIERCER)
		apply_stat_change(BattleMon.BuffableStat.DEF, -1)
	
	if current_health != 0:
		if underlying_mon.has_passive(MonData.Passive.THORNS):
			#reflect some damage back to attacker and maybe LEAK
			attacker.take_damage(max(1, int(damage_taken * 0.05)), MonData.DamageType.TYPELESS)
			if Global.RNG.randi_range(0, 2) == 0:
				attacker.inflict_status(BattleMon.Status.LEAK)
			queue_passive_text(MonData.Passive.THORNS)
		

# deals damage to a mon
# ignores defense and defending
# generally, don't call this directly in attack blocks, call apply_attack instead
func take_damage(damage_taken: int, damage_type: MonData.DamageType) -> void:
	current_health -= damage_taken
	current_health = max(current_health, 0)
	
	var type_str = ""
	var damage_color = Global.COLOR_WHITE
	var flash_color = "white"
	match(damage_type):
		MonData.DamageType.HEAT:
			type_str = "Heat "
			damage_color = Global.COLOR_RED
			flash_color = "red"
		MonData.DamageType.CHILL:
			type_str = "Chill "
			damage_color = Global.COLOR_LIGHT_BLUE
			flash_color = "blue"
		MonData.DamageType.VOLT:
			type_str = "Volt "
			damage_color = Global.COLOR_YELLOW
			flash_color = "yellow"
		MonData.DamageType.LEAK:
			damage_color = Global.COLOR_PURPLE
			flash_color = "purple"
	flash(flash_color) # flash color based on the type of damage taken
	shake() # make the damaged mon shake a bit
	
	var log_message = "%s took %d %sdamage!"
	if underlying_mon.get_damage_multiplier_for_type(damage_type) > 1:
		log_message = "%s took %d %sdamage! Super effective!"
	elif underlying_mon.get_damage_multiplier_for_type(damage_type) < 1:
		log_message = "%s took %d %sdamage! Not very effective!"
	battle_log.add_text(log_message % [battle_log.MON_NAME_PLACEHOLDER, damage_taken, type_str], self)
	
	# make damage numbers
	self.add_child(
		MOVING_TEXT_SCENE.instantiate()
		.offset(Vector2(0, 0)).tx(damage_taken).direction_up().speed(20, _speed_scale).time(0.4).color(damage_color))
	
	if current_health == 0:
		# check for passive endure effects
		if underlying_mon.has_passive(MonData.Passive.BOURNE_AGAIN) and not metadata.has(MonData.Passive.BOURNE_AGAIN):
			current_health = int(max_health * 0.1)
			queue_passive_text(MonData.Passive.BOURNE_AGAIN)
			metadata[MonData.Passive.BOURNE_AGAIN] = true #mark that we've done this so it doesn't happen again
			battle_log.add_text("%s endured the attack!" % battle_log.MON_NAME_PLACEHOLDER, self)
		else:
			set_action_points(0)
			create_tween().tween_property(self, "modulate:a", 0.0, 0.25)
			emit_signal("zero_health", self)
	
	emit_signal("health_or_ap_changed")

var _ability_text_queue = []
var _ability_text = null

func _on_ability_text_finished():
	_ability_text = null
	if _ability_text_queue.size() != 0:
		_show_ability_text(_ability_text_queue.pop_front())

func _show_ability_text(text: String):
	_ability_text = MOVING_TEXT_SCENE.instantiate().offset(Vector2(0, -9)).tx(text).direction_up().speed(20, _speed_scale).time(0.22)
	_ability_text.deleted.connect(_on_ability_text_finished)
	self.add_child(_ability_text)

func queue_passive_text(passive: MonData.Passive) -> void:
	queue_text(MonData.get_passive_name(passive) + "!")

func queue_text(text: String) -> void:
	if _ability_text == null:
		_show_ability_text(text)
	else:
		_ability_text_queue.append(text)

func shake() -> void:
	shake_animation_player.seek(0) #restart shake
	shake_animation_player.play("shake")

func flash(color: String) -> void:
	flash_animation_player.seek(0)
	flash_animation_player.play("flash_%s" % color)

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
		.tx(heal_amt).direction_up().speed(20, _speed_scale).time(0.4).color(Global.COLOR_GREEN))
	
	# make self glow green for a sec
	flash_animation_player.seek(0)
	flash_animation_player.play("flash_green")

func inflict_status(status: Status) -> void:
	# only display inflicted message if don't actually have this status
	match status:
		Status.LEAK:
			if not statuses[status]:
				battle_log.add_text("%s has a memory leak!" % battle_log.MON_NAME_PLACEHOLDER, self)
				flash("purple")
				emit_signal("status_changed", status, true)
			else:
				pass
				#battle_log.add_text("%s is already leaking memory!" % battle_log.MON_NAME_PLACEHOLDER, self)
		Status.SLEEP:
			if not statuses[status]:
				battle_log.add_text("%s has been put to sleep!" % battle_log.MON_NAME_PLACEHOLDER, self)
				emit_signal("status_changed", status, true)
			else:
				pass
				#battle_log.add_text("%s is already asleep!" % battle_log.MON_NAME_PLACEHOLDER, self)
		_:
			assert(false, "No message for status!")
			
	statuses[status] = true

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
	
	# make self glow green for a sec
	flash_animation_player.seek(0)
	flash_animation_player.play("flash_green")

func heal_all_statuses() -> void:
	for status in statuses.keys():
		statuses[status] = false
	flash_animation_player.seek(0)
	flash_animation_player.play("flash_green")

# apply a buff/debuff
func apply_stat_change(stat: BuffableStat, mod: int):
	assert(mod != 0)
	assert(mod <= 4 and mod >= -4)
	
	var stat_str = ""
	var show_log_text = false
	match stat:
		BuffableStat.ATK:
			var prev_atk = atk_buff_stage
			atk_buff_stage = clamp(atk_buff_stage + mod, MIN_DEBUFF_STAGE, MAX_BUFF_STAGE)
			if atk_buff_stage != prev_atk:
				show_log_text = true
				stat_str = "ATK"
		BuffableStat.DEF:
			var prev_def = def_buff_stage
			def_buff_stage = clamp(def_buff_stage + mod, MIN_DEBUFF_STAGE, MAX_BUFF_STAGE)
			if def_buff_stage != prev_def:
				show_log_text = true
				stat_str = "DEF"
		BuffableStat.SPD:
			var prev_spd = spd_buff_stage
			spd_buff_stage = clamp(spd_buff_stage + mod, MIN_DEBUFF_STAGE, MAX_BUFF_STAGE)
			if spd_buff_stage != prev_spd:
				show_log_text = true
				stat_str = "SPD"
	
	if show_log_text:
		battle_log.add_text("%s's %s was %s!" % [battle_log.MON_NAME_PLACEHOLDER, stat_str, "increased" if mod > 0 else "decreased"], self)
	
	# TODO - EFFECT
	
	emit_signal("stats_changed")

func set_speed_scale(speed_scale: float) -> void:
	_speed_scale = speed_scale

	var invalid_tweens = []
	for tween in _active_tweens:
		if not tween.is_valid():
			invalid_tweens.append(tween)
			continue
		tween.set_speed_scale(speed_scale)
	
	for invalid_tween in invalid_tweens:
		_active_tweens.erase(invalid_tween)
	
	shake_animation_player.speed_scale = speed_scale
	flash_animation_player.speed_scale = speed_scale
