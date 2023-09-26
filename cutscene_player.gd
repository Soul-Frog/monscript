extends Node

enum CutsceneID {
	INTRO
}

var _ID_TO_CUTSCENE_MAP := {
	CutsceneID.INTRO : _CUTSCENE_INTRODUCTION
}

# plays a cutscene with the given id in the given node 
# (usually an area, but can be the visual novel scene)
# note that for most cutscenes, this must be the correct area/scene.
func play_cutscene(id: CutsceneID, node: Node):
	assert(_ID_TO_CUTSCENE_MAP.has(id))
	await _ID_TO_CUTSCENE_MAP[id].call(node)

#the introductory cutscnee in the visual novel node
#plays at the start of the game
func _CUTSCENE_INTRODUCTION(vn: Node):
	assert(vn is VisualNovel)

	# open the initial dialogue in classroom
	vn.switch_subscene(vn.CLASSROOM_SCENE, false)
	vn.open_dialogue("classroom")
	await vn.dialogue_completed

	# switch the scene to the bus stop
	await vn.switch_subscene(vn.BUS_STOP_SCENE)
	vn.open_dialogue("bus_stop")
	await vn.dialogue_completed

	# switch the scene to the bus
	await vn.switch_subscene(vn.BUS_SCENE)
	vn.open_dialogue("bus")
	await vn.dialogue_completed

	# switch the scene to the room
	await vn.switch_subscene(vn.ROOM_SCENE)
	vn.open_dialogue("room")
	await vn.dialogue_completed

	# wait for a the second click on the computer
	var msg: String = await Dialogue.dialogue_signal
	assert(msg == "examined computer twice")
	await vn.dialogue_completed

	# Get name from player
	vn.open_dialogue("login1")
	await vn.dialogue_completed
	vn.display_name_input()
	GameData.PLAYER_NAME = await vn.name_inputted
	vn.hide_name_input()
	vn.open_dialogue("login2")
	await vn.dialogue_completed

	# switch background to IDE
	await vn.switch_subscene(vn.COMPUTER_SCENE)
	vn.open_dialogue("work_on_game")
	await vn.dialogue_completed

	# open the badgame and play dialogue...
	vn.BADGAME_SCENE.disable()
	vn.BADGAME_SCENE.update_name()
	await vn.switch_subscene(vn.BADGAME_SCENE)
	vn.open_dialogue("badgame1")
	await vn.dialogue_completed
	vn.BADGAME_SCENE.enable()

	# wait for the player to fall once
	await vn.BADGAME_SCENE.fallen
	vn.BADGAME_SCENE.disable()
	vn.open_dialogue("badgame2")
	var chk = await Dialogue.dialogue_signal #fancy reset mid conversation
	assert(chk == "reset")
	vn.BADGAME_SCENE.reset()
	await vn.dialogue_completed
	vn.BADGAME_SCENE.enable()

	# wait for the second fall
	await vn.BADGAME_SCENE.fallen
	vn.open_dialogue("badgame3")
	await vn.dialogue_completed
	vn.BADGAME_SCENE.reset()

	# let the player fall a few times.
	for i in 3:
		await vn.BADGAME_SCENE.fallen
		if i == 0: #play text on the first fall here
			vn.open_dialogue("badgame4")
			await vn.dialogue_completed
		vn.BADGAME_SCENE.reset()
	
	vn.BADGAME_SCENE.bug_out() #make the scene flip out some graphically
	
	await vn.BADGAME_SCENE.fallen
	vn.open_dialogue("badgame5")
	await vn.dialogue_completed
	vn.BADGAME_SCENE.reset()

	# let the player fall a few times in the buggy scene
	var times_to_fall = 3
	for i in times_to_fall:
		await vn.BADGAME_SCENE.fallen
		if i != times_to_fall-1:
			vn.BADGAME_SCENE.reset()
	#start displaying errors, and we're done
	vn.BADGAME_SCENE.start_displaying_errors()
	vn.open_dialogue("badgame6")
	await vn.dialogue_completed
	
	# switch back to room, play some text
	await vn.switch_subscene(vn.ROOM_SCENE)
	vn.open_dialogue("post_badgame")
	# wait for bed to be examined
	var msg2: String = await Dialogue.dialogue_signal
	assert(msg2 == "sleep")
	await vn.fade_out()
	await vn.dialogue_completed
