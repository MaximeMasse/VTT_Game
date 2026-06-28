shader_type canvas_item;

uniform sampler2D mask_texture : source_color;
uniform sampler2D noise_texture : repeat_enable;

uniform float bike_speed = 0.0; // à envoyer depuis le script
uniform float max_speed = 50.0;

uniform float scroll_speed = 0.1;
uniform float noise_strength = 0.05;
uniform float edge_noise_strength = 0.08;

uniform float alpha_power = 1;
uniform float tail_fade = 0.5;

void fragment() {
	vec2 uv = UV;
	float speed_ratio = clamp(bike_speed / max_speed, 0.0, 1.0);
	// Plus le vélo va vite, plus le nuage s'étire vers la gauche
	vec2 mask_uv = uv;
	mask_uv.x = mix(uv.x, uv.x * 0.85 + 0.15, speed_ratio);
	// Déformation naturelle du masque
	float n1 = texture(noise_texture, vec2(uv.x * 2.0 - TIME * 0.15, uv.y * 2.0)).r;
	float n2 = texture(noise_texture, vec2(uv.x * 4.0 + TIME * 0.25, uv.y * 4.0 - TIME * 0.1)).r;
	float edge_noise = (n1 - 0.5) * edge_noise_strength * (0.4 + speed_ratio);
	mask_uv.y += edge_noise;
	float mask = texture(mask_texture, mask_uv).r;
	// Gonflements internes arbitraires
	float swell = texture(noise_texture, vec2(uv.x * 1.5 - TIME * 0.1, uv.y * 1.5 + TIME * 0.08)).r;
	swell = smoothstep(0.35, 0.9, swell);
	mask *= mix(0.75, 1.25, swell);
	// Scroll de la texture poussière à l'intérieur du masque
	vec2 dust_uv = uv;
	dust_uv.x += TIME * scroll_speed * (0.5 + speed_ratio * 1.5);
	dust_uv.y += (n2 - 0.5) * noise_strength;
	vec4 dust = texture(TEXTURE, dust_uv);
	// Fade en queue de traînée : gauche transparent, droite plus dense
	float tail = pow(smoothstep(0.0, 0.85, uv.x), tail_fade);
	// Fade vertical doux
	float vertical_fade = smoothstep(0.0, 0.15, uv.y) * smoothstep(1.0, 0.85, uv.y);
	float alpha = mask * tail * vertical_fade;
	alpha = pow(alpha, alpha_power);
	COLOR = vec4(dust.rgb, dust.a * alpha);
}