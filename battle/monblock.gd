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
@onready var status_icon = $StatusIcon
@onready var stat_arrows = $StatsArrows

var active_mon: BattleMon = null

func _ready():
	assert(name_label)
	assert(level_label)
	assert(health_bar)
	assert(action_bar)
	assert(status_icon)
	assert(stat_arrows)

# assign a new mon for this block to track
func assign_mon(mon: BattleMon) -> void:
	assert(active_mon == null)
	assert(mon != null)
	
	active_mon = mon
	
	status_icon.reset()
	stat_arrows.reset()
	
	# recolor this block using the mon's three colors
	material.set_shader_parameter("white_replace", mon.base_mon.get_colors()[0])
	material.set_shader_parameter("lightgray_replace", mon.base_mon.get_colors()[1])
	material.set_shader_parameter("darkgray_replace", mon.base_mon.get_colors()[2])
	
	# connect the new mon
	active_mon.connect("health_or_ap_changed", _on_mon_health_or_ap_changed)
	active_mon.connect("status_changed", status_icon.on_status_changed)
	active_mon.connect("stats_changed", _on_mon_stats_changed)
	
	# update name and level label
	name_label.text = active_mon.base_mon.get_name()
	level_label.text = LEVEL_FORMAT % active_mon.base_mon.get_level()
	
	# update health/ap bars
	action_bar.max_value = active_mon.ACTION_POINTS_PER_TURN
	health_bar.max_value = active_mon.max_health
	_on_mon_health_or_ap_changed()
	show()

func remove_mon() -> void:
	active_mon = null
	hide()

func _on_mon_health_or_ap_changed() -> void:
	action_bar.value = active_mon.action_points
	health_bar.value = active_mon.current_health
	
	action_label.text = ACTION_FORMAT % [action_bar.value, action_bar.max_value]
	health_label.text = HEALTH_FORMAT % [health_bar.value, health_bar.max_value]
	
	if active_mon.is_defeated():
		hide() # hide this control if the mon is defeated
	
func _on_mon_stats_changed() -> void:
	stat_arrows.on_stats_changed(active_mon)
