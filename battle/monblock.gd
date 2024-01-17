extends NinePatchRect

@onready var name_label = $NameLabel
@onready var level_label = $LevelLabel
const LEVEL_FORMAT = "Lv%d"

@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/HealthLabel
@onready var action_bar = $ActionBar
const HEALTH_FORMAT = "%d/%d"

@onready var action_label = $ActionBar/ActionLabel
const ACTION_FORMAT = "%d/%d"

@onready var xp_bar = $XPBar
@onready var xp_label = $XPBar/XPLabel
const XP_FORMAT = "%d/%d"

@onready var status_icon = $StatusIcon
@onready var stat_arrows = $StatsArrows

var active_mon: BattleMon = null

var _full_ap_color = Color(255.0/255.0, 58.0/255.0, 50.0/255.0, 1)

func _ready():
	assert(name_label)
	assert(level_label)
	assert(health_bar)
	assert(action_bar)
	assert(status_icon)
	assert(stat_arrows)
	assert(xp_bar)
	assert(xp_label)
	_switch_to_battle_mode()

# assign a new mon for this block to track
func assign_mon(mon: BattleMon) -> void:
	assert(active_mon == null)
	assert(mon != null)
	
	active_mon = mon
	
	status_icon.reset()
	stat_arrows.reset()
	
	# recolor this block using the mon's three colors
	material.set_shader_parameter("white_replace", mon.underlying_mon.get_colors()[0])
	material.set_shader_parameter("lightgray_replace", mon.underlying_mon.get_colors()[1])
	material.set_shader_parameter("darkgray_replace", mon.underlying_mon.get_colors()[2])
	
	# connect the new mon
	active_mon.connect("health_or_ap_changed", _on_mon_health_or_ap_changed)
	active_mon.connect("status_changed", status_icon.on_status_changed)
	active_mon.connect("stats_changed", _on_mon_stats_changed)
	
	# update name and level label
	name_label.text = active_mon.underlying_mon.get_name()
	level_label.text = LEVEL_FORMAT % active_mon.underlying_mon.get_level()
	
	# update health/ap bars
	action_bar.max_value = active_mon.ACTION_POINTS_PER_TURN
	health_bar.max_value = active_mon.max_health
	_on_mon_health_or_ap_changed()
	modulate.a = 1.0
	
	on_mon_xp_changed()
	
	_switch_to_battle_mode()

func remove_mon() -> void:
	active_mon = null
	modulate.a = 0.0

func _on_mon_health_or_ap_changed() -> void:
	assert(active_mon)
	action_bar.value = active_mon.action_points
	action_bar.tint_progress = _full_ap_color if action_bar.value == action_bar.max_value else Color.WHITE
	health_bar.value = active_mon.current_health
	
	action_label.text = ACTION_FORMAT % [action_bar.value, action_bar.max_value]
	health_label.text = HEALTH_FORMAT % [health_bar.value, health_bar.max_value]
	
	if active_mon.is_defeated():
		create_tween().tween_property(self, "modulate:a", 0.0, 0.2)

func _on_mon_stats_changed() -> void:
	stat_arrows.on_stats_changed(active_mon)

func _switch_to_battle_mode() -> void:
	health_bar.show()
	action_bar.show()
	xp_bar.hide()

func switch_to_results_mode() -> void:
	health_bar.hide()
	action_bar.hide()
	xp_bar.show()

func on_mon_xp_changed() -> void:
	assert(active_mon)
	
	var mon := active_mon.underlying_mon as MonData.Mon
	
	var current_xp = mon.get_current_XP()
	var next_level_xp = MonData.XP_for_level(mon.get_level() + 1)
	
	xp_label.text = XP_FORMAT % [current_xp, next_level_xp]
	# multiply by 100 here to create a more gradually filling bar
	xp_bar.max_value = next_level_xp * 100 #do max before value
	xp_bar.value = current_xp * 100
	
	# also update the level here in case it's changed
	level_label.text = LEVEL_FORMAT % active_mon.underlying_mon.get_level()
