class_name JapaneseUITheme extends RefCounted

const COLOR_GOLD := Color(0.95, 0.80, 0.20)
const COLOR_GOLD_BRIGHT := Color(1.0, 0.90, 0.40)
const COLOR_VERMILION := Color(0.85, 0.25, 0.25)
const COLOR_DARK_WOOD := Color(0.10, 0.08, 0.06)
const COLOR_MED_WOOD := Color(0.18, 0.14, 0.10)
const COLOR_LIGHT_WOOD := Color(0.25, 0.20, 0.14)
const COLOR_BG_DARK := Color(0.06, 0.05, 0.04)
const COLOR_TEXT := Color(0.95, 0.88, 0.75)
const COLOR_TEXT_DIM := Color(0.70, 0.60, 0.45)
const COLOR_PARCHMENT := Color(0.92, 0.88, 0.78)

static func panel_style(corner: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = COLOR_DARK_WOOD
	s.border_color = COLOR_GOLD
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	s.shadow_color = Color(0, 0, 0, 0.50)
	s.shadow_size = 12
	s.shadow_offset = Vector2(0, 6)
	return s

static func panel_style_subtle(corner: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.06, 0.04)
	s.border_color = Color(0.35, 0.28, 0.18)
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	return s

static func button_style(bg: Color = COLOR_MED_WOOD, border: Color = COLOR_GOLD) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 4
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	s.shadow_color = Color(0, 0, 0, 0.40)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 3)
	return s

static func button_hover_style() -> StyleBoxFlat:
	return button_style(COLOR_LIGHT_WOOD, COLOR_GOLD_BRIGHT)

static func button_pressed_style() -> StyleBoxFlat:
	return button_style(Color(0.08, 0.06, 0.03), Color(0.60, 0.50, 0.30))

static func style_button(btn: Button) -> void:
	var normal := button_style()
	var hover := button_style(COLOR_LIGHT_WOOD, COLOR_GOLD_BRIGHT)
	var pressed := button_style(Color(0.08, 0.06, 0.03), Color(0.60, 0.50, 0.30))
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.9))
	btn.add_theme_color_override("font_pressed_color", Color(0.8, 0.8, 0.75))

static func style_label(label: Label, gold: bool = false, size: int = 14) -> void:
	label.add_theme_color_override("font_color", COLOR_GOLD if gold else COLOR_TEXT)
	label.add_theme_font_size_override("font_size", size)

static func add_hover_scale(control: Control, scale_up: float = 1.05) -> void:
	control.mouse_entered.connect(func():
		var t := control.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(control, "scale", Vector2(scale_up, scale_up), 0.12)
	)
	control.mouse_exited.connect(func():
		var t := control.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		t.tween_property(control, "scale", Vector2(1.0, 1.0), 0.08)
	)

static func create_japanese_border(pattern: Color = COLOR_VERMILION) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_color = pattern
	s.border_width_left = 3
	s.border_width_right = 3
	s.border_width_top = 3
	s.border_width_bottom = 3
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	return s

static func corner_decoration(parent: Control, color: Color = COLOR_GOLD, size: int = 8, offset: int = -4) -> void:
	var corners := [Vector2(offset, offset), Vector2(1, offset), Vector2(offset, 1), Vector2(1, 1)]
	for c in corners:
		var corner := ColorRect.new()
		corner.color = color
		corner.size = Vector2(size, size)
		if c.x == 1:
			corner.position.x = parent.size.x - size + offset
		else:
			corner.position.x = c.x
		if c.y == 1:
			corner.position.y = parent.size.y - size + offset
		else:
			corner.position.y = c.y
		corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(corner)
		parent.resized.connect(func():
			if c.x == 1:
				corner.position.x = parent.size.x - size + offset
			if c.y == 1:
				corner.position.y = parent.size.y - size + offset
		)

static func divider(parent: Control, y_pos: float, width_ratio: float = 0.6, color: Color = COLOR_GOLD) -> void:
	var div := ColorRect.new()
	div.color = color
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(div)
	parent.resized.connect(func():
		var w := parent.size.x * width_ratio
		div.position = Vector2((parent.size.x - w) / 2.0, y_pos)
		div.size = Vector2(w, 2)
	)

static func flash_screen(parent: CanvasItem, color: Color, duration: float = 0.2) -> void:
	var flash := ColorRect.new()
	flash.color = color
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(flash)
	var t := parent.create_tween()
	t.tween_property(flash, "color:a", 0.0, duration).from(0.5)
	t.tween_callback(flash.queue_free)
