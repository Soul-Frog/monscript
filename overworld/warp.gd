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
	
	# connect to Overworld so it knows to change area when we signal
	var warpsNode = get_parent()
	assert(warpsNode.name == "Warps", "Warp must be a child of Warps!")
	var areaNode = warpsNode.get_parent()
	assert(areaNode.name == "Area", "Warp parent Warps must be a child of Area!")
	var overworldNode = areaNode.get_parent()
	assert(overworldNode.name == "Overworld", "Warp's parent Warps parent Area must be a child of Overworld!")
	self.change_area.connect(overworldNode._on_change_area)

func _on_body_entered(body):
	emit_signal("change_area", area, spawn_point)
