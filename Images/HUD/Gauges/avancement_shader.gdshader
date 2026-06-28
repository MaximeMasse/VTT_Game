shader_type canvas_item;

uniform float wind_speed = 0.6;
uniform float wind_strength = 0.008;

uniform float shine_speed = 0.12;
uniform float shine_width = 0.08;
uniform float shine_strength = 0.18;

uniform float pulse_strength = 0.04;

void fragment() {
	vec2 uv = UV;

	// Léger mouvement de vent
	//uv.y += sin(UV.x * 18.0 + TIME * wind_speed * 6.0) * wind_strength;
	//uv.y += sin(UV.x * 7.0 - TIME * wind_speed * 4.0) * wind_strength * 0.5;
	vec4 col = texture(TEXTURE, uv);

	// Balayage lumineux
	float pos = fract(TIME * shine_speed);
	float shine = smoothstep(
		shine_width,
		0.0,
		abs(UV.x - pos)
	);

	// Petite pulsation globale
	float pulse = 1.0 + pulse_strength * sin(TIME * 2.5);

	col.rgb *= pulse;
	col.rgb += vec3(1.0, 1.0, 0.8) * shine * shine_strength;

	COLOR = col;
}