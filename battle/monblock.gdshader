shader_type canvas_item;

#include "res://shaders/utils.gdshaderinc"

// Replace all pixels matching white/lightgray/darkgray with...
const vec3 white = vec3(1.0, 1.0, 1.0);
const vec3 lightgray = vec3(224.0/255.0, 224.0/255.0, 224.0/255.0);
const vec3 darkgray = vec3(189.0/255.0, 189.0/255.0, 189.0/255.0);

// ...these colors
uniform vec3 white_replace = vec3(1.0, 0.0, 1.0);
uniform vec3 lightgray_replace = vec3(0.0, 1.0, 1.0);
uniform vec3 darkgray_replace = vec3(1.0, 1.0, 0.0);

void fragment() {
	if (vec3eq(COLOR.rgb, white)) {
		COLOR.rgb = white_replace;
	}
	
	if (vec3eq(COLOR.rgb, lightgray)) {
		COLOR.rgb = lightgray_replace;
	}
	
	if (vec3eq(COLOR.rgb, darkgray)) {
		COLOR.rgb = darkgray_replace;
	}
}