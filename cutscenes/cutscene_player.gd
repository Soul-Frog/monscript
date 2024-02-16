extends Node2D

signal _clicked

var _ID_TO_CUTSCENE_MAP := {
	Cutscene.ID.INTRO_OLD : _CUTSCENE_INTRODUCTION_OLD,
	Cutscene.ID.CAVE1_INTRO : _CUTSCENE_CAVE1_INTRO,
	Cutscene.ID.CAVE2_FIRST_BATTLE : _CUTSCENE_CAVE2_FIRST_BATTLE,
	Cutscene.ID.CAVE4_LEVIATHAN_MEETING : _CUTSCENE_CAVE4_LEVIATHAN_MEETING,
	Cutscene.ID.BATTLE_TUTORIAL_FIRST_BATTLE : _CUTSCENE_BATTLE_TUTORIAL_FIRST_BATTLE,
	Cutscene.ID.BATTLE_TUTORIAL_SPEED_AND_QUEUE : _CUTSCENE_BATTLE_TUTORIAL_SPEED_AND_QUEUE,
	Cutscene.ID.BATTLE_TUTORIAL_ESCAPE : _CUTSCENE_BATTLE_TUTORIAL_ESCAPE,
	Cutscene.ID.SCRIPT_TUTORIAL : _CUTSCENE_SCRIPT_TUTORIAL,
	Cutscene.ID.CAVE12_LEVIATHAN_BOSS : _CUTSCENE_CAVE12_LEVIATHAN_BOSS,
	Cutscene.ID.BATTLE_LEVIATHAN_BOSS_INJECT : _CUTSCENE_BATTLE_LEVIATHAN_BOSS_INJECT,
	Cutscene.ID.CAVE4_POSTBOSS_DEBRIEF : _CUTSCENE_CAVE4_POSTBOSS_DEBRIEF,
	Cutscene.ID.CAVE4_WIRE_TO_THE_CITY : _CUTSCENE_CAVE4_WIRE_TO_THE_CITY
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
		emit_signal("_clicked")

func _wait_for_click() -> void:
	_accepting_click = true
	await _clicked
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

func _move_actor(actor, point: Vector2) -> void:
	assert(actor is PlayerOverhead or actor is MonScene or actor is NPC)
	actor.move_to_point(point)
	await actor.reached_point

func _create_overworld_bitleon(area: Area) -> MonScene:
	var bitleon = load("res://mons/bitleon.tscn").instantiate()
	bitleon.position = area.PLAYER.position
	area.call_deferred("add_child", bitleon)
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
	
	await _move_actor(area.PLAYER, area.POINTS.find_child("CutsceneFirstBattlePlayerBeforeBattle").position)
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
	leviathan.set_animation("submerged")
	leviathan.modulate.a = 0.0
	leviathan.disable_collisions()
	area.call_deferred("add_child", leviathan)
	
	# fetch the red hat, create a bitleon
	var red_hat = area.get_entity("RedHat")
	var bitleon = _create_overworld_bitleon(area)

	# move player and bitleon towards corruption, then talk
	_move_actor(area.PLAYER, area.POINTS.find_child("CutscenePlayerCorruption").position)
	await _move_actor(bitleon, area.POINTS.find_child("CutsceneBitleonCorruption").position)
	await Dialogue.play(_DIALOGUE_FILE, "cave4_bitleon_sees_corruption")
	
	# leviathan emerges! move everyone towards leviathan and talk
	await create_tween().tween_property(leviathan, "modulate:a", 1.0, 0.5).finished
	_move_actor(area.PLAYER, area.POINTS.find_child("CutscenePlayerLeviathan").position)
	_move_actor(red_hat, area.POINTS.find_child("CutsceneRedHatLeviathan").position)
	await _move_actor(bitleon, area.POINTS.find_child("CutsceneBitleonLeviathan").position)
	await Dialogue.play(_DIALOGUE_FILE, "cave4_leviathan_pre_fight")
	await _move_actor(bitleon, area.POINTS.find_child("CutsceneBitleonAttack").position)
	
	# fight!
	#GameData.queue_battle_cutscene(Cutscene.ID.BATTLE_TUTORIAL_ESCAPE)
	Events.emit_signal("battle_started", leviathan, leviathan.mons)
	await Events.battle_ended
	await Global.delay(0.5)
	
	# todo - actually make everyone back off a bit
	
	Dialogue.play(_DIALOGUE_FILE, "cave4_leviathan_post_fight")
	await Dialogue.dialogue_signal # fade leviathan mid dialogue
	var tween = create_tween()
	tween.tween_property(leviathan, "modulate:a", 0.0, 0.5)
	tween.tween_callback(leviathan.queue_free)
	await Dialogue.dialogue_ended
	
	# remove bitleon
	await _move_actor(bitleon, area.PLAYER.position)
	await _delete_bitleon(bitleon)

func _CUTSCENE_CAVE12_LEVIATHAN_BOSS(area: Area) -> void:
	assert(area.area_enum == GameData.Area.COOLANT_CAVE12_BOSSROOM)
	# todo - add leviathan to the scene
	# todo - create a bitleon
	# todo - move player and bitleon towards leviathan
	await Dialogue.play(_DIALOGUE_FILE, "cave12_leviathan_pre_fight")
	# todo - fight leviathan!
	# todo - leviathan defeated animation
	await Dialogue.play(_DIALOGUE_FILE, "cave12_leviathan_post_fight")
	# todo - remove bitleon

func _CUTSCENE_CAVE4_POSTBOSS_DEBRIEF(area: Area) -> void:
	assert(area.area_enum == GameData.Area.COOLANT_CAVE4_PLAZA)
	await Dialogue.play(_DIALOGUE_FILE, "cave4_debrief")

func _CUTSCENE_CAVE4_WIRE_TO_THE_CITY(area: Area) -> void:
	assert(area.area_enum == GameData.Area.COOLANT_CAVE4_PLAZA)
	await Dialogue.play(_DIALOGUE_FILE, "cave4_wire_to_the_city")

func _CUTSCENE_SCRIPT_TUTORIAL(script: UIScriptMenu) -> void:
	'''
	
	Block out files, make it an unlockable
Block out the drawer at the start
----------


Red Hat - 
"Alright, so here we have Bitleon's Script."
Bitleon - "Wow! It's like I'm looking at the inside of my brain!"
Red Hat - "Hmm, I thought it would be even emptier."
"Anyway, during battle, a mon chooses what actions to perform based on their Script."
"A Script contains Lines. Lines contain Blocks."
"It looks like this Script contains one Line, which is made up of two Blocks."
"This Line says that during Bitleon's turns, they will do an attack to a random foe."
Bitleon - "This script is awesome! I just keep attacking!"

"And the most part, that works. But as you saw with L3V14TH4N, this strategy has a few flaws."
Bitlone - "Impossible! ...but go on."
"Each mon has a different special action only they can use."
"Bitleon's special action is Self-Repair, which heals them."
Bitleon - "Whaaaat? I didn't even know I could do that!"
Red Hat - "How have you managed to survive this long...?"
"Let's go ahead modify this Script so that Bitleon uses Self-Repair when low on health."

"First, we'll need to add a new Line."
"Click the plus button here to add a new Line." (highlight +)

"Now that we have a Line, we need to add some Blocks."
"Down here is the Block drawer, which contains all the Blocks you have so far."
"Here, I'll give you a new one."
"(Obtained IfSelfLowHP)" (updates drawer with new block)

"This is an IF Block. IF Blocks are triggered when their condition is met."
"In this case, IfSelfLowHP will trigger if Bitleon's HP is below 30%."
Bitleon - "Psh, like that'll ever happen!"
Red Hat - "Bitleon, did you already forget that last fight...?"
"Click on the Block to pick it up." (highlight)
(after clicking)
"Now that you're holding the Block, click on the highlighted area in the Line to place it."

"Nice job. Next, we'll add the Self-Repair DO Block."
"This way, when the condition of being low on health is met, Bitleon performs the Self-Repair action."
"Click on the DO tab to switch drawers." (highlight)
"Now, click on the Self-Repair Block to pick it up." (highlight)
"Lastly, drop it into the Line after the IF Block."
"And that's it for this Line!"
Bitleon - "Hey, why doesn't this Line have a TO Block like the other one?"
"Good question for once, Bitleon!"
"In this case, a TO Block isn't necessary since Self-Repair doesn't require a target."
"Self-Repair always heals just Bitleon."

Bitleon - "Alright, I feel ready to fight some mons!"
"Wait! There's still a small issue with this Script!"
"Right now, the Script will never check the second line. 
It will always just do an attack."
"Try moving that second line up above the first line."
"Click the line number to pick up the line." (prompt)
"Now click the space above the first line."
"So what we've done here is made it so that if Bitleon is low on HP, 
it will perform a Self-Repair."
"If it is not low on HP, it will go to the next Line in the Script instead."
"Think of your Script like a checklist which always reads from top to bottom."
"Is Bitleon's HP low? If it is, Bitleon heals with Self-Repair. 
If not, the Script goes to the next Line and Bitleon attacks a random foe."

Bitleon - "Awesome! Now my script is perfect! I'll never lose!"
"...This script is alright for now, but don't get too cocky."
"If you find any new blocks while exploring, try modifying your Script!"
"Anyway, that's all you need to know for now."
"If you want more details, come chat with me. I'll be right here at the beach."
"Now get out there and take down L3V14TH4N!"



(Questions for afterwards)
Q: Can you tell me more about the structure of a script?
A Script contains Lines. 
A Line can start with an IF Block or a DO Block.
An IF Block always leads into a DO Block.
And a DO Block can lead into a TO BLock, if the DO Block need a target.

Q: What determines which Line executes when my Script runs?
When a Script runs, the Lines are evaluated from top to bottom.
The first line evaluated with a true IF Block condition is executed.
If the Script reached a Line that does not have an IF Block, that Line is always executed.
Only one Line will be executed each time the Script runs.
If the end of the Script is reached and no Lines were executed, a script error occurs.
When a script error occurs, the mon simply skips their turn.

Q: How do I get more blocks?
You'll just find them while exploring!
Chests, for example, can sometimes contain blocks. 
You might also be able to buy them from certain mons.
I think that Pascalican over here is looking to sell one. 

	'''
	
	pass

func _CUTSCENE_BATTLE_TUTORIAL_ESCAPE(battle: Battle) -> void:
	pass

func _CUTSCENE_BATTLE_LEVIATHAN_BOSS_INJECT(battle: Battle) -> void:
	pass

func _CUTSCENE_BATTLE_TUTORIAL_FIRST_BATTLE(battle: Battle) -> void:
	# disable tooltips for this battle
	UITooltip.disable_tooltips()
	
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
	await _popup_and_wait(_TOP_POPUP, "This is your first battle, right?\n[color=%s](click to continue)[/color]" % Color.GOLD.to_html())
	await _popup_and_wait(_TOP_POPUP, "Don't worry, I can teach you the basics!")
	_bring_to_front_z(player_mon_blocks)
	await _popup_and_wait(_MONBLOCK_POPUP, "The green bar here is my health points, or HP for short.")
	await _popup_and_wait(_MONBLOCK_POPUP, "If I ever hit 0 HP, I'll be terminated. That would be... NOT good!")
	await _popup_and_wait(_MONBLOCK_POPUP, "This yellow bar is my action points, or AP!")
	await _popup_and_wait(_MONBLOCK_POPUP, "My AP bar fills up automatically. Once it's full, I get to take my turn!")
	await _popup_and_wait(_MONBLOCK_POPUP, "Here we go!")
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
	await _popup_and_wait(_MIDDLE_POPUP, "See how much damage I did?")
	_bring_to_front_z(script_line_viewer)
	await _popup_and_wait(_MIDDLE_POPUP, "You can see the script line I just executed up there too.")
	await _popup_and_wait(_MIDDLE_POPUP, "What's a script? Uh...  more on that later.")
	await _popup_and_wait(_MIDDLE_POPUP, "Now let's get back to the battle!")
	await _fade_blocker_out()
	_reset_to_normal_z(computer_mon_blocks)
	_reset_to_normal_z(script_line_viewer)
	
	# wait for bitleon to take a hit
	battle._set_mon_speed(Battle.Speed.NORMAL)
	await battle.turn_ended
	battle._set_mon_speed(Battle.Speed.PAUSE_CUTSCENE)
	await _fade_blocker_in()
	await _popup_and_wait(_MIDDLE_POPUP, "Ouch! That wasn't very nice!")
	await _popup_and_wait(_MIDDLE_POPUP, "I'm gonna take you down!")
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
	await _popup_and_wait(_RESULTS_POPUP, "Yay! Victory is mine!")
	await _popup_and_wait(_RESULTS_POPUP, "And look, we got some rewards!")
	
	# show the Xp and level up
	_bring_to_front_z(results.XP_PANEL)
	await _popup_and_wait(_RESULTS_POPUP, "First off, experience points, or XP! XP makes me stronger!")
	_bring_to_front_z(player_mon_blocks)
	_bring_to_front_z(player_mons)
	results._granting_xp = true
	await results.done_granting_xp
	await _popup_and_wait(_RESULTS_POPUP, "I leveled up! That increases my HP, ATK, DEF, and SPD!")
	await _popup_and_wait(_RESULTS_POPUP, "HP is the amount of damage I can take.")
	await _popup_and_wait(_RESULTS_POPUP, "ATK increases the damage I deal.")
	await _popup_and_wait(_RESULTS_POPUP, "DEF decreases the damage I take.")
	await _popup_and_wait(_RESULTS_POPUP, "And SPD makes my AP bar fill up faster.")
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
	await _popup_and_wait(_RESULTS_POPUP, "Down here is the decompilation progress.")
	await _popup_and_wait(_RESULTS_POPUP, "These bars show how much data you've collected on this type of mon.") 
	await _popup_and_wait(_RESULTS_POPUP, "Once the bar is full, you can view info about that mon in your Database...")
	await _popup_and_wait(_RESULTS_POPUP, "...and word on the wire is you could even make your own copy of it, but that's just a rumor! ")
	results._granting_decompile = true
	await results.done_granting_decompile
	_reset_to_normal_z(results.DECOMPILATION_PANEL)
	
	# show bugs
	_bring_to_front_z(results.BUGS_PANEL)
	await _popup_and_wait(_RESULTS_POPUP, "And lastly, bugs! Mmm... delicious bugs.")
	await _popup_and_wait(_RESULTS_POPUP, "If we come across a campsite, I'll show you to fry 'em up!")
	_reset_to_normal_z(results.BUGS_PANEL)
	
	# show the full panel
	_bring_to_front_z(results)
	results._EXIT_BUTTON.disabled = false
	create_tween().tween_property(results._EXIT_BUTTON, "modulate:a", 1.0, 0.5)
	await _popup_and_wait(_RESULTS_POPUP, "And that's everything! Go ahead and press continue whenever you're ready.")
	await _fade_blocker_out()
	_reset_to_normal_z(results)
	
	assert(_reset_z_map.size() == 0)
	speed_controls.enable()
	
	UITooltip.enable_tooltips()

func _CUTSCENE_BATTLE_TUTORIAL_SPEED_AND_QUEUE(battle: Battle) -> void:
	var speed_controls = battle._speed_controls
	var queue = battle._mon_action_queue

	battle._set_mon_speed(Battle.Speed.PAUSE_CUTSCENE)
	battle._set_label_speed(Battle.Speed.NORMAL)
	speed_controls.disable()
	
	GameData.set_var(GameData.BATTLE_SPEED_UNLOCKED, true)
	GameData.set_var(GameData.BATTLE_SHOW_QUEUE, true)
	
	await _fade_blocker_in()
	
	await _popup_and_wait(_TOP_POPUP, "Hey, you wanna speed things up a bit?")
	
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
	await _popup_and_wait(_SPEED_POPUP, "Check this out! Speed controls!")
	
	# show the queue
	_bring_to_front_z(queue)
	battle.slide_in_queue()
	await _popup_and_wait(_QUEUE_POPUP, "And, while we're at it, here's an turn queue too!")
	await _popup_and_wait(_TOP_POPUP, "Pretty nifty, right?")
	await _popup_and_wait(_TOP_POPUP, "Try giving these speed buttons a press sometime!")
	
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
