// Toy base-plate: a world-space grid of raised round studs over the shared
// two-colour checker. The stud top is flat with a chamfered rim that catches
// a highlight; the recessed grid between studs is a touch darker. The pattern
// is anti-aliased with fwidth so it flattens into solid plate colour in the
// distance instead of moireing. Same plastic light() as the surface shader,
// a little less glossy. No screen or depth reads.
shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
// Studs sit on a square grid "pitch" world units apart.
uniform float pitch = 1.0;
uniform float stud = 0.34;
// Chamfer width (world units) and how far its normal tilts outward.
uniform float chamfer = 0.09;
uniform float relief : hint_range(0.0, 2.0) = 0.85;
// Shading of the recessed grid and the lift on the stud tops.
uniform float gap_shade : hint_range(0.0, 0.5) = 0.14;
uniform float top_lift : hint_range(0.0, 0.5) = 0.07;
uniform float wrap : hint_range(0.0, 1.0) = 0.12;
uniform float gloss : hint_range(0.0, 2.0) = 0.45;
uniform float shininess = 30.0;

varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 f = (fract(world.xz / pitch) - 0.5) * pitch; // world offset to cell centre
	float r = length(f);
	float aa = fwidth(r) + 0.0005;
	// 1 on the flat stud top, fading out across the chamfer.
	float top = 1.0 - smoothstep(stud - chamfer - aa, stud - chamfer + aa, r);
	// The chamfer band: where the stud wall tilts outward.
	float band = smoothstep(stud - chamfer - aa, stud - chamfer, r) * (1.0 - smoothstep(stud, stud + aa, r));
	float cover = 1.0 - smoothstep(stud - aa, stud + aa, r); // 1 anywhere on the stud
	vec2 dir = f / max(r, 0.0001);
	vec3 nrm = normalize(vec3(dir.x * relief * band, 1.0, dir.y * relief * band));
	NORMAL = normalize((VIEW_MATRIX * vec4(nrm, 0.0)).xyz);
	// Stud tops read slightly proud, the grid between them slightly sunk.
	float tone = 1.0 + top * top_lift - (1.0 - cover) * gap_shade;
	ALBEDO = albedo.rgb * tone;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float diff = clamp((dot(NORMAL, LIGHT) + wrap) / (1.0 + wrap), 0.0, 1.0);
	float shade = mix(0.3, 1.0, ATTENUATION);
	DIFFUSE_LIGHT += LIGHT_COLOR * diff * shade / PI;
	vec3 halfway = normalize(LIGHT + VIEW);
	float spot = pow(max(dot(NORMAL, halfway), 0.0), shininess) * gloss;
	SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * spot;
}
