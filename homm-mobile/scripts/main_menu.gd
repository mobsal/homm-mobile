extends Control

# ============================================
# MAIN MENU - Écran titre du jeu
# ============================================

var _title_label: Label
var _subtitle_label: Label
var _btn_new_game: Button
var _btn_continue: Button
var _btn_settings: Button
var _btn_quit: Button
var _settings_panel: Panel = null
var _anim_time: float = 0.0
var _petals: Array = []
var _jap_theme := JapaneseUITheme.new()
var _vignette_overlay: ColorRect = null
var _fog_overlay: ColorRect = null
const FOG_SHADER_CODE := """
shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123); }

float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	float n1 = noise(uv * 3.0 + time * 0.02);
	float n2 = noise(uv * 5.0 - time * 0.03 + 100.0);
	float fog = n1 * 0.6 + n2 * 0.4;
	fog = smoothstep(0.2, 0.6, fog);
	vec2 d = min(UV, 1.0 - UV);
	float vignette = 1.0 - smoothstep(0.0, 0.2, min(d.x, d.y));
	float alpha = fog * 0.25 + vignette * 0.35;
	COLOR = vec4(0.02, 0.03, 0.06, alpha);
}
"""

var _creation_panel: Panel = null

const DOTGOTHIC_FONT = preload("res://assets/fonts/DotGothic16-Regular.ttf")
const NOTO_FONT = preload("res://assets/fonts/NotoSansJP.ttf")

# Couleurs
const COLOR_GOLD := Color(0.95, 0.80, 0.20)
const COLOR_DARK_BG := Color(0.04, 0.03, 0.02)
const COLOR_ACCENT := Color(0.35, 0.28, 0.18)

