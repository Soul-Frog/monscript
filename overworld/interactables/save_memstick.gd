extends DialogueInteractable

func _on_interact():
	_SPRITE.play("saving")
	
	GameData.save_game()
	
	super() #show dialogue
	await DialogueManager.dialogue_ended
	
	_SPRITE.play("rise")
	await _SPRITE.animation_finished
	_SPRITE.play("idle")
