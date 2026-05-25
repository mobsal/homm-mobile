shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform vec4 sky_top : source_color = vec4(0.15, 0.22, 0.40, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.55, 0.70, 0.85, 1.0);
uniform vec4 cloud_color : source_color = vec4(0.90, 0.88, 0.85, 0.6);
uniform vec4 cloud_shadow : source_color = vec4(0.70, 0.72, 0.78, 0.3);
uniform float cloud_speed : hint_range(0.0, 2.0) = 0.3;

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
	float sky_grad = uv.y;
	vec4 sky = mix(sky_bottom, sky_top, sky_grad);
	
	float cloud_uv_x = uv.x * 3.0 + time * cloud_speed;
	float cloud_uv_y = uv.y * 1.5 - time * cloud_speed * 0.1;
	vec2 cloud_p = vec2(cloud_uv_x, cloud_uv_y);
	float c1 = fbm(cloud_p);
	float c2 = fbm(cloud_p * 1.5 + 50.0);
	float cloud = (c1 * 0.7 + c2 * 0.3);
	cloud = smoothstep(0.35, 0.75, cloud);
	
	float edge_fade = 1.0 - smoothstep(0.0, 0.6, uv.y);
	cloud *= edge_fade;
	
	vec4 final_cloud = mix(cloud_shadow, cloud_color, cloud);
	COLOR = mix(sky, final_cloud, cloud * 0.6);
}
