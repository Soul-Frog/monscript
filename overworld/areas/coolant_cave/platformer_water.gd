# water used in the platformer view
# the Water area is used to tell when the player is in the water
# the Topwater area is used to check when the water is at the top of the water
# when in the Topwater, the player's jump is increased
extends Node

@onready var WATER = $Water
@onready var TOPWATER = $Topwater

func _ready():
	assert(WATER)
	assert(WATER.get_child_count() != 0)
	assert(TOPWATER)
	assert(TOPWATER.get_child_count() != 0)
	
	# set up connections for water
	if WATER.body_entered.get_connections().size() == 0:
		WATER.body_entered.connect(_on_water_body_entered)
	if WATER.body_exited.get_connections().size() == 0:
		WATER.body_exited.connect(_on_water_body_exited)
	
	# set up connections for topwater
	if TOPWATER.body_entered.get_connections().size() == 0:
		TOPWATER.body_entered.connect(_on_topwater_body_entered)
	if TOPWATER.body_exited.get_connections().size() == 0:
		TOPWATER.body_exited.connect(_on_topwater_body_exited)

func _on_water_body_entered(body):
	if body is PlayerPlatformer:
		body.notify_entered_water()

func _on_water_body_exited(body):
	if body is PlayerPlatformer:
		body.notify_exited_water()

func _on_topwater_body_entered(body):
	if body is PlayerPlatformer:
		body.notify_entered_topwater()

func _on_topwater_body_exited(body):
	if body is PlayerPlatformer:
		body.notify_exited_topwater()
