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
	
	# open the initial dialogue
	vn.switch_subscene(vn.CLASSROOM_SCENE, false)
	vn.open_dialogue("classroom")
	await Dialogue.ended
	
	# switch the scene to the bus
	await vn.switch_subscene(vn.BUS_SCENE)
	vn.open_dialogue("bus")
	await Dialogue.ended
	
	# switch the scene to the classroom
	await vn.switch_subscene(vn.ROOM_SCENE)
	vn.open_dialogue("room")
	
	# wait for a the second click on the computer
	var msg: String = await Dialogue.dialogue_signal
	assert(msg == "examined computer twice")
	
	# switch to computer scene and now work on the game a bit
	await vn.switch_subscene(vn.COMPUTER_SCENE)
	vn.open_dialogue("work_on_game")
	await Dialogue.ended
	
	# TODO
	# open the playable game segment
	# gotta figure this shit out
	
	
	# switch back to room and wait until bed is examined for sleeping
	await vn.switch_subscene(vn.ROOM_SCENE)
	var msg2: String = await Dialogue.dialogue_signal
	assert(msg2 == "sleep")
	
	await vn.fade_out()
