extends Node

enum CutsceneID {
	UNSET, INTRO_OLD, CAVE2_FIRST_BATTLE
}

var _ID_TO_CUTSCENE_MAP := {
	CutsceneID.INTRO_OLD : _CUTSCENE_INTRODUCTION_OLD,
	CutsceneID.CAVE2_FIRST_BATTLE : _CUTSCENE_CAVE2_FIRST_BATTLE
}

const _DIALOGUE_FILE = preload("res://dialogue/cutscene.dialogue")

# plays a cutscene with the given id in the given node 
# (usually an area, but can be the visual novel scene)
# note that for most cutscenes, this must be the correct area/scene.
func play_cutscene(id: CutsceneID, node: Node):
	assert(_ID_TO_CUTSCENE_MAP.has(id))
	assert(not GameData.cutscenes_played.has(id))
	
	if node is Area:
		node.PLAYER.enable_cutscene_mode()
	
	await _ID_TO_CUTSCENE_MAP[id].call(node)

	# mark that this cutscene has been played
	# for now, treat all cutscenes as oneshot; may need to add more flexability later
	GameData.cutscenes_played.append(id)

	if node is Area:
		node.PLAYER.disable_cutscene_mode()

func move_camera(camera: Camera2D, offset: Vector2, time: float) -> void:
	var cam_tween = create_tween()
	cam_tween.tween_property(camera, "position", camera.position + offset, time)
	await cam_tween.finished

func move_actor(actor, position) -> void:
	actor.move_to_point(position)
	await actor.reached_point

func _CUTSCENE_CAVE2_FIRST_BATTLE(area: Area) -> void:
	assert(area is Area and area.area_enum == GameData.Area.COOLANT_CAVE2_ENTRANCE)
	
	# add the overworld encounter
	var gelif = load("res://mons/gelif.tscn").instantiate()
	gelif.set_script(load("res://overworld/components/overworld_mons/overworld_mon.gd"))
	gelif.mon1Type = MonData.MonType.GELIF
	gelif.mon1Level = 0
	gelif.position = area.POINTS.find_child("CutsceneFirstBattleGelif").position
	area.OVERWORLD_ENCOUNTERS.call_deferred("add_child", gelif)
	
	await move_actor(area.PLAYER, area.POINTS.find_child("CutsceneFirstBattlePlayerBeforeBattle"))
	area.PLAYER.face_right()
	
	# create a bitleon and move him...
	var bitleon = load("res://mons/bitleon.tscn").instantiate()
	bitleon.position = area.PLAYER.position
	area.add_child(bitleon)
	await move_actor(bitleon, area.POINTS.find_child("CutsceneFirstBattleBitleon").position)
	bitleon.face_left()
	
	await Dialogue.play(_DIALOGUE_FILE, "cave2_first_battle_before_battle")
	
	await move_camera(area.CAMERA, Vector2(0, -50), 1.0)
	await Dialogue.play(_DIALOGUE_FILE, "cave2_first_battle_corrupted_mon")
	
	await move_actor(bitleon, area.POINTS.find_child("CutsceneFirstBattleGelif").position)
	Events.emit_signal("battle_started", gelif, gelif.mons)
	await Events.battle_ended
	await Global.delay(0.5)
	
	await Dialogue.play(_DIALOGUE_FILE, "cave2_first_battle_after_battle")
	
	
	move_camera(area.CAMERA, Vector2(0, 50), 1.0)
	await move_actor(bitleon, area.PLAYER.position)
	
	bitleon.queue_free()
	

#the introductory cutscnee in the visual novel node
#plays at the start of the game
func _CUTSCENE_INTRODUCTION_OLD(vn: Node):
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
	GameData.set_var(GameData.PLAYER_NAME, await vn.name_inputted)
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
