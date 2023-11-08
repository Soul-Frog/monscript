# An interactable which triggers an area transition when interacted with
extends Interactable

# the area that should be loaded when hitting this warp
@export var area = GameData.Area.NONE
# where in that area the player should be spawned
@export var spawn_point = ""

func _ready():
	super()
	assert(area != GameData.Area.NONE, "Did not set destination for transition!")
	assert(spawn_point.length() != 0, "Did not set spawn point for transition!")
	if $Sprite.sprite_frames == null:
		$Sprite.queue_free()

func _on_interact():
	Events.emit_signal("area_changed", area, spawn_point, false)
