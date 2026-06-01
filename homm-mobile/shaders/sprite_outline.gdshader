shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 0.85);
uniform float outline_width : hint_range(0.0, 4.0) = 1.0;
uniform vec4 glow_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float glow_width : hint_range(0.0, 8.0) = 0.0;
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	if (col.a > 0.01) {
		COLOR = col;
		return;
	}

	int kernel_size = int(max(outline_width, glow_width));
	float outline_alpha = 0.0;
	float glow_alpha = 0.0;
	vec2 ps = TEXTURE_PIXEL_SIZE;

	for (int x = -kernel_size; x <= kernel_size; x++) {
		for (int y = -kernel_size; y <= kernel_size; y++) {
			if (x == 0 && y == 0) continue;
			vec2 sample_uv = UV + vec2(float(x), float(y)) * ps;
			if (sample_uv.x < 0.0 || sample_uv.x > 1.0 || sample_uv.y < 0.0 || sample_uv.y > 1.0) continue;
			float sa = texture(TEXTURE, sample_uv).a;
			if (sa > 0.01) {
				float d = length(vec2(float(x), float(y)));
				if (d <= outline_width) {
					outline_alpha = max(outline_alpha, 1.0 - d / (outline_width + 1.0));
				}
				if (d <= glow_width && glow_intensity > 0.0) {
					glow_alpha = max(glow_alpha, (1.0 - d / glow_width) * glow_intensity);
				}
			}
		}
	}

	outline_alpha = clamp(outline_alpha, 0.0, 1.0);
	glow_alpha = clamp(glow_alpha, 0.0, 1.0);

	vec3 final_col = outline_color.rgb * outline_alpha * outline_color.a;
	final_col += glow_color.rgb * glow_alpha * glow_color.a;

	COLOR = vec4(final_col, max(outline_alpha * outline_color.a, glow_alpha * glow_color.a));
}
