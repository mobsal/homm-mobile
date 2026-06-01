shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float bob_intensity : hint_range(0.0, 10.0) = 2.0;
uniform float bob_speed : hint_range(0.0, 4.0) = 1.5;
uniform float pulse_intensity : hint_range(0.0, 0.1) = 0.02;
uniform float pulse_speed : hint_range(0.0, 4.0) = 2.0;

void vertex() {
	float bob = sin(time * bob_speed + VERTEX.x * 0.1) * bob_intensity;
	VERTEX.y += bob;
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float pulse = 1.0 + sin(time * pulse_speed) * pulse_intensity;
	COLOR = vec4(col.rgb * pulse, col.a);
}
