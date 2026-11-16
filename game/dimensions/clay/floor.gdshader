// Rolled clay slabs on the set table: world-space mottling, rolling-pin
// streaks, shallow thumb dents and a pressed bevel around every checker tile.
// Static (the set is not re-sculpted between frames), no texture lookups.
shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float bump : hint_range(0.0, 2.0) = 1.0;
uniform float dent_scale = 0.55;
// Width in metres of the rounded tile edge.
uniform float bevel = 0.16;
uniform float wrap : hint_range(0.0, 1.0) = 0.45;
uniform vec4 warmth : source_color = vec4(0.92, 0.42, 0.28, 1.0);
uniform float sheen : hint_range(0.0, 1.0) = 0.12;

varying vec3 world_pos;
varying vec2 half_size;

float hash12(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

// 2D value noise with analytic gradient: x = value 0..1, yz = gradient.
vec3 noise_d(vec2 x) {
	vec2 i = floor(x);
	vec2 w = fract(x);
	vec2 u = w * w * (3.0 - 2.0 * w);
	vec2 du = 6.0 * w * (1.0 - w);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return vec3(a + (b - a) * u.x + (c - a) * u.y + (a - b - c + d) * u.x * u.y,
		du * (vec2(b - a, c - a) + (a - b - c + d) * u.yx));
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// The four corners of an unsubdivided plane all sit at the half extent,
	// so this interpolates to a constant: the slab size without a uniform.
	half_size = abs(VERTEX.xz);
}

void fragment() {
	vec2 p = world_pos.xz;
	vec3 dents = noise_d(p * dent_scale);
	vec3 lumps = noise_d(p * dent_scale * 4.3 + 17.0);
	// Rolling pin passes: long soft streaks along X.
	vec3 streak = noise_d(vec2(p.x * 0.12, p.y * 1.9) + 5.0);
	vec2 slope = dents.yz * 0.5 + lumps.yz * 0.22 + vec2(0.0, streak.z) * 0.25;
	// Distance in metres to the nearest edge of this slab.
	vec2 to_edge = (0.5 - abs(UV - 0.5)) * 2.0 * half_size;
	vec2 round_off = 1.0 - smoothstep(0.0, bevel, to_edge);
	vec2 outward = sign(UV - 0.5) * round_off * round_off;
	float seam = max(round_off.x, round_off.y);
	vec3 normal = normalize(vec3(-slope.x * bump * 0.3 + outward.x * 0.9, 1.0, -slope.y * bump * 0.3 + outward.y * 0.9));
	NORMAL = normalize((VIEW_MATRIX * vec4(normal, 0.0)).xyz);
	float mottle = dents.x * 0.5 + lumps.x * 0.25 + streak.x * 0.25;
	ALBEDO = albedo.rgb * (0.88 + 0.22 * mottle) * (1.0 - seam * 0.3);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float facing = dot(NORMAL, LIGHT);
	float wrapped = clamp((facing + wrap) / (1.0 + wrap), 0.0, 1.0);
	vec3 scatter = mix(warmth.rgb, vec3(1.0), smoothstep(0.0, 0.6, wrapped));
	// Cast shadows stay warm and soft, never black: gameplay reads through.
	float shade = mix(0.2, 1.0, ATTENUATION);
	DIFFUSE_LIGHT += LIGHT_COLOR * wrapped * mix(warmth.rgb, scatter, ATTENUATION) * shade / PI;
	vec3 halfway = normalize(LIGHT + VIEW);
	SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * pow(max(dot(NORMAL, halfway), 0.0), 7.0) * sheen / PI;
}