func _ready() -> void:
	var custom_font: FontFile = DOTGOTHIC_FONT
	if custom_font:
		custom_font.hinting = TextServer.HINTING_NONE
		var fb: FontFile = NOTO_FONT
		if fb:
			custom_font.fallbacks = [fb]
		ThemeDB.fallback_font = custom_font
		var theme := Theme.new()
		theme.default_font = custom_font
		self.theme = theme
		print("✓ Polices personnalisées chargées (DotGothic16 + NotoSansJP)")
	else:
		print("⚠ ÉCHEC chargement DotGothic16")

	print("  ThemeDB.fallback_font = ", ThemeDB.fallback_font)
	
	RetroBGM.play_menu()
	
	# Fond procédural japonais
	_create_japanese_background()
	_add_fog_overlay()
	_setup_visual_enhancements()

	# Titre principal
	_title_label = Label.new()
	_title_label.text = "HOMURA"
	_title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title_label.position = Vector2(0, 80)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 56)
	_title_label.add_theme_color_override("font_color", COLOR_GOLD)
	add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.text = "Heroes of Conquest"
	_subtitle_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_subtitle_label.position = Vector2(0, 140)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 28)
	_subtitle_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	add_child(_subtitle_label)

	# Séparateur décoratif
	var separator = ColorRect.new()
	separator.position = Vector2(get_viewport_rect().size.x / 2 - 100, 200)
	separator.size = Vector2(200, 3)
	separator.color = COLOR_ACCENT
	add_child(separator)

	# Conteneur de boutons
	var btn_container = VBoxContainer.new()
	btn_container.set_anchors_preset(Control.PRESET_CENTER)
	btn_container.position = Vector2(-120, -40)
	btn_container.custom_minimum_size = Vector2(240, 200)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 16)
	add_child(btn_container)

	# Styles des boutons (via JapaneseUITheme)
	var btn_normal = _jap_theme.button_style(Color(0.12, 0.10, 0.06), Color(0.50, 0.40, 0.25))
	var btn_hover = _jap_theme.button_style(Color(0.22, 0.18, 0.10), Color(0.75, 0.60, 0.35))
	var btn_pressed = _jap_theme.button_style(Color(0.08, 0.06, 0.03), Color(0.35, 0.28, 0.15))

	# Bouton Nouvelle Partie
	_btn_new_game = Button.new()
	_btn_new_game.text = "Nouvelle Partie"
	_btn_new_game.custom_minimum_size = Vector2(240, 50)
	_btn_new_game.add_theme_font_size_override("font_size", 18)
	_btn_new_game.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	_btn_new_game.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.9))
	_btn_new_game.add_theme_stylebox_override("normal", btn_normal)
	_btn_new_game.add_theme_stylebox_override("hover", btn_hover)
	_btn_new_game.add_theme_stylebox_override("pressed", btn_pressed)
	_btn_new_game.pressed.connect(_on_new_game_pressed)
	_add_hover_scale(_btn_new_game)
	btn_container.add_child(_btn_new_game)

	# Bouton Continuer
	_btn_continue = Button.new()
	_btn_continue.text = "Continuer"
	_btn_continue.custom_minimum_size = Vector2(240, 50)
	_btn_continue.add_theme_font_size_override("font_size", 18)
	_btn_continue.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_btn_continue.add_theme_stylebox_override("normal", btn_normal)
	_btn_continue.add_theme_stylebox_override("hover", btn_hover)
	_btn_continue.add_theme_stylebox_override("pressed", btn_pressed)
	_btn_continue.disabled = not _has_save_file()
	_btn_continue.pressed.connect(_on_continue_pressed)
	_add_hover_scale(_btn_continue)
	btn_container.add_child(_btn_continue)

	# Bouton Options
	_btn_settings = Button.new()
	_btn_settings.text = "Options"
	_btn_settings.custom_minimum_size = Vector2(240, 50)
	_btn_settings.add_theme_font_size_override("font_size", 18)
	_btn_settings.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	_btn_settings.add_theme_stylebox_override("normal", btn_normal)
	_btn_settings.add_theme_stylebox_override("hover", btn_hover)
	_btn_settings.add_theme_stylebox_override("pressed", btn_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_add_hover_scale(_btn_settings)
	btn_container.add_child(_btn_settings)

	# Bouton Quitter
	_btn_quit = Button.new()
	_btn_quit.text = "Quitter"
	_btn_quit.custom_minimum_size = Vector2(240, 50)
	_btn_quit.add_theme_font_size_override("font_size", 18)
	_btn_quit.add_theme_color_override("font_color", Color(0.85, 0.75, 0.65))
	_btn_quit.add_theme_stylebox_override("normal", btn_normal)
	_btn_quit.add_theme_stylebox_override("hover", btn_hover)
	_btn_quit.add_theme_stylebox_override("pressed", btn_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)
	_add_hover_scale(_btn_quit)
	btn_container.add_child(_btn_quit)

	# Version
	var version_label = Label.new()
	version_label.text = "v1.0.0"
	version_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version_label.position = Vector2(-60, -20)
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version_label.add_theme_font_size_override("font_size", 10)
	version_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	add_child(version_label)

	# Animation d'entrée
	_title_label.modulate.a = 0.0
	_subtitle_label.modulate.a = 0.0
	btn_container.modulate.a = 0.0
	btn_container.scale = Vector2(0.8, 0.8)

	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_title_label, "modulate:a", 1.0, 0.8).set_delay(0.2)
	tween.parallel().tween_property(_subtitle_label, "modulate:a", 1.0, 0.8).set_delay(0.4)
	tween.parallel().tween_property(btn_container, "modulate:a", 1.0, 0.6).set_delay(0.6)
	tween.parallel().tween_property(btn_container, "scale", Vector2(1.0, 1.0), 0.6).set_delay(0.6)

func _process(delta: float) -> void:
	_anim_time += delta
	var shimmer: float = (sin(_anim_time * 0.8) + 1.0) * 0.5
	_title_label.modulate = Color(0.95, 0.80 + shimmer * 0.15, 0.20 + shimmer * 0.1, _title_label.modulate.a)
	if _fog_overlay and _fog_overlay.material:
		_fog_overlay.material.set_shader_parameter("time", _anim_time)
	if _vignette_overlay:
		VisualEnhancer.set_vignette_time(_vignette_overlay, _anim_time)
	_spawn_petal()
	for i in range(_petals.size() - 1, -1, -1):
		var p = _petals[i]
		if not is_instance_valid(p):
			_petals.remove_at(i)
			continue
		var wind_x := sin(_anim_time * 0.3 + i * 0.7) * delta * 8.0
		p.position.y += delta * (45 + sin(_anim_time * 0.7 + i) * 5)
		p.position.x += delta * 12.0 + wind_x
		p.rotation += delta * (0.3 + i * 0.02)
		if p.position.y > get_viewport_rect().size.y + 30:
			p.queue_free()
			_petals.remove_at(i)

