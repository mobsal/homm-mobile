shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform vec4 flame_color1 : source_color = vec4(1.0, 0.7, 0.15, 1.0);
uniform vec4 flame_color2 : source_color = vec4(1.0, 0.35, 0.05, 1.0);
uniform vec4 flame_color3 : source_color = vec4(0.7, 0.1, 0.0, 1.0);
uniform vec4 smoke_color : source_color = vec4(0.15, 0.1, 0.08, 0.3);
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float flame_height : hint_range(0.5, 2.0) = 1.2;

float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i.x + i.y * 57.0);
	float b = hash(i.x + 1.0 + i.y * 57.0);
	float c = hash(i.x + (i.y + 1.0) * 57.0);
	float d = hash(i.x + 1.0 + (i.y + 1.0) * 57.0);
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100.0);
	for (int i = 0; i < 3; i++) {
		v += a * noise(p);
		p = p * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y;
	uv.y *= flame_height;
	uv.x += sin(uv.y * 10.0 + time * 3.0) * 0.03;

	float t = time * 2.0;

	float n1 = fbm(vec2(uv.x * 5.0 + t * 1.3, uv.y * 3.0 - t * 0.8));
	float n2 = fbm(vec2(uv.x * 3.0 - t * 1.1, uv.y * 5.0 + t * 0.5 + 50.0));
	float n3 = noise(vec2(uv.x * 8.0 + t * 2.1, uv.y * 2.0 - t * 1.2));

	float flame = n1 * 0.5 + n2 * 0.3 + n3 * 0.2;
	flame = flame * intensity;

	float shape = 1.0 - uv.y;
	shape = pow(shape, 1.5);
	float edge = abs(uv.x - 0.5) * 2.0;
	shape *= 1.0 - pow(edge, 2.5) * 0.9;

	float flicker = sin(uv.y * 30.0 + t * 8.0) * 0.1;
	flicker += sin(uv.y * 50.0 + t * 12.0 + 100.0) * 0.05;
	flicker = 1.0 + flicker;
	shape *= flicker;

	float alpha = smoothstep(0.25, 1.0, flame) * shape;
	alpha = clamp(alpha * 1.8, 0.0, 1.0);

	vec4 color = mix(flame_color3, flame_color2, uv.y * 0.5 + flame * 0.5);
	color = mix(color, flame_color1, pow(uv.y * 0.8 + flame * 0.2, 2.0) * 0.6);

	float glow = alpha * 0.4;
	glow += exp(-uv.y * 3.0) * 0.15;

	float smoke = noise(vec2(uv.x * 4.0 + time * 0.5, uv.y * 2.0 - time * 0.3));
	smoke = smoothstep(0.4, 0.7, smoke);
	float smoke_alpha = smoke * (1.0 - uv.y) * 0.2;

	vec3 final_rgb = color.rgb * alpha + flame_color1.rgb * glow;
	final_rgb += smoke_color.rgb * smoke_alpha;

	float final_alpha = alpha + glow + smoke_alpha;
	COLOR = vec4(final_rgb, min(final_alpha, 1.0));
}
