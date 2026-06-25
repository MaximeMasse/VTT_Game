shader_type canvas_item;

uniform float max_boost = 1.6;
uniform float beat_duration = 1.25;

uniform float red_threshold = 0.35;
uniform float red_dominance = 0.12;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	float t = mod(TIME, beat_duration) / beat_duration;

	float small_beat = exp(-pow((t - 0.12) / 0.045, 2.0));
	float big_beat = exp(-pow((t - 0.28) / 0.075, 2.0));
	float pulse = clamp(small_beat * 0.45 + big_beat, 0.0, 1.0);

	// Détection des pixels rouges
	float is_red = 0.0;
	is_red += step(red_threshold, tex.r);
	is_red += step(red_dominance, tex.r - tex.g);
	is_red += step(red_dominance, tex.r - tex.b);
	is_red = step(3.0, is_red);

	// Boost uniquement sur les rouges
	vec3 color = tex.rgb;
	color.r += pulse * max_boost * is_red;
	color.g *= 1.0 - pulse * 0.35 * is_red;
	color.b *= 1.0 - pulse * 0.35 * is_red;

	COLOR = vec4(color, tex.a);
}