shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform vec4 sky_top : source_color = vec4(0.12, 0.18, 0.38, 1.0);
uniform vec4 sky_mid : source_color = vec4(0.35, 0.50, 0.70, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.65, 0.80, 0.90, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.85, 0.50, 1.0);
uniform vec4 cloud_color : source_color = vec4(0.92, 0.90, 0.88, 0.7);
uniform vec4 cloud_shadow : source_color = vec4(0.60, 0.65, 0.75, 0.3);
uniform float cloud_speed : hint_range(0.0, 2.0) = 0.25;
uniform vec2 sun_position : hint_range(-1.0, 2.0) = vec2(0.7, 0.3);

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
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;

	vec3 sky_grad = mix(sky_bottom.rgb, sky_mid.rgb, smoothstep(0.0, 0.4, uv.y));
	sky_grad = mix(sky_grad, sky_top.rgb, smoothstep(0.4, 1.0, uv.y));

	vec2 sun_uv = uv - sun_position;
	float sun_dist = length(sun_uv);
	float sun_glow = exp(-sun_dist * 4.0) * 0.3;
	float sun_disk = exp(-sun_dist * 80.0);
	sun_glow += sun_disk * 0.8;
	sky_grad += sun_color.rgb * sun_glow * 0.5;

	float glow_halo = exp(-sun_dist * 1.5) * 0.15;
	sky_grad += vec3(1.0, 0.9, 0.6) * glow_halo;

	float cloud_uv_x = uv.x * 2.5 + time * cloud_speed;
	float cloud_uv_y = uv.y * 1.2 - time * cloud_speed * 0.08;
	vec2 cloud_p = vec2(cloud_uv_x, cloud_uv_y);
	float c1 = fbm(cloud_p);
	float c2 = fbm(cloud_p * 1.8 + 50.0);
	float c3 = fbm(cloud_p * 3.0 + 200.0);
	float cloud = (c1 * 0.5 + c2 * 0.3 + c3 * 0.2);
	cloud = smoothstep(0.30, 0.70, cloud);

	float edge_fade = 1.0 - smoothstep(0.6, 1.0, uv.y);
	cloud *= edge_fade;

	vec3 cloud_col = mix(cloud_shadow.rgb, cloud_color.rgb, cloud);
	cloud_col += vec3(1.0, 0.95, 0.8) * exp(-sun_dist * 6.0) * cloud * 0.3;
	float cloud_alpha = cloud * cloud_color.a * (0.5 + uv.y * 0.5);

	vec3 final_col = mix(sky_grad, cloud_col, cloud_alpha);

	float horizon_haze = exp(-pow((uv.y - 0.5) * 6.0, 2.0)) * 0.08;
	final_col += vec3(0.7, 0.75, 0.8) * horizon_haze;

	float star_n = noise(uv * 100.0 + 500.0);
	float star_mask = smoothstep(0.85, 0.98, star_n);
	float star_alpha = star_mask * smoothstep(0.5, 0.0, uv.y);
	final_col += vec3(1.0, 0.95, 0.9) * star_alpha * 0.3;

	COLOR = vec4(final_col, 1.0);
}
