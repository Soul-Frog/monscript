extends Node2D

signal _continue_tutorial

var _ID_TO_CUTSCENE_MAP := {
	Cutscene.ID.INTRO_OLD : _CUTSCENE_INTRODUCTION_OLD,
	Cutscene.ID.CAVE1_INTRO : _CUTSCENE_CAVE1_INTRO,
	Cutscene.ID.CAVE2_FIRST_BATTLE : _CUTSCENE_CAVE2_FIRST_BATTLE,
	Cutscene.ID.CAVE4_LEVIATHAN_MEETING : _CUTSCENE_CAVE4_LEVIATHAN_MEETING,
	Cutscene.ID.BATTLE_TUTORIAL_FIRST_BATTLE : _CUTSCENE_BATTLE_TUTORIAL_FIRST_BATTLE,
	Cutscene.ID.BATTLE_TUTORIAL_SPEED_AND_QUEUE : _CUTSCENE_BATTLE_TUTORIAL_SPEED_AND_QUEUE
}

const _DIALOGUE_FILE = preload("res://dialogue/cutscene.dialogue")
const _FADED_ALPHA = 0.6

@onready var _BLOCKER = $Blocker
@onready var _POPUPS = $Popup
@onready var _TOP_POPUP = $Popup/Top
@onready var _MIDDLE_POPUP = $Popup/Middle
@onready var _MONBLOCK_POPUP = $Popup/Monblock
@onready var _RESULTS_POPUP = $Popup/Results
@onready var _SPEED_POPUP = $Popup/Speed
@onready var _QUEUE_POPUP = $Popup/Queue

var _accepting_click = false
var _reset_z_map = {} # used by bring_to_front_z and reset_to_back_z

func _ready():
	assert(_BLOCKER)
	assert(_TOP_POPUP)
	assert(_MIDDLE_POPUP)
	assert(_MONBLOCK_POPUP)
	assert(_RESULTS_POPUP)
	_BLOCKER.modulate.a = 0.0
	_BLOCKER.hide()
	
	assert(_POPUPS)
	for popup in _POPUPS.get_children():
		popup.hide()

func _input(event) -> void: 
	if event is InputEventMouseButton and event.is_pressed() and _accepting_click:
		emit_signal("_continue_tutorial")

func _wait_for_click() -> void:
	_accepting_click = true
	await _continue_tutorial
	_accepting_click = false

func _fade_blocker_in() -> void:
	_BLOCKER.show()
	var tween = create_tween()
	tween.tween_property(_BLOCKER, "modulate:a", _FADED_ALPHA, 0.5)
	await tween.finished

func _fade_blocker_out() -> void:
	var tween = create_tween()
	tween.tween_property(_BLOCKER, "modulate:a", 0.0, 0.5)
	await tween.finished
	_BLOCKER.hide()

func _show_popup(popup: Container, text: String) -> void:
	popup.show()
	popup.modulate.a = 0
	
	var label = popup.find_child("Text")
	label.text = ""
	label.custom_minimum_size = Vector2.ZERO
	label.text = "[center]%s[/center]" % text
	
	var speaker = popup.find_child("Speaker")
	speaker.find_child("Mon").position = speaker.position + (speaker.size/2)
	
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 1.0, 0.3)
	await tween.finished

func _hide_popup(popup: Container) -> void:
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 0.3)
	await tween.finished
	popup.hide()

func _popup_and_wait(popup: Container, text: String) -> void:
	await _show_popup(popup, text)
	await _wait_for_click()
	await _hide_popup(popup)

func _bring_to_front_z(node: Node) -> void:
	assert(not _reset_z_map.has(node))
	_reset_z_map[node] = node.z_index
	node.z_index = z_index + 1

func _reset_to_normal_z(node: Node) -> void:
	assert(_reset_z_map.has(node))
	node.z_index = _reset_z_map[node]
	_reset_z_map.erase(node)

