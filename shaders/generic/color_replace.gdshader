shader_type canvas_item;

#include "res://shaders/utils.gdshaderinc"

const vec3 REPLACED_COLOR = vec3(0.91, 0.3, 0.25);
const vec3 REPLACEMENT_COLOR = vec3(0.5, 0.5, 1.0);

void fragment() {
	if(vec3eq(COLOR.rgb, REPLACED_COLOR))
	{
		COLOR.rgb = REPLACEMENT_COLOR;
	}
}