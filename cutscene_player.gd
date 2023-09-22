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
	vn._open_dialogue("start")
	
	# wait for the classroom dialogue to end
	var msg1: String = await DialogueIO.dialogue_signal
	assert(msg1 == "end classroom") # safety assert
	
	# switch the scene to the bus
	await vn._switch_subscene(vn.BUS_SCENE)
	
	# wait for the user to examine the window
	var msg2: String = await DialogueIO.dialogue_signal
	assert(msg2 == "examined window") # safety assert
	
	await vn.fade_out()
