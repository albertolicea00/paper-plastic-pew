// Comic page floor: flat colour printed with a world-anchored Ben-Day screen
// that gets heavier towards the arena edge. Cast shadows are drawn on the same
// dot grid, so they read as halftone ink instead of a grey blob.
shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
// Colour the dots multiply the floor with.
uniform vec4 tint : source_color = vec4(0.86, 0.72, 0.5, 1.0);
// Dot rows per world unit.
uniform float density = 2.6;
// Dot radius (in cells) at the centre and at the rim of the arena.
uniform float dot_min = 0.14;
uniform float dot_max = 0.36;
// World distance over which the dots grow.
uniform vec2 spread = vec2(5.0, 22.0);
// Radius of the dots inside cast shadows; above 0.71 the shadow is solid.
uniform float shadow_dot = 0.6;

varying vec3 world;

// x: distance to the nearest dot centre, y: one pixel in cell units.
vec2 screen_dots(vec2 at) {
	vec2 cell = mat2(vec2(0.7071, -0.7071), vec2(0.7071, 0.7071)) * at * density;
	return vec2(length(fract(cell) - 0.5), length(fwidth(cell)) * 0.7);
}

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 grid = screen_dots(world.xz);
	float radius = mix(dot_min, dot_max, smoothstep(spread.x, spread.y, length(world.xz)));
	float ink = 1.0 - smoothstep(radius - grid.y, radius + grid.y, grid.x);
	ALBEDO = mix(albedo.rgb, albedo.rgb * tint.rgb, ink * tint.a);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	vec2 grid = screen_dots(world.xz);
	float shade = 1.0 - clamp(dot(NORMAL, LIGHT) * 4.0, 0.0, 1.0) * ATTENUATION;
	float radius = sqrt(shade) * (shadow_dot + 2.0 * grid.y) - grid.y;
	DIFFUSE_LIGHT += LIGHT_COLOR * smoothstep(radius - grid.y, radius + grid.y, grid.x);
}
