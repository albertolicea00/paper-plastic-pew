// Brush-ink inverted hull. Same contract as the core outline (ink, width) with
// two changes: flat faces push their corners out diagonally so box outlines
// close at the corners, and the line weight varies like a hand-inked stroke.
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 ink : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float width = 0.05;
// 0 = even line, 1 = line weight swings between 0 and 2 widths.
uniform float wobble = 0.3;

void vertex() {
	vec3 push = NORMAL;
	// Axis-aligned normal = box face (or a pole of a round mesh, where the
	// scaled position below is ~0 on the other axes and changes nothing).
	if (max(abs(NORMAL.x), max(abs(NORMAL.y), abs(NORMAL.z))) > 0.999) {
		push = clamp(VERTEX * 1000.0, vec3(-1.0), vec3(1.0));
	}
	float weight = 1.0 + wobble * sin(dot(VERTEX, vec3(7.3, 5.1, 9.7)) + 1.3);
	VERTEX += push * width * weight;
}

void fragment() {
	ALBEDO = ink.rgb;
}