func _move_camera(camera: Camera2D, offset: Vector2, time: float) -> void:
	var cam_tween = create_tween()
	cam_tween.tween_property(camera, "position", camera.position + offset, time)
	await cam_tween.finished

func _move_actor(actor, point) -> void:
	assert(actor is PlayerOverhead or actor is MonScene)
	actor.move_to_point(point)
	await actor.reached_point

func _create_overworld_bitleon(area: Area) -> MonScene:
	var bitleon = load("res://mons/bitleon.tscn").instantiate()
	bitleon.position = area.PLAYER.position
	area.add_child(bitleon)
	bitleon.modulate.a = 0.0
	bitleon.z_index = area.PLAYER.z_index - 1
	create_tween().tween_property(bitleon, "modulate:a", 1.0, 0.1)
	return bitleon

func _delete_bitleon(bitleon: MonScene) -> void:
	var tween = create_tween()
	tween.tween_property(bitleon, "modulate:a", 0.0, 0.1)
	tween.tween_callback(bitleon.queue_free)
	await tween.finished

# plays a cutscene with the given id in the given node 
# (usually an area, but can be the visual novel scene)
# note that for most cutscenes, this must be the correct area/scene.
func play_cutscene(id: Cutscene.ID, node: Node):
	assert(_ID_TO_CUTSCENE_MAP.has(id))
	assert(not GameData.cutscenes_played.has(id))
	
	# could be either the overworld or a battle
	if node is Area:
		node.PLAYER.enable_cutscene_mode()
	
	await _ID_TO_CUTSCENE_MAP[id].call(node)

	# mark that this cutscene has been played
	# for now, treat all cutscenes as oneshot; may need to add more flexibility later
	GameData.cutscenes_played.append(id)

	if node is Area:
		node.PLAYER.disable_cutscene_mode()

### CUTSCENES ###

func _CUTSCENE_CAVE1_INTRO(area: Area) -> void:
	assert(area.area_enum == GameData.Area.COOLANT_CAVE1_BEACH)
	
	# create bitleon and place it
	var bitleon = _create_overworld_bitleon(area)
	bitleon.position = area.POINTS.find_child("CutsceneIntroBitleon").position
	bitleon.face_left()
	
	# put the player at spawn
	area.PLAYER.position = area.POINTS.find_child("PlayerSpawn").position
	#area.PLAYER.CAMERA.enabled = false
	area.PLAYER.face_right()
	
	await Dialogue.play(_DIALOGUE_FILE, "cave1_intro_start")
	
	# create the customization panel
	var customization = load("res://ui/customization/customization.tscn").instantiate()
	add_child(customization)
	customization.PANEL.modulate.a = 0.0
	create_tween().tween_property(customization.PANEL, "modulate:a", 1.0, 1.0)
	
	# wait for customization to be done
	await customization.customization_complete
	
	await create_tween().tween_property(customization.PANEL, "modulate:a", 0.0, 1.0).finished
	customization.queue_free()
	
	await TransitionPlayer.play(TransitionPlayer.Effect.SLOW_FADE_IN)
	await Global.delay(0.5)
	await Dialogue.play(_DIALOGUE_FILE, "cave1_intro_meet_bitleon")
	
	# move bitleon to cave entrance as it talks
	await _move_actor(bitleon, area.PLAYER.position)
	await _delete_bitleon(bitleon)

