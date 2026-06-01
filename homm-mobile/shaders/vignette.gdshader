shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_roundness : hint_range(0.0, 2.0) = 0.5;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float time : hint_range(0.0, 100.0) = 0.0;

uniform float scanline_strength : hint_range(0.0, 0.1) = 0.0;

uniform float color_saturation : hint_range(0.0, 2.0) = 1.0;
uniform float color_contrast : hint_range(0.0, 2.0) = 1.0;
uniform float color_brightness : hint_range(0.0, 2.0) = 1.0;
uniform vec4 color_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	vec3 c = col.rgb;

	c = (c - 0.5) * color_contrast + 0.5;
	c = c * color_brightness;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(lum), c, color_saturation);
	c *= color_tint.rgb;

	vec2 center = UV - 0.5;
	float vignette = dot(center, center) * vignette_roundness;
	vignette = 1.0 - vignette * vignette_intensity;
	c *= clamp(vignette, 0.0, 1.0);
	c += vignette_color.rgb * (1.0 - vignette) * vignette_color.a;

	if (scanline_strength > 0.0) {
		float scanline = sin(UV.y * 800.0 + time * 2.0) * 0.5 + 0.5;
		c *= 1.0 - scanline * scanline_strength;
	}

	COLOR = vec4(c, col.a);
}
