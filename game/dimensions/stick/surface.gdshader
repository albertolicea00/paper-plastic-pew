// Marker fill: a flat, highly saturated ink colour that reads the same whatever
// the light does, with at most a faint two-step shade so limbs stay solid
// strokes. Most of the colour is emitted unlit; the light only adds the small
// remainder, so the figure never depends on ambient or light energy (measured:
// LIGHT_COLOR arrives bright on the Compatibility renderer). An optional pencil
// grain roughens the fill, and a "glow" role self-lights bullets and pickups.
shader_type spatial;
render_mode ambient_light_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
// Share of the colour emitted flat; the rest is handed to the light for a
// barely-there second step.
uniform float flat_fill : hint_range(0.0, 1.0) = 0.82;
// Brightness of the shaded step (1 = no shade).
uniform float shade : hint_range(0.0, 1.0) = 0.74;
// Pencil/paper grain in the fill, locked to world space so it does not swim.
uniform float grain : hint_range(0.0, 1.0) = 0.0;
uniform float grain_scale = 40.0;
// Self-lit amount for bullets and pickups: 1 = always its own full colour.
uniform float glow : hint_range(0.0, 1.0) = 0.0;

varying vec3 world_pos;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = albedo.rgb;
	// Dry-marker speckle: a few darker grains scratched into the fill.
	if (grain > 0.001) {
		float g = hash(floor(world_pos * grain_scale));
		base *= 1.0 - grain * 0.35 * step(0.62, g);
	}
	vec3 flat_part = mix(base * flat_fill, base, glow);
	EMISSION = flat_part;
	ALBEDO = base - flat_part; // what the light is allowed to add back
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	// Two hard steps: a near-flat lit face and a faint shaded one. No soft ramp,
	// so each stroke stays one solid tone like a felt-tip fill.
	float ndl = dot(NORMAL, LIGHT);
	float step2 = mix(shade, 1.0, smoothstep(0.0, 0.1, ndl));
	float open = smoothstep(0.4, 0.6, ATTENUATION);
	DIFFUSE_LIGHT += vec3(step2 * open);
}