func _CUTSCENE_CAVE2_FIRST_BATTLE(area: Area) -> void:
	assert(area.area_enum == GameData.Area.COOLANT_CAVE2_ENTRANCE)
	
	# add the overworld encounter
	var gelif = load("res://mons/gelif.tscn").instantiate()
	gelif.set_script(load("res://overworld/components/overworld_mons/overworld_mon.gd"))
	gelif.mon1Type = MonData.MonType.GELIF
	gelif.mon1Level = 0
	gelif.position = area.POINTS.find_child("CutsceneFirstBattleGelif").position
	area.OVERWORLD_ENCOUNTERS.call_deferred("add_child", gelif)
	
	await _move_actor(area.PLAYER, area.POINTS.find_child("CutsceneFirstBattlePlayerBeforeBattle"))
	area.PLAYER.face_right()
	
	# create a bitleon and move him...
	var bitleon = _create_overworld_bitleon(area)
	await _move_actor(bitleon, area.POINTS.find_child("CutsceneFirstBattleBitleon").position)
	bitleon.face_left()
	
	await Dialogue.play(_DIALOGUE_FILE, "cave2_first_battle_before_battle")
	
	await _move_camera(area.CAMERA, Vector2(0, -50), 1.0)
	await Dialogue.play(_DIALOGUE_FILE, "cave2_first_battle_corrupted_mon")
	
	_move_camera(area.CAMERA, Vector2(0, 50), 1.0)
	await _move_actor(gelif, bitleon.position)
	GameData.queue_battle_cutscene(Cutscene.ID.BATTLE_TUTORIAL_FIRST_BATTLE)
	Events.emit_signal("battle_started", gelif, gelif.mons)
	await Events.battle_ended
	await Global.delay(0.5)
	
	await Dialogue.play(_DIALOGUE_FILE, "cave2_first_battle_after_battle")
	
	await _move_actor(bitleon, area.PLAYER.position)
	await _delete_bitleon(bitleon)

func _CUTSCENE_CAVE4_LEVIATHAN_MEETING(area: Area) -> void:
	assert(area.area_enum == GameData.Area.COOLANT_CAVE4_PLAZA)
	
	# add leviathan to the scene
	var leviathan = load("res://mons/leviathan.tscn").instantiate()
	leviathan.set_script(load("res://overworld/components/overworld_mons/overworld_mon.gd"))
	leviathan.mon1Type = MonData.MonType.LEVIATHAN
	leviathan.mon1Level = 5
	leviathan.position = area.POINTS.find_child("CutsceneLeviathan").position
	area.call_deferred("add_child", leviathan)
	
	await _move_actor(area.PLAYER, area.POINTS.find_child("CutscenePlayer"))
	area.PLAYER.face_left()
	
	# create a bitleon and move him...
	var bitleon = _create_overworld_bitleon(area)
	await _move_actor(bitleon, area.POINTS.find_child("CutsceneBitleon").position)
	bitleon.face_left()
	
	await _move_camera(area.CAMERA, Vector2(-80, 0), 0.5)
	
	#GameData.queue_battle_cutscene(Cutscene.ID.BATTLE_TUTORIAL_ESCAPE)
	Events.emit_signal("battle_started", leviathan, leviathan.mons)
	await Events.battle_ended
	await Global.delay(0.5)
	
	leviathan.queue_free()
	
	_move_camera(area.CAMERA, Vector2(80, 0), 0.5)
	await _move_actor(bitleon, area.PLAYER.position)
	await _delete_bitleon(bitleon)

