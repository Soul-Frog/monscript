extends DialogueInteractable

@export var chest_id := "NULL" # A unique identifier for this chest, used for persistence

func _ready():
	assert(chest_id != "NULL")
	super()
	
	# check if this chest has been opened before, if so, open it and mark it as opened
	if GameData.get_var(chest_id):
		_SPRITE.play("opened")

func _on_interact():
	if not GameData.get_var(chest_id):
		# change our animation to opened chest
		_SPRITE.play("opened")
		
		# record that this chest has been opened in GameData.
		GameData.set_var(chest_id, true)
		
		# show dialogue
		super()
