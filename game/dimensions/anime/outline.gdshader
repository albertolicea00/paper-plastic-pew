// Inverted-hull ink line with brush weight: heavier underneath and away from
// the light, lighter where the light hits, like a G-pen stroke.
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 ink : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float width = 0.03;
uniform vec3 heavy = vec3(0.35, -0.75, 0.55); // world direction of the thick side
uniform float weight = 0.45; // 0 = uniform line

void vertex() {
	vec3 world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
	float side = dot(world_normal, normalize(heavy));
	VERTEX += NORMAL * width * (1.0 + side * weight);
}

void fragment() {
	ALBEDO = ink.rgb;
}
