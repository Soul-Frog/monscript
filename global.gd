extends Node

var RNG = RandomNumberGenerator.new()

# change this to turn debug tool (debug_tool.tscn) functionality on/off
var DEBUG_TOOL_ACTIVE = true

# represents the result of a battle
enum BattleEndCondition {
	WIN, # the player on the battle
	LOSE, # the player lost the battle
	RUN, # player ran away from battle
	NONE # default/error condition; should be set before battle ends
}
