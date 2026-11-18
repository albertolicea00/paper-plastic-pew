// 8/16-bit sprite plastic: a flat limited-palette base lit with posterized
// diffuse (a few hard brightness steps, no smooth gradients) and ordered
// Bayer 4x4 dithering between the steps, computed in SCREEN space so it reads
// as a regular pixel dot-grid. Flat faces stay solid; only the lit edges of a
// voxel figure dither. A "glow" role (bullets, pickups) self-lights so it
// never goes dark on any tile. No texture lookups, no screen/depth reads.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
// Hard brightness steps the diffuse is quantised to (3-4 reads as 8-bit).
uniform float levels : hint_range(1.0, 8.0) = 4.0;
// Shadows never reach pure black, so gameplay reads through them.
uniform float shade_floor : hint_range(0.0, 1.0) = 0.42;
// Tiny wrap keeps a crisp terminator; sprites are not soft.
uniform float wrap : hint_range(0.0, 1.0) = 0.08;
// Side of one dither cell in physical pixels: a few px sells the dot-grid.
uniform float pixel : hint_range(1.0, 8.0) = 2.0;
// How strongly the dither pushes across a step edge (0 = hard bands).
uniform float dither : hint_range(0.0, 1.0) = 1.0;
// One hard white highlight pixel on the brightest facets (no smooth spec).
uniform float spark : hint_range(0.0, 1.0) = 0.0;
uniform float spark_tight = 40.0;
// Self-lit amount for bullets and pickups.
uniform float glow : hint_range(0.0, 1.0) = 0.0;

// Ordered 4x4 Bayer threshold, written in the fragment and read in light().
varying float bayer;

// Bayer 4x4 matrix, 0..15.
const float BAYER[16] = float[](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

void fragment() {
	// Screen-space dot-grid: one threshold per `pixel`-sized block of the frame.
	ivec2 c = ivec2(mod(floor(FRAGCOORD.xy / pixel), 4.0));
	bayer = (BAYER[c.y * 4 + c.x] + 0.5) / 16.0;
	ALBEDO = albedo.rgb * (1.0 - glow);
	EMISSION = albedo.rgb * glow;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

// Quantise v to `steps` hard levels, dithering the boundary with threshold d.
float poster(float v, float steps, float d) {
	float s = clamp(v, 0.0, 1.0) * steps;
	float lo = floor(s);
	return (lo + step(mix(0.5, d, dither), s - lo)) / steps;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float diff = clamp((ndl + wrap) / (1.0 + wrap), 0.0, 1.0);
	// Lift out of black by the shadow floor, then snap to hard steps.
	float lum = mix(shade_floor, 1.0, diff * ATTENUATION);
	float lvl = poster(lum, levels, bayer);
	DIFFUSE_LIGHT += LIGHT_COLOR * lvl / PI;
	// Optional single highlight pixel: a hard on/off dot, never a soft bloom.
	if (spark > 0.001) {
		vec3 halfway = normalize(LIGHT + VIEW);
		float hard = step(1.0 - bayer * 0.3, pow(max(dot(NORMAL, halfway), 0.0), spark_tight));
		SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * hard * spark;
	}
}
