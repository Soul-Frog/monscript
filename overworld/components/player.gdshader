shader_type canvas_item;

#include "res://shaders/utils.gdshaderinc"

const vec3 HAIR_COLOR_LIGHT = vec3(0.36, 0.25, 0.21);
const vec3 HAIR_COLOR_DARK = vec3(0.24, 0.15, 0.14);
const vec3 EYE_COLOR = vec3(0.34, 0.46, 0.98);
const vec3 SHIRT_COLOR_LIGHT = vec3(0.91, 0.30, 0.25);
const vec3 SHIRT_COLOR_DARK = vec3(0.81, 0.09, 0.09);
const vec3 SKIN_COLOR_LIGHT = vec3(1.0, 0.67, 0.57);
const vec3 SKIN_COLOR_DARK = vec3(0.96, 0.60, 0.53);

uniform vec3 HAIR_RECOLOR_LIGHT = vec3(1.0, 0.5, 0.5);
uniform vec3 HAIR_RECOLOR_DARK = vec3(1.0, 0.1, 0.1);
uniform vec3 EYE_RECOLOR = vec3(0.1, 1.0, 1.0);
uniform vec3 SHIRT_RECOLOR_LIGHT = vec3(0.06, 0.7, 0.35);
uniform vec3 SHIRT_RECOLOR_DARK = vec3(0.5, 0.5, 0.5);
uniform vec3 SKIN_RECOLOR_LIGHT = vec3(0.25, 0.25, 1.0);
uniform vec3 SKIN_RECOLOR_DARK = vec3(0.1, 0.8, 0.6);

void fragment() {
	if(vec3eq(COLOR.rgb, HAIR_COLOR_LIGHT)) {
		COLOR.rgb = HAIR_RECOLOR_LIGHT;
	}
	if(vec3eq(COLOR.rgb, HAIR_COLOR_DARK)) {
		COLOR.rgb = HAIR_RECOLOR_DARK;
	}
	if(vec3eq(COLOR.rgb, EYE_COLOR)) {
		COLOR.rgb = EYE_RECOLOR;
	}
	
	if(vec3eq(COLOR.rgb, SHIRT_COLOR_LIGHT)) {
		COLOR.rgb = SHIRT_RECOLOR_LIGHT;
	}
	if(vec3eq(COLOR.rgb, SHIRT_COLOR_DARK)) {
		COLOR.rgb = SHIRT_RECOLOR_DARK;
	}
	
	if(vec3eq(COLOR.rgb, SKIN_COLOR_LIGHT)) {
		COLOR.rgb = SKIN_RECOLOR_LIGHT;
	}
	if(vec3eq(COLOR.rgb, SKIN_COLOR_DARK)) {
		COLOR.rgb = SKIN_RECOLOR_DARK;
	}
}