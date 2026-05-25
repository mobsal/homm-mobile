shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;

void fragment() {
	vec2 uv = UV;
	float wave = sin(uv.x * 12.0 + time * 1.5) * 0.003;
	wave += sin(uv.y * 8.0 + time * 1.2) * 0.002;
	wave += sin((uv.x + uv.y) * 6.0 + time * 0.8) * 0.002;
	vec4 col = texture(TEXTURE, uv + vec2(wave * 0.5, wave));
	float blue = col.b;
	float blend = smoothstep(0.25, 0.6, blue) * 0.15;
	col.r += blend * sin(uv.x * 20.0 + time * 2.0) * 0.03;
	col.g += blend * sin(uv.y * 16.0 + time * 1.8) * 0.03;
	col.b += blend * 0.05;
	COLOR = col;
}
