// Hand-drawn ink line: the core inverted hull, but the stroke weight wobbles
// along its length in world space, so every edge reads as a pen line pressed
// harder here and lighter there instead of a machined offset. Stickman is the
// one dimension where the outline IS the drawing, so it is worth its own shader.
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 ink : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float width = 0.055;
uniform float wobble : hint_range(0.0, 1.0) = 0.4; // pen-pressure variation

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Two out-of-phase waves so the thick/thin pattern never looks periodic.
	float w = sin(wp.y * 8.3 + wp.x * 6.1) * 0.5 + sin(wp.x * 12.7 - wp.z * 4.9) * 0.5;
	VERTEX += NORMAL * width * (1.0 + wobble * w);
}

void fragment() {
	ALBEDO = ink.rgb;
}
