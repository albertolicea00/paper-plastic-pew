// Comic-book surface: flat colour, two tones split by a band of screen-space
// Ben-Day dots, and a hard white highlight. Shadow colour comes from the
// pack's ambient light, lit colour from ambient + sun.
shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
// N.L value where light turns into shadow, and half-width of the dotted band.
uniform float edge = 0.2;
uniform float band = 0.24;
// Dot rows across the screen height (resolution independent).
uniform float dots = 96.0;
// Highlight: N.H threshold (higher = smaller blob) and brightness.
uniform float gloss = 0.965;
uniform float shine = 0.55;
// Self-lit amount, for bullets and pickups that must never go dark.
uniform float glow = 0.0;

void fragment() {
	ALBEDO = albedo.rgb * (1.0 - glow);
	EMISSION = albedo.rgb * glow;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float tone = smoothstep(edge - band, edge + band, dot(NORMAL, LIGHT) * ATTENUATION);
	// 45 degree dot screen; shadow dots grow until they merge into solid shade.
	float pixel = dots / VIEWPORT_SIZE.y;
	vec2 cell = mat2(vec2(0.7071, -0.7071), vec2(0.7071, 0.7071)) * FRAGCOORD.xy * pixel;
	float reach = length(fract(cell) - 0.5);
	float radius = sqrt(1.0 - tone) * (0.72 + 2.0 * pixel) - pixel;
	float lit = smoothstep(radius - pixel, radius + pixel, reach);
	DIFFUSE_LIGHT += LIGHT_COLOR * lit;
	float spark = step(gloss, dot(NORMAL, normalize(LIGHT + VIEW)));
	SPECULAR_LIGHT += vec3(shine) * spark * lit;
}
