class_name SakuraParticles
extends Node2D

var _particles: Array = []
var _petal_texture: ImageTexture = _create_petal_texture()
var _time: float = 0.0
var _emit_timer: float = 0.0
var _screen_rect: Rect2

@export var max_particles: int = 40
@export var emit_rate: float = 0.15
@export var wind_strength: float = 15.0
@export var wind_variation: float = 8.0
@export var fall_speed: float = 35.0

func _ready() -> void:
	_screen_rect = get_viewport_rect()
	for i in range(15):
		_spawn_petal(randf() * _screen_rect.size.x, randf() * _screen_rect.size.y, true)

func _process(delta: float) -> void:
	_time += delta
	_screen_rect = get_viewport_rect()
	_emit_timer += delta
	if _emit_timer >= emit_rate and _particles.size() < max_particles:
		_emit_timer = 0.0
		_spawn_petal(randf() * _screen_rect.size.x * 1.4 - _screen_rect.size.x * 0.2, -30)

	for i in range(_particles.size() - 1, -1, -1):
		var p := _particles[i]
		if not is_instance_valid(p.node):
			_particles.remove_at(i)
			continue
		p.phase += delta * p.speed
		var wind_x := sin(_time * 0.3 + p.offset) * wind_variation
		p.node.position.x += (wind_strength + wind_x) * delta
		p.node.position.y += (fall_speed + sin(p.phase * 2.0) * 8.0) * delta
		p.node.rotation += delta * p.rot_speed
		var wobble := sin(p.phase * 1.5) * 0.3
		p.node.scale = Vector2(p.base_scale + wobble * 0.1, p.base_scale - wobble * 0.05)
		if p.node.position.y > _screen_rect.size.y + 40 or p.node.position.x < -60 or p.node.position.x > _screen_rect.size.x + 60:
			_spawn_petal(randf() * _screen_rect.size.x * 1.4 - _screen_rect.size.x * 0.2, -30)
			_particles.remove_at(i)

func _spawn_petal(x: float, y: float, random_age: bool = false) -> void:
	var p := ColorRect.new()
	p.size = Vector2(randf_range(6, 10), randf_range(10, 16))
	p.position = Vector2(x, y)
	var pink_shade := randf_range(0.5, 0.85)
	p.color = Color(0.95, pink_shade, pink_shade * 0.8, randf_range(0.4, 0.7))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.rotation = randf() * TAU
	add_child(p)
	_particles.append({
		node = p,
		phase = randf() * TAU if not random_age else _time * (0.5 + randf()),
		speed = randf_range(0.4, 1.0),
		offset = randf() * TAU,
		rot_speed = randf_range(0.3, 0.8) * (1.0 if randf() > 0.5 else -1.0),
		base_scale = randf_range(0.7, 1.3),
	})

static func _create_petal_texture() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 16:
		for y in 16:
			var cx := (x - 8) / 8.0
			var cy := (y - 8) / 8.0
			var d := sqrt(cx * cx + cy * cy)
			if d <= 1.0:
				var alpha := 1.0 - d * d
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha * 0.8))
	return ImageTexture.create_from_image(img)
