// Retro game-map floor: the shared two-colour checker, broken into small
// world-space map tiles (a faint per-tile brightness jitter plus a darker
// grid border) and lit with the same posterized + screen-space Bayer dither
// as the surface shader, so the ground reads as a chunky tiled level. The
// tiling is area-based, not thin lines, so it stays stable at the top-down
// distance instead of shimmering. No screen or depth reads.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
// One map tile every `tile` world units.
uniform float tile = 1.0;
// Darker border drawn around each tile (fraction of the tile).
uniform float grid : hint_range(0.0, 0.4) = 0.12;
uniform float grid_shade : hint_range(0.0, 0.6) = 0.18;
// Random tone step per tile, so the map does not read as one flat sheet.
uniform float jitter : hint_range(0.0, 0.5) = 0.12;
uniform float levels : hint_range(1.0, 8.0) = 4.0;
uniform float shade_floor : hint_range(0.0, 1.0) = 0.46;
uniform float wrap : hint_range(0.0, 1.0) = 0.08;
uniform float pixel : hint_range(1.0, 8.0) = 2.0;
uniform float dither : hint_range(0.0, 1.0) = 1.0;

varying vec3 world;
varying float bayer;

const float BAYER[16] = float[](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	ivec2 c = ivec2(mod(floor(FRAGCOORD.xy / pixel), 4.0));
	bayer = (BAYER[c.y * 4 + c.x] + 0.5) / 16.0;
	vec2 cell = floor(world.xz / tile);
	vec2 f = fract(world.xz / tile);
	// Darker border band around the tile edge; a hard step keeps it crisp.
	float edge = step(f.x, grid) + step(1.0 - grid, f.x) + step(f.y, grid) + step(1.0 - grid, f.y);
	float border = 1.0 - min(edge, 1.0) * grid_shade;
	// A flat per-tile brightness notch, snapped to three values.
	float tone = 1.0 + (floor(hash(cell) * 3.0) / 2.0 - 0.5) * jitter;
	ALBEDO = albedo.rgb * border * tone;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

float poster(float v, float steps, float d) {
	float s = clamp(v, 0.0, 1.0) * steps;
	float lo = floor(s);
	return (lo + step(mix(0.5, d, dither), s - lo)) / steps;
}

void light() {
	float diff = clamp((dot(NORMAL, LIGHT) + wrap) / (1.0 + wrap), 0.0, 1.0);
	float lum = mix(shade_floor, 1.0, diff * ATTENUATION);
	DIFFUSE_LIGHT += LIGHT_COLOR * poster(lum, levels, bayer) / PI;
}
