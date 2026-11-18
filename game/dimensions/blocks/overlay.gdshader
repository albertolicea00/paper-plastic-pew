// Toybox glass: a faint cool vignette, a subtle gloss band sweeping the upper
// screen like light off moulded plastic, a sharp snap-flash when a dimension
// shifts in, and a short pulse on impact. The centre stays clear so the fight
// always reads. Mostly transparent, no screen read.
shader_type canvas_item;

// Set by the core every frame.
uniform float impact = 0.0;
uniform float shift = 0.0;

uniform vec4 edge_tint : source_color = vec4(0.05, 0.08, 0.11, 1.0);
uniform vec4 snap_tint : source_color = vec4(0.92, 0.96, 1.0, 1.0);
uniform vec4 pulse_tint : source_color = vec4(1.0, 0.82, 0.25, 1.0);
uniform float vignette : hint_range(0.0, 1.0) = 0.42;
uniform float gloss : hint_range(0.0, 0.3) = 0.06;

void fragment() {
	vec2 p = UV - 0.5;
	// 0 at the centre, ~1 at the middle of an edge, ~2 in the corners.
	float away = dot(p, p) * 4.0;
	vec3 color = edge_tint.rgb;
	float alpha = smoothstep(0.55, 1.95, away) * vignette;

	// Gloss band: a soft diagonal sweep across the top, kept off the centre.
	float diag = (UV.x * 0.6 + UV.y);
	float band = smoothstep(0.35, 0.0, abs(diag - 0.42)) * smoothstep(0.35, 0.75, 1.0 - UV.y);
	alpha = max(alpha, band * gloss);
	color = mix(color, vec3(1.0), band);

	// Impact: a quick warm bloom from the edges inward, never over the action.
	float pulse = impact * smoothstep(0.35, 1.7, away);
	color = mix(color, pulse_tint.rgb, clamp(pulse, 0.0, 1.0));
	alpha = max(alpha, pulse * 0.28);

	// Shift: a bright plate-snap that fills the frame then pulls back to the
	// edges as the flash fades, so the new world clicks into place.
	float ring = clamp(smoothstep(0.0, 0.7, away - (1.0 - shift) * 2.5), 0.0, 1.0) * shift;
	float flash = shift * shift;
	color = mix(color, snap_tint.rgb, max(ring, flash * 0.25));
	alpha = max(alpha, max(ring * 0.85, flash * 0.2));

	COLOR = vec4(color, clamp(alpha, 0.0, 1.0));
}