func _CUTSCENE_BATTLE_TUTORIAL_FIRST_BATTLE(battle: Battle) -> void:
	# grab some necessary variables
	var results = battle._results
	var speed_controls = battle._speed_controls
	var player_mon_blocks = battle._player_mon_blocks
	var player_mons = battle._player_mons
	var computer_mon_blocks = battle._computer_mon_blocks
	var script_line_viewer = battle._script_line_viewer

	# set the speed for the tutorial scene
	battle._set_mon_speed(Battle.Speed.PAUSE_CUTSCENE)
	battle._set_label_speed(Battle.Speed.NORMAL)
	speed_controls.disable()
	
	await _fade_blocker_in()
	
	# introduction at start of battle
	await _popup_and_wait(_TOP_POPUP, "This is your first battle, right?\n[color=%s](click to continue)[/color]" % Color.LIGHT_YELLOW.to_html())
	await _popup_and_wait(_TOP_POPUP, "Don't worry, I can teach you the basics!")
	_bring_to_front_z(player_mon_blocks)
	await _popup_and_wait(_MONBLOCK_POPUP, "The green bar here is my health points, or HP for short.")
	await _popup_and_wait(_MONBLOCK_POPUP, "If I ever hit 0 HP, I'll be terminated. That would be... not good.")
	await _popup_and_wait(_MONBLOCK_POPUP, "This yellow bar is my action points, or AP!")
	await _popup_and_wait(_MONBLOCK_POPUP, "My AP bar fills up automatically. Once it's full, I get to take a turn.")
	await _popup_and_wait(_MONBLOCK_POPUP, "It might be easier for me to just show you.")
	await _fade_blocker_out()
	_reset_to_normal_z(player_mon_blocks)
	
	# wait for bitleons to attack
	battle._set_mon_speed(Battle.Speed.NORMAL)
	await battle.turn_ended
	battle._set_mon_speed(Battle.Speed.PAUSE_CUTSCENE)
	await _fade_blocker_in()
	await _popup_and_wait(_MIDDLE_POPUP, "Did you see that? I just attacked that Gelif!")
	# show the computer's damaged hp bar
	_bring_to_front_z(computer_mon_blocks)
	await _popup_and_wait(_MIDDLE_POPUP, "It's HP bar has taken damage, like you might expect.")
	_bring_to_front_z(script_line_viewer)
	await _popup_and_wait(_MIDDLE_POPUP, "You can see the script line I just executed, too.")
	await _popup_and_wait(_MIDDLE_POPUP, "What's a script? Uh...  don't worry about that.")
	await _popup_and_wait(_MIDDLE_POPUP, "You'll just have to wait for that part of the game to be explained later!")
	await _popup_and_wait(_MIDDLE_POPUP, "In the meantime... let's get back to the battling!")
	await _fade_blocker_out()
	_reset_to_normal_z(computer_mon_blocks)
	_reset_to_normal_z(script_line_viewer)
	
	# wait for bitleon to take a hit
	battle._set_mon_speed(Battle.Speed.NORMAL)
	await battle.turn_ended
	battle._set_mon_speed(Battle.Speed.PAUSE_CUTSCENE)
	await _fade_blocker_in()
	await _popup_and_wait(_MIDDLE_POPUP, "Ouch! That wasn't very nice...\nAre you getting the hang of this now?")
	await _popup_and_wait(_MIDDLE_POPUP, "Well, it should be pretty simple; you don't need to do anything at all!")
	await _popup_and_wait(_MIDDLE_POPUP, "So sit back, and I'll finish off this Gelif! Here I go!")
	await _fade_blocker_out()
	
	# hide the results continue button for now
	results._EXIT_BUTTON.modulate.a = 0.0
	results._EXIT_BUTTON.disabled = true
	
	# wait for the battle to end...
	battle._set_mon_speed(Battle.Speed.NORMAL)
	await results.shown
	results._granting_xp = false
	results._granting_decompile = false
	
	await _fade_blocker_in()
	await _popup_and_wait(_RESULTS_POPUP, "Did you see that?\nI won!")
	await _popup_and_wait(_RESULTS_POPUP, "After winning a battle, you'll get a few types of rewards!")
	
	# show the Xp and level up
	_bring_to_front_z(results.XP_PANEL)
	await _popup_and_wait(_RESULTS_POPUP, "First off, experience points, or XP! XP makes me stronger!")
	_bring_to_front_z(player_mon_blocks)
	_bring_to_front_z(player_mons)
	results._granting_xp = true
	await results.done_granting_xp
	await _popup_and_wait(_RESULTS_POPUP, "I leveled up! That increases my HP, ATK, DEF, and SPD!")
	_reset_to_normal_z(player_mon_blocks)
	_reset_to_normal_z(player_mons)
	_reset_to_normal_z(results.XP_PANEL)
	
	# show the Bits
	_bring_to_front_z(results.BITS_PANEL)
	await _popup_and_wait(_RESULTS_POPUP, "Next up, Bits! Bits are our local currency!")
	await _popup_and_wait(_RESULTS_POPUP, "...you do use Bits back where you came from, right?")
	_reset_to_normal_z(results.BITS_PANEL)
	
	# show decompile
	_bring_to_front_z(results.DECOMPILATION_PANEL)
	await _popup_and_wait(_RESULTS_POPUP, "Over here is decompilation progress.")
	await _popup_and_wait(_RESULTS_POPUP, "It's basically a measure of how much you know about this type of mon.") 
	await _popup_and_wait(_RESULTS_POPUP, "Once this bar is full, you can view  information about this mon in the Database!")
	results._granting_decompile = true
	await results.done_granting_decompile
	_reset_to_normal_z(results.DECOMPILATION_PANEL)
	
	# show bugs
	_bring_to_front_z(results.BUGS_PANEL)
	await _popup_and_wait(_RESULTS_POPUP, "And lastly, bugs! I'm not quite sure what these are good for yet...")
	await _popup_and_wait(_RESULTS_POPUP, "But it can't hurt to collect them, right?")
	_reset_to_normal_z(results.BUGS_PANEL)
	
	# show the full panel
	_bring_to_front_z(results)
	results._EXIT_BUTTON.disabled = false
	create_tween().tween_property(results._EXIT_BUTTON, "modulate:a", 1.0, 0.5)
	await _popup_and_wait(_RESULTS_POPUP, "And that's everything! Go ahead and press continue whenever you're ready.")
	await _fade_blocker_out()
	_reset_to_normal_z(results)
	
	assert(_reset_z_map.size() == 0)
	await _fade_blocker_out()
	speed_controls.enable()

