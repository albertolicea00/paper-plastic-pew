// Manga page floor: flat paper, inked panel lines on the tile grid and cast
// shadows drawn as screentone dots instead of a darker fill. No texture reads.
shader_type spatial;
render_mode ambient_light_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 ink : source_color = vec4(0.07, 0.07, 0.1, 1.0);
uniform vec4 shade : source_color = vec4(0.55, 0.5, 0.8, 1.0); // paper tint under the dots
uniform float tile = 4.0; // matches the arena checker
uniform float line = 0.022; // panel line half width in world units
uniform float dot_pitch = 0.22; // screentone pitch in world units
uniform float grain = 0.03;

varying vec3 world_pos;
varying vec2 from_edge;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Floor planes have corner vertices only, so this measures from the plane's
	// own edge and the lines land on the checker whatever the arena size.
	from_edge = VERTEX.xz + abs(VERTEX.xz);
}

void fragment() {
	vec2 at = world_pos.xz;
	// Panel gutters: an ink line on every tile edge, thin ticks on the half grid.
	vec2 cell = abs(fract(from_edge / tile + 0.5) - 0.5) * tile;
	float soft = fwidth(at.x) + fwidth(at.y);
	float panel = 1.0 - smoothstep(line, line + soft, min(cell.x, cell.y));
	vec2 sub = abs(fract(from_edge / tile) - 0.5) * tile;
	float tick = (1.0 - smoothstep(line * 0.4, line * 0.4 + soft, min(sub.x, sub.y))) * 0.18;
	// World-anchored dots so the tone stays put under a moving camera.
	vec2 grid = mat2(vec2(0.707, 0.707), vec2(-0.707, 0.707)) * at / dot_pitch;
	float dots = 1.0 - smoothstep(0.32, 0.32 + soft / dot_pitch, length(fract(grid) - 0.5));
	float fibre = (hash(floor(at * 24.0)) - 0.5) * grain;
	vec3 paper = mix(albedo.rgb + fibre, ink.rgb, max(panel, tick));
	vec3 dark = mix(paper * shade.rgb, ink.rgb, max(dots * 0.8, panel));
	EMISSION = dark;
	ALBEDO = max(paper - dark, vec3(0.0));
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	DIFFUSE_LIGHT += vec3(smoothstep(0.4, 0.6, ATTENUATION) * step(0.0, dot(NORMAL, LIGHT)));
}
