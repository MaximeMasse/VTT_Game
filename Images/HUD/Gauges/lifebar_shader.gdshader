shader_type canvas_item;

uniform float pulse_strength = 0.10;
uniform float glow_strength = 1.25;

uniform float warning_threshold = 0.3;
uniform float life = 100.0;

void fragment() {
	vec2 uv = UV;

	vec4 col = texture(TEXTURE, uv);

	// Battement type vie / coeur
	float beat = exp(-pow(sin(TIME * 4.0), 8.0));
	float pulse = 1.0 + beat * pulse_strength;

	// Plus la vie est basse, plus ça clignote
	float danger = smoothstep(warning_threshold, 0.0, life/100.0);
	float danger_flash = 0.5 + 0.5 * sin(TIME * 12.0);

	col.rgb *= glow_strength * pulse;
	col.rgb += vec3(1.0, 0.05, 0.0) * danger * danger_flash * 0.6;

	// Renforce les zones déjà très rouges/claires
	float brightness = max(col.r, max(col.g, col.b));
	float hot = smoothstep(0.45, 1.0, brightness);
	col.rgb += vec3(1.0, 0.2, 0.05) * hot * 0.25;

	COLOR = col;
}