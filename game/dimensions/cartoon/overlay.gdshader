// Comic page overlay: halftone dots creeping in from the corners, an inked
// panel border, a spiky "POW" burst from the screen edge on `impact`, and a
// starburst iris that opens from the centre on `shift`. No texture reads; the
// middle of the screen is always left clear.
shader_type canvas_item;

// Set by the core every frame.
uniform float impact = 0.0;
uniform float shift = 0.0;

uniform vec4 ink : source_color = vec4(0.07, 0.05, 0.15, 1.0);
// Corner dots.
uniform vec4 tint : source_color = vec4(0.15, 0.08, 0.45, 1.0);
// Burst fill and the dots printed on it.
uniform vec4 pop : source_color = vec4(1.0, 0.88, 0.1, 1.0);
uniform vec4 pop_dots : source_color = vec4(1.0, 0.25, 0.3, 1.0);
// Corner dot opacity.
uniform float strength = 0.55;
// Dot rows across the screen height.
uniform float dots = 44.0;
// Panel border thickness as a fraction of the screen height; 0 removes it.
uniform float frame = 0.008;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

// Starburst profile for an angle: 0 in the valleys, up to 1 at spike tips,
// every spike a different length.
float spikes(float angle, float count, float seed) {
	float turn = angle / TAU * count;
	float tip = 1.0 - abs(fract(turn) - 0.5) * 2.0;
	return tip * mix(0.45, 1.0, hash(mod(floor(turn), count) + seed));
}

// Coverage of a 45 degree dot screen, radius in cells (0.71 = solid).
float halftone(vec2 at, float radius, float pixel) {
	vec2 cell = mat2(vec2(0.7071, -0.7071), vec2(0.7071, 0.7071)) * at;
	return 1.0 - smoothstep(radius - pixel, radius + pixel, length(fract(cell) - 0.5));
}

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 p = UV * 2.0 - 1.0;
	vec2 grid = UV * vec2(aspect, 1.0) * dots;
	float pixel = dots * SCREEN_PIXEL_SIZE.y;
	float angle = atan(p.y, p.x);
	// Squircle distance: 1 at the middle of each edge, 1.41 in the corners.
	float rim = length(p * p);

	// Corner vignette: dots swell towards the corners.
	float corner = smoothstep(0.62, 1.45, rim);
	vec4 result = vec4(tint.rgb, halftone(grid, corner * 0.6 - pixel, pixel) * strength * step(0.001, corner));

	// Impact: jagged burst pushing in from the edge, inked on its inner side.
	if (impact > 0.001) {
		float reach = 1.46 - impact * (0.22 + 0.42 * spikes(angle, 34.0, 3.0));
		float inside = rim - reach;
		float line = 0.012 + 0.02 * impact;
		vec3 fill = mix(pop.rgb, pop_dots.rgb, halftone(grid * 1.5, clamp(inside * 2.2, 0.0, 0.5), pixel * 1.5));
		fill = mix(ink.rgb, fill, smoothstep(line, line + 0.006, inside));
		result = mix(result, vec4(fill, 1.0), smoothstep(0.0, 0.006, inside));
	}

	// Shift: the old panel is covered, then a starburst hole tears open.
	if (shift > 0.001) {
		float open = (1.0 - shift) * 1.5 * (0.68 + 0.32 * spikes(angle, 22.0, 11.0));
		float inside = length(p) * 0.7071 - open;
		vec3 fill = mix(pop.rgb, pop_dots.rgb, halftone(grid * 0.7, clamp(0.12 + inside * 1.4, 0.0, 0.55), pixel * 0.7));
		fill = mix(ink.rgb, fill, smoothstep(0.022, 0.03, inside));
		result = mix(result, vec4(fill, 1.0), smoothstep(0.0, 0.006, inside));
	}

	// Panel border.
	vec2 margin = min(UV, 1.0 - UV) * vec2(aspect, 1.0);
	float border = 1.0 - smoothstep(frame - SCREEN_PIXEL_SIZE.y, frame + SCREEN_PIXEL_SIZE.y, min(margin.x, margin.y));
	result = mix(result, vec4(ink.rgb, 1.0), border * step(0.0001, frame));

	COLOR = result;
}
