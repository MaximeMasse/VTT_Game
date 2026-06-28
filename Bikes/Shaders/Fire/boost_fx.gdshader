shader_type canvas_item;

render_mode blend_add;

uniform sampler2D noise_tex : repeat_enable;
uniform float speed = 2.0;
uniform float distortion = 0.035;
uniform float vertex_distortion = 12.0;
uniform float pulse_strength = 0.035;
uniform float glow_strength = 0.14;
uniform float alpha_power = 0.315;

void vertex() {
	float t = TIME * speed;

	float wave1 = sin(UV.x * 12.0 + t * 4.0);
	float wave2 = sin(UV.y * 18.0 - t * 3.0);

	float deform = (wave1 + wave2) * 0.5;

	VERTEX.y += deform * vertex_distortion * UV.x;
	VERTEX.x += sin(UV.y * 10.0 + t * 2.0) * vertex_distortion * 0.25;

	float pulse = 1.0 + sin(TIME * 8.0) * pulse_strength;
	VERTEX *= pulse;
}

void fragment() {
	vec2 uv = UV;

	float t = TIME * speed;

	vec2 noise_uv = uv;
	noise_uv.x += t * 0.35;
	noise_uv.y += sin(t + uv.x * 6.0) * 0.05;

	float n = texture(noise_tex, noise_uv).r;

	uv.y += (n - 0.5) * distortion;
	uv.x += (n - 0.5) * distortion * 0.5;

	vec4 col = texture(TEXTURE, uv);

	float alpha = pow(col.a, alpha_power);

	float flicker = 0.85 + 0.15 * sin(TIME * 18.0 + n * 8.0);

	col.rgb *= glow_strength * flicker;

	float hot_core = smoothstep(0.35, 1.0, col.a);
	col.rgb += vec3(1.0, 0.45, 0.05) * hot_core * 0.8;

	COLOR = vec4(col.rgb, alpha);
}