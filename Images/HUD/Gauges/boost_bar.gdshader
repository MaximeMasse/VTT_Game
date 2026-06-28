shader_type canvas_item;

uniform float flame_strength = 0.172;
uniform float flame_speed = 0.172;

uniform float brightness = 0.785;
uniform float pulse_strength = 0.195;

uniform float spark_density = 89.545;
uniform float spark_speed = 89.545;
uniform vec3 spark_color : source_color = vec3(1.0, 0.85, 0.35);

float hash(vec2 p)
{
	return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453123);
}

void fragment()
{
	vec2 uv = UV;

	// ========= Flammes =========

	float n1 = sin(UV.x * 18.0 + TIME * flame_speed);
	float n2 = sin(UV.x * 9.0 - TIME * flame_speed * 1.4);
	float n3 = sin(UV.x * 35.0 + TIME * flame_speed * 0.7);

	float flame = (n1 + n2 * 0.6 + n3 * 0.3);

	// Les bords bougent peu, le centre davantage
	float center = 1.0 - abs(UV.y - 0.5) * 2.0;

	uv.y += flame * flame_strength * center;

	vec4 col = texture(TEXTURE, uv);

	// ========= Battement =========

	float pulse = 1.0 + pulse_strength * sin(TIME * 8.0);

	col.rgb *= brightness * pulse;

	// ========= Étincelles =========

	vec2 grid = floor(UV * vec2(spark_density, spark_density * 0.4));

	float h = hash(grid);

	if (h > 0.985)
	{
		float phase = fract(TIME * spark_speed + h * 20.0);

		vec2 p = fract(UV * vec2(spark_density, spark_density * 0.4));

		p.y += phase;

		float d = length(p - vec2(0.5));

		float spark = smoothstep(0.5, 0.0, d);

		col.rgb += spark * spark_color * (1.0 - phase);
	}

	// ========= Lueur des zones claires =========

	float hot = pow(col.a,2.0);

	col.rgb += hot * vec3(1.0,0.35,0.05) * 0.25;

	COLOR = col;
}