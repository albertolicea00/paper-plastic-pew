// Manga page overlay: corner screentone and paper grain at rest, radial speed
// lines on `impact`, a black and white impact frame on `shift`.
// Everything is kept outside an ellipse around the screen centre.
shader_type canvas_item;

uniform float impact = 0.0; // set by the core: dash, hit taken, kill
uniform float shift = 0.0; // set by the core: 1 to 0 after a dimension shift
uniform vec4 ink : source_color = vec4(0.07, 0.07, 0.1, 1.0);
uniform vec4 paper : source_color = vec4(1.0, 0.99, 0.96, 1.0);
uniform float strength = 1.0; // speed line opacity
uniform float lines = 90.0; // angular slots around the screen
uniform float vignette = 0.5; // corner screentone opacity
uniform float grain = 0.035;
// Tuning aids: force a pulse from pack.json to look at a held frame.
uniform float preview_impact = 0.0;
uniform float preview_shift = 0.0;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Wedge-shaped streaks pointing at the centre. `reach` is how close the tips
// get (1 = screen edge), `density` the share of angular slots that are drawn.
float streaks(vec2 p, float count, float reach, float density, float seed) {
	float turn = atan(p.y, p.x) / TAU + 0.5;
	float slot = floor(turn * count);
	float across = abs(fract(turn * count) - 0.5);
	float drawn = step(1.0 - density, hash(slot + seed));
	float tip = reach * (0.8 + 0.5 * hash(slot * 1.7 + seed + 3.0));
	float along = length(p) - tip;
	float half_width = clamp(along * 1.6, 0.0, 1.0) * (0.15 + 0.35 * hash(slot + seed + 9.0));
	return drawn * step(across, half_width) * step(0.0, along);
}

void fragment() {
	float hit = max(impact, preview_impact);
	float warp = max(shift, preview_shift);
	vec2 p = (UV - 0.5) * 2.0; // edges at 1, so the clear zone follows the screen shape
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float far = length(p);
	// Lines are redrawn 14 times a second, like animation cels.
	float cel = floor(TIME * 14.0);
	vec3 tint = ink.rgb;
	float cover = 0.0;

	// Rest: paper fibre everywhere, screentone dots growing into the corners.
	cover = abs(hash2(floor(FRAGCOORD.xy * 0.5)) - 0.5) * grain;
	vec2 grid = mat2(vec2(0.707, 0.707), vec2(-0.707, 0.707)) * (UV * vec2(aspect, 1.0)) * 110.0;
	float corner = smoothstep(0.95, 1.45, far);
	float dots = 1.0 - smoothstep(corner * 0.55 - 0.06, corner * 0.55, length(fract(grid) - 0.5));
	cover = max(cover, dots * vignette * step(0.01, corner));

	// Speed lines: tips push inwards with the pulse but never reach the middle.
	float pulse = smoothstep(0.0, 0.25, hit);
	float speed = streaks(p, lines, mix(1.15, 0.6, hit), 0.5, cel);
	cover = max(cover, speed * pulse * strength);

	// Impact frame: a jagged ink burst closing in from the border, cut by white streaks.
	float kick = smoothstep(0.0, 0.5, warp);
	float slot = floor((atan(p.y, p.x) / TAU + 0.5) * 48.0);
	float burst = step(mix(1.5, 0.78, kick) + 0.3 * hash(slot + cel), far);
	float dark = max(burst, streaks(p, lines * 1.5, 0.5, 0.55, cel + 17.0));
	float white = streaks(p, lines, 0.42, 0.3, cel + 41.0);
	cover = mix(cover, 1.0, dark * kick);
	tint = mix(tint, paper.rgb, white * kick);
	cover = max(cover, white * kick);

	COLOR = vec4(tint, cover);
}
