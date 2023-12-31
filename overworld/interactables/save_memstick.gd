extends DialogueInteractable

func _on_interact():
	_SPRITE.play("saving")
	
	GameData.inject_points = GameData.get_var(GameData.MAX_INJECTS) * GameData.POINTS_PER_INJECT
	
	GameData.save_game()
	
	super() #show dialogue
	await DialogueManager.dialogue_ended
	
	_SPRITE.play("rise")
	await _SPRITE.animation_finished
	_SPRITE.play("idle")
