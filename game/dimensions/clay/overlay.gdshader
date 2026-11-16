// Miniature-set photography: warm lens vignette, film grain and lamp flicker
// that step on stop-motion frames. Mostly transparent, no screen read.
shader_type canvas_item;

uniform float impact = 0.0;
uniform float shift = 0.0;
uniform vec4 shade : source_color = vec4(0.16, 0.08, 0.05, 1.0);
uniform vec4 leak : source_color = vec4(1.0, 0.62, 0.32, 1.0);
uniform float vignette : hint_range(0.0, 1.0) = 0.5;
uniform float grain : hint_range(0.0, 0.3) = 0.05;
uniform float grain_size = 2.0;
uniform float flicker : hint_range(0.0, 0.2) = 0.03;
uniform float fps = 12.0;

float hash12(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

void fragment() {
	float frame = floor(TIME * fps);
	vec2 centred = UV - 0.5;
	// 0 at the centre, 1 at the middle of an edge, 2 in the corners.
	float away = dot(centred, centred) * 4.0;
	float edge = smoothstep(0.5, 1.9, away);
	// The set lamp is never perfectly steady between exposures.
	float lamp = hash12(vec2(frame, 3.7));
	float dark = edge * vignette * (1.0 + (lamp - 0.5) * 4.0 * flicker) + lamp * flicker * 0.5;
	// Hits bloom as a warm light leak in the corners, never over the action.
	float pulse = impact * edge;
	vec3 color = mix(shade.rgb, leak.rgb, clamp(pulse * 0.6, 0.0, 1.0));
	float alpha = dark + pulse * 0.1;
	// Dimension shift: the camera iris opens from the centre under the flash.
	float iris = smoothstep(0.0, 0.5, away - (1.0 - shift) * 2.6) * shift;
	alpha = max(alpha, iris * 0.85);
	// Film grain, re-rolled every exposure.
	float speck = hash12(floor(FRAGCOORD.xy / grain_size) + frame * vec2(17.3, 9.1)) - 0.5;
	float speck_alpha = abs(speck) * 2.0 * grain;
	vec3 speck_color = speck > 0.0 ? vec3(1.0, 0.95, 0.85) : shade.rgb;
	float total = alpha + speck_alpha * (1.0 - alpha);
	COLOR = vec4(mix(color, speck_color, speck_alpha * (1.0 - alpha) / max(total, 0.0001)), total);
}
