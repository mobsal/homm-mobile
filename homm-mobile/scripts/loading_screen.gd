extends CanvasLayer

var _container: Control
var _spinner: Node2D
var _arcs: Array = []
var _loading_label: Label
var _title_label: Label
var _petals: Array = []
var _anim_time: float = 0.0
var _visible_flag: bool = false
var _screen_size: Vector2

const COLOR_GOLD := Color(0.95, 0.80, 0.20)
const COLOR_DARK_BG := Color(0.04, 0.03, 0.02)

func show_loading() -> void:
	if _visible_flag:
		return
	_visible_flag = true

	if get_viewport():
		_screen_size = get_viewport().get_visible_rect().size
	else:
		_screen_size = Vector2(1080, 2400)

	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_container)

	var bg := ColorRect.new()
	bg.color = COLOR_DARK_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.add_child(bg)

	_title_label = Label.new()
	_title_label.text = "HOMURA"
	_title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title_label.position = Vector2(0, 80)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 56)
	_title_label.add_theme_color_override("font_color", COLOR_GOLD)
	_container.add_child(_title_label)

	var subtitle := Label.new()
	subtitle.text = "Heroes of Conquest"
	subtitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitle.position = Vector2(0, 140)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	_container.add_child(subtitle)

	var cx := _screen_size.x / 2
	var cy := _screen_size.y / 2

	_spinner = Node2D.new()
	_spinner.position = Vector2(cx, cy - 40)
	_container.add_child(_spinner)

	var arc_radius: float = 40.0
	var arc_count: int = 8
	for i in range(arc_count):
		var arc := ColorRect.new()
		arc.size = Vector2(6, 16)
		var angle: float = (float(i) / float(arc_count)) * TAU
		arc.position = Vector2(
			cos(angle) * arc_radius - arc.size.x / 2,
			sin(angle) * arc_radius - arc.size.y / 2
		)
		arc.rotation = angle
		arc.color = Color(0.95, 0.80, 0.20, 1.0)
		arc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_spinner.add_child(arc)
		_arcs.append(arc)

	var inner_ring := ColorRect.new()
	inner_ring.size = Vector2(16, 16)
	inner_ring.position = Vector2(-8, -8)
	inner_ring.color = Color(0.8, 0.7, 0.5, 0.3)
	inner_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spinner.add_child(inner_ring)

	_loading_label = Label.new()
	_loading_label.text = "Chargement"
	_loading_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_loading_label.position = Vector2(0, cy + 40)
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.add_theme_font_size_override("font_size", 18)
	_loading_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	_container.add_child(_loading_label)

	var tip_label := Label.new()
	tip_label.text = "Préparez votre aventure..."
	tip_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tip_label.position = Vector2(0, cy + 70)
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 12)
	tip_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35))
	_container.add_child(tip_label)

	var separator := ColorRect.new()
	separator.position = Vector2(cx - 80, 185)
	separator.size = Vector2(160, 2)
	separator.color = Color(0.35, 0.28, 0.18)
	_container.add_child(separator)

	_container.modulate.a = 0.0
	var fade_in = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	fade_in.tween_property(_container, "modulate:a", 1.0, 0.4)

	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

func hide_loading() -> void:
	if not _visible_flag:
		return
	set_process(false)
	var fade_out = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fade_out.tween_property(_container, "modulate:a", 0.0, 0.3)
	fade_out.tween_callback(func():
		_visible_flag = false
		_petals.clear()
		_arcs.clear()
		for c in get_children():
			c.queue_free()
		_container = null
		_spinner = null
		_loading_label = null
		_title_label = null
	)

func _process(delta: float) -> void:
	if not _visible_flag:
		return
	_anim_time += delta

	if _spinner:
		_spinner.rotation += delta * 2.0

	for i in range(_arcs.size()):
		var phase: float = (float(i) / float(_arcs.size())) * TAU
		var alpha: float = (sin(_anim_time * 3.0 + phase) + 1.0) * 0.4 + 0.15
		if is_instance_valid(_arcs[i]):
			_arcs[i].color.a = alpha

	if _loading_label:
		var dot_count: int = int(_anim_time * 2.0) % 4
		_loading_label.text = "Chargement" + ".".repeat(dot_count)

	if _title_label:
		var shimmer: float = (sin(_anim_time * 0.8) + 1.0) * 0.5
		_title_label.modulate = Color(0.95, 0.80 + shimmer * 0.15, 0.20 + shimmer * 0.1, _title_label.modulate.a)

	_spawn_petal()
	var screen_h := _screen_size.y
	for i in range(_petals.size() - 1, -1, -1):
		var p = _petals[i]
		if not is_instance_valid(p):
			_petals.remove_at(i)
			continue
		var wind_x := sin(_anim_time * 0.3 + i * 0.7) * delta * 8.0
		p.position.y += delta * (45 + sin(_anim_time * 0.7 + i) * 5)
		p.position.x += delta * 12.0 + wind_x
		p.rotation += delta * (0.3 + i * 0.02)
		if p.position.y > screen_h + 30:
			p.queue_free()
			_petals.remove_at(i)

func _spawn_petal() -> void:
	if _petals.size() >= 20 or randf() > 0.03:
		return
	var p = ColorRect.new()
	var sz := randf_range(5, 9)
	p.size = Vector2(sz, sz * randf_range(1.3, 2.0))
	var pink_shade := randf_range(0.5, 0.85)
	p.color = Color(0.95, pink_shade, pink_shade * 0.75, randf_range(0.3, 0.5))
	p.position = Vector2(randf() * _screen_size.x, -20)
	p.rotation = randf() * TAU
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(p)
	_petals.append(p)
	var lifetime = create_tween()
	lifetime.tween_property(p, "modulate:a", 0.0, 6.0).set_delay(randf() * 3.0)
