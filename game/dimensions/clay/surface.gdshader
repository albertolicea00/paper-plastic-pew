// Hand-sculpted plasticine: wrapped matte light, warm shadows, thumb dents,
// fingerprint ridges and a surface that "boils" on stepped frames like
// re-touched stop-motion puppets. Fully procedural, no texture lookups.
shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
// 0 = static set piece, 1 = re-sculpted every frame (puppets).
uniform float boil : hint_range(0.0, 1.0) = 0.0;
uniform float boil_fps = 10.0;
// Vertex wobble in metres; small so the look still matches shared hitboxes.
uniform float lump = 0.018;
uniform float lump_scale = 2.6;
// Strength of dents and fingerprints in the shading normal.
uniform float bump : hint_range(0.0, 2.0) = 1.0;
uniform float dent_scale = 1.3;
uniform float print_scale = 26.0;
uniform float wrap : hint_range(0.0, 1.0) = 0.45;
uniform vec4 warmth : source_color = vec4(0.92, 0.42, 0.28, 1.0);
uniform float sheen : hint_range(0.0, 1.0) = 0.22;
// Self-lit amount, for bullets and pickups that must read on any floor.
uniform float glow = 0.0;

varying vec3 clay_pos;
varying vec3 clay_normal;
varying vec3 clay_seed;

float hash13(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// Value noise with analytic gradient: x = value 0..1, yzw = gradient.
vec4 noise_d(vec3 x) {
	vec3 i = floor(x);
	vec3 w = fract(x);
	vec3 u = w * w * (3.0 - 2.0 * w);
	vec3 du = 6.0 * w * (1.0 - w);
	float a = hash13(i);
	float b = hash13(i + vec3(1.0, 0.0, 0.0));
	float c = hash13(i + vec3(0.0, 1.0, 0.0));
	float d = hash13(i + vec3(1.0, 1.0, 0.0));
	float e = hash13(i + vec3(0.0, 0.0, 1.0));
	float f = hash13(i + vec3(1.0, 0.0, 1.0));
	float g = hash13(i + vec3(0.0, 1.0, 1.0));
	float h = hash13(i + vec3(1.0, 1.0, 1.0));
	float k1 = b - a;
	float k2 = c - a;
	float k3 = e - a;
	float k4 = a - b - c + d;
	float k5 = a - c - e + g;
	float k6 = a - b - e + f;
	float k7 = -a + b + c - d + e - f - g + h;
	return vec4(a + k1 * u.x + k2 * u.y + k3 * u.z + k4 * u.x * u.y + k5 * u.y * u.z + k6 * u.z * u.x + k7 * u.x * u.y * u.z,
		du * vec3(k1 + k4 * u.y + k6 * u.z + k7 * u.y * u.z, k2 + k5 * u.z + k4 * u.x + k7 * u.z * u.x, k3 + k6 * u.x + k5 * u.y + k7 * u.x * u.y));
}

void vertex() {
	// Quantised clock: the whole surface is re-seeded a few times per second.
	float frame = floor(TIME * boil_fps);
	clay_seed = boil * (vec3(hash13(vec3(frame, 1.7, 9.2)), hash13(vec3(4.1, frame, 2.3)), hash13(vec3(7.9, 3.3, frame))) - 0.5) * 9.0;
	// Displace by a field of the position, not along the normal, so the
	// split vertices of box edges move together and stay watertight.
	vec3 q = VERTEX * lump_scale + clay_seed;
	VERTEX += vec3(sin(q.y * 1.7 + q.z * 1.3), sin(q.z * 1.9 + q.x * 1.1 + 2.0), sin(q.x * 1.5 + q.y * 1.2 + 4.0)) * lump;
	clay_pos = VERTEX;
	clay_normal = NORMAL;
}

void fragment() {
	vec3 p = clay_pos + clay_seed;
	vec4 dents = noise_d(p * dent_scale);
	vec4 lumps = noise_d(p * dent_scale * 3.1 + 11.0);
	// Fingerprints only where a thumb pressed: patches of warped ridges.
	float press = smoothstep(0.5, 0.72, dents.x);
	float ridge = dot(p, vec3(0.61, 0.52, 0.6)) * print_scale + lumps.x * 5.0;
	vec3 slope = dents.yzw * 0.55 + lumps.yzw * 0.3 + vec3(0.61, 0.52, 0.6) * cos(ridge) * press * 0.25;
	vec3 normal = normalize(clay_normal);
	// Keep only the part of the slope that lies in the surface.
	slope -= normal * dot(slope, normal);
	normal = normalize(normal - slope * bump * 0.5);
	NORMAL = normalize((VIEW_MATRIX * vec4(MODEL_NORMAL_MATRIX * normal, 0.0)).xyz);
	// Marbled pigment and darker pressed-in cavities.
	float mottle = dents.x * 0.6 + lumps.x * 0.4;
	vec3 tone = albedo.rgb * (0.9 + 0.18 * mottle);
	tone *= 1.0 - press * (0.5 - 0.5 * sin(ridge)) * 0.12 * bump;
	ALBEDO = tone;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = albedo.rgb * glow;
}

void light() {
	float facing = dot(NORMAL, LIGHT);
	float wrapped = clamp((facing + wrap) / (1.0 + wrap), 0.0, 1.0);
	// Light bleeding through soft clay: the terminator and cast shadows
	// pick up a warm tint instead of going grey.
	vec3 scatter = mix(warmth.rgb, vec3(1.0), smoothstep(0.0, 0.6, wrapped));
	float shade = mix(0.2, 1.0, ATTENUATION);
	DIFFUSE_LIGHT += LIGHT_COLOR * wrapped * mix(warmth.rgb, scatter, ATTENUATION) * shade / PI;
	// Broad waxy sheen instead of a highlight.
	vec3 halfway = normalize(LIGHT + VIEW);
	float gloss = pow(max(dot(NORMAL, halfway), 0.0), 7.0);
	float rim = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.0) * wrapped;
	SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * (gloss + rim * 0.6) * sheen / PI;
}
