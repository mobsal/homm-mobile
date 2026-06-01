shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform vec4 deep_color : source_color = vec4(0.05, 0.18, 0.35, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.12, 0.42, 0.68, 1.0);
uniform vec4 foam_color : source_color = vec4(0.85, 0.90, 0.95, 0.6);
uniform vec4 reflection_color : source_color = vec4(0.60, 0.75, 0.90, 0.25);
uniform float wave_strength : hint_range(0.0, 0.05) = 0.015;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	vec2 uv_shift = vec2(0.0);

	float w1 = sin(uv.x * 8.0 + time * 1.2) * wave_strength;
	float w2 = sin(uv.y * 6.0 - time * 0.9) * wave_strength * 0.7;
	float w3 = sin((uv.x + uv.y) * 5.0 + time * 1.5) * wave_strength * 0.5;
	float w4 = sin(uv.x * 12.0 - time * 2.0 + uv.y * 4.0) * wave_strength * 0.3;
	uv_shift = vec2(w1 + w3, w2 + w4);

	vec4 col = texture(TEXTURE, uv + uv_shift);

	float depth_factor = smoothstep(0.0, 0.6, uv.y);
	vec3 water_col = mix(deep_color.rgb, shallow_color.rgb, depth_factor);

	float wave_pattern = sin(uv.x * 20.0 + time * 1.8) * 0.5 + 0.5;
	wave_pattern += sin(uv.y * 16.0 + time * 1.4 + uv.x * 4.0) * 0.3;
	wave_pattern = wave_pattern / 1.3;
	water_col += vec3(0.02, 0.04, 0.06) * wave_pattern;

	float n1 = noise(uv * 6.0 + time * 0.3);
	float n2 = noise(uv * 10.0 - time * 0.2 + 100.0);
	float foam = n1 * 0.6 + n2 * 0.4;
	foam = smoothstep(0.55, 0.85, foam);
	float foam_edge = smoothstep(0.3, 1.0, 1.0 - abs(uv.x - 0.5) * 2.0);
	foam *= foam_edge * 0.3;

	float reflection = sin(uv.x * 15.0 + time * 0.5 + uv.y * 10.0) * 0.5 + 0.5;
	reflection *= sin(uv.y * 8.0 - time * 0.3) * 0.5 + 0.5;
	vec3 refl = reflection_color.rgb * reflection * reflection_color.a;

	float sparkle = noise(uv * 20.0 + time * 2.0 + floor(uv * 40.0));
	sparkle = smoothstep(0.7, 0.95, sparkle);
	vec3 sparkle_col = vec3(1.0, 0.95, 0.8) * sparkle * 0.15;

	vec3 final_col = mix(col.rgb, water_col, 0.6 + depth_factor * 0.3);
	final_col += refl;
	final_col += foam_color.rgb * foam * foam_color.a;
	final_col += sparkle_col;

	COLOR = vec4(final_col, col.a);
}
