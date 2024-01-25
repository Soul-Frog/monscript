extends Node2D

# this node just holds this enum
# because of a Godot bug which makes it so I can't put it in CutscenePlayer
# because CutscenePlayer is a scene and not a script
# :( :( :(
enum ID {
	UNSET, INTRO_OLD, 
	CAVE2_FIRST_BATTLE,
	BATTLE_TUTORIAL_FIRST_BATTLE
}
