shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform vec4 fog_color : source_color = vec4(0.04, 0.06, 0.10, 1.0);
uniform vec4 edge_glow : source_color = vec4(0.30, 0.50, 0.70, 0.15);
uniform float edge_width : hint_range(0.0, 0.3) = 0.08;
uniform float fog_density : hint_range(0.0, 1.0) = 0.6;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	vec2 uv = UV;
	float n1 = noise(uv * 4.0 + time * 0.05);
	float n2 = noise(uv * 8.0 - time * 0.03 + 50.0);
	float cloud = n1 * 0.6 + n2 * 0.4;
	cloud = smoothstep(0.3, 0.8, cloud);
	
	vec3 dark_fog = fog_color.rgb * (1.0 - cloud * 0.3 * fog_density);
	float fog_alpha = tex_color.a;
	COLOR.rgb = mix(tex_color.rgb, dark_fog, fog_alpha * 0.5);
	COLOR.a = fog_alpha;
	
	vec2 dist_to_edge = min(UV, 1.0 - UV);
	float edge_factor = min(dist_to_edge.x, dist_to_edge.y) / edge_width;
	float edge_alpha = 1.0 - smoothstep(0.0, 1.0, edge_factor);
	
	COLOR.rgb += edge_glow.rgb * edge_alpha * edge_glow.a * fog_alpha;
}
