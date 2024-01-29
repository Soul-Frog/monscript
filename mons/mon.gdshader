shader_type canvas_item;

#include "res://shaders/utils.gdshaderinc"

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_modifier : hint_range(0.0, 1.0);

uniform bool apply_recolor = false;
const vec3 BITLEON_COLOR1 = vec3(0.96, 0.60, 0.53);
const vec3 BITLEON_COLOR2 = vec3(0.95, 0.42, 0.38);
const vec3 BITLEON_COLOR3 = vec3(0.91, 0.30, 0.25);
const vec3 BITLEON_COLOR4 = vec3(0.89, 0.11, 0.14);
const vec3 BITLEON_COLOR5 = vec3(0.69, 0.07, 0.04);
uniform vec3 BITLEON_RECOLOR1 = vec3(1.0, 0.0, 0.0);
uniform vec3 BITLEON_RECOLOR2 = vec3(0.0, 1.0, 0.0);
uniform vec3 BITLEON_RECOLOR3 = vec3(0.0, 0.0, 1.0);
uniform vec3 BITLEON_RECOLOR4 = vec3(0.5, 0.5, 0.0);
uniform vec3 BITLEON_RECOLOR5 = vec3(0.75, 0.0, 0.75);

void fragment() {
	vec3 flash = mix(COLOR.rgb, flash_color.rgb, flash_modifier);
	COLOR.rgb = flash;
	
	if (apply_recolor)
	{
		if (vec3eq(COLOR.rgb, BITLEON_COLOR1))
		{
			COLOR.rgb = BITLEON_RECOLOR1;
		}
		else if (vec3eq(COLOR.rgb, BITLEON_COLOR2))
		{
			COLOR.rgb = BITLEON_RECOLOR2;
		}
		else if (vec3eq(COLOR.rgb, BITLEON_COLOR3))
		{
			COLOR.rgb = BITLEON_RECOLOR3;
		} 
		else if (vec3eq(COLOR.rgb, BITLEON_COLOR4))
		{
			COLOR.rgb = BITLEON_RECOLOR4;
		} 
		else if (vec3eq(COLOR.rgb, BITLEON_COLOR5))
		{
			COLOR.rgb = BITLEON_RECOLOR5;
		}
	}
}
