shader_type canvas_item;

uniform float speed = 2;
uniform float wave_strength = 0.05;
uniform float wave_size = 10.0;

void fragment() {
	vec2 uv = UV;
	// Ondulation principale
	uv.y += sin((UV.x * wave_size) + TIME * speed) * wave_strength;
	// Petite deuxième ondulation pour éviter un mouvement trop mécanique
	//uv.x += sin((UV.y * wave_size * 0.7) + TIME * speed * 1.4) * wave_strength * 0.5;
	COLOR = texture(TEXTURE, uv);
}
