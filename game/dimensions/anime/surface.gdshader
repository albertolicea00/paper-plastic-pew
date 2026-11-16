// Anime cel shading: flat colour bands with a crisp terminator, a tinted
// shadow instead of black, screentone in the shadow and an optional specular
// dot and rim. No texture reads.
shader_type spatial;
// The shadow colour is emitted and the light only adds the difference up to
// the lit colour, so the result never depends on ambient or light energy.
render_mode ambient_light_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 shade : source_color = vec4(0.55, 0.5, 0.8, 1.0); // multiplied into the shadow
uniform vec4 tone_ink : source_color = vec4(0.07, 0.07, 0.1, 1.0);
uniform float bands = 3.0; // 2 = lit/shadow, 3 adds a half tone
uniform float mid = 0.6; // brightness of the half tone band
uniform float tone = 0.35; // screentone strength inside the shadow
uniform float tone_scale = 7.0; // dot pitch in pixels (screen) or lines per unit (world)
uniform float world_tone = 0.0; // 0 = screen-space dots, 1 = world-space hatching
uniform float spec = 0.0; // hard highlight dot
uniform float rim = 0.0; // hard rim on the lit side

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Screen dots on a 45 degree grid: fine for small moving shapes.
	vec2 grid = mat2(vec2(0.707, 0.707), vec2(-0.707, 0.707)) * FRAGCOORD.xy / tone_scale;
	float dots = 1.0 - smoothstep(0.3, 0.38, length(fract(grid) - 0.5));
	// Hatching anchored to the world so static scenery does not swim. Planes of
	// constant x+y+z cut every axis-aligned face in diagonal lines.
	float stripe = abs(fract((world_pos.x + world_pos.y + world_pos.z) * tone_scale) - 0.5);
	float width = fwidth((world_pos.x + world_pos.y + world_pos.z) * tone_scale);
	float hatch = 1.0 - smoothstep(0.16 - width, 0.16 + width, stripe);
	float pattern = mix(dots, hatch, world_tone) * tone;
	vec3 lit = albedo.rgb;
	vec3 dark = mix(lit * shade.rgb, tone_ink.rgb, pattern);
	EMISSION = dark;
	ALBEDO = max(lit - dark, vec3(0.0));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float facing = dot(NORMAL, LIGHT);
	// Thresholded so the shadow map edge is as hard as the terminator.
	float open = smoothstep(0.4, 0.6, ATTENUATION);
	float full = smoothstep(0.62, 0.66, facing);
	float half_tone = smoothstep(0.02, 0.06, facing);
	float level = bands > 2.5 ? mix(half_tone * mid, 1.0, full) : half_tone;
	level *= open;
	DIFFUSE_LIGHT += vec3(level);
	float glint = step(0.965, dot(NORMAL, normalize(LIGHT + VIEW))) * spec;
	float edge = step(0.72, 1.0 - dot(NORMAL, VIEW)) * rim;
	SPECULAR_LIGHT += vec3(max(glint, edge) * level);
}