func _spawn_petal() -> void:
	if _petals.size() >= 25 or randf() > 0.025:
		return
	var p = ColorRect.new()
	var sz := randf_range(6, 10)
	p.size = Vector2(sz, sz * randf_range(1.3, 2.0))
	var pink_shade := randf_range(0.5, 0.85)
	p.color = Color(0.95, pink_shade, pink_shade * 0.75, randf_range(0.3, 0.6))
	p.position = Vector2(randf() * get_viewport_rect().size.x, -20)
	p.rotation = randf() * TAU
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	_petals.append(p)
	var lifetime = create_tween()
	lifetime.tween_property(p, "modulate:a", 0.0, 8.0).set_delay(randf() * 4.0)

func _create_japanese_background() -> void:
	var screen_size := get_viewport_rect().size
	var bg := ColorRect.new()
	bg.color = COLOR_DARK_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var px_w := 270
	var px_h := 600
	var img := Image.create(px_w, px_h, false, Image.FORMAT_RGBA8)

	# --- Sky gradient ---
	for x in px_w:
		for y in px_h:
			var t: float = float(y) / px_h
			var r: float
			var g: float
			var b: float
			if t < 0.35:
				var lt: float = t / 0.35
				r = 0.04 + lt * 0.12
				g = 0.02 + lt * 0.08
				b = 0.18 + lt * 0.20
			elif t < 0.55:
				var lt: float = (t - 0.35) / 0.20
				r = 0.16 + lt * 0.20
				g = 0.10 + lt * 0.15
				b = 0.38 - lt * 0.10
			elif t < 0.65:
				var lt: float = (t - 0.55) / 0.10
				r = 0.36 + lt * 0.30
				g = 0.25 + lt * 0.15
				b = 0.28 - lt * 0.08
			else:
				var lt: float = (t - 0.65) / 0.35
				r = 0.66 - lt * 0.40
				g = 0.40 - lt * 0.20
				b = 0.20 - lt * 0.08
			img.set_pixel(x, y, Color(r, g, b))

	# --- Stars ---
	var star_rng := RandomNumberGenerator.new()
	star_rng.randomize()
	for s in 50:
		var sx: int = star_rng.randi() % px_w
		var sy: int = star_rng.randi() % int(px_h * 0.45)
		var brightness: float = 0.5 + star_rng.randf() * 0.5
		img.set_pixel(sx, sy, Color(1, 1, 0.9, brightness))
		if star_rng.randf() > 0.7:
			if sx + 1 < px_w:
				img.set_pixel(sx + 1, sy, Color(1, 1, 0.9, brightness * 0.5))

	# --- Moon ---
	var moon_cx: int = 200
	var moon_cy: int = 50
	var moon_r: int = 18
	for x in range(moon_cx - moon_r - 2, moon_cx + moon_r + 3):
		for y in range(moon_cy - moon_r - 2, moon_cy + moon_r + 3):
			var dx: float = (x - moon_cx) / float(moon_r)
			var dy: float = (y - moon_cy) / float(moon_r)
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist <= 1.0:
				if x >= 0 and x < px_w and y >= 0 and y < px_h:
					if dist > 0.85:
						img.set_pixel(x, y, Color(0.80, 0.70, 0.50))
					elif dist > 0.50:
						img.set_pixel(x, y, Color(0.90, 0.82, 0.60))
					else:
						img.set_pixel(x, y, Color(0.95, 0.90, 0.70))

	# --- Clouds ---
	var cloud_rng := RandomNumberGenerator.new()
	cloud_rng.randomize()
	for c in 4:
		var cx: int = cloud_rng.randi() % px_w
		var cy: int = 80 + cloud_rng.randi() % 60
		var cw: int = 30 + cloud_rng.randi() % 40
		var ch: int = 6 + cloud_rng.randi() % 6
		var alpha: float = 0.08 + cloud_rng.randf() * 0.10
		for x in range(cx, cx + cw):
			for y in range(cy, cy + ch):
				var dx: float = (x - cx - cw / 2) / (cw / 2)
				var dy: float = (y - cy - ch / 2) / (ch / 2)
				if dx * dx + dy * dy <= 1.0:
					if x >= 0 and x < px_w and y >= 0 and y < px_h:
						var existing := img.get_pixel(x, y)
						var cloud_c := Color(0.70, 0.65, 0.60, alpha)
						img.set_pixel(x, y, existing.lerp(cloud_c, alpha))

	# --- Far mountains ---
	var mt_data := [
		{ "base_y": 305, "color": Color(0.10, 0.08, 0.14), "peaks": [[50, 50], [80, 35], [120, 55], [155, 40], [190, 50], [220, 38], [260, 48]] },
		{ "base_y": 320, "color": Color(0.16, 0.12, 0.20), "peaks": [[30, 45], [65, 30], [100, 50], [135, 35], [170, 48], [200, 32], [235, 45], [265, 35]] },
		{ "base_y": 335, "color": Color(0.22, 0.18, 0.26), "peaks": [[20, 35], [55, 25], [90, 40], [125, 28], [160, 38], [195, 25], [230, 35], [255, 28]] },
	]
	for mt in mt_data:
		for x in px_w:
			var h: float = 0.0
			for p in mt["peaks"]:
				var dist: float = abs(x - p[0]) / 20.0
				h += p[1] * exp(-dist * dist * 2.5)
			var top_y: int = int(mt["base_y"] - h)
			top_y = clampi(top_y, 0, px_h - 1)
			for y in range(top_y, mt["base_y"] + 1):
				if x >= 0 and x < px_w and y >= 0 and y < px_h:
					img.set_pixel(x, y, mt["color"])

	# --- Snow caps on far mountains ---
	for x in px_w:
		var snow_y := 0
		for y in range(250, 310):
			var px := img.get_pixel(x, y)
			if px.r > 0.05 and px.g > 0.03 and px.r < 0.30:
				snow_y = y
				break
		if snow_y > 0:
			for y in range(snow_y, snow_y + 4):
				if y < px_h and x >= 0 and x < px_w:
					var shade := 0.7 + (y - snow_y) * 0.05
					img.set_pixel(x, y, Color(shade, shade * 0.95, shade * 0.90))

	# --- Castle / Pagoda ---
	var castle_base_y: int = 330
	var castle_x: int = 100
	var castle_colors := {
		"wall": Color(0.20, 0.16, 0.12),
		"roof": Color(0.35, 0.12, 0.10),
		"roof_edge": Color(0.45, 0.15, 0.12),
		"accent": Color(0.70, 0.55, 0.25),
	}
	# Base walls
	for x in range(castle_x - 20, castle_x + 20):
		for y in range(castle_base_y - 15, castle_base_y + 3):
			if x >= 0 and x < px_w and y >= 0 and y < px_h:
				img.set_pixel(x, y, castle_colors["wall"])
	# Gate
	for x in range(castle_x - 5, castle_x + 5):
		for y in range(castle_base_y - 8, castle_base_y + 3):
			if x >= 0 and x < px_w and y >= 0 and y < px_h:
				img.set_pixel(x, y, Color(0.08, 0.06, 0.04))
	# Roof tier 1 (bottom)
	for x in range(castle_x - 30, castle_x + 30):
		var local_x: float = abs(x - castle_x) / 30.0
		var roof_bottom: int = castle_base_y - 15
		var roof_top: int = castle_base_y - 25
		var roof_x_offset: int = int(local_x * local_x * 20)
		var y_start: int = roof_top - roof_x_offset
		for y in range(y_start, roof_bottom + 1):
			if x >= 0 and x < px_w and y >= 0 and y < px_h:
				var edge_dist: float = (roof_bottom - y) / float(roof_bottom - y_start)
				if edge_dist < 0.15 or (abs(local_x) > 0.85 and edge_dist < 0.3):
					img.set_pixel(x, y, castle_colors["roof_edge"])
				else:
					img.set_pixel(x, y, castle_colors["roof"])
	# Roof tier 2 (middle)
	for x in range(castle_x - 22, castle_x + 22):
		var local_x: float = abs(x - castle_x) / 22.0
		var roof_bottom: int = castle_base_y - 30
		var roof_top: int = castle_base_y - 38
		var roof_x_offset: int = int(local_x * local_x * 14)
		var y_start: int = roof_top - roof_x_offset
		for y in range(y_start, roof_bottom + 1):
			if x >= 0 and x < px_w and y >= 0 and y < px_h:
				var edge_dist: float = (roof_bottom - y) / float(roof_bottom - y_start)
				if edge_dist < 0.12 or (abs(local_x) > 0.80 and edge_dist < 0.25):
					img.set_pixel(x, y, castle_colors["roof_edge"])
				else:
					img.set_pixel(x, y, castle_colors["roof"])
	# Roof tier 3 (top)
	for x in range(castle_x - 14, castle_x + 14):
		var local_x: float = abs(x - castle_x) / 14.0
		var roof_bottom: int = castle_base_y - 43
		var roof_top: int = castle_base_y - 50
		var roof_x_offset: int = int(local_x * local_x * 8)
		var y_start: int = roof_top - roof_x_offset
		for y in range(y_start, roof_bottom + 1):
			if x >= 0 and x < px_w and y >= 0 and y < px_h:
				if abs(local_x) > 0.85:
					img.set_pixel(x, y, castle_colors["roof_edge"])
				else:
					img.set_pixel(x, y, castle_colors["roof"])
	# Spire
	for x in range(castle_x - 3, castle_x + 3):
		for y in range(castle_base_y - 58, castle_base_y - 48):
			if x >= 0 and x < px_w and y >= 0 and y < px_h:
				img.set_pixel(x, y, castle_colors["roof_edge"])

	# --- Cherry blossom trees ---
	var tree_rng := RandomNumberGenerator.new()
	tree_rng.randomize()
	var tree_sides := [
		{ "trees": [[30, 345], [45, 355], [55, 340]], "trunk_color": Color(0.22, 0.14, 0.08), "crown_color": Color(0.80, 0.40, 0.50) },
		{ "trees": [[215, 348], [230, 360], [245, 345], [258, 355]], "trunk_color": Color(0.20, 0.12, 0.07), "crown_color": Color(0.75, 0.35, 0.48) },
	]
	for side in tree_sides:
		for tree in side["trees"]:
			var tx: int = tree[0]
			var ty: int = tree[1]
			var trunk_h: int = 15 + tree_rng.randi() % 10
			for y in range(ty - trunk_h, ty):
				for x in range(tx - 1, tx + 2):
					if x >= 0 and x < px_w and y >= 0 and y < px_h:
						img.set_pixel(x, y, side["trunk_color"])
			var crown_r: int = 8 + tree_rng.randi() % 6
			for x in range(tx - crown_r, tx + crown_r + 1):
				for y in range(ty - trunk_h - crown_r, ty - trunk_h + crown_r + 1):
					var dx: float = (x - tx) / float(crown_r)
					var dy: float = (y - (ty - trunk_h)) / float(crown_r)
					if dx * dx + dy * dy <= 1.0 and x >= 0 and x < px_w and y >= 0 and y < px_h:
						var shade := 0.6 + tree_rng.randf() * 0.4
						img.set_pixel(x, y, Color(side["crown_color"].r * shade, side["crown_color"].g * shade, side["crown_color"].b * shade))

	# --- Ground ---
	for x in px_w:
		for y in range(340, px_h):
			var gt: float = (y - 340) / float(px_h - 340)
			if y < 360:
				var dark := Color(0.08, 0.05, 0.04, 1.0)
				img.set_pixel(x, y, dark)
			elif y < 380:
				var dark := Color(0.10, 0.08, 0.06, 1.0)
				img.set_pixel(x, y, dark)
			else:
				var dark := Color(0.12 + tree_rng.randf() * 0.04, 0.18 + tree_rng.randf() * 0.06, 0.08 + tree_rng.randf() * 0.03, 1.0)
				img.set_pixel(x, y, dark)
	# Grass tufts
	for g in 30:
		var gx: int = tree_rng.randi() % px_w
		var gy: int = 380 + tree_rng.randi() % 200
		for i in range(3):
			var gxx := gx + tree_rng.randi() % 3
			var gyy := gy - tree_rng.randi() % 4
			if gxx >= 0 and gxx < px_w and gyy >= 0 and gyy < px_h:
				img.set_pixel(gxx, gyy, Color(0.15, 0.35, 0.10))

	# --- Fog at mountain base ---
	for x in px_w:
		for y in range(340, 365):
			if x >= 0 and x < px_w and y >= 0 and y < px_h:
				var fog_alpha: float = 1.0 - (y - 340) / 25.0
				var fog_c := Color(0.60, 0.55, 0.50, fog_alpha * 0.3)
				var existing := img.get_pixel(x, y)
				img.set_pixel(x, y, existing.lerp(fog_c, fog_alpha * 0.3))

	# --- Create texture and display ---
	var tex := ImageTexture.create_from_image(img)
	var rect := TextureRect.new()
	rect.texture = tex
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(rect)

