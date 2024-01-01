shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_modifier : hint_range(0.0, 1.0);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	color.rgb = mix(color.rgb, flash_color.rgb, flash_modifier);
	// I have no idea why I need to do this to make alpha work correctly
	COLOR.r = color.r;
	COLOR.g = color.g;
	COLOR.b = color.b;
}
