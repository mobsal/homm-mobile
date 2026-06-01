extends RefCounted

class_name VisualEnhancer

static func add_world_environment(parent: Node) -> WorldEnvironment:
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment_Visual"

	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.tonemap_white = 1.0

	environment.glow_enabled = false
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.02
	environment.adjustment_contrast = 1.05
	environment.adjustment_saturation = 1.1

	env.environment = environment
	parent.add_child(env)
	return env

static func add_vignette_overlay(parent: CanvasLayer) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.name = "VignetteOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.45;
uniform float vignette_roundness : hint_range(0.0, 2.0) = 0.7;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 0.85);

void fragment() {
	vec2 center = UV - 0.5;
	center.x *= 1.4;
	float vignette = dot(center, center) * vignette_roundness;
	vignette = 1.0 - vignette * vignette_intensity;
	float alpha = (1.0 - clamp(vignette, 0.0, 1.0)) * vignette_color.a;
	COLOR = vec4(vignette_color.rgb, alpha);
}
"""

	var mat := ShaderMaterial.new()
	mat.shader = shader
	overlay.material = mat
	parent.add_child(overlay)
	return overlay

static func set_vignette_time(overlay: ColorRect, time: float) -> void:
	if overlay and overlay.material:
		overlay.material.set_shader_parameter("time", time)
