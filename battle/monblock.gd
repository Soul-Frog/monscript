extends NinePatchRect

@onready var name_label = $NameLabel
@onready var level_label = $LevelLabel
const LEVEL_FORMAT = "Lv%d"
@onready var health_bar = $HealthBar
@onready var action_bar = $ActionBar

var active_mon: BattleMon = null

func _ready():
	assert(name_label)
	assert(level_label)
	assert(health_bar)
	assert(action_bar)

# assign a new mon for this block to track
func assign_mon(mon: BattleMon) -> void:
	assert(active_mon == null)
	assert(mon != null)
	
	active_mon = mon
	
	# recolor this block using the mon's three colors
	material.set_shader_parameter("white_replace", mon.base_mon.get_colors()[0])
	material.set_shader_parameter("lightgray_replace", mon.base_mon.get_colors()[1])
	material.set_shader_parameter("darkgray_replace", mon.base_mon.get_colors()[2])
	
	# connect the new mon
	active_mon.connect("health_or_ap_changed", _on_mon_health_or_ap_changed)
	
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
	
	if active_mon.is_defeated():
		hide() # hide this control if the mon is defeated
