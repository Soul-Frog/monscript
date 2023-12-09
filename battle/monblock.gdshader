shader_type canvas_item;

// Replace all pixels matching white/lightgray/darkgray with...
const vec3 white = vec3(1.0, 1.0, 1.0);
const vec3 lightgray = vec3(224.0/255.0, 224.0/255.0, 224.0/255.0);
const vec3 darkgray = vec3(189.0/255.0, 189.0/255.0, 189.0/255.0);

// ...these colors
uniform vec3 white_replace = vec3(1.0, 0.0, 1.0);
uniform vec3 lightgray_replace = vec3(0.0, 1.0, 1.0);
uniform vec3 darkgray_replace = vec3(1.0, 1.0, 0.0);

// checks if two values are 'equal' (within EPSILON of each other)
// necessary when doing float calculations since it's not perfectly precise
const float EPSILON = 0.001;
bool equals(float val1, float val2) {
	return val1 >= val2 - EPSILON && val1 <= val2 + EPSILON;
}

void fragment() {
	if (equals(COLOR.r, white.r) && equals(COLOR.b, white.b) && equals(COLOR.g, white.g) && COLOR.a != 0.0) {
		COLOR = vec4(vec3(white_replace.r, white_replace.g, white_replace.b), 1.0);
	}
	
	if (equals(COLOR.r, lightgray.r) && equals(COLOR.b, lightgray.b) && equals(COLOR.g, lightgray.g) && COLOR.a != 0.0) {
		COLOR = vec4(vec3(lightgray_replace.r, lightgray_replace.g, lightgray_replace.b), 1.0);
	}
	
	if (equals(COLOR.r, darkgray.r) && equals(COLOR.b, darkgray.b) && equals(COLOR.g, darkgray.g) && COLOR.a != 0.0) {
		COLOR = vec4(vec3(darkgray_replace.r, darkgray_replace.g, darkgray_replace.b), 1.0);
	}
}