func _add_fog_overlay() -> void:
	_fog_overlay = ColorRect.new()
	_fog_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fog_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = FOG_SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_fog_overlay.material = mat
	add_child(_fog_overlay)

func _add_hover_scale(b: Button) -> void:
	b.mouse_entered.connect(func():
		if SFX and SFX.has_method("play_hover"):
			SFX.play_hover()
		var ht = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		ht.tween_property(b, "scale", Vector2(1.05, 1.05), 0.15)
	)
	b.mouse_exited.connect(func():
		var ht = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		ht.tween_property(b, "scale", Vector2(1.0, 1.0), 0.1)
	)

func _has_save_file() -> bool:
	return FileAccess.file_exists("user://save_game.json")

func _show_hero_creation() -> void:
	if _creation_panel:
		return
	_creation_panel = Panel.new()
	_creation_panel.position = Vector2(
		(get_viewport_rect().size.x - 360) / 2,
		(get_viewport_rect().size.y - 400) / 2
	)
	_creation_panel.size = Vector2(360, 400)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.04, 0.02, 0.95)
	panel_style.border_color = Color(0.50, 0.40, 0.25)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	_creation_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_creation_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	vbox.add_theme_constant_override("margin_left", 24)
	vbox.add_theme_constant_override("margin_right", 24)
	vbox.add_theme_constant_override("margin_top", 24)
	vbox.add_theme_constant_override("margin_bottom", 24)
	_creation_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Créer votre Héros"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	vbox.add_child(title)

	vbox.add_child(_make_spacer(8))

	var name_label := Label.new()
	name_label.text = "Nom du héros :"
	name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	vbox.add_child(name_label)

	var name_input := LineEdit.new()
	name_input.placeholder_text = "Entrez un nom..."
	name_input.text = GameData.hero_name
	name_input.custom_minimum_size = Vector2(280, 36)
	name_input.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_input)

	vbox.add_child(_make_spacer(12))

	var diff_label := Label.new()
	diff_label.text = "Difficulté :"
	diff_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	vbox.add_child(diff_label)

	var btn_normal = _jap_theme.button_style(Color(0.12, 0.10, 0.06), Color(0.50, 0.40, 0.25))
	var btn_hover = _jap_theme.button_style(Color(0.22, 0.18, 0.10), Color(0.75, 0.60, 0.35))
	var btn_pressed = _jap_theme.button_style(Color(0.08, 0.06, 0.03), Color(0.35, 0.28, 0.15))

	var selected_diff: int = -1
	var diff_btns: Array = []
	var diff_names: Array = ["Facile", "Moyen", "Difficile"]
	var diff_values: Array = [GameData.Difficulty.EASY, GameData.Difficulty.MEDIUM, GameData.Difficulty.HARD]
	var diff_hbox := HBoxContainer.new()
	diff_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	diff_hbox.add_theme_constant_override("separation", 8)

	var start_btn := Button.new()
	start_btn.text = "Commencer l'aventure !"
	start_btn.custom_minimum_size = Vector2(280, 50)
	start_btn.add_theme_font_size_override("font_size", 18)
	start_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	start_btn.disabled = true
	start_btn.add_theme_stylebox_override("normal", _jap_theme.button_style(Color(0.08, 0.06, 0.04), Color(0.25, 0.20, 0.12)))
	start_btn.add_theme_stylebox_override("hover", _jap_theme.button_style(Color(0.08, 0.06, 0.04), Color(0.25, 0.20, 0.12)))
	start_btn.add_theme_stylebox_override("pressed", _jap_theme.button_style(Color(0.08, 0.06, 0.04), Color(0.25, 0.20, 0.12)))

	for di in range(3):
		var db := Button.new()
		db.text = diff_names[di]
		db.custom_minimum_size = Vector2(85, 40)
		db.add_theme_font_size_override("font_size", 14)
		db.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
		var idx = di
		db.pressed.connect(func():
			selected_diff = diff_values[idx]
			for b in diff_btns:
				b.modulate = Color(0.7, 0.7, 0.7)
			db.modulate = Color(1.0, 1.0, 1.0)
			start_btn.disabled = false
			start_btn.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
			start_btn.add_theme_stylebox_override("normal", btn_normal)
			start_btn.add_theme_stylebox_override("hover", btn_hover)
			start_btn.add_theme_stylebox_override("pressed", btn_pressed)
		)
		diff_hbox.add_child(db)
		diff_btns.append(db)
	vbox.add_child(diff_hbox)

	vbox.add_child(_make_spacer(16))

	start_btn.pressed.connect(func():
		var hero_name_text: String = name_input.text.strip_edges()
		if hero_name_text.is_empty():
			hero_name_text = "Samurai"
		GameData.hero_name = hero_name_text
		GameData.difficulty = selected_diff
		GameData.should_load_save = false
		if FileAccess.file_exists("user://save_game.json"):
			var da = DirAccess.open("user://")
			if da:
				da.remove("save_game.json")
		RetroBGM.stop_menu()
		LoadingScreen.show_loading()
		await get_tree().process_frame
		get_tree().change_scene_to_file("res://scenes/tile_map_world.tscn")
	)
	_add_hover_scale(start_btn)
	vbox.add_child(start_btn)

	var back_btn := Button.new()
	back_btn.text = "Retour"
	back_btn.custom_minimum_size = Vector2(280, 36)
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	back_btn.add_theme_stylebox_override("normal", btn_normal)
	back_btn.add_theme_stylebox_override("hover", btn_hover)
	back_btn.add_theme_stylebox_override("pressed", btn_pressed)
	back_btn.pressed.connect(func():
		_creation_panel.queue_free()
		_creation_panel = null
	)
	_add_hover_scale(back_btn)
	vbox.add_child(back_btn)

func _make_spacer(h: int) -> ColorRect:
	var s := ColorRect.new()
	s.custom_minimum_size = Vector2(0, h)
	s.color = Color.TRANSPARENT
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s

func _on_new_game_pressed() -> void:
	if SFX and SFX.has_method("play_click"):
		SFX.play_click()
	_show_hero_creation()

func _on_continue_pressed() -> void:
	if SFX and SFX.has_method("play_click"):
		SFX.play_click()
	GameData.should_load_save = true
	RetroBGM.stop_menu()
	LoadingScreen.show_loading()
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/tile_map_world.tscn")

func _on_settings_pressed() -> void:
	if SFX and SFX.has_method("play_click"):
		SFX.play_click()
	if _settings_panel:
		_settings_panel.queue_free()
		_settings_panel = null
		return

	_settings_panel = Panel.new()
	_settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	_settings_panel.custom_minimum_size = Vector2(280, 200)
	_settings_panel.add_theme_stylebox_override("panel", _jap_theme.panel_style(10))
	add_child(_settings_panel)

	var container := VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 12)
	_settings_panel.add_child(container)

	var title := Label.new()
	title.text = "Options"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.95, 0.80, 0.20))
	container.add_child(title)

	var vol_label := Label.new()
	vol_label.text = "Volume Musique"
	vol_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	container.add_child(vol_label)

	var slider := HSlider.new()
	slider.min_value = -30.0
	slider.max_value = 0.0
	slider.value = _get_bgm_volume()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_set_bgm_volume)
	container.add_child(slider)

	var close_btn := Button.new()
	close_btn.text = "Fermer"
	close_btn.pressed.connect(_on_settings_pressed)
	_jap_theme.style_button(close_btn)
	_jap_theme.add_hover_scale(close_btn)
	container.add_child(close_btn)

func _get_bgm_volume() -> float:
	var bgm = get_node_or_null("/root/RetroBGM")
	if bgm and bgm.has_method("get_volume"):
		return bgm.get_volume()
	return -8.0

func _set_bgm_volume(value: float) -> void:
	var bgm = get_node_or_null("/root/RetroBGM")
	if bgm and bgm.has_method("set_volume"):
		bgm.set_volume(value)

func _setup_visual_enhancements() -> void:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "PostProcessLayer"
	canvas_layer.layer = 128
	add_child(canvas_layer)
	_vignette_overlay = VisualEnhancer.add_vignette_overlay(canvas_layer)

func _on_quit_pressed() -> void:
	get_tree().quit()
