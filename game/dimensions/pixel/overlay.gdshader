// CRT glass: faint horizontal scanlines tied to the viewport height, a soft
// rounded-corner vignette, a very subtle vertical RGB stripe, a short bright
// pulse on impact and a retro "screen wipe" flash when a dimension shifts in.
// The centre stays mostly clear so the fight always reads. Mostly transparent,
// no screen read.
shader_type canvas_item;

// Set by the core every frame.
uniform float impact = 0.0;
uniform float shift = 0.0;

uniform vec4 line_tint : source_color = vec4(0.04, 0.05, 0.09, 1.0);
uniform vec4 edge_tint : source_color = vec4(0.03, 0.03, 0.07, 1.0);
uniform vec4 flash_tint : source_color = vec4(0.92, 0.98, 1.0, 1.0);
uniform vec4 pulse_tint : source_color = vec4(1.0, 0.86, 0.35, 1.0);
// One scanline per this many screen pixels.
uniform float line_px : hint_range(1.0, 8.0) = 3.0;
uniform float scan : hint_range(0.0, 1.0) = 0.22;
uniform float stripe : hint_range(0.0, 0.3) = 0.05;
uniform float vignette : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 px = UV * res;
	vec3 color = edge_tint.rgb;
	float alpha = 0.0;

	// Scanlines: every other pixel-row of the virtual screen is dimmed.
	float line = step(0.5, fract(px.y / (line_px * 2.0)));
	alpha = max(alpha, line * scan);
	color = mix(color, line_tint.rgb, line);

	// RGB phosphor stripe: a faint cool/warm tint cycling across columns.
	float col = mod(floor(px.x / line_px), 3.0);
	vec3 phosphor = col < 1.0 ? vec3(1.0, 0.7, 0.7) : (col < 2.0 ? vec3(0.7, 1.0, 0.7) : vec3(0.7, 0.7, 1.0));
	color = mix(color, color * phosphor, stripe * 4.0);
	alpha = max(alpha, stripe * (1.0 - line));

	// Rounded-corner vignette: darkens only the frame, never the centre.
	vec2 p = UV - 0.5;
	float away = dot(p, p) * 4.0;
	float dark = smoothstep(0.75, 2.0, away) * vignette;
	color = mix(color, edge_tint.rgb, dark);
	alpha = max(alpha, dark);

	// Impact: a quick warm flash blooming from the edges inward.
	float pulse = impact * smoothstep(0.3, 1.7, away);
	color = mix(color, pulse_tint.rgb, clamp(pulse, 0.0, 1.0));
	alpha = max(alpha, pulse * 0.3);

	// Shift: a hard horizontal wipe bar sweeps the screen under a white flash,
	// like a game cutting to the next level.
	float bar = smoothstep(0.08, 0.0, abs(UV.y - (1.0 - shift)));
	float flash = shift * shift;
	color = mix(color, flash_tint.rgb, max(bar, flash * 0.35));
	alpha = max(alpha, max(bar * 0.9, flash * 0.3));

	COLOR = vec4(color, clamp(alpha, 0.0, 1.0));
}
