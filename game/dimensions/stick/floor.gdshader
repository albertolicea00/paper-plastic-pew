// The page: pale paper with a faint graph-paper grid in world space, heavier
// every few lines like a notebook margin. The shared floor/floor_alt checker
// survives only as a barely-there tint (it rides in `albedo`). Lines are
// anti-aliased with fwidth so they thin out at the top-down distance instead of
// shimmering. A sliver of the colour is handed to the light so props and
// characters drop a soft shadow onto the page. No screen or depth reads.
shader_type spatial;
render_mode ambient_light_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 ink : source_color = vec4(0.18, 0.29, 0.52, 1.0); // graph-line blue
uniform float cell = 1.0;        // grid pitch in world units
uniform float line = 0.022;      // line half-width in world units
uniform float major = 5.0;       // every Nth line is heavier
uniform float line_fade = 0.42;  // opacity of the thin lines
uniform float grain = 0.02;      // paper fibre
uniform float shade_floor = 0.84; // colour kept flat; the rest casts shadow

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Coverage of the nearest grid line along both axes, at pitch `p`, width `w`.
float grid_lines(vec2 at, float p, float w, float soft) {
	vec2 d = abs(fract(at / p) - 0.5) * p;
	return 1.0 - smoothstep(w, w + soft, min(d.x, d.y));
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 at = world_pos.xz;
	float soft = fwidth(at.x) + fwidth(at.y);
	float minor = grid_lines(at, cell, line, soft) * line_fade;
	float heavy = grid_lines(at, cell * major, line * 1.5, soft);
	float grid = max(minor, heavy);
	float fibre = (hash(floor(at * 24.0)) - 0.5) * grain;
	vec3 paper = albedo.rgb + fibre;
	vec3 col = mix(paper, ink.rgb, grid);
	EMISSION = col * shade_floor;
	ALBEDO = col * (1.0 - shade_floor);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	DIFFUSE_LIGHT += vec3(smoothstep(0.4, 0.6, ATTENUATION) * step(0.0, dot(NORMAL, LIGHT)));
}
