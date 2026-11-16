// Bullets: unshaded colour with a hot core and an ink rim, so both teams read
// on white paper as well as on dark walls. Drawn through a MultiMesh.
shader_type spatial;
render_mode unshaded;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 ink : source_color = vec4(0.07, 0.07, 0.1, 1.0);
uniform float rim = 0.5; // facing below this is ink
uniform float core = 0.88; // facing above this is the hot centre

void fragment() {
	float facing = dot(NORMAL, VIEW);
	vec3 tint = mix(ink.rgb, albedo.rgb, step(rim, facing));
	ALBEDO = mix(tint, mix(albedo.rgb, vec3(1.0), 0.75), step(core, facing));
}
