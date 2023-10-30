extends Area2D

# the area that should be loaded when hitting this warp
@export var area = GameData.Area.NONE
# where in that area the player should be spawned
@export var spawn_point = ""

signal change_area

func _ready():
	assert(area != GameData.Area.NONE, "Did not set destination for transition!")
	assert(spawn_point.length() != 0, "Did not set spawn point for transition!")
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	Events.emit_signal("area_changed", area, spawn_point, false)
