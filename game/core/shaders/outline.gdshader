// Inverted-hull ink outline, attached as next_pass of a pack surface material.
shader_type spatial;
render_mode unshaded, cull_front;
uniform vec4 ink : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float width = 0.03;
void vertex() {
	VERTEX += NORMAL * width;
}
void fragment() {
	ALBEDO = ink.rgb;
}
