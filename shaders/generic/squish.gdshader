shader_type canvas_item;

#include "res://shaders/utils.gdshaderinc"

const float SQUISH_AMOUNT = 1.5;
const float SQUISH_SPEED = 5.0;

void vertex() {
	// Add 1.0 to make the expression always positive; since since is -1.0 to 1.0
	float squish = SQUISH_AMOUNT * (1.0 + sin(TIME * SQUISH_SPEED));
	
	// Move the top up/down
	if (VERTEX.y < 0.0)
	{
		VERTEX.y += squish;
	}
	
	// Move the left to the left
	if (VERTEX.x > 0.0)
	{
		VERTEX.x += squish;
	}
	
	// Move the right to the right
	if (VERTEX.x < 0.0)
	{
		VERTEX.x -= squish;
	}
}