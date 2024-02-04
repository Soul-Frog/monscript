extends Node2D

# this node just holds this enum
# because of a Godot bug which makes it so I can't put it in CutscenePlayer
# because CutscenePlayer is a scene and not a script
# :( :( :(
enum ID {
	UNSET = 0, INTRO_OLD = 99999,
	CAVE1_INTRO = 1, 
	CAVE2_FIRST_BATTLE = 2,
	BATTLE_TUTORIAL_FIRST_BATTLE = 3,
	BATTLE_TUTORIAL_SPEED_AND_QUEUE = 4,
	CAVE4_LEVIATHAN_MEETING = 5,
	BATTLE_TUTORIAL_ESCAPE = 6,
	SCRIPT_TUTORIAL = 7,
	CAVE12_LEVIATHAN_BOSS = 8,
	BATTLE_LEVIATHAN_BOSS_INJECT = 9,
	CAVE4_POSTBOSS_DEBRIEF = 10,
	CAVE4_WIRE_TO_THE_CITY = 11
}
