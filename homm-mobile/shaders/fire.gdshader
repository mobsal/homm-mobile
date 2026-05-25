shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform vec4 flame_color1 : source_color = vec4(1.0, 0.6, 0.1, 1.0);
uniform vec4 flame_color2 : source_color = vec4(1.0, 0.2, 0.05, 1.0);
uniform vec4 flame_color3 : source_color = vec4(0.8, 0.1, 0.0, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float flame_height : hint_range(0.5, 2.0) = 1.0;

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

void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y;
	uv.y *= flame_height;
	
	float t = time * 2.0;
	
	float n1 = noise(vec2(uv.x * 6.0 + t * 1.3, uv.y * 4.0 - t * 0.8));
	float n2 = noise(vec2(uv.x * 4.0 - t * 1.1, uv.y * 6.0 + t * 0.5));
	float n3 = noise(vec2(uv.x * 8.0 + t * 2.1, uv.y * 3.0 - t * 1.2));
	
	float flame = n1 * 0.5 + n2 * 0.3 + n3 * 0.2;
	flame = flame * intensity;
	
	float shape = 1.0 - uv.y;
	shape = pow(shape, 1.5);
	float edge = abs(uv.x - 0.5) * 2.0;
	shape *= 1.0 - pow(edge, 3.0) * 0.8;
	
	float flicker = sin(uv.y * 20.0 + t * 5.0) * 0.1 + 0.9;
	shape *= flicker;
	
	float alpha = smoothstep(0.3, 1.0, flame) * shape;
	alpha = clamp(alpha * 1.5, 0.0, 1.0);
	
	vec4 color = mix(flame_color3, flame_color2, uv.y * 0.6 + flame * 0.4);
	color = mix(color, flame_color1, pow(uv.y, 2.0) * 0.7);
	
	float glow = alpha * 0.3;
	COLOR = color * alpha + vec4(flame_color1.rgb, 1.0) * glow;
	COLOR.a = alpha + glow;
}