func _CUTSCENE_BATTLE_TUTORIAL_SPEED_AND_QUEUE(battle: Battle):
	var speed_controls = battle._speed_controls
	var queue = battle._mon_action_queue

	battle._set_mon_speed(Battle.Speed.PAUSE_CUTSCENE)
	battle._set_label_speed(Battle.Speed.NORMAL)
	speed_controls.disable()
	
	GameData.set_var(GameData.BATTLE_SPEED_UNLOCKED, true)
	GameData.set_var(GameData.BATTLE_SHOW_QUEUE, true)
	
	await _fade_blocker_in()
	
	await _popup_and_wait(_TOP_POPUP, "Listen... I can tell you're thinking these fights are taking a bit too long.")
	
	# show the speed controls
	_bring_to_front_z(speed_controls)
	battle.slide_in_speed()
	# just for visuals, remove the disabled texture so it looks normal
	var run_disabled_tex = speed_controls._run_button.texture_disabled
	var pause_disabled_tex = speed_controls._pause_button.texture_disabled
	var speedup_disabled_tex = speed_controls._speedup_button.texture_disabled
	speed_controls._run_button.texture_disabled = null
	speed_controls._pause_button.texture_disabled = null
	speed_controls._speedup_button.texture_disabled = null
	await _popup_and_wait(_SPEED_POPUP, "If so, here you go! Speed controls!")
	
	# show the queue
	_bring_to_front_z(queue)
	battle.slide_in_queue()
	await _popup_and_wait(_QUEUE_POPUP, "And, while we're at it, here's an turn queue too!")
	await _popup_and_wait(_TOP_POPUP, "I'm pretty considerate, right?")
	await _popup_and_wait(_TOP_POPUP, "Try giving those speed buttons a press sometime!")
	
	await _fade_blocker_out()
	_reset_to_normal_z(speed_controls)
	_reset_to_normal_z(queue)
	
	# enable speed controlsadd back the disabled textures too
	speed_controls.enable()
	speed_controls._run_button.texture_disabled = run_disabled_tex
	speed_controls._pause_button.texture_disabled = pause_disabled_tex
	speed_controls._speedup_button.texture_disabled = speedup_disabled_tex
	
	assert(_reset_z_map.size() == 0)
	battle._set_speed(Battle.Speed.NORMAL)

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
