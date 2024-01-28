shader_type canvas_item;

const float SWAY_AMOUNT = 2.0;
const float SWAY_SPEED = 1.0;

void vertex() {
	if(VERTEX.y < 0.0)
	{
		VERTEX.x += SWAY_AMOUNT * sin(TIME * SWAY_SPEED);
	}
}