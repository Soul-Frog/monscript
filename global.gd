extends Node

var RNG = RandomNumberGenerator.new()

# represents the result of a battle
enum BattleEndCondition {
	WIN, # the player on the battle
	LOSE, # the player lost the battle
	RUN, # player ran away from battle
	NONE # default/error condition; should be set before battle ends
}
