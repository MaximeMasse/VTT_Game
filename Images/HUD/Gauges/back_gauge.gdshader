shader_type canvas_item;

uniform float shine_strength = 50;
uniform float shine_speed = 1.8;
uniform float edge_threshold = 0.28;
uniform vec4 shine_color : source_color = vec4(1.0, 0.85, 0.55, 1.0);

float rand(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	float brightness = max(col.r, max(col.g, col.b));

	// Sélectionne surtout les bords clairs/métalliques
	float edge_mask = smoothstep(edge_threshold, 0.75, brightness);

	// Petits scintillements aléatoires
	float sparkle = rand(floor(UV * vec2(90.0, 8.0)));
	sparkle = step(0.965, sparkle);

	float flicker = 0.5 + 0.5 * sin(TIME * shine_speed * 8.0 + UV.x * 40.0);

	// Reflet qui se balade doucement sur la longueur
	float sweep = sin(UV.x * 10.0 - TIME * shine_speed);
	sweep = smoothstep(0.92, 1.0, sweep);

	float shine = edge_mask * (sparkle * flicker + sweep * 0.35);

	col.rgb += shine_color.rgb * shine * shine_strength;
	COLOR = col;
}