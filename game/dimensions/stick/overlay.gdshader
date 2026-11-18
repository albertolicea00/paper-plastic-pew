// The page over the lens: faint paper grain and a soft vignette at rest, a red
// margin line down the left like a ruled notebook, a short ink-dash pulse from
// the edges on `impact`, and a quick scribble-scrawl flash on a dimension
// `shift` (like a hand sketching the new page in). The centre stays clear so
// the fight always reads. Mostly transparent, no screen read.
shader_type canvas_item;

uniform float impact = 0.0; // set by the core: dash, hit taken, kill
uniform float shift = 0.0;  // set by the core: 1 to 0 after a dimension shift
uniform vec4 ink : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform vec4 margin : source_color = vec4(0.82, 0.23, 0.2, 1.0);
uniform float grain : hint_range(0.0, 0.2) = 0.03;
uniform float vignette : hint_range(0.0, 1.0) = 0.34;
uniform float strength : hint_range(0.0, 1.0) = 0.9;
// Tuning aids: force a pulse from pack.json to inspect a held frame.
uniform float preview_impact = 0.0;
uniform float preview_shift = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Ragged ink wedges pointing at the centre, like quick biro flicks.
float flicks(vec2 p, float count, float reach, float density, float seed) {
	float turn = atan(p.y, p.x) / TAU + 0.5;
	float slot = floor(turn * count);
	float across = abs(fract(turn * count) - 0.5);
	float drawn = step(1.0 - density, hash(vec2(slot, seed)));
	float tip = reach * (0.8 + 0.5 * hash(vec2(slot + 3.0, seed)));
	float along = length(p) - tip;
	float wide = clamp(along * 1.6, 0.0, 1.0) * (0.14 + 0.32 * hash(vec2(slot + 9.0, seed)));
	return drawn * step(across, wide) * step(0.0, along);
}

void fragment() {
	float hit = max(impact, preview_impact);
	float warp = max(shift, preview_shift);
	vec2 p = (UV - 0.5) * 2.0; // edges at 1
	float far = length(p);
	float cel = floor(TIME * 12.0); // redrawn 12 times a second, like cheap cels

	vec3 tint = ink.rgb;
	// Rest: paper fibre everywhere, a soft vignette darkening the corners.
	float cover = abs(hash(floor(FRAGCOORD.xy * 0.5)) - 0.5) * grain;
	cover = max(cover, smoothstep(0.9, 1.6, far) * vignette);

	// Red ruled margin down the left, faint like the real thing.
	float m = 1.0 - smoothstep(0.004, 0.004 + fwidth(UV.x), abs(UV.x - 0.085));
	tint = mix(tint, margin.rgb, m);
	cover = max(cover, m * 0.5);

	// Impact: a ring of ink flicks stabs in from the border, never to the core.
	float pulse = smoothstep(0.0, 0.25, hit);
	float dash = flicks(p, 64.0, mix(1.15, 0.62, hit), 0.5, cel);
	cover = max(cover, dash * pulse * strength);

	// Shift: a scribble closing in from the edge plus scratchy flicks, so the
	// new page looks hand-sketched into place, then it peels back to the border.
	float kick = smoothstep(0.0, 0.6, warp);
	float slot = floor((atan(p.y, p.x) / TAU + 0.5) * 40.0);
	float edge = step(mix(1.6, 0.8, kick) + 0.28 * hash(vec2(slot, cel)), far);
	float scrawl = max(edge, flicks(p, 96.0, 0.5, 0.55, cel + 17.0));
	cover = mix(cover, 1.0, scrawl * kick);

	COLOR = vec4(tint, clamp(cover, 0.0, 1.0));
}
