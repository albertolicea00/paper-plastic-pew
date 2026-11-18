// Injection-moulded ABS plastic: a flat bright base colour, a hard tight
// specular highlight with a broad sheen under it, a glancing-edge gloss that
// reads as the chamfered rim of a brick, and optional faint mould seams and
// sparse speckle. Lit through light() so it works on the GL Compatibility
// renderer. Fully procedural, no texture lookups. A "glow" role (bullets,
// pickups) self-lights so it never goes dark on any plate.
shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
// Small wrap: plastic keeps a crisp terminator, unlike soft clay.
uniform float wrap : hint_range(0.0, 1.0) = 0.12;
// Hard highlight: strength and tightness (higher shininess = smaller, sharper).
uniform float gloss : hint_range(0.0, 2.0) = 0.9;
uniform float shininess = 46.0;
// Broad waxy sheen sitting under the hard spot.
uniform float sheen : hint_range(0.0, 1.0) = 0.16;
// Glancing fresnel rim: the lit chamfer along every edge.
uniform float rim : hint_range(0.0, 1.0) = 0.28;
// Faint mould parting line, every "seam" world units.
uniform float seam : hint_range(0.0, 1.0) = 0.0;
uniform float seam_scale = 0.5;
// Sparse flecks in the pigment (very low; plastic is mostly uniform).
uniform float speckle : hint_range(0.0, 1.0) = 0.0;
// Self-lit amount for bullets and pickups.
uniform float glow : hint_range(0.0, 1.0) = 0.0;

varying vec3 world_pos;

float hash13(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = albedo.rgb;
	// Sparse moulding flecks: a few darker specks locked to world space.
	if (speckle > 0.001) {
		float fleck = hash13(floor(world_pos * 42.0));
		base *= 1.0 - speckle * step(0.93, fleck) * 0.3;
	}
	// Mould parting line: a thin darker crease on a repeating world plane.
	if (seam > 0.001) {
		float s = abs(fract((world_pos.x + world_pos.z) * seam_scale) - 0.5);
		base *= 1.0 - seam * smoothstep(0.03, 0.0, s) * 0.14;
	}
	ALBEDO = base * (1.0 - glow);
	EMISSION = albedo.rgb * glow;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	// Crisp wrapped diffuse; cast shadows stay readable, never pure black.
	float diff = clamp((ndl + wrap) / (1.0 + wrap), 0.0, 1.0);
	float shade = mix(0.3, 1.0, ATTENUATION);
	DIFFUSE_LIGHT += LIGHT_COLOR * diff * shade / PI;
	// Hard moulded highlight plus the broad sheen beneath it.
	vec3 halfway = normalize(LIGHT + VIEW);
	float ndh = max(dot(NORMAL, halfway), 0.0);
	float spot = pow(ndh, shininess) * gloss;
	float broad = pow(ndh, 4.0) * sheen;
	// Edge gloss: the rounded chamfer of a brick catches light at grazing angles.
	float fres = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 4.0) * rim * diff;
	SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * (spot + broad + fres);
}
