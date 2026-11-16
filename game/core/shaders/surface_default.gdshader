// Fallback surface used when a dimension pack ships no surface shader.
shader_type spatial;
uniform vec4 albedo : source_color = vec4(1.0);
void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 0.9;
}
