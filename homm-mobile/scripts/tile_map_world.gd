extends Node2D

# Constants pour la carte
const TILE_SIZE: int = 64

# Dimensions du monde (NOUVEAUX noms pour éviter le cache Godot)
var _map_width: int = 60
var _map_height: int = 40
var _play_w: int = 60
var _play_h: int = 40
var _zx: int = 0
var _zy: int = 0
var _zex: int = 60
var _zey: int = 40

# Aliases pour compatibilité (propriétés dynamiques)
var _world_w: int:
	get: return _map_width
	set(value): _map_width = value
var _world_h: int:
	get: return _map_height
	set(value): _map_height = value
var _zone_w: int:
	get: return _play_w
	set(value): _play_w = value
var _zone_h: int:
	get: return _play_h
	set(value): _play_h = value

# Références aux objets
var _hero: Node2D = null
var _camera: Camera2D = null
var _movement_indicator: Node2D = null  # Indicateur de portée de déplacement
var _floating_texts: Array = []  # Textes flottants (effets visuels)

# Références UI
var _label_gold: Label = null
var _label_wood: Label = null
var _label_ore: Label = null

# Panneau héros amélioré
var _label_hero_name: Label = null
var _xp_bar_bg: ColorRect = null
var _xp_bar_fill: ColorRect = null
var _hp_bar_bg: ColorRect = null
var _hp_bar_fill: ColorRect = null
var _label_xp: Label = null
var _label_hp: Label = null
var _resource_gold_label: Label = null
var _resource_wood_label: Label = null
var _resource_ore_label: Label = null
var _label_level: Label = null

# Position du héros
var _hero_tile: Vector2i = Vector2i.ZERO


# ============================================================
# GÉNÉRATEUR DE SPRITES PROCÉDURAUX PIXEL ART
# ============================================================
func _generate_sprite(type: String, size: int, variant_seed: int = -1) -> ImageTexture:
	"""Génère un sprite pixel art détaillé procéduralement avec variante optionnelle"""
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if variant_seed >= 0:
		rng.seed = variant_seed
	else:
		rng.randomize()
	
	# Fond transparent
	img.fill(Color(0, 0, 0, 0))
	
	match type:
		"castle":
			_generate_castle_sprite(img, size, rng)
		"house":
			_generate_house_sprite(img, size, rng)
		"mine_gold":
			_generate_mine_sprite(img, size, rng, Color(0.9, 0.75, 0.1))
		"mine_wood":
			_generate_mine_sprite(img, size, rng, Color(0.5, 0.35, 0.2))
		"mine_ore":
			_generate_mine_sprite(img, size, rng, Color(0.6, 0.6, 0.65))
		"tower":
			_generate_tower_sprite(img, size, rng)
		"tree":
			_generate_tree_sprite(img, size, rng)
		"rock":
			_generate_rock_sprite(img, size, rng)
		"chest":
			_generate_chest_sprite(img, size, rng)
		"enemy_skeleton":
			_generate_enemy_sprite(img, size, rng, "skeleton")
		"enemy_goblin":
			_generate_enemy_sprite(img, size, rng, "goblin")
		"enemy_archer":
			_generate_enemy_sprite(img, size, rng, "archer")
		"enemy_swordsman":
			_generate_enemy_sprite(img, size, rng, "swordsman")
		"hero":
			_generate_hero_sprite(img, size, rng)
		_:
			# Fallback : cercle coloré
			for x in range(size):
				for y in range(size):
					if (x - size/2)**2 + (y - size/2)**2 < (size/3)**2:
						img.set_pixel(x, y, Color(0.5, 0.5, 0.5))
	
	# Ajouter un contour noir autour du sprite
	_add_outline(img)

	# Effet de lueur douce pour les éléments importants
	if type in ["mine_gold", "mine_ore", "chest", "tower"]:
		var glow_color = Color(0.9, 0.8, 0.3, 0.15) if type == "mine_gold" else Color(0.5, 0.5, 0.6, 0.12) if type == "mine_ore" else Color(0.85, 0.7, 0.2, 0.18) if type == "chest" else Color(0.3, 0.3, 0.35, 0.10)
		for x in range(size):
			for y in range(size):
				if img.get_pixel(x, y).a > 0:
					for dx in range(-2, 3):
						for dy in range(-2, 3):
							var nx = x + dx
							var ny = y + dy
							if nx >= 0 and nx < size and ny >= 0 and ny < size:
								if img.get_pixel(nx, ny).a == 0:
									var dist = sqrt(dx*dx + dy*dy)
									var alpha = glow_color.a * (1.0 - dist / 3.0)
									if alpha > 0:
										var existing = img.get_pixel(nx, ny)
										if existing.a == 0:
											img.set_pixel(nx, ny, Color(glow_color.r, glow_color.g, glow_color.b, alpha))

	return ImageTexture.create_from_image(img)

func _draw_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	if w <= 0 or h <= 0:
		return
	var rx: int = max(x, 0)
	var ry: int = max(y, 0)
	var rw: int = min(w, img.get_width() - rx)
	var rh: int = min(h, img.get_height() - ry)
	if rw > 0 and rh > 0:
		img.fill_rect(Rect2i(rx, ry, rw, rh), color)

func _draw_pixel(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, color)

func _draw_circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for x in range(-r, r + 1):
		for y in range(-r, r + 1):
			if x*x + y*y <= r*r:
				_draw_pixel(img, cx + x, cy + y, color)

func _draw_line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color, thickness: int = 1) -> void:
	var dx: int = abs(x1 - x0)
	var dy: int = abs(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy
	while true:
		for tx in range(-thickness/2, thickness/2 + 1):
			for ty in range(-thickness/2, thickness/2 + 1):
				_draw_pixel(img, x0 + tx, y0 + ty, color)
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

func _add_noise_to_rect(img: Image, x: int, y: int, w: int, h: int, base_color: Color, noise_amount: float, rng: RandomNumberGenerator) -> void:
	for dx in range(w):
		for dy in range(h):
			var nx: int = x + dx
			var ny: int = y + dy
			if nx >= 0 and nx < img.get_width() and ny >= 0 and ny < img.get_height():
				var noise: float = rng.randf_range(-noise_amount, noise_amount)
				var c: Color = base_color
				c.r = clamp(c.r + noise, 0, 1)
				c.g = clamp(c.g + noise, 0, 1)
				c.b = clamp(c.b + noise, 0, 1)
				img.set_pixel(nx, ny, c)

func _draw_gradient_rect(img: Image, x: int, y: int, w: int, h: int, top_color: Color, bottom_color: Color) -> void:
	for dx in range(w):
		for dy in range(h):
			var nx: int = x + dx
			var ny: int = y + dy
			if nx >= 0 and nx < img.get_width() and ny >= 0 and ny < img.get_height():
				var t: float = dy / max(1.0, float(h - 1))
				img.set_pixel(nx, ny, top_color.lerp(bottom_color, t))

func _draw_shaded_circle(img: Image, cx: int, cy: int, r: int, base_color: Color, highlight_dir: Vector2 = Vector2(-1, -1)) -> void:
	var hr: float = highlight_dir.normalized().x
	var hy: float = highlight_dir.normalized().y
	for x in range(cx - r - 1, cx + r + 2):
		for y in range(cy - r - 1, cy + r + 2):
			var dx: float = float(x - cx) / max(1, r)
			var dy: float = float(y - cy) / max(1, r)
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist <= 1.0 and x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				var shade: float = (dx * hr + dy * hy) * 0.25
				var c: Color = base_color
				c.r = clamp(c.r + shade, 0, 1)
				c.g = clamp(c.g + shade, 0, 1)
				c.b = clamp(c.b + shade, 0, 1)
				var edge_alpha: float = 1.0 if dist < 0.85 else (1.0 - dist) / 0.15
				c.a = clamp(edge_alpha, 0, 1)
				img.set_pixel(x, y, c)

func _draw_triangle(img: Image, x1: int, y1: int, x2: int, y2: int, x3: int, y3: int, color: Color) -> void:
	var min_x: int = min(x1, min(x2, x3))
	var max_x: int = max(x1, max(x2, x3))
	var min_y: int = min(y1, min(y2, y3))
	var max_y: int = max(y1, max(y2, y3))
	for x in range(max(0, min_x), min(img.get_width(), max_x + 1)):
		for y in range(max(0, min_y), min(img.get_height(), max_y + 1)):
			var b1: float = float((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / float((y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3) + 0.001)
			var b2: float = float((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / float((y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3) + 0.001)
			var b3: float = 1.0 - b1 - b2
			if b1 >= 0 and b2 >= 0 and b3 >= 0:
				img.set_pixel(x, y, color)

func _draw_vertical_gradient_rect(img: Image, x: int, y: int, w: int, h: int, left_color: Color, right_color: Color) -> void:
	for dx in range(w):
		for dy in range(h):
			var nx: int = x + dx
			var ny: int = y + dy
			if nx >= 0 and nx < img.get_width() and ny >= 0 and ny < img.get_height():
				var t: float = dx / max(1.0, float(w - 1))
				img.set_pixel(nx, ny, left_color.lerp(right_color, t))

func _draw_ramp(img: Image, x1: int, y1: int, w: int, h: int, top_w: int, color: Color) -> void:
	var hw: int = w / 2
	var thw: int = top_w / 2
	for dy in range(h):
		var t: float = dy / max(1.0, float(h - 1))
		var cw: int = int(lerp(float(thw * 2), float(w), t))
		var chw: int = cw / 2
		var cx: int = x1 + hw - chw
		for dx in range(cw):
			var nx: int = cx + dx
			var ny: int = y1 + dy
			if nx >= 0 and nx < img.get_width() and ny >= 0 and ny < img.get_height():
				img.set_pixel(nx, ny, color)

func _add_bevel(img: Image, x: int, y: int, w: int, h: int, highlight: Color, shadow: Color) -> void:
	for dx in range(w):
		if x + dx >= 0 and x + dx < img.get_width():
			if y >= 0 and y < img.get_height():
				img.set_pixel(x + dx, y, highlight)
			if y + h - 1 >= 0 and y + h - 1 < img.get_height():
				img.set_pixel(x + dx, y + h - 1, shadow)
	for dy in range(h):
		if y + dy >= 0 and y + dy < img.get_height():
			if x >= 0 and x < img.get_width():
				img.set_pixel(x, y + dy, highlight)
			if x + w - 1 >= 0 and x + w - 1 < img.get_width():
				img.set_pixel(x + w - 1, y + dy, shadow)

func _add_outline(img: Image, outline_color: Color = Color(0, 0, 0, 0.85), thickness: int = 1) -> void:
	"""Ajoute un contour noir autour des pixels opaques de l'image"""
	var w: int = img.get_width()
	var h: int = img.get_height()
	var outline_pixels: Array = []
	for x in range(w):
		for y in range(h):
			if img.get_pixel(x, y).a > 0.1:
				for ox in range(-thickness, thickness + 1):
					for oy in range(-thickness, thickness + 1):
						if ox == 0 and oy == 0:
							continue
						var nx: int = x + ox
						var ny: int = y + oy
						if nx >= 0 and nx < w and ny >= 0 and ny < h:
							if img.get_pixel(nx, ny).a <= 0.1:
								outline_pixels.append(Vector2i(nx, ny))
	for p in outline_pixels:
		img.set_pixel(p.x, p.y, outline_color)

func _create_elliptical_shadow(parent: Node2D, width: int, height: int, y_offset: int, opacity: float = 0.35) -> void:
	"""Crée une ombre elliptique réaliste sous un sprite"""
	var shadow_texture: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	shadow_texture.fill(Color(0, 0, 0, 0))
	
	var hw: int = width / 2
	var hh: int = height / 2
	
	# Dessiner une ellipse avec dégradé
	for x in range(width):
		for y in range(height):
			# Normaliser les coordonnées (-1 à 1)
			var nx: float = (x - hw) / float(hw)
			var ny: float = (y - hh) / float(hh)
			# Distance depuis le centre de l'ellipse
			var dist: float = nx * nx + ny * ny
			if dist <= 1.0:
				# Alpha basé sur la distance (plus foncé au centre)
				var alpha: float = opacity * (1.0 - dist * 0.5)
				shadow_texture.set_pixel(x, y, Color(0, 0, 0, alpha))
	
	var shadow_sprite: Sprite2D = Sprite2D.new()
	shadow_sprite.texture = ImageTexture.create_from_image(shadow_texture)
	shadow_sprite.position = Vector2(0, y_offset)
	shadow_sprite.set_z_index(-1)
	parent.add_child(shadow_sprite)

# --- CHÂTEAU 192x192 MEGA DÉTAILLÉ ---
func _generate_castle_sprite(img: Image, size: int, rng: RandomNumberGenerator) -> void:
	var s: int = size
	var hs: int = s / 2
	
	# === 1. OMBRE MASSIVE AU SOL ===
	_draw_rect(img, 10, s - 12, s - 20, 12, Color(0, 0, 0, 0.30))
	
	# === 2. FOSSÉ D'EAU (demi-cercle devant) ===
	for fx in range(hs - 60, hs + 60):
		for fy in range(hs + 50, hs + 72):
			var dist: float = abs(fx - hs) * 0.02 + (fy - hs - 50) * 0.03
			if dist < 2.0:
				var water: Color = Color(0.12, 0.22, 0.42, 0.85)
				if (fx + fy) % 6 < 3:
					water = Color(0.15, 0.26, 0.48, 0.85)
				img.set_pixel(fx, fy, water)
	
	# === 3. PONT-LEVIS (bois détaillé avec traverses) ===
	var bridge_w: int = 40
	var bridge_x: int = hs - bridge_w / 2
	_draw_rect(img, bridge_x - 2, hs + 48, bridge_w + 4, 14, Color(0.30, 0.20, 0.12))
	for bx in [bridge_x, bridge_x + 6, bridge_x + 12, bridge_x + 18, bridge_x + 24, bridge_x + 30, bridge_x + 36]:
		_draw_rect(img, bx, hs + 48, 3, 14, Color(0.25, 0.15, 0.08))
	# Chaînes massives
	_draw_rect(img, bridge_x - 4, hs + 44, 4, 16, Color(0.45, 0.42, 0.38))
	_draw_rect(img, bridge_x + bridge_w, hs + 44, 4, 16, Color(0.45, 0.42, 0.38))
	# Rivets sur les chaînes
	for ry in [hs + 46, hs + 50, hs + 54, hs + 58]:
		_draw_rect(img, bridge_x - 3, ry, 2, 2, Color(0.55, 0.52, 0.48))
		_draw_rect(img, bridge_x + bridge_w + 1, ry, 2, 2, Color(0.55, 0.52, 0.48))
	
	# === 4. SOL / FONDATION (terre compacte avec herbe) ===
	_draw_rect(img, 8, hs + 12, s - 16, hs - 16, Color(0.40, 0.30, 0.20))
	_draw_rect(img, 6, hs + 12, s - 12, 6, Color(0.32, 0.30, 0.28))
	# Herbe au bord
	for gx in range(6, s - 6, 4):
		if rng.randf() < 0.4:
			_draw_rect(img, gx, hs + 10, 3, 4, Color(0.20, 0.38, 0.12))
	
	# === 5. MUR D'ENCEINTE EXTÉRIEUR ===
	var outer_mx: int = hs - 60
	var outer_my: int = hs - 10
	var outer_mw: int = 120
	var outer_mh: int = 32
	_add_noise_to_rect(img, outer_mx, outer_my, outer_mw, outer_mh, Color(0.48, 0.46, 0.43), 0.06, rng)
	for jy in range(outer_my + 10, outer_my + outer_mh, 12):
		_draw_rect(img, outer_mx, jy, outer_mw, 2, Color(0.38, 0.36, 0.33))
	# Créneaux extérieurs
	for cx in range(outer_mx, outer_mx + outer_mw, 8):
		_draw_rect(img, cx, outer_my - 8, 4, 8, Color(0.46, 0.44, 0.41))
	
	# === 6. TOURS D'ANGLE (30×80) - 4 tours massives ===
	var tw: int = 30
	var th: int = 80
	var tower_pos: Array = [Vector2(24, 18), Vector2(138, 18), Vector2(24, 78), Vector2(138, 78)]
	var t_cols: Array = [Color(0.44, 0.42, 0.39), Color(0.46, 0.44, 0.41), Color(0.48, 0.46, 0.43), Color(0.45, 0.43, 0.40)]
	
	for i in range(4):
		var tx: int = int(tower_pos[i].x)
		var ty: int = int(tower_pos[i].y)
		# Base de la tour (plus large)
		_draw_rect(img, tx - 2, ty + th - 4, tw + 4, 6, Color(0.38, 0.36, 0.33))
		# Corps
		_add_noise_to_rect(img, tx, ty, tw, th, t_cols[i], 0.06, rng)
		# Joints horizontaux (tous les 10px)
		for jy in range(ty + 12, ty + th, 10):
			_draw_rect(img, tx, jy, tw, 2, Color(0.36, 0.34, 0.31))
		# Meurtrières (petites fentes verticales)
		for mry in [ty + 20, ty + 35, ty + 50, ty + 65]:
			_draw_rect(img, tx + 6, mry, 3, 6, Color(0.15, 0.13, 0.10))
			_draw_rect(img, tx + tw - 9, mry, 3, 6, Color(0.15, 0.13, 0.10))
		# Créneaux (5 créneaux)
		for cx in [tx + 4, tx + 10, tx + 16, tx + 22, tx + 26]:
			_draw_rect(img, cx, ty - 8, 3, 10, t_cols[i])
	
	# === 7. MUR INTÉRIEUR ===
	var mw: int = 84
	var mh: int = 48
	var mx: int = hs - mw / 2
	var my: int = hs - 2
	_add_noise_to_rect(img, mx, my, mw, mh, Color(0.50, 0.48, 0.45), 0.07, rng)
	for jy in range(my + 12, my + mh, 12):
		_draw_rect(img, mx, jy, mw, 2, Color(0.40, 0.38, 0.35))
	# Créneaux intérieurs
	for cx in range(mx, mx + mw, 7):
		_draw_rect(img, cx, my - 8, 4, 8, Color(0.46, 0.44, 0.41))
	
	# === 8. DONJON CENTRAL (36×92) ===
	var dw: int = 36
	var dh: int = 92
	var dx: int = hs - dw / 2
	var dy: int = my - 32
	_add_noise_to_rect(img, dx, dy, dw, dh, Color(0.46, 0.44, 0.41), 0.06, rng)
	for jy in range(dy + 12, dy + dh, 10):
		_draw_rect(img, dx, jy, dw, 2, Color(0.38, 0.36, 0.33))
	# Meurtrières du donjon
	for mry in [dy + 20, dy + 40, dy + 60, dy + 80]:
		_draw_rect(img, dx + 8, mry, 3, 6, Color(0.15, 0.13, 0.10))
		_draw_rect(img, dx + dw - 11, mry, 3, 6, Color(0.15, 0.13, 0.10))
	# Créneaux
	for cx in [dx + 4, dx + 12, dx + 20, dx + 28, dx + 32]:
		_draw_rect(img, cx, dy - 8, 3, 10, Color(0.46, 0.44, 0.41))
	
	# === 9. TOITS CONIQUES DES TOURS (6 niveaux) ===
	for i in range(4):
		var tx: int = int(tower_pos[i].x)
		var ty: int = int(tower_pos[i].y)
		_draw_rect(img, tx - 2, ty - 14, tw + 4, 14, Color(0.50, 0.14, 0.04))
		_draw_rect(img, tx, ty - 26, tw, 14, Color(0.56, 0.18, 0.06))
		_draw_rect(img, tx + 3, ty - 38, tw - 6, 14, Color(0.62, 0.22, 0.08))
		_draw_rect(img, tx + 6, ty - 48, tw - 12, 12, Color(0.68, 0.26, 0.10))
		_draw_rect(img, tx + 9, ty - 56, tw - 18, 10, Color(0.73, 0.30, 0.12))
		_draw_rect(img, tx + 12, ty - 62, tw - 24, 8, Color(0.78, 0.34, 0.14))
		# Ornement doré
		_draw_rect(img, tx + 13, ty - 68, 4, 6, Color(0.88, 0.72, 0.18))
	
	# Toit du donjon (plus grand)
	_draw_rect(img, dx - 4, dy - 16, dw + 8, 16, Color(0.50, 0.14, 0.04))
	_draw_rect(img, dx - 2, dy - 30, dw + 4, 16, Color(0.56, 0.18, 0.06))
	_draw_rect(img, dx + 2, dy - 44, dw - 4, 16, Color(0.62, 0.22, 0.08))
	_draw_rect(img, dx + 6, dy - 56, dw - 12, 14, Color(0.68, 0.26, 0.10))
	_draw_rect(img, dx + 10, dy - 66, dw - 20, 12, Color(0.73, 0.30, 0.12))
	_draw_rect(img, dx + 14, dy - 74, dw - 28, 10, Color(0.78, 0.34, 0.14))
	_draw_rect(img, dx + 15, dy - 82, 6, 8, Color(0.90, 0.75, 0.20))
	
	# === 10. PORTE PRINCIPALE (double, massive) ===
	var gate_w: int = 32
	var gate_h: int = 28
	var gate_x: int = hs - gate_w / 2
	var gate_y: int = hs + 18
	# Arc monumental (5 niveaux)
	_draw_rect(img, gate_x - 4, gate_y - 4, gate_w + 8, 4, Color(0.42, 0.40, 0.37))
	_draw_rect(img, gate_x - 2, gate_y - 8, gate_w + 4, 4, Color(0.45, 0.43, 0.40))
	_draw_rect(img, gate_x, gate_y - 12, gate_w, 4, Color(0.48, 0.46, 0.43))
	_draw_rect(img, gate_x + 2, gate_y - 16, gate_w - 4, 4, Color(0.50, 0.48, 0.45))
	_draw_rect(img, gate_x + 4, gate_y - 20, gate_w - 8, 4, Color(0.52, 0.50, 0.47))
	# Porte double en bois renforcé
	_add_noise_to_rect(img, gate_x + 2, gate_y, gate_w - 4, gate_h, Color(0.20, 0.12, 0.05), 0.04, rng)
	_draw_rect(img, hs - 1, gate_y, 2, gate_h, Color(0.12, 0.06, 0.02))
	# Barreaux métalliques (3 barreaux)
	for by in [gate_y + 6, gate_y + 14, gate_y + 22]:
		_draw_rect(img, gate_x + 4, by, gate_w - 8, 2, Color(0.32, 0.28, 0.22))
	# Rivets (plus nombreux)
	for rx in [gate_x + 6, gate_x + 12, gate_x + gate_w - 8, gate_x + gate_w - 14]:
		for ry in [gate_y + 3, gate_y + 10, gate_y + 17]:
			_draw_rect(img, rx, ry, 2, 2, Color(0.48, 0.44, 0.38))
	# Serrure massive
	_draw_rect(img, hs - 3, gate_y + 10, 6, 8, Color(0.55, 0.50, 0.40))
	_draw_rect(img, hs - 1, gate_y + 12, 2, 4, Color(0.25, 0.20, 0.15))
	
	# === 11. HERSE (grille avec barreaux individuels) ===
	_draw_rect(img, gate_x + 2, gate_y - 20, gate_w - 4, 14, Color(0.28, 0.28, 0.30))
	for hx in range(gate_x + 4, gate_x + gate_w - 4, 5):
		_draw_rect(img, hx, gate_y - 20, 2, 14, Color(0.42, 0.42, 0.46))
	# Pointes de la herse
	for hx in [gate_x + 4, gate_x + 9, gate_x + 14, gate_x + 19, gate_x + 24]:
		_draw_rect(img, hx, gate_y - 24, 2, 4, Color(0.50, 0.50, 0.54))
	
	# === 12. TORCHES (4 torches géantes) ===
	var torch_positions: Array = [gate_x - 10, gate_x - 6, gate_x + gate_w + 4, gate_x + gate_w + 8]
	for tx_pos in torch_positions:
		_draw_rect(img, tx_pos, gate_y - 2, 3, 14, Color(0.32, 0.25, 0.18))
		_draw_rect(img, tx_pos - 1, gate_y - 8, 5, 8, Color(0.88, 0.50, 0.12))
		_draw_rect(img, tx_pos, gate_y - 6, 3, 5, Color(1.00, 0.78, 0.28))
		_draw_rect(img, tx_pos + 1, gate_y - 5, 1, 3, Color(1.00, 0.92, 0.55))
	
	# === 13. FENÊTRES (8 fenêtres avec encadrement pierre) ===
	var wps: Array = [
		Vector2(64, 72), Vector2(96, 72), Vector2(128, 72),
		Vector2(36, 58), Vector2(156, 58), Vector2(60, 38), Vector2(132, 38), Vector2(96, 22)
	]
	for wp in wps:
		var wx: int = int(wp.x)
		var wy: int = int(wp.y)
		# Encadrement pierre (épais)
		_draw_rect(img, wx - 4, wy - 4, 12, 3, Color(0.38, 0.36, 0.33))
		_draw_rect(img, wx - 4, wy + 10, 12, 3, Color(0.38, 0.36, 0.33))
		_draw_rect(img, wx - 4, wy - 1, 3, 12, Color(0.38, 0.36, 0.33))
		_draw_rect(img, wx + 5, wy - 1, 3, 12, Color(0.38, 0.36, 0.33))
		# Intérieur sombre
		_draw_rect(img, wx - 1, wy, 6, 10, Color(0.10, 0.08, 0.06))
		# Lumière jaune chaude (3 couches)
		_draw_rect(img, wx, wy + 1, 4, 8, Color(0.85, 0.68, 0.18))
		_draw_rect(img, wx + 1, wy + 2, 2, 6, Color(0.95, 0.78, 0.32))
		_draw_rect(img, wx + 1, wy + 3, 2, 4, Color(1.00, 0.88, 0.45))
	
	# === 14. DRAPEAUX (2 drapeaux) ===
	for flag_info in [[144, 18], [40, 18]]:
		var fpx: int = flag_info[0]
		var fpy: int = flag_info[1]
		_draw_rect(img, fpx, fpy - 44, 3, 50, Color(0.52, 0.42, 0.32))
		_draw_rect(img, fpx - 1, fpy - 50, 5, 6, Color(0.88, 0.72, 0.18))
		for i in range(10):
			var wv: int = 3 if i % 2 == 0 else 0
			_draw_rect(img, fpx + 4 + wv, fpy - 46 + i, 28, 3, Color(0.70, 0.08, 0.08))
		# Lion / blason simplifié
		_draw_rect(img, fpx + 14, fpy - 40, 6, 10, Color(0.85, 0.75, 0.15))
		_draw_rect(img, fpx + 12, fpy - 36, 10, 3, Color(0.85, 0.75, 0.15))
	
	# === 15. BANNIÈRE AU-DESSUS DE LA PORTE ===
	_draw_rect(img, hs - 14, gate_y - 24, 28, 10, Color(0.62, 0.10, 0.10))
	_draw_rect(img, hs - 4, gate_y - 22, 8, 6, Color(0.88, 0.78, 0.18))
	# Franges de la bannière
	for fx in range(hs - 14, hs + 14, 4):
		_draw_rect(img, fx, gate_y - 14, 2, 3, Color(0.65, 0.12, 0.12))
	
	# === 16. ÉCURIE / FORGE À DROITE ===
	var stable_x: int = hs + 54
	var stable_y: int = hs + 8
	_add_noise_to_rect(img, stable_x, stable_y, 28, 24, Color(0.38, 0.30, 0.22), 0.05, rng)
	_draw_rect(img, stable_x + 4, stable_y + 20, 20, 4, Color(0.32, 0.22, 0.14))
	# Toit de chaume
	_draw_rect(img, stable_x - 2, stable_y - 6, 32, 8, Color(0.55, 0.45, 0.25))
	_draw_rect(img, stable_x, stable_y - 12, 28, 6, Color(0.60, 0.50, 0.30))
	# Porte écurie
	_draw_rect(img, stable_x + 8, stable_y + 6, 12, 14, Color(0.25, 0.18, 0.10))
	# Cheval (silhouette simplifiée)
	_draw_rect(img, stable_x + 10, stable_y + 2, 8, 10, Color(0.55, 0.45, 0.35))
	_draw_rect(img, stable_x + 12, stable_y - 2, 4, 6, Color(0.55, 0.45, 0.35))
	
	# === 17. PUITS À GAUCHE ===
	var well_x: int = hs - 52
	var well_y: int = hs + 14
	_draw_rect(img, well_x, well_y, 16, 14, Color(0.35, 0.33, 0.30))
	_draw_rect(img, well_x + 2, well_y + 2, 12, 10, Color(0.08, 0.10, 0.15))
	_draw_rect(img, well_x + 7, well_y - 14, 2, 16, Color(0.45, 0.38, 0.28))
	_draw_rect(img, well_x + 2, well_y - 16, 12, 4, Color(0.42, 0.35, 0.25))
	# Seau
	_draw_rect(img, well_x + 18, well_y + 6, 6, 8, Color(0.42, 0.32, 0.20))
	
	# === 18. CIMETIÈRE À GAUCHE (3 tombes) ===
	for tomb in [[hs - 44, hs + 6], [hs - 38, hs + 10], [hs - 50, hs + 12]]:
		var tmx: int = tomb[0]
		var tmy: int = tomb[1]
		_draw_rect(img, tmx, tmy, 6, 8, Color(0.42, 0.40, 0.38))
		_draw_rect(img, tmx + 1, tmy - 4, 4, 4, Color(0.38, 0.36, 0.34))
		_draw_rect(img, tmx + 2, tmy - 3, 2, 3, Color(0.52, 0.50, 0.48))
	
	# === 19. POTENCE (à droite, loin) ===
	var gib_x: int = hs + 64
	var gib_y: int = hs + 4
	_draw_rect(img, gib_x, gib_y, 3, 24, Color(0.32, 0.25, 0.18))
	_draw_rect(img, gib_x - 4, gib_y - 2, 11, 3, Color(0.32, 0.25, 0.18))
	_draw_rect(img, gib_x + 2, gib_y + 4, 2, 6, Color(0.28, 0.20, 0.15))
	
	# === 20. VÉGÉTATION LUXURIANTE ===
	# Arbustes contre le mur
	for bush in [[18, hs + 16], [170, hs + 14], [14, hs + 28], [174, hs + 26]]:
		var bx: int = bush[0]
		var by: int = bush[1]
		_draw_circle(img, bx, by, 5, Color(0.18, 0.35, 0.10))
		_draw_circle(img, bx + 2, by - 2, 3, Color(0.22, 0.42, 0.12))
	# Fleurs devant
	for flower in [[hs - 30, hs + 38], [hs + 28, hs + 40], [hs - 20, hs + 44], [hs + 18, hs + 46]]:
		var flx: int = flower[0]
		var fly: int = flower[1]
		_draw_rect(img, flx, fly, 2, 2, Color(0.85, 0.20, 0.20))
		_draw_rect(img, flx + 1, fly + 2, 2, 3, Color(0.20, 0.40, 0.10))
	# Champignons
	_draw_rect(img, hs + 42, hs + 34, 3, 3, Color(0.72, 0.15, 0.15))
	_draw_rect(img, hs + 43, hs + 37, 2, 2, Color(0.35, 0.28, 0.20))
	
	# === 21. CHEMIN DE TERRE DÉTAILLÉ ===
	_draw_rect(img, hs - 20, hs + 56, 40, 28, Color(0.52, 0.40, 0.28))
	for px in [hs - 14, hs - 6, hs + 4, hs + 12, hs + 18]:
		for py in [hs + 60, hs + 68, hs + 76]:
			if rng.randf() < 0.6:
				_draw_rect(img, px, py, 4, 3, Color(0.58, 0.46, 0.34))
	
	# === 22. GARDES (2 petites silhouettes devant la porte) ===
	for guard_x in [hs - 18, hs + 14]:
		_draw_rect(img, guard_x, gate_y + 28, 4, 10, Color(0.55, 0.55, 0.60))
		_draw_rect(img, guard_x - 1, gate_y + 24, 6, 4, Color(0.60, 0.60, 0.65))
		_draw_rect(img, guard_x, gate_y + 20, 4, 4, Color(0.45, 0.40, 0.35))
		# Lance
		_draw_rect(img, guard_x + 4, gate_y + 16, 2, 20, Color(0.35, 0.30, 0.25))
		_draw_rect(img, guard_x + 3, gate_y + 14, 4, 3, Color(0.55, 0.55, 0.60))

# --- MAISON ---
func _generate_house_sprite(img: Image, size: int, rng: RandomNumberGenerator) -> void:
	var s: int = size
	var hs: int = s / 2
	
	# Sol
	_draw_rect(img, 6, hs + 8, s - 12, hs - 10, Color(0.50, 0.40, 0.28))
	
	# Mur principal (bois/plâtre)
	_add_noise_to_rect(img, hs - 16, hs - 4, 32, 22, Color(0.72, 0.62, 0.45), 0.06, rng)
	
	# Poutres de bois (verticales)
	for px in [hs - 14, hs + 14]:
		_draw_rect(img, px, hs - 4, 3, 22, Color(0.38, 0.24, 0.14))
	
	# Toit (triangle avec tuiles)
	for ty in range(14):
		var tw: int = 34 - ty * 2
		var tx: int = hs - tw / 2
		var shade: float = 0.55 + ty * 0.015
		_draw_rect(img, tx, hs - 16 - ty, tw, 2, Color(shade, shade * 0.35, shade * 0.15))
	
	# Porte
	_draw_rect(img, hs - 5, hs + 8, 10, 12, Color(0.30, 0.18, 0.10))
	_draw_rect(img, hs - 1, hs + 8, 2, 12, Color(0.20, 0.12, 0.06))
	
	# Fenêtre
	_draw_rect(img, hs - 10, hs - 2, 6, 6, Color(0.12, 0.10, 0.08))
	_draw_rect(img, hs - 9, hs - 1, 4, 4, Color(0.80, 0.65, 0.30))
	
	# Ombre
	_draw_rect(img, 10, s - 5, s - 20, 3, Color(0, 0, 0, 0.25))

# --- MINE 96x96 MEGA DÉTAILLÉE ---
func _generate_mine_sprite(img: Image, size: int, rng: RandomNumberGenerator, accent_color: Color) -> void:
	var s: int = size
	var hs: int = s / 2
	
	# Ombre large
	_draw_rect(img, 8, s - 8, s - 16, 8, Color(0, 0, 0, 0.25))
	
	# Sol terreux avec cailloux
	_draw_rect(img, 6, hs + 10, s - 12, hs - 14, Color(0.40, 0.33, 0.26))
	for _i in range(8):
		var cx: int = rng.randi_range(6, s - 10)
		var cy: int = rng.randi_range(hs + 12, s - 10)
		_draw_rect(img, cx, cy, 3, 2, Color(0.48, 0.42, 0.35))
	
	# Entrée tunnel (beaucoup plus profonde)
	_draw_rect(img, hs - 22, hs - 12, 44, 36, Color(0.06, 0.04, 0.03))
	_draw_rect(img, hs - 18, hs - 8, 36, 28, Color(0.04, 0.03, 0.02))
	_draw_rect(img, hs - 14, hs - 4, 28, 20, Color(0.03, 0.02, 0.01))
	
	# Cadre bois massif (poutres verticales triples)
	for px in [hs - 24, hs - 18, hs + 18, hs + 24]:
		_draw_rect(img, px, hs - 14, 6, 38, Color(0.32, 0.20, 0.12))
		# Clous
		for cy in range(hs - 10, hs + 18, 6):
			_draw_rect(img, px + 2, cy, 2, 2, Color(0.55, 0.50, 0.40))
	# Traverse supérieure épaisse
	_draw_rect(img, hs - 28, hs - 16, 56, 8, Color(0.38, 0.24, 0.14))
	_draw_rect(img, hs - 26, hs - 18, 52, 4, Color(0.32, 0.20, 0.10))
	# Traverse inférieure
	_draw_rect(img, hs - 28, hs + 16, 56, 6, Color(0.38, 0.24, 0.14))
	
	# Étaiements diagonaux
	_draw_line(img, hs - 24, hs + 18, hs - 14, hs - 12, Color(0.30, 0.18, 0.10), 2)
	_draw_line(img, hs + 24, hs + 18, hs + 14, hs - 12, Color(0.30, 0.18, 0.10), 2)
	
	# Rails de mine avec traverses détaillées
	_draw_rect(img, hs - 14, hs + 4, 4, 26, Color(0.32, 0.32, 0.36))
	_draw_rect(img, hs + 10, hs + 4, 4, 26, Color(0.32, 0.32, 0.36))
	for ry in range(hs + 6, hs + 26, 5):
		_draw_rect(img, hs - 16, ry, 40, 3, Color(0.24, 0.14, 0.08))
		_draw_rect(img, hs - 14, ry + 1, 36, 1, Color(0.20, 0.10, 0.05))
	# Boulons sur les rails
	for rx in [hs - 13, hs + 11]:
		for ry in [hs + 8, hs + 18]:
			_draw_rect(img, rx, ry, 2, 2, Color(0.50, 0.50, 0.55))
	
	# Chariot de mine sur rails
	_draw_rect(img, hs - 10, hs + 14, 20, 12, Color(0.28, 0.18, 0.10))
	_draw_rect(img, hs - 8, hs + 12, 16, 4, Color(0.32, 0.20, 0.12))
	# Roues
	_draw_rect(img, hs - 8, hs + 26, 4, 4, Color(0.22, 0.14, 0.08))
	_draw_rect(img, hs + 4, hs + 26, 4, 4, Color(0.22, 0.14, 0.08))
	# Minerai dans le chariot
	for _i in range(6):
		var ox: int = rng.randi_range(hs - 8, hs + 6)
		var oy: int = rng.randi_range(hs + 10, hs + 14)
		_draw_rect(img, ox, oy, 3, 3, accent_color)
	
	# Filons de minerai (20 filons)
	for _i in range(20):
		var fx: int = rng.randi_range(hs - 16, hs + 16)
		var fy: int = rng.randi_range(hs - 8, hs + 14)
		_draw_rect(img, fx, fy, 4, 3, accent_color)
	# Scintillement blanc/or
	for sx in [hs - 12, hs - 6, hs + 4, hs + 10, hs + 14]:
		for sy in [hs - 4, hs + 2, hs + 8]:
			if rng.randf() < 0.5:
				_draw_rect(img, sx, sy, 2, 2, Color(1.0, 1.0, 0.9))
	
	# Panneau d'avertissement (gros avec croix)
	_draw_rect(img, hs - 30, hs - 20, 14, 12, Color(0.62, 0.52, 0.12))
	_draw_rect(img, hs - 28, hs - 18, 10, 8, Color(0.12, 0.08, 0.03))
	# Croix X rouge
	_draw_line(img, hs - 26, hs - 16, hs - 20, hs - 12, Color(0.75, 0.10, 0.10), 2)
	_draw_line(img, hs - 20, hs - 16, hs - 26, hs - 12, Color(0.75, 0.10, 0.10), 2)
	# Piquet
	_draw_rect(img, hs - 24, hs - 8, 2, 12, Color(0.35, 0.22, 0.12))
	
	# Lanterne suspendue
	_draw_rect(img, hs + 18, hs - 18, 2, 10, Color(0.25, 0.20, 0.15))
	_draw_rect(img, hs + 16, hs - 8, 6, 8, Color(0.55, 0.55, 0.60))
	_draw_rect(img, hs + 17, hs - 6, 4, 4, Color(0.90, 0.75, 0.20))
	
	# Câbles suspendus
	_draw_line(img, hs - 20, hs - 18, hs + 20, hs - 14, Color(0.15, 0.12, 0.08), 1)
	
	# Outils à droite
	# Pioche (plus détaillée)
	_draw_rect(img, hs + 30, hs - 4, 3, 22, Color(0.42, 0.26, 0.14))
	_draw_rect(img, hs + 26, hs - 10, 11, 6, Color(0.55, 0.55, 0.60))
	_draw_rect(img, hs + 28, hs - 12, 7, 2, Color(0.65, 0.65, 0.70))
	# Seau avec anse
	_draw_rect(img, hs + 34, hs + 8, 10, 12, Color(0.48, 0.34, 0.22))
	_draw_rect(img, hs + 36, hs + 6, 6, 2, Color(0.40, 0.30, 0.20))
	# Pelle
	_draw_rect(img, hs + 38, hs + 2, 3, 16, Color(0.35, 0.22, 0.12))
	_draw_rect(img, hs + 36, hs - 2, 7, 4, Color(0.55, 0.55, 0.60))
	
	# Barils à gauche (3 barils)
	for bx in [hs - 34, hs - 28, hs - 30]:
		_draw_rect(img, bx, hs + 2, 8, 12, Color(0.48, 0.30, 0.18))
		_draw_rect(img, bx, hs + 4, 8, 2, Color(0.38, 0.22, 0.12))
		_draw_rect(img, bx, hs + 10, 8, 2, Color(0.38, 0.22, 0.12))
	
	# Herbe sèche et cailloux
	_draw_rect(img, 8, hs + 20, 4, 5, Color(0.32, 0.40, 0.16))
	_draw_rect(img, s - 14, hs + 18, 4, 5, Color(0.32, 0.40, 0.16))
	_draw_rect(img, 12, hs + 24, 3, 3, Color(0.45, 0.40, 0.35))
	_draw_rect(img, s - 18, hs + 22, 3, 3, Color(0.45, 0.40, 0.35))

# --- TOUR 96x96 MEGA DÉTAILLÉE ---
func _generate_tower_sprite(img: Image, size: int, rng: RandomNumberGenerator) -> void:
	var s: int = size
	var hs: int = s / 2
	
	# Ombre large
	_draw_rect(img, 8, s - 8, s - 16, 8, Color(0, 0, 0, 0.28))
	
	# Base rocheuse (plus large et texturée)
	_draw_circle(img, hs, hs + 16, 24, Color(0.38, 0.36, 0.32))
	_draw_circle(img, hs - 6, hs + 14, 14, Color(0.42, 0.40, 0.36))
	_draw_circle(img, hs + 8, hs + 18, 12, Color(0.44, 0.42, 0.38))
	
	# Socle pierre de la tour
	_draw_rect(img, hs - 18, hs + 12, 36, 10, Color(0.32, 0.30, 0.28))
	
	# Corps de tour (34×64)
	var tw: int = 34
	var th: int = 64
	var tx: int = hs - tw / 2
	var ty: int = hs - 24
	_add_noise_to_rect(img, tx, ty, tw, th, Color(0.44, 0.42, 0.39), 0.06, rng)
	# Joints horizontaux (tous les 8px)
	for jy in range(ty + 10, ty + th, 8):
		_draw_rect(img, tx, jy, tw, 2, Color(0.36, 0.34, 0.31))
	# Joints verticaux (maçonnerie)
	for jx in [tx + 8, tx + 17, tx + 26]:
		_draw_rect(img, jx, ty, 2, th, Color(0.36, 0.34, 0.31))
	
	# Meurtrières (4 meurtrières de chaque côté)
	for mry in [ty + 16, ty + 28, ty + 40, ty + 52]:
		_draw_rect(img, tx + 3, mry, 4, 6, Color(0.10, 0.08, 0.06))
		_draw_rect(img, tx + tw - 7, mry, 4, 6, Color(0.10, 0.08, 0.06))
	
	# Créneaux (7 créneaux)
	for cx in [tx + 3, tx + 8, tx + 13, tx + 18, tx + 23, tx + 28, tx + 31]:
		_draw_rect(img, cx, ty - 8, 4, 10, Color(0.46, 0.44, 0.41))
	# Bandeau sous créneaux
	_draw_rect(img, tx, ty - 4, tw, 4, Color(0.40, 0.38, 0.35))
	
	# Toit conique (7 niveaux, plus haut)
	_draw_rect(img, tx - 4, ty - 14, tw + 8, 14, Color(0.48, 0.14, 0.04))
	_draw_rect(img, tx - 2, ty - 26, tw + 4, 14, Color(0.54, 0.18, 0.06))
	_draw_rect(img, tx + 2, ty - 38, tw - 4, 14, Color(0.60, 0.22, 0.08))
	_draw_rect(img, tx + 6, ty - 48, tw - 12, 12, Color(0.66, 0.26, 0.10))
	_draw_rect(img, tx + 10, ty - 56, tw - 20, 10, Color(0.72, 0.30, 0.12))
	_draw_rect(img, tx + 13, ty - 62, tw - 26, 8, Color(0.76, 0.34, 0.14))
	_draw_rect(img, tx + 15, ty - 68, 4, 6, Color(0.88, 0.72, 0.18))
	# Flèche au sommet
	_draw_rect(img, hs - 1, ty - 74, 2, 6, Color(0.55, 0.45, 0.35))
	
	# Fenêtres (3 fenêtres avec lumière bleutée - tour abandonnée)
	for wx in [hs - 10, hs + 2, hs - 10]:
		var wy: int = ty + 16 if wx == hs - 10 else ty + 32
		if wx == hs + 2:
			wy = ty + 44
		# Encadrement
		_draw_rect(img, wx - 1, wy - 1, 8, 2, Color(0.38, 0.36, 0.33))
		_draw_rect(img, wx - 1, wy + 12, 8, 2, Color(0.38, 0.36, 0.33))
		_draw_rect(img, wx - 1, wy, 2, 12, Color(0.38, 0.36, 0.33))
		_draw_rect(img, wx + 5, wy, 2, 12, Color(0.38, 0.36, 0.33))
		# Intérieur
		_draw_rect(img, wx, wy, 6, 12, Color(0.10, 0.12, 0.16))
		# Lumière faible (abandonnée)
		_draw_rect(img, wx + 1, wy + 1, 4, 10, Color(0.18, 0.22, 0.30))
		_draw_rect(img, wx + 2, wy + 2, 2, 8, Color(0.25, 0.30, 0.38))
	
	# Porte bas (grande porte en bois avec ferrures)
	_draw_rect(img, hs - 7, hs + 18, 14, 18, Color(0.18, 0.10, 0.04))
	# Planches verticales
	for px in [hs - 5, hs - 1, hs + 3]:
		_draw_rect(img, px, hs + 18, 2, 18, Color(0.14, 0.08, 0.02))
	# Ferrures (bandes horizontales)
	_draw_rect(img, hs - 6, hs + 22, 12, 2, Color(0.52, 0.50, 0.48))
	_draw_rect(img, hs - 6, hs + 30, 12, 2, Color(0.52, 0.50, 0.48))
	# Serrure
	_draw_rect(img, hs - 2, hs + 26, 4, 6, Color(0.55, 0.53, 0.48))
	_draw_rect(img, hs - 1, hs + 28, 2, 2, Color(0.25, 0.23, 0.18))
	# Poignée
	_draw_rect(img, hs + 3, hs + 26, 3, 3, Color(0.58, 0.55, 0.50))
	
	# Vigne/mousse luxuriante sur le côté droit
	for vy in range(ty + 8, ty + th - 4, 4):
		var vx: int = tx + tw - rng.randi_range(2, 6)
		var vw: int = rng.randi_range(3, 6)
		_draw_rect(img, vx, vy, vw, 3, Color(0.20, 0.36, 0.12))
	# Tiges
	_draw_rect(img, tx + tw - 3, ty + 10, 2, th - 16, Color(0.28, 0.42, 0.18))
	_draw_rect(img, tx + tw - 6, ty + 20, 2, th - 30, Color(0.25, 0.38, 0.14))
	# Feuilles de vigne en grappes
	for vy in [ty + 14, ty + 28, ty + 42, ty + 54]:
		_draw_circle(img, tx + tw - 2, vy, 3, Color(0.22, 0.40, 0.12))
	
	# Écailles/brèches sur la pierre (signes d'abandon)
	_draw_rect(img, tx + 4, ty + 30, 5, 4, Color(0.35, 0.33, 0.30))
	_draw_rect(img, tx + 12, ty + 38, 4, 3, Color(0.38, 0.36, 0.32))
	_draw_rect(img, tx + 20, ty + 24, 3, 5, Color(0.32, 0.30, 0.28))
	
	# Herbe sèche et buissons autour
	_draw_circle(img, 10, hs + 22, 5, Color(0.38, 0.44, 0.18))
	_draw_circle(img, s - 12, hs + 20, 4, Color(0.35, 0.42, 0.16))
	_draw_circle(img, 18, hs + 26, 3, Color(0.42, 0.48, 0.20))
	# Petit caillou
	_draw_circle(img, hs + 22, hs + 28, 3, Color(0.50, 0.50, 0.54))
	# Fleur sauvage
	_draw_rect(img, hs + 18, hs + 24, 2, 2, Color(0.80, 0.20, 0.25))
	_draw_rect(img, hs + 19, hs + 26, 2, 3, Color(0.20, 0.40, 0.10))

# --- ARBRE 96x96 MEGA DÉTAILLÉ ---
func _generate_tree_sprite(img: Image, size: int, rng: RandomNumberGenerator) -> void:
	var s: int = size
	var hs: int = s / 2
	
	# Ombre large
	_draw_rect(img, 14, s - 8, s - 28, 8, Color(0, 0, 0, 0.22))
	
	# Tronc (beaucoup plus épais avec texture de bark)
	_add_noise_to_rect(img, hs - 8, hs + 6, 16, 36, Color(0.30, 0.18, 0.08), 0.05, rng)
	# Bark lines verticales
	for bx in [hs - 6, hs - 2, hs + 2, hs + 6]:
		_draw_rect(img, bx, hs + 8, 2, 32, Color(0.26, 0.15, 0.06))
	# Nœuds sur le tronc (plus nombreux)
	_draw_rect(img, hs - 6, hs + 12, 4, 4, Color(0.25, 0.14, 0.06))
	_draw_rect(img, hs + 2, hs + 22, 4, 4, Color(0.25, 0.14, 0.06))
	_draw_rect(img, hs - 5, hs + 30, 3, 5, Color(0.27, 0.16, 0.07))
	_draw_rect(img, hs + 3, hs + 16, 3, 3, Color(0.24, 0.13, 0.05))
	# Champignon sur tronc
	_draw_rect(img, hs + 8, hs + 18, 4, 3, Color(0.65, 0.15, 0.15))
	_draw_rect(img, hs + 9, hs + 21, 2, 3, Color(0.35, 0.28, 0.20))
	# Mousse sur le tronc
	for mry in [hs + 10, hs + 20, hs + 30]:
		_draw_rect(img, hs - 10, mry, 4, 3, Color(0.20, 0.36, 0.10))
	
	# Branches (plus nombreuses et détaillées)
	# Branche gauche bas
	_draw_rect(img, hs - 22, hs - 2, 16, 5, Color(0.28, 0.16, 0.08))
	_draw_rect(img, hs - 20, hs - 4, 12, 3, Color(0.26, 0.14, 0.06))
	# Branche droite bas
	_draw_rect(img, hs + 8, hs - 8, 18, 5, Color(0.28, 0.16, 0.08))
	_draw_rect(img, hs + 10, hs - 10, 14, 3, Color(0.26, 0.14, 0.06))
	# Branche gauche haut
	_draw_rect(img, hs - 18, hs - 14, 12, 4, Color(0.26, 0.15, 0.07))
	# Branche droite haut
	_draw_rect(img, hs + 6, hs - 18, 14, 4, Color(0.26, 0.15, 0.07))
	# Branche centrale
	_draw_rect(img, hs - 2, hs - 26, 4, 10, Color(0.27, 0.16, 0.08))
	
	# Feuillage en multiples couches (cercles plus grands et variés)
	# Couche 1 (fond sombre)
	_draw_circle(img, hs, hs - 18, 34, Color(0.08, 0.24, 0.04))
	_draw_circle(img, hs - 10, hs - 26, 26, Color(0.09, 0.26, 0.05))
	_draw_circle(img, hs + 12, hs - 24, 24, Color(0.09, 0.26, 0.05))
	_draw_circle(img, hs - 6, hs - 34, 20, Color(0.10, 0.28, 0.06))
	# Couche 2 (moyen)
	_draw_circle(img, hs, hs - 22, 30, Color(0.11, 0.32, 0.06))
	_draw_circle(img, hs - 8, hs - 30, 22, Color(0.12, 0.34, 0.07))
	_draw_circle(img, hs + 10, hs - 28, 20, Color(0.12, 0.34, 0.07))
	_draw_circle(img, hs, hs - 38, 16, Color(0.14, 0.38, 0.08))
	# Couche 3 (clair)
	_draw_circle(img, hs, hs - 26, 26, Color(0.15, 0.40, 0.09))
	_draw_circle(img, hs - 6, hs - 36, 18, Color(0.16, 0.42, 0.10))
	_draw_circle(img, hs + 6, hs - 40, 14, Color(0.18, 0.44, 0.11))
	_draw_circle(img, hs - 2, hs - 44, 10, Color(0.20, 0.46, 0.12))
	# Highlight (éclat)
	_draw_circle(img, hs + 10, hs - 38, 8, Color(0.24, 0.50, 0.16))
	_draw_circle(img, hs - 4, hs - 42, 6, Color(0.26, 0.52, 0.18))
	# Grappes de feuilles
	_draw_circle(img, hs + 14, hs - 16, 8, Color(0.12, 0.36, 0.08))
	_draw_circle(img, hs - 14, hs - 20, 8, Color(0.12, 0.36, 0.08))
	_draw_circle(img, hs + 8, hs - 48, 6, Color(0.18, 0.44, 0.12))
	
	# Nid d'oiseau (petit dans une branche)
	_draw_rect(img, hs + 10, hs - 22, 6, 4, Color(0.42, 0.32, 0.20))
	_draw_rect(img, hs + 11, hs - 23, 4, 2, Color(0.35, 0.25, 0.15))
	# Petit oiseau
	_draw_rect(img, hs + 8, hs - 26, 3, 2, Color(0.55, 0.20, 0.15))
	
	# Pommes/fruits (petits points rouges)
	for fx in [hs - 8, hs + 6, hs - 2, hs + 10]:
		var fy: int = rng.randi_range(hs - 18, hs - 8)
		_draw_rect(img, fx, fy, 2, 2, Color(0.75, 0.12, 0.12))
	
	# Racines visibles (plus nombreuses)
	_draw_rect(img, hs - 12, hs + 30, 8, 5, Color(0.26, 0.16, 0.08))
	_draw_rect(img, hs + 4, hs + 30, 8, 5, Color(0.26, 0.16, 0.08))
	_draw_rect(img, hs - 16, hs + 32, 6, 4, Color(0.24, 0.14, 0.07))
	_draw_rect(img, hs + 10, hs + 32, 6, 4, Color(0.24, 0.14, 0.07))
	_draw_rect(img, hs - 18, hs + 34, 4, 3, Color(0.22, 0.13, 0.06))
	
	# Herbe et fleurs au pied
	_draw_circle(img, hs - 20, hs + 34, 5, Color(0.18, 0.38, 0.10))
	_draw_circle(img, hs + 18, hs + 34, 4, Color(0.18, 0.38, 0.10))
	_draw_circle(img, hs - 14, hs + 38, 3, Color(0.22, 0.42, 0.12))
	# Fleurs
	_draw_rect(img, hs - 16, hs + 36, 2, 2, Color(0.82, 0.18, 0.22))
	_draw_rect(img, hs + 14, hs + 36, 2, 2, Color(0.85, 0.70, 0.15))
	_draw_rect(img, hs - 8, hs + 38, 2, 2, Color(0.75, 0.12, 0.65))
	# Caillou
	_draw_circle(img, hs + 20, hs + 36, 2, Color(0.48, 0.48, 0.52))

# --- ROCHER 96x96 MEGA DÉTAILLÉ ---
func _generate_rock_sprite(img: Image, size: int, rng: RandomNumberGenerator) -> void:
	var s: int = size
	var hs: int = s / 2
	
	# Ombre large
	_draw_rect(img, 10, s - 8, s - 20, 8, Color(0, 0, 0, 0.25))
	
	# Rocher principal (formes complexes superposées)
	_draw_circle(img, hs, hs + 10, 26, Color(0.35, 0.35, 0.39))
	_draw_circle(img, hs - 10, hs + 4, 20, Color(0.42, 0.42, 0.46))
	_draw_circle(img, hs + 12, hs + 6, 20, Color(0.44, 0.44, 0.48))
	_draw_circle(img, hs, hs - 2, 18, Color(0.50, 0.50, 0.54))
	_draw_circle(img, hs - 6, hs - 10, 14, Color(0.58, 0.58, 0.62))
	_draw_circle(img, hs + 6, hs - 14, 12, Color(0.64, 0.64, 0.68))
	_draw_circle(img, hs - 2, hs - 20, 10, Color(0.70, 0.70, 0.74))
	_draw_circle(img, hs + 4, hs - 22, 8, Color(0.75, 0.75, 0.78))
	
	# Strates horizontales (bandes de roche détaillées)
	_draw_rect(img, hs - 24, hs + 8, 48, 3, Color(0.30, 0.30, 0.34))
	_draw_rect(img, hs - 20, hs + 2, 40, 3, Color(0.36, 0.36, 0.40))
	_draw_rect(img, hs - 16, hs - 6, 32, 3, Color(0.44, 0.44, 0.48))
	_draw_rect(img, hs - 12, hs - 14, 24, 3, Color(0.52, 0.52, 0.56))
	_draw_rect(img, hs - 8, hs - 22, 16, 3, Color(0.60, 0.60, 0.64))
	# Strates brisées/irrégulières
	_draw_rect(img, hs - 18, hs - 10, 14, 2, Color(0.48, 0.48, 0.52))
	_draw_rect(img, hs + 8, hs - 18, 12, 2, Color(0.56, 0.56, 0.60))
	
	# Texture granitique (points aléatoires)
	for _i in range(40):
		var gx: int = rng.randi_range(hs - 20, hs + 20)
		var gy: int = rng.randi_range(hs - 20, hs + 20)
		_draw_rect(img, gx, gy, 2, 2, Color(0.55, 0.55, 0.60))
	
	# Mousse luxuriante sur le côté gauche
	_draw_circle(img, hs - 20, hs + 6, 8, Color(0.18, 0.33, 0.12))
	_draw_circle(img, hs - 18, hs, 6, Color(0.24, 0.38, 0.16))
	_draw_circle(img, hs - 22, hs + 10, 5, Color(0.22, 0.35, 0.14))
	_draw_circle(img, hs - 16, hs - 6, 4, Color(0.26, 0.40, 0.18))
	_draw_circle(img, hs - 14, hs + 14, 4, Color(0.20, 0.34, 0.12))
	# Lichen orange
	_draw_circle(img, hs - 18, hs + 2, 3, Color(0.55, 0.42, 0.22))
	_draw_circle(img, hs - 20, hs + 8, 2, Color(0.52, 0.38, 0.18))
	
	# Cristaux / Géodes (petits brillants)
	for cx in [hs - 4, hs + 8, hs + 2]:
		for cy in [hs - 6, hs + 4, hs - 12]:
			if rng.randf() < 0.5:
				_draw_rect(img, cx, cy, 3, 3, Color(0.75, 0.72, 0.78))
				_draw_rect(img, cx + 1, cy + 1, 1, 1, Color(0.92, 0.90, 0.95))
	
	# Petits cailloux autour (plus nombreux)
	_draw_circle(img, hs - 28, hs + 26, 4, Color(0.42, 0.42, 0.46))
	_draw_circle(img, hs + 26, hs + 24, 5, Color(0.48, 0.48, 0.52))
	_draw_circle(img, hs + 20, hs + 28, 4, Color(0.40, 0.40, 0.44))
	_draw_circle(img, hs - 24, hs + 30, 3, Color(0.46, 0.46, 0.50))
	_draw_circle(img, hs + 14, hs + 32, 3, Color(0.44, 0.44, 0.48))
	_draw_circle(img, hs - 14, hs + 28, 2, Color(0.50, 0.50, 0.54))
	
	# Fissures (plus nombreuses et détaillées)
	# Fissure principale
	_draw_rect(img, hs + 4, hs - 8, 2, 16, Color(0.20, 0.20, 0.23))
	_draw_rect(img, hs + 5, hs - 6, 1, 12, Color(0.12, 0.12, 0.14))
	# Fissure secondaire
	_draw_rect(img, hs - 8, hs + 4, 3, 2, Color(0.24, 0.24, 0.28))
	_draw_rect(img, hs - 8, hs + 6, 2, 6, Color(0.22, 0.22, 0.26))
	_draw_rect(img, hs - 7, hs + 10, 1, 4, Color(0.16, 0.16, 0.18))
	# Petite fissure en haut
	_draw_rect(img, hs + 2, hs - 18, 2, 6, Color(0.26, 0.26, 0.30))
	# Éboulis (petites pierres dans une fissure)
	_draw_rect(img, hs + 3, hs + 6, 2, 2, Color(0.42, 0.42, 0.46))
	_draw_rect(img, hs + 6, hs + 2, 2, 2, Color(0.40, 0.40, 0.44))
	
	# Herbe sèche autour du rocher
	_draw_circle(img, hs + 24, hs + 18, 4, Color(0.30, 0.42, 0.16))
	_draw_circle(img, hs - 26, hs + 16, 3, Color(0.28, 0.40, 0.14))
	_draw_rect(img, hs + 18, hs + 22, 3, 4, Color(0.32, 0.44, 0.18))
	# Petite fleur sauvage
	_draw_rect(img, hs + 28, hs + 20, 2, 2, Color(0.78, 0.15, 0.20))
	_draw_rect(img, hs + 29, hs + 22, 2, 3, Color(0.20, 0.38, 0.10))

# --- COFFRE 64x64 DÉTAILLÉ ---
func _generate_chest_sprite(img: Image, size: int, rng: RandomNumberGenerator) -> void:
	var s: int = size
	var hs: int = s / 2
	var wood_dark: Color = Color(0.38, 0.22, 0.10)
	var wood_mid: Color = Color(0.52, 0.32, 0.16)
	var wood_light: Color = Color(0.62, 0.40, 0.22)
	var gold: Color = Color(0.92, 0.78, 0.20)
	var gold_dark: Color = Color(0.75, 0.60, 0.12)
	
	# Ombre
	_draw_rect(img, 8, s - 6, s - 16, 6, Color(0, 0, 0, 0.30))
	
	# Corps du coffre (base)
	_add_noise_to_rect(img, hs - 18, hs - 4, 36, 24, wood_dark, 0.04, rng)
	# Planches verticales
	for px in [hs - 14, hs - 6, hs + 2, hs + 10]:
		_draw_rect(img, px, hs - 4, 2, 24, Color(0.28, 0.16, 0.08))
	
	# Couvercle (plus clair, légèrement arrondi en haut)
	_add_noise_to_rect(img, hs - 18, hs - 20, 36, 18, wood_mid, 0.04, rng)
	# Planches du couvercle
	for px in [hs - 14, hs - 6, hs + 2, hs + 10]:
		_draw_rect(img, px, hs - 20, 2, 18, Color(0.35, 0.20, 0.10))
	
	# Courbe du couvercle (highlight au centre)
	_draw_rect(img, hs - 12, hs - 22, 24, 4, wood_light)
	_draw_rect(img, hs - 8, hs - 24, 16, 3, Color(0.68, 0.44, 0.24))
	
	# Bandes métalliques dorées (verticales)
	_draw_rect(img, hs - 18, hs - 20, 4, 40, gold_dark)
	_draw_rect(img, hs + 14, hs - 20, 4, 40, gold_dark)
	# Rivets sur les bandes
	for ry in [hs - 16, hs - 8, hs, hs + 8, hs + 14]:
		_draw_rect(img, hs - 17, ry, 2, 2, gold)
		_draw_rect(img, hs + 15, ry, 2, 2, gold)
	
	# Serrure centrale
	_draw_rect(img, hs - 5, hs - 6, 10, 10, gold_dark)
	_draw_rect(img, hs - 3, hs - 4, 6, 6, gold)
	_draw_rect(img, hs - 1, hs - 2, 2, 2, Color(0.20, 0.15, 0.05))
	
	# Trou de la serrure
	_draw_rect(img, hs - 1, hs - 4, 2, 3, Color(0.15, 0.10, 0.05))
	
	# Éclats de lumière sur le couvercle (reflet)
	_draw_rect(img, hs - 8, hs - 18, 4, 2, Color(1.0, 0.95, 0.80))
	_draw_rect(img, hs + 4, hs - 16, 3, 2, Color(1.0, 0.95, 0.80))

# --- ENNEMI 64x64 ULTRA-DÉTAILLÉ ---
func _generate_enemy_sprite(img: Image, size: int, rng: RandomNumberGenerator, enemy_type: String) -> void:
	var s: int = size
	var hs: int = s / 2
	
	var body_color: Color = Color(0.7, 0.75, 0.72)
	var head_color: Color = Color(0.8, 0.85, 0.82)
	var detail_color: Color = Color(0.5, 0.5, 0.5)
	var eye_color: Color = Color(0.15, 0.6, 0.15)
	var weapon_color: Color = Color(0.55, 0.55, 0.6)
	
	match enemy_type:
		"skeleton":
			body_color = Color(0.78, 0.82, 0.78)
			head_color = Color(0.88, 0.90, 0.88)
			detail_color = Color(0.25, 0.25, 0.25)
			weapon_color = Color(0.65, 0.65, 0.70)
			eye_color = Color(0.85, 0.20, 0.15)
		"goblin":
			body_color = Color(0.22, 0.52, 0.16)
			head_color = Color(0.32, 0.62, 0.22)
			detail_color = Color(0.15, 0.35, 0.10)
			weapon_color = Color(0.55, 0.30, 0.15)
			eye_color = Color(0.90, 0.15, 0.15)
		"archer":
			body_color = Color(0.58, 0.28, 0.18)
			head_color = Color(0.72, 0.42, 0.28)
			detail_color = Color(0.38, 0.18, 0.10)
			weapon_color = Color(0.45, 0.30, 0.15)
			eye_color = Color(0.20, 0.15, 0.10)
		"swordsman":
			body_color = Color(0.35, 0.38, 0.48)
			head_color = Color(0.50, 0.55, 0.65)
			detail_color = Color(0.55, 0.58, 0.68)
			weapon_color = Color(0.70, 0.72, 0.78)
			eye_color = Color(0.15, 0.20, 0.40)
	
	# Ombre elliptique réaliste
	for x in range(s):
		for y in range(s):
			var ox: float = (x - hs) / 16.0
			var oy: float = (y - (s - 4)) / 4.0
			var dist: float = ox * ox + oy * oy
			if dist <= 1.0:
				var alpha: float = 0.30 * (1.0 - dist * 0.5)
				img.set_pixel(x, y, Color(0, 0, 0, alpha))
	
	# Corps (ovale avec dégradé vertical)
	_draw_shaded_circle(img, hs, hs + 8, 18, body_color, Vector2(-0.3, -0.8))
	_draw_shaded_circle(img, hs - 4, hs + 6, 10, head_color, Vector2(-0.3, -0.8))
	_draw_shaded_circle(img, hs + 4, hs + 10, 10, head_color, Vector2(-0.3, -0.8))
	# Texture du corps
	_add_noise_to_rect(img, hs - 10, hs - 2, 20, 20, body_color, 0.04, rng)
	
	# Tête (cercle plus haut avec ombrage)
	_draw_shaded_circle(img, hs, hs - 12, 14, head_color, Vector2(-0.3, -0.8))
	_draw_shaded_circle(img, hs - 3, hs - 15, 10, Color(head_color.r + 0.05, head_color.g + 0.05, head_color.b + 0.05), Vector2(-0.3, -0.8))
	
	# Yeux détaillés avec blancs, iris, pupilles, reflets
	# Blanches
	_draw_shaded_circle(img, hs - 5, hs - 14, 4, Color(0.95, 0.95, 0.95), Vector2(-0.2, -0.2))
	_draw_shaded_circle(img, hs + 5, hs - 14, 4, Color(0.95, 0.95, 0.95), Vector2(-0.2, -0.2))
	# Iris
	_draw_circle(img, hs - 5, hs - 14, 3, eye_color)
	_draw_circle(img, hs + 5, hs - 14, 3, eye_color)
	# Pupilles
	_draw_rect(img, hs - 6, hs - 15, 2, 2, Color(0.05, 0.05, 0.05))
	_draw_rect(img, hs + 4, hs - 15, 2, 2, Color(0.05, 0.05, 0.05))
	# Reflets dans les yeux
	_draw_rect(img, hs - 4, hs - 15, 1, 1, Color(1, 1, 1))
	_draw_rect(img, hs + 5, hs - 15, 1, 1, Color(1, 1, 1))
	# Sourcils/oreilles selon type
	if enemy_type == "goblin":
		# Oreilles pointues avec dégradé
		_draw_triangle(img, hs - 12, hs - 12, hs - 18, hs - 18, hs - 8, hs - 18, head_color)
		_draw_triangle(img, hs + 12, hs - 12, hs + 18, hs - 18, hs + 8, hs - 18, head_color)
		# Dents crochues
		_draw_rect(img, hs - 2, hs - 5, 2, 3, Color(0.90, 0.90, 0.85))
		_draw_rect(img, hs, hs - 5, 2, 3, Color(0.90, 0.90, 0.85))
	elif enemy_type == "skeleton":
		# Crâne avec orbites profondes
		_draw_rect(img, hs - 5, hs - 10, 10, 4, Color(0.08, 0.08, 0.08))
		_draw_rect(img, hs - 4, hs - 11, 8, 2, Color(0.05, 0.05, 0.05))
		# Mâchoire
		_draw_rect(img, hs - 4, hs - 4, 8, 3, Color(0.70, 0.74, 0.70))
		# Dents
		_draw_rect(img, hs - 2, hs - 3, 1, 2, Color(0.85, 0.88, 0.85))
		_draw_rect(img, hs, hs - 3, 1, 2, Color(0.85, 0.88, 0.85))
		_draw_rect(img, hs + 1, hs - 3, 1, 2, Color(0.85, 0.88, 0.85))
		# Côtes visibles
		for ry in [hs + 4, hs + 8, hs + 12]:
			_draw_rect(img, hs - 6, ry, 12, 2, Color(0.75, 0.78, 0.75))
	elif enemy_type == "swordsman":
		# Casque avec visière et crête
		_draw_gradient_rect(img, hs - 12, hs - 22, 24, 8, Color(0.48, 0.52, 0.62), Color(0.42, 0.45, 0.55))
		_draw_rect(img, hs - 2, hs - 26, 4, 6, Color(0.65, 0.68, 0.78))
		# Visière
		_draw_gradient_rect(img, hs - 10, hs - 18, 20, 5, Color(0.35, 0.38, 0.48), Color(0.30, 0.33, 0.42))
		# Barbe noire
		for by in range(hs - 6, hs + 2):
			var bw: int = int(lerp(10.0, 3.0, float(by - (hs - 6)) / 8.0))
			_draw_rect(img, hs - bw / 2, by, bw, 2, Color(0.12, 0.10, 0.08))
	elif enemy_type == "archer":
		# Capuche
		_draw_gradient_rect(img, hs - 10, hs - 22, 20, 8, Color(0.48, 0.22, 0.12), Color(0.38, 0.18, 0.10))
		_draw_rect(img, hs - 12, hs - 18, 4, 8, Color(0.38, 0.18, 0.10))
		_draw_rect(img, hs + 8, hs - 18, 4, 8, Color(0.38, 0.18, 0.10))
	
	# Bouche détaillée
	if enemy_type == "skeleton":
		_draw_rect(img, hs - 3, hs - 5, 6, 2, Color(0.05, 0.05, 0.05))
	else:
		_draw_rect(img, hs - 3, hs - 6, 6, 2, Color(0.12, 0.08, 0.06))
		_draw_rect(img, hs - 2, hs - 6, 4, 1, Color(0.75, 0.25, 0.20))  # Lèvre
	
	# Détail / armure sur le corps avec textures
	if enemy_type == "swordsman":
		# Plastron métallique avec rivets
		_draw_shaded_circle(img, hs, hs + 2, 14, Color(0.55, 0.58, 0.68), Vector2(-0.5, -0.8))
		_draw_gradient_rect(img, hs - 8, hs - 2, 16, 16, Color(0.62, 0.65, 0.75), Color(0.48, 0.51, 0.60))
		_add_bevel(img, hs - 8, hs - 2, 16, 16, Color(0.72, 0.75, 0.85), Color(0.38, 0.41, 0.50))
		# Rivets
		for ry in [hs - 1, hs + 6, hs + 12]:
			for rx in [hs - 6, hs + 6]:
				_draw_rect(img, rx - 1, ry - 1, 3, 3, Color(0.55, 0.55, 0.60))
				_draw_rect(img, rx, ry, 1, 1, Color(0.85, 0.85, 0.90))
	elif enemy_type == "archer":
		# Cape avec plis
		_draw_gradient_rect(img, hs - 14, hs, 6, 20, Color(0.35, 0.15, 0.08), Color(0.22, 0.10, 0.05))
		_draw_gradient_rect(img, hs + 8, hs, 6, 20, Color(0.35, 0.15, 0.08), Color(0.22, 0.10, 0.05))
		_draw_gradient_rect(img, hs - 8, hs + 2, 16, 16, Color(0.42, 0.20, 0.10), Color(0.28, 0.12, 0.06))
		# Carquois avec flèches
		_draw_rect(img, hs - 16, hs - 10, 5, 14, Color(0.30, 0.18, 0.08))
		for ay in [hs - 12, hs - 8, hs - 4]:
			_draw_rect(img, hs - 18, ay, 2, 10, Color(0.55, 0.45, 0.30))
			_draw_rect(img, hs - 16, ay - 2, 2, 2, Color(0.55, 0.55, 0.60))
	elif enemy_type == "goblin":
		# Armure de cuir avec clous
		_draw_gradient_rect(img, hs - 8, hs, 16, 12, Color(0.35, 0.22, 0.10), Color(0.22, 0.14, 0.06))
		for ry in [hs + 2, hs + 6, hs + 10]:
			for rx in [hs - 5, hs + 4]:
				_draw_rect(img, rx, ry, 2, 2, Color(0.45, 0.35, 0.25))
		# Ceinture avec dents
		_draw_rect(img, hs - 6, hs + 10, 12, 3, Color(0.42, 0.28, 0.15))
		for dx in range(-4, 5, 3):
			_draw_rect(img, hs + dx, hs + 10, 1, 3, Color(0.55, 0.40, 0.25))
	elif enemy_type == "skeleton":
		# Os du torse
		_draw_rect(img, hs - 4, hs - 2, 8, 16, Color(0.78, 0.82, 0.78))
		_draw_rect(img, hs - 8, hs + 2, 4, 3, Color(0.75, 0.78, 0.75))
		_draw_rect(img, hs + 4, hs + 2, 4, 3, Color(0.75, 0.78, 0.75))
		_draw_rect(img, hs - 8, hs + 8, 4, 3, Color(0.75, 0.78, 0.75))
		_draw_rect(img, hs + 4, hs + 8, 4, 3, Color(0.75, 0.78, 0.75))
		# Brume d'âme (aura rouge)
		for x in range(hs - 20, hs + 20):
			for y in range(hs - 20, hs + 20):
				var dx: float = float(x - hs) / 18.0
				var dy: float = float(y - hs) / 18.0
				var dist: float = sqrt(dx * dx + dy * dy)
				if dist >= 0.85 and dist <= 1.0:
					var existing: Color = img.get_pixel(x, y)
					if existing.a < 0.1:
						img.set_pixel(x, y, Color(0.80, 0.15, 0.15, 0.15))
	
	# Jambes / Pieds détaillés
	if enemy_type == "goblin":
		_draw_gradient_rect(img, hs - 8, hs + 16, 5, 8, Color(0.18, 0.42, 0.12), Color(0.12, 0.30, 0.08))
		_draw_gradient_rect(img, hs + 3, hs + 16, 5, 8, Color(0.18, 0.42, 0.12), Color(0.12, 0.30, 0.08))
		# Grands pieds
		_draw_rect(img, hs - 10, hs + 22, 8, 3, Color(0.12, 0.30, 0.08))
		_draw_rect(img, hs + 2, hs + 22, 8, 3, Color(0.12, 0.30, 0.08))
	elif enemy_type == "skeleton":
		# Os des jambes
		_draw_rect(img, hs - 6, hs + 16, 3, 10, Color(0.78, 0.82, 0.78))
		_draw_rect(img, hs + 3, hs + 16, 3, 10, Color(0.78, 0.82, 0.78))
		# Pieds osseux
		_draw_rect(img, hs - 8, hs + 24, 6, 3, Color(0.75, 0.78, 0.75))
		_draw_rect(img, hs + 2, hs + 24, 6, 3, Color(0.75, 0.78, 0.75))
	elif enemy_type == "swordsman":
		# Bottes métalliques
		_draw_gradient_rect(img, hs - 8, hs + 16, 6, 10, Color(0.48, 0.51, 0.60), Color(0.38, 0.41, 0.50))
		_draw_gradient_rect(img, hs + 2, hs + 16, 6, 10, Color(0.48, 0.51, 0.60), Color(0.38, 0.41, 0.50))
		# Rebots
		_draw_rect(img, hs - 9, hs + 24, 8, 3, Color(0.35, 0.38, 0.48))
		_draw_rect(img, hs + 1, hs + 24, 8, 3, Color(0.35, 0.38, 0.48))
	elif enemy_type == "archer":
		# Bottes en cuir
		_draw_gradient_rect(img, hs - 7, hs + 16, 5, 10, Color(0.30, 0.15, 0.08), Color(0.18, 0.08, 0.04))
		_draw_gradient_rect(img, hs + 2, hs + 16, 5, 10, Color(0.30, 0.15, 0.08), Color(0.18, 0.08, 0.04))
	
	# Armes ultra-détaillées
	if enemy_type == "skeleton":
		# Épée rouillée à droite avec garde détaillée
		_draw_gradient_rect(img, hs + 18, hs - 6, 5, 26, Color(0.72, 0.75, 0.80), Color(0.55, 0.58, 0.62))
		_draw_rect(img, hs + 20, hs - 6, 2, 26, Color(0.82, 0.85, 0.90))  # Tranchant
		_draw_rect(img, hs + 16, hs - 10, 9, 6, Color(0.55, 0.55, 0.60))  # Garde
		_draw_rect(img, hs + 17, hs + 14, 7, 3, Color(0.45, 0.35, 0.25))  # Poignée
		_draw_rect(img, hs + 19, hs + 18, 3, 3, Color(0.65, 0.55, 0.30))  # Pommeau
		# Rouille sur la lame
		_draw_rect(img, hs + 19, hs + 2, 2, 4, Color(0.55, 0.30, 0.15))
		_draw_rect(img, hs + 18, hs - 4, 2, 3, Color(0.55, 0.30, 0.15))
	elif enemy_type == "goblin":
		# Hache massive à droite avec manche en bois
		_draw_rect(img, hs + 20, hs - 8, 4, 26, Color(0.42, 0.28, 0.15))  # Manche
		_draw_rect(img, hs + 18, hs - 12, 8, 10, Color(0.55, 0.55, 0.60))  # Lame haut
		_draw_rect(img, hs + 18, hs - 2, 8, 10, Color(0.55, 0.55, 0.60))  # Lame bas
		_draw_rect(img, hs + 20, hs - 14, 4, 14, Color(0.65, 0.65, 0.70))  # Tranchant
		# Sang sur la hache
		_draw_rect(img, hs + 19, hs - 10, 2, 3, Color(0.75, 0.10, 0.10))
	elif enemy_type == "archer":
		# Arc en bois courbé
		for ay in range(hs - 16, hs + 16):
			var ax: int = hs - 20 + int(sin((ay - (hs - 16)) / 32.0 * PI) * 6)
			_draw_rect(img, ax, ay, 3, 2, Color(0.42, 0.28, 0.15))
		# Corde
		_draw_rect(img, hs - 22, hs - 16, 1, 32, Color(0.75, 0.72, 0.68))
		# Flèche prête à tirer
		_draw_rect(img, hs - 20, hs - 4, 18, 2, Color(0.55, 0.45, 0.30))
		_draw_rect(img, hs - 2, hs - 6, 4, 6, Color(0.55, 0.55, 0.60))  # Pointe
		# Carquois avec flèches visibles
		_draw_rect(img, hs - 16, hs - 12, 5, 14, Color(0.28, 0.16, 0.08))
		for fy in [hs - 10, hs - 6, hs - 2]:
			_draw_rect(img, hs - 18, fy, 2, 8, Color(0.48, 0.38, 0.28))
			_draw_rect(img, hs - 16, fy - 2, 2, 2, Color(0.55, 0.55, 0.60))
	elif enemy_type == "swordsman":
		# Grande épée longue à droite
		_draw_gradient_rect(img, hs + 20, hs - 14, 7, 36, Color(0.82, 0.85, 0.92), Color(0.62, 0.65, 0.75))
		_draw_rect(img, hs + 22, hs - 14, 3, 36, Color(0.92, 0.95, 1.0))  # Tranchant
		# Reflets sur la lame
		_draw_rect(img, hs + 21, hs - 10, 1, 8, Color(1.0, 1.0, 1.0))
		_draw_rect(img, hs + 23, hs, 1, 6, Color(1.0, 1.0, 1.0))
		# Garde ornementée
		_draw_rect(img, hs + 16, hs + 18, 14, 5, Color(0.48, 0.42, 0.28))
		_draw_rect(img, hs + 18, hs + 16, 10, 3, Color(0.62, 0.55, 0.38))
		# Poignée
		_draw_rect(img, hs + 22, hs + 23, 3, 10, Color(0.42, 0.28, 0.15))
		# Pommeau sphérique
		_draw_shaded_circle(img, hs + 23, hs + 34, 4, Color(0.68, 0.58, 0.32), Vector2(-0.3, -0.5))
	
	# Bouclier à gauche (swordsman uniquement)
	if enemy_type == "swordsman":
		# Bouclier ovale avec dégradé
		for x in range(hs - 28, hs - 6):
			for y in range(hs - 4, hs + 14):
				var dx: float = float(x - (hs - 17)) / 11.0
				var dy: float = float(y - (hs + 5)) / 9.0
				if dx * dx + dy * dy <= 1.0:
					var t: float = dx * dx + dy * dy
					var c: Color = Color(lerp(0.60, 0.40, t), lerp(0.63, 0.43, t), lerp(0.73, 0.53, t))
					img.set_pixel(x, y, c)
		# Bordure dorée
		for x in range(hs - 28, hs - 6):
			for y in range(hs - 4, hs + 14):
				var dx: float = float(x - (hs - 17)) / 11.0
				var dy: float = float(y - (hs + 5)) / 9.0
				var dist: float = dx * dx + dy * dy
				if dist >= 0.78 and dist <= 1.0:
					img.set_pixel(x, y, Color(0.85, 0.72, 0.20))
		# Blason (crâne stylisé)
		_draw_circle(img, hs - 17, hs + 5, 4, Color(0.25, 0.28, 0.38))
		_draw_rect(img, hs - 19, hs + 3, 4, 2, Color(0.85, 0.72, 0.20))
		_draw_rect(img, hs - 15, hs + 3, 4, 2, Color(0.85, 0.72, 0.20))
		# Bosses métalliques
		_draw_shaded_circle(img, hs - 17, hs + 5, 2, Color(0.72, 0.72, 0.78), Vector2(-0.3, -0.3))
	
	# Aura spécifique selon le type
	if enemy_type == "goblin":
		# Aura verdâtre toxique
		for x in range(hs - 20, hs + 20):
			for y in range(hs - 20, hs + 20):
				var dx: float = float(x - hs) / 18.0
				var dy: float = float(y - hs) / 18.0
				var dist: float = sqrt(dx * dx + dy * dy)
				if dist >= 0.9 and dist <= 1.0:
					var existing: Color = img.get_pixel(x, y)
					if existing.a < 0.1:
						img.set_pixel(x, y, Color(0.20, 0.55, 0.10, 0.12))

# --- HÉROS 64x64 ULTRA-DÉTAILLÉ (style Age of Empires / HoMM3) ---
func _generate_hero_sprite(img: Image, size: int, rng: RandomNumberGenerator) -> void:
	var s: int = size
	var hs: int = s / 2
	
	# 1. OMBRE ELLIPTIQUE RÉALISTE
	for x in range(s):
		for y in range(s):
			var ox: float = (x - hs) / 16.0
			var oy: float = (y - (s - 4)) / 4.0
			var dist: float = ox * ox + oy * oy
			if dist <= 1.0:
				var alpha: float = 0.30 * (1.0 - dist * 0.5)
				img.set_pixel(x, y, Color(0, 0, 0, alpha))
	
	# 2. CAPE ROUGE LUXURIEUSE (avec plis et ombrage)
	# Cape gauche (ombre)
	_draw_gradient_rect(img, hs - 22, hs + 4, 10, 26, Color(0.45, 0.06, 0.06), Color(0.35, 0.04, 0.04))
	# Cape droite (lumière)
	_draw_gradient_rect(img, hs + 12, hs + 4, 10, 26, Color(0.70, 0.08, 0.08), Color(0.55, 0.06, 0.06))
	# Cape centre
	_draw_gradient_rect(img, hs - 14, hs + 6, 28, 24, Color(0.62, 0.08, 0.08), Color(0.50, 0.06, 0.06))
	# Plis de la cape
	for pli_y in [hs + 10, hs + 16, hs + 22]:
		_draw_rect(img, hs - 12, pli_y, 24, 2, Color(0.40, 0.05, 0.05))
		_draw_rect(img, hs - 10, pli_y + 1, 20, 1, Color(0.75, 0.12, 0.12))
	# Bordure dorée de la cape
	_add_bevel(img, hs - 14, hs + 6, 28, 24, Color(0.85, 0.72, 0.20), Color(0.35, 0.04, 0.04))
	
	# 3. JAMBES / BOTTES
	# Botte gauche
	_draw_gradient_rect(img, hs - 10, hs + 20, 7, 14, Color(0.32, 0.20, 0.12), Color(0.22, 0.12, 0.06))
	_draw_rect(img, hs - 10, hs + 28, 7, 3, Color(0.42, 0.28, 0.16))  # Rebot
	_draw_rect(img, hs - 9, hs + 22, 2, 8, Color(0.55, 0.38, 0.22))  # Lacet
	# Botte droite
	_draw_gradient_rect(img, hs + 3, hs + 20, 7, 14, Color(0.35, 0.22, 0.14), Color(0.25, 0.14, 0.08))
	_draw_rect(img, hs + 3, hs + 28, 7, 3, Color(0.45, 0.30, 0.18))  # Rebot
	_draw_rect(img, hs + 4, hs + 22, 2, 8, Color(0.58, 0.40, 0.24))  # Lacet
	
	# 4. ARMURE DE PLAQUES DORÉE (corps)
	# Base métallique avec dégradé
	_draw_shaded_circle(img, hs, hs + 2, 16, Color(0.78, 0.68, 0.38), Vector2(-0.5, -0.8))
	# Pectoral (plastron)
	_draw_gradient_rect(img, hs - 10, hs - 4, 20, 18, Color(0.82, 0.72, 0.42), Color(0.68, 0.58, 0.28))
	# Bordures de l'armure
	_add_bevel(img, hs - 10, hs - 4, 20, 18, Color(0.92, 0.82, 0.52), Color(0.55, 0.45, 0.22))
	# Rivets
	for rivet_y in [hs - 2, hs + 4, hs + 10]:
		for rivet_x in [hs - 8, hs + 8]:
			_draw_rect(img, rivet_x - 1, rivet_y - 1, 3, 3, Color(0.55, 0.50, 0.30))
			_draw_rect(img, rivet_x, rivet_y, 1, 1, Color(0.95, 0.90, 0.70))
	# Croix rouge écarlate sur le plastron
	_draw_rect(img, hs - 2, hs - 2, 4, 14, Color(0.78, 0.08, 0.08))
	_draw_rect(img, hs - 6, hs + 3, 12, 4, Color(0.78, 0.08, 0.08))
	# Contour doré de la croix
	_add_bevel(img, hs - 2, hs - 2, 4, 14, Color(0.90, 0.80, 0.50), Color(0.50, 0.40, 0.20))
	
	# 5. CEINTURE
	_draw_rect(img, hs - 11, hs + 10, 22, 4, Color(0.35, 0.22, 0.12))
	_draw_rect(img, hs - 3, hs + 8, 6, 8, Color(0.45, 0.35, 0.18))  # Boucle
	_draw_rect(img, hs - 1, hs + 10, 2, 4, Color(0.85, 0.72, 0.20))  # Ornement boucle
	# Dague à la ceinture
	_draw_rect(img, hs + 8, hs + 8, 3, 10, Color(0.82, 0.85, 0.92))
	_draw_rect(img, hs + 7, hs + 6, 5, 3, Color(0.55, 0.45, 0.25))
	
	# 6. BRAS GAUCHE (bouclier)
	_draw_gradient_rect(img, hs - 22, hs - 2, 8, 16, Color(0.72, 0.62, 0.32), Color(0.58, 0.48, 0.22))
	_add_bevel(img, hs - 22, hs - 2, 8, 16, Color(0.85, 0.75, 0.45), Color(0.50, 0.40, 0.18))
	# Gantelets
	_draw_rect(img, hs - 22, hs + 10, 8, 5, Color(0.55, 0.48, 0.28))
	_draw_rect(img, hs - 21, hs + 8, 6, 3, Color(0.45, 0.38, 0.20))
	
	# 7. BRAS DROIT (épée)
	_draw_gradient_rect(img, hs + 14, hs - 2, 8, 16, Color(0.75, 0.65, 0.35), Color(0.60, 0.50, 0.25))
	_add_bevel(img, hs + 14, hs - 2, 8, 16, Color(0.88, 0.78, 0.48), Color(0.52, 0.42, 0.20))
	# Gantelets
	_draw_rect(img, hs + 14, hs + 10, 8, 5, Color(0.58, 0.50, 0.30))
	_draw_rect(img, hs + 15, hs + 8, 6, 3, Color(0.48, 0.40, 0.22))
	
	# 8. BOUCLIER HÉRALDIQUE (gauche)
	# Forme bouclier (ovale vertical)
	for x in range(hs - 28, hs - 8):
		for y in range(hs - 6, hs + 18):
			var dx: float = float(x - (hs - 18)) / 10.0
			var dy: float = float(y - (hs + 6)) / 12.0
			if dx * dx + dy * dy <= 1.0:
				var c: Color = Color(0.52, 0.55, 0.65)
				# Dégradé radial
				var t: float = (dx * dx + dy * dy)
				c.r = lerp(0.62, 0.42, t)
				c.g = lerp(0.65, 0.45, t)
				c.b = lerp(0.75, 0.55, t)
				img.set_pixel(x, y, c)
	# Bordure bouclier
	for x in range(hs - 28, hs - 8):
		for y in range(hs - 6, hs + 18):
			var dx: float = float(x - (hs - 18)) / 10.0
			var dy: float = float(y - (hs + 6)) / 12.0
			var dist: float = dx * dx + dy * dy
			if dist >= 0.75 and dist <= 1.0:
				img.set_pixel(x, y, Color(0.85, 0.72, 0.20))
	# Blason (croix rouge)
	_draw_rect(img, hs - 19, hs + 4, 4, 10, Color(0.78, 0.08, 0.08))
	_draw_rect(img, hs - 22, hs + 7, 10, 4, Color(0.78, 0.08, 0.08))
	# Lion stylisé (jaune)
	_draw_rect(img, hs - 18, hs + 3, 3, 3, Color(0.90, 0.80, 0.15))
	_draw_rect(img, hs - 17, hs + 2, 1, 2, Color(0.90, 0.80, 0.15))
	
	# 9. ÉPÉE MASSIVE (droite)
	# Lame (acier brillant avec reflets)
	_draw_gradient_rect(img, hs + 22, hs - 28, 6, 38, Color(0.92, 0.95, 1.0), Color(0.68, 0.72, 0.82))
	# Tranchant (plus clair)
	_draw_rect(img, hs + 24, hs - 28, 2, 38, Color(0.98, 0.98, 1.0))
	# Reflets sur la lame
	_draw_rect(img, hs + 23, hs - 20, 1, 8, Color(1.0, 1.0, 1.0))
	_draw_rect(img, hs + 25, hs - 10, 1, 6, Color(1.0, 1.0, 1.0))
	# Garde (ornementée)
	_draw_rect(img, hs + 18, hs + 8, 14, 4, Color(0.55, 0.45, 0.25))
	_draw_rect(img, hs + 20, hs + 6, 10, 2, Color(0.72, 0.62, 0.32))
	# Pommeau (sphère dorée)
	_draw_shaded_circle(img, hs + 25, hs + 16, 5, Color(0.82, 0.72, 0.38), Vector2(-0.5, -0.5))
	
	# 10. TÊTE ET CASQUE
	# Cou
	_draw_gradient_rect(img, hs - 5, hs - 8, 10, 6, Color(0.82, 0.68, 0.52), Color(0.72, 0.58, 0.42))
	# Visage (peau)
	_draw_shaded_circle(img, hs, hs - 14, 12, Color(0.90, 0.75, 0.58), Vector2(-0.4, -0.6))
	# Joues (rose)
	_draw_circle(img, hs - 5, hs - 10, 3, Color(0.95, 0.70, 0.60))
	_draw_circle(img, hs + 5, hs - 10, 3, Color(0.95, 0.70, 0.60))
	# Nez
	_draw_rect(img, hs - 1, hs - 12, 2, 4, Color(0.85, 0.65, 0.45))
	_draw_rect(img, hs - 1, hs - 10, 2, 1, Color(0.75, 0.55, 0.38))
	# Bouche
	_draw_rect(img, hs - 3, hs - 6, 6, 2, Color(0.65, 0.35, 0.30))
	_draw_rect(img, hs - 2, hs - 6, 4, 1, Color(0.80, 0.45, 0.40))
	
	# 11. BARBE BLONDE LUXURIANTE
	# Barbe principale
	for by in range(hs - 8, hs + 4):
		var bw: int = int(lerp(12.0, 4.0, float(by - (hs - 8)) / 12.0))
		_draw_rect(img, hs - bw / 2, by, bw, 2, Color(0.72, 0.58, 0.28))
	# Moustache
	_draw_rect(img, hs - 6, hs - 8, 12, 3, Color(0.78, 0.62, 0.32))
	_draw_rect(img, hs - 4, hs - 9, 8, 2, Color(0.82, 0.66, 0.35))
	# Reflets dans la barbe
	_draw_rect(img, hs - 2, hs - 4, 4, 2, Color(0.88, 0.74, 0.42))
	
	# 12. CASQUE CHEVALIER (grand et imposant)
	# Base du casque
	_draw_rect(img, hs - 14, hs - 26, 28, 14, Color(0.50, 0.53, 0.63))
	_draw_rect(img, hs - 12, hs - 30, 24, 6, Color(0.58, 0.62, 0.72))
	# Crête du casque
	_draw_rect(img, hs - 2, hs - 36, 4, 8, Color(0.65, 0.68, 0.78))
	# Visière (levée)
	_draw_rect(img, hs - 10, hs - 20, 20, 6, Color(0.42, 0.45, 0.55))
	_draw_rect(img, hs - 8, hs - 22, 16, 4, Color(0.38, 0.42, 0.52))
	# Reflets métalliques
	_draw_rect(img, hs - 6, hs - 28, 4, 3, Color(0.82, 0.85, 0.92))
	_draw_rect(img, hs + 4, hs - 26, 3, 2, Color(0.78, 0.82, 0.90))
	# PLUME ROUGE DRAMATIQUE
	# Tige
	_draw_rect(img, hs + 8, hs - 36, 2, 16, Color(0.55, 0.45, 0.30))
	# Plumes (plusieurs couches)
	_draw_rect(img, hs + 6, hs - 42, 8, 8, Color(0.82, 0.10, 0.10))
	_draw_rect(img, hs + 8, hs - 48, 6, 8, Color(0.88, 0.12, 0.12))
	_draw_rect(img, hs + 10, hs - 54, 4, 8, Color(0.92, 0.14, 0.14))
	_draw_rect(img, hs + 11, hs - 58, 2, 6, Color(0.95, 0.16, 0.16))
	# Reflets dans la plume
	_draw_rect(img, hs + 8, hs - 46, 2, 4, Color(0.98, 0.30, 0.30))
	
	# 13. YEUX (expressifs, visibles sous la visière)
	# Blanches
	_draw_shaded_circle(img, hs - 5, hs - 16, 4, Color(0.95, 0.95, 0.95), Vector2(-0.3, -0.3))
	_draw_shaded_circle(img, hs + 5, hs - 16, 4, Color(0.95, 0.95, 0.95), Vector2(-0.3, -0.3))
	# Iris bleu acier
	_draw_circle(img, hs - 5, hs - 16, 3, Color(0.28, 0.42, 0.72))
	_draw_circle(img, hs + 5, hs - 16, 3, Color(0.28, 0.42, 0.72))
	# Pupilles
	_draw_rect(img, hs - 6, hs - 17, 2, 2, Color(0.08, 0.08, 0.12))
	_draw_rect(img, hs + 4, hs - 17, 2, 2, Color(0.08, 0.08, 0.12))
	# Reflets brillants
	_draw_rect(img, hs - 5, hs - 17, 1, 1, Color(1.0, 1.0, 1.0))
	_draw_rect(img, hs + 5, hs - 17, 1, 1, Color(1.0, 1.0, 1.0))
	# Sourcils blonds épais
	_draw_rect(img, hs - 9, hs - 20, 8, 3, Color(0.75, 0.58, 0.25))
	_draw_rect(img, hs + 1, hs - 20, 8, 3, Color(0.75, 0.58, 0.25))
	
	# 14. DÉTAILS FINALS
	# Épaulettes dorées
	_draw_shaded_circle(img, hs - 16, hs - 2, 5, Color(0.82, 0.72, 0.38), Vector2(-0.5, -0.5))
	_draw_shaded_circle(img, hs + 16, hs - 2, 5, Color(0.82, 0.72, 0.38), Vector2(-0.5, -0.5))
	# Gemme sur le plastron
	_draw_shaded_circle(img, hs, hs + 2, 3, Color(0.85, 0.15, 0.15), Vector2(-0.3, -0.3))
	_draw_rect(img, hs - 1, hs + 1, 2, 2, Color(1.0, 0.40, 0.40))
	
	# 15. AURA / GLOW SUBTIL (halo doré autour du héros)
	for x in range(hs - 22, hs + 22):
		for y in range(hs - 38, hs + 32):
			var dx: float = float(x - hs) / 20.0
			var dy: float = float(y - (hs - 4)) / 22.0
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist >= 0.9 and dist <= 1.0:
				var existing: Color = img.get_pixel(x, y)
				if existing.a < 0.1:
					var glow_alpha: float = (1.0 - dist) * 0.25
					img.set_pixel(x, y, Color(0.90, 0.80, 0.30, glow_alpha))

# ============================================================
# FIN GÉNÉRATEUR DE SPRITES
# ============================================================

# Ressources du joueur
var _gold: int = 100
var _wood: int = 50
var _ore: int = 25

func _ready() -> void:
	print("=== WORLD SIZE === ", _world_w, "x", _world_h)
	print("=== ZONE SIZE === ", _zone_w, "x", _zone_h, " (toute la map colorée)")
	print("=== VÉRIFICATION: _play_w = ", _play_w, " _play_h = ", _play_h)
	
	print("=== HoMM Mobile - Étape 10 : Niveau et Expérience ===")
	print("Création de la carte avec TileMapLayer")
	
		
	# Créer la carte
	_create_map()
	
	# Créer les villes
	_create_cities()
	
	# Créer les ennemis
	_create_enemies()
	
	# Créer les ressources collectables
	_create_resources()
	
	# Créer le héros avec visuel
	_create_hero()
	
	# Créer l'interface HoMM3 (inclut la minimap)
	_create_ui()
	
	# === INITIALISATION SYSTÈMES HOMM ===
	_hero_mp = _hero_max_mp
	_init_fog_of_war()
	_init_enemy_armies()
	_update_fog_of_war()
	_create_end_turn_button()
	
	# === INITIALISATION COMBAT MANAGER ===
	var combat_scene := preload("res://scenes/combat_manager.tscn")
	_combat_manager = combat_scene.instantiate()
	_combat_manager.combat_victory.connect(_on_combat_victory)
	_combat_manager.combat_defeat.connect(_on_combat_defeat)
	_combat_manager.combat_fled.connect(_on_combat_fled)
	add_child(_combat_manager)
	print("✓ Combat Manager initialisé")
	
	# Charger sauvegarde si demandé
	if GameData.should_load_save:
		_load_game()
	
	print("✓ Carte créée : ", _world_w, "x", _world_h, " tuiles")
	print("✓ ", CITY_COUNT, " villes créées sur la carte")
	print("✓ ", ENEMY_COUNT, " ennemis créés sur la carte")
	print("✓ ", RESOURCE_COUNT, " ressources à collecter")
	print("✓ ", TREASURE_COUNT, " coffres au trésor à découvrir")
	print("✓ ", TREE_COUNT, " arbres, ", ROCK_COUNT, " rochers, ", TOWER_COUNT, " tours abandonnées")
	print("✓ Héros créé - Niveau ", _hero_level, " (XP: ", _hero_xp, "/", _hero_xp_to_next, ")")
	print("✓ Héros Stats - HP: ", _hero_hp, "/", _hero_max_hp, ", ATK: ", _hero_attack)
	print("✓ Interface HoMM3 avec panneau latéral et cadres dorés")
	print("✓ Minimap HoMM3 élaborée créée")
	print("✓ Système HoMM initialisé: MP=", _hero_mp, "/", _hero_max_mp, ", Brouillard de guerre, Armées")
	print("✓ Effet de sélection doré autour du héros")
	print("✓ Prêt pour l'aventure !")

func _create_map() -> void:
	print("=== _create_map ===")
	print("World: ", _world_w, "x", _world_h, " | Zone: ", _zx, ",", _zy, " to ", _zex, ",", _zey)
	
	# === DÉTRUIRE ANCIEN TERRAIN ===
	for child in get_children():
		if child.name == "MapSprite" or child is TileMapLayer:
			child.queue_free()
			print("=== ANCIEN TERRAIN DÉTRUIT ===")
	
	# Générer l'image du terrain
	var map_texture: ImageTexture = _generate_map_image()
	
	# Créer un Sprite2D pour afficher le terrain
	_map_sprite = Sprite2D.new()
	_map_sprite.name = "MapSprite"
	_map_sprite.texture = map_texture
	_map_sprite.position = Vector2(60 * TILE_SIZE / 2, 40 * TILE_SIZE / 2)  # Centré sur la map
	_map_sprite.set_z_index(-10)
	add_child(_map_sprite)
	print("=== TERRAIN SPRITE CRÉÉ: 60×40 tuiles ===")

	print("Carte générée : 60×40 = 2400 tuiles")
	_create_decorations()
	_create_mountain_sprites()
	_create_bridges()

func _generate_tile_texture(tile_type: int, rng: RandomNumberGenerator) -> Image:
	"""Génère une tuile de terrain 64x64 avec texture détaillée procédurale"""
	var img: Image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	
	match tile_type:
		0, 5:  # Herbe / Prairie
			# Fond herbe avec variations riches
			var base_g: Color = Color(0.28, 0.50, 0.18)
			if tile_type == 5:
				base_g = Color(0.40, 0.60, 0.26)
			img.fill(base_g)
			# Variations de ton (plus nombreuses)
			for _i in range(120):
				var gx: int = rng.randi_range(0, TILE_SIZE - 1)
				var gy: int = rng.randi_range(0, TILE_SIZE - 1)
				var gshade: float = rng.randf_range(-0.05, 0.05)
				var gc: Color = base_g
				gc.r = clamp(gc.r + gshade + rng.randf_range(-0.03, 0.03), 0, 1)
				gc.g = clamp(gc.g + gshade + rng.randf_range(-0.03, 0.08), 0, 1)
				gc.b = clamp(gc.b + gshade, 0, 1)
				img.set_pixel(gx, gy, gc)
			# Touffes d'herbe (plus sombres et nombreuses)
			for _i in range(10):
				var tx: int = rng.randi_range(4, TILE_SIZE - 8)
				var ty: int = rng.randi_range(4, TILE_SIZE - 8)
				for dx in range(-4, 5):
					for dy in range(-4, 5):
						if dx*dx + dy*dy < 14 and rng.randf() < 0.55:
							var tcol: Color = Color(0.16, 0.40, 0.08)
							if rng.randf() < 0.35:
								tcol = Color(0.20, 0.44, 0.12)
							img.set_pixel(clamp(tx + dx, 0, TILE_SIZE - 1), clamp(ty + dy, 0, TILE_SIZE - 1), tcol)
			# Touffes d'herbe claire (contrastes)
			for _i in range(8):
				var tx: int = rng.randi_range(4, TILE_SIZE - 8)
				var ty: int = rng.randi_range(4, TILE_SIZE - 8)
				for dx in range(-3, 4):
					for dy in range(-3, 4):
						if dx*dx + dy*dy < 8 and rng.randf() < 0.45:
							var tcol: Color = Color(0.32, 0.56, 0.22)
							if rng.randf() < 0.3:
								tcol = Color(0.36, 0.62, 0.26)
							img.set_pixel(clamp(tx + dx, 0, TILE_SIZE - 1), clamp(ty + dy, 0, TILE_SIZE - 1), tcol)
			# Petites fleurs colorées
			if rng.randf() < 0.5:
				for _j in range(rng.randi_range(3, 8)):
					var fx: int = rng.randi_range(8, TILE_SIZE - 10)
					var fy: int = rng.randi_range(8, TILE_SIZE - 10)
					var flower_type: float = rng.randf()
					var fcol: Color = Color(0.85, 0.78, 0.20)
					if flower_type < 0.33:
						fcol = Color(0.82, 0.25, 0.28)
					elif flower_type < 0.66:
						fcol = Color(0.72, 0.55, 0.82)
					img.set_pixel(fx, fy, fcol)
					img.set_pixel(fx + 1, fy, fcol)
					img.set_pixel(fx, fy + 1, Color(0.20, 0.42, 0.12))
			# Petits cailloux
			for _i in range(4):
				var cx: int = rng.randi_range(4, TILE_SIZE - 6)
				var cy: int = rng.randi_range(4, TILE_SIZE - 6)
				img.set_pixel(cx, cy, Color(0.55, 0.52, 0.48))
				img.set_pixel(cx + 1, cy, Color(0.60, 0.58, 0.52))
				img.set_pixel(cx, cy + 1, Color(0.50, 0.48, 0.42))
			# Mouches d'herbe fines
			for _i in range(15):
				var lx: int = rng.randi_range(0, TILE_SIZE - 1)
				var ly: int = rng.randi_range(0, TILE_SIZE - 1)
				var lcol: Color = Color(0.12, 0.35, 0.08)
				if rng.randf() < 0.5:
					lcol = Color(0.32, 0.55, 0.18)
				img.set_pixel(lx, ly, lcol)
				img.set_pixel(lx + 1, ly, lcol)
			if rng.randf() < 0.4:
				var px: int = rng.randi_range(8, TILE_SIZE - 12)
				var py: int = rng.randi_range(8, TILE_SIZE - 12)
				for pdx in range(2, 4):
					for pdy in range(2, 3):
						img.set_pixel(px + pdx, py + pdy, Color(0.30, 0.48, 0.18))
		
		1:  # Terre
			img.fill(Color(0.55, 0.42, 0.28))
			# Variations
			for _i in range(120):
				var tx: int = rng.randi_range(0, TILE_SIZE - 1)
				var ty: int = rng.randi_range(0, TILE_SIZE - 1)
				var dshade: float = rng.randf_range(-0.06, 0.04)
				var dc: Color = Color(0.55 + dshade, 0.42 + dshade * 0.8, 0.28 + dshade * 0.6)
				img.set_pixel(tx, ty, dc)
			# Cailloux
			for _i in range(5):
				var cx: int = rng.randi_range(4, TILE_SIZE - 6)
				var cy: int = rng.randi_range(4, TILE_SIZE - 6)
				var cw: int = rng.randi_range(3, 6)
				var ch: int = rng.randi_range(2, 4)
				var cc: Color = Color(0.48, 0.44, 0.38)
				if rng.randf() < 0.5:
					cc = Color(0.52, 0.48, 0.42)
				for dx in range(cw):
					for dy in range(ch):
						if cx + dx < TILE_SIZE and cy + dy < TILE_SIZE:
							img.set_pixel(cx + dx, cy + dy, cc)
			# Fissures
			for _i in range(3):
				var fx: int = rng.randi_range(0, TILE_SIZE - 1)
				var fy: int = rng.randi_range(0, TILE_SIZE - 1)
				for j in range(rng.randi_range(5, 12)):
					if fx >= 0 and fx < TILE_SIZE and fy >= 0 and fy < TILE_SIZE:
						img.set_pixel(fx, fy, Color(0.42, 0.35, 0.25))
						fx += rng.randi_range(-1, 1)
						fy += rng.randi_range(0, 1)

		2:  # Eau
			img.fill(Color(0.10, 0.32, 0.58))
			# Reflets plus riches
			for _i in range(30):
				var rx = rng.randi_range(4, TILE_SIZE - 8)
				var ry = rng.randi_range(4, TILE_SIZE - 8)
				for dx in range(4):
					img.set_pixel(rx + dx, ry, Color(0.20, 0.45, 0.72))
					img.set_pixel(rx + dx, ry + 1, Color(0.15, 0.38, 0.65))
			# Profondeur
			for _i in range(40):
				var dx = rng.randi_range(0, TILE_SIZE - 1)
				var dy = rng.randi_range(0, TILE_SIZE - 1)
				img.set_pixel(dx, dy, Color(0.08, 0.28, 0.52))
			# Bulles/écume
			for _i in range(15):
				var bx = rng.randi_range(0, TILE_SIZE - 1)
				var by = rng.randi_range(0, TILE_SIZE - 1)
				img.set_pixel(bx, by, Color(0.18, 0.48, 0.78, 0.6))
				img.set_pixel(bx + 1, by, Color(0.15, 0.42, 0.72, 0.4))
			# Vagues légères
			for x in range(TILE_SIZE):
				for y in range(TILE_SIZE):
					if (x + y) % 7 == 0:
						img.set_pixel(x, y, img.get_pixel(x, y).lightened(0.05))

		3:  # Montagne
			img.fill(Color(0.48, 0.46, 0.42))
			# Pierres
			for _i in range(8):
				var sx = rng.randi_range(4, TILE_SIZE - 10)
				var sy = rng.randi_range(4, TILE_SIZE - 10)
				for dx in range(6):
					for dy in range(6):
						if (dx-3)*(dx-3) + (dy-3)*(dy-3) < 9:
							img.set_pixel(sx+dx, sy+dy, Color(0.58, 0.56, 0.52))
			# Neige sommités
			for x in range(TILE_SIZE):
				for y in range(12):
					if rng.randf() < 0.4 - y*0.025:
						img.set_pixel(x, y, Color(0.88, 0.90, 0.92))
					elif rng.randf() < 0.2 - y*0.015:
						img.set_pixel(x, y, Color(0.75, 0.78, 0.82))
			# Ombres
			for _i in range(50):
				var ox = rng.randi_range(0, TILE_SIZE - 1)
				var oy = rng.randi_range(0, TILE_SIZE - 1)
				img.set_pixel(ox, oy, Color(0.38, 0.36, 0.32))
			# Minerais brillants
			for _i in range(6):
				var mx = rng.randi_range(0, TILE_SIZE - 1)
				var my = rng.randi_range(0, TILE_SIZE - 1)
				img.set_pixel(mx, my, Color(0.65, 0.60, 0.55))
				img.set_pixel(mx + 1, my, Color(0.55, 0.50, 0.45))

		4:  # Forêt
			img.fill(Color(0.18, 0.35, 0.12))
			# Arbres plus détaillés
			for _i in range(5):
				var tx = rng.randi_range(6, TILE_SIZE - 10)
				var ty = rng.randi_range(6, TILE_SIZE - 10)
				# Tronc
				for dy in range(5):
					img.set_pixel(tx, ty + dy, Color(0.42, 0.28, 0.15))
					if tx + 1 < TILE_SIZE:
						img.set_pixel(tx + 1, ty + dy, Color(0.35, 0.22, 0.12))
				# Feuillage
				for dx in range(-4, 5):
					for dy in range(-4, 5):
						if dx*dx + dy*dy < 10:
							var fcol = Color(0.15, 0.45, 0.08)
							if rng.randf() < 0.3:
								fcol = Color(0.20, 0.50, 0.12)
							img.set_pixel(tx+dx, ty+dy-2, fcol)
			# Sol clair avec feuilles mortes
			for _i in range(80):
				var sx = rng.randi_range(0, TILE_SIZE - 1)
				var sy = rng.randi_range(0, TILE_SIZE - 1)
				img.set_pixel(sx, sy, Color(0.22, 0.38, 0.14))
			# Champignons
			for _i in range(3):
				var mx = rng.randi_range(4, TILE_SIZE - 6)
				var my = rng.randi_range(4, TILE_SIZE - 6)
				img.set_pixel(mx, my + 1, Color(0.70, 0.65, 0.60))
				img.set_pixel(mx, my, Color(0.85, 0.25, 0.20))
				img.set_pixel(mx + 1, my, Color(0.80, 0.20, 0.15))
			# Fissures sombres
			for _i in range(3):
				var fx: int = rng.randi_range(8, TILE_SIZE - 8)
				for fy in range(rng.randi_range(6, 15)):
					img.set_pixel(fx + rng.randi_range(-1, 1), rng.randi_range(4, TILE_SIZE - 4), Color(0.30, 0.28, 0.24))
		
		4:  # Forêt
			img.fill(Color(0.10, 0.26, 0.08))
			# Sous-bois plus clair par endroits
			for _i in range(30):
				var sx: int = rng.randi_range(0, TILE_SIZE - 1)
				var sy: int = rng.randi_range(0, TILE_SIZE - 1)
				img.set_pixel(sx, sy, Color(0.12, 0.30, 0.10))
			# Troncs d'arbres
			for _i in range(4):
				var tx: int = rng.randi_range(8, TILE_SIZE - 12)
				var ty: int = rng.randi_range(8, TILE_SIZE - 16)
				for dy in range(rng.randi_range(8, 16)):
					var tw: int = rng.randi_range(3, 5)
					for dx in range(tw):
						img.set_pixel(clamp(tx + dx, 0, TILE_SIZE - 1), clamp(ty + dy, 0, TILE_SIZE - 1), Color(0.32, 0.20, 0.10))
			# Taches de mousse
			for _i in range(8):
				var mx: int = rng.randi_range(4, TILE_SIZE - 6)
				var my: int = rng.randi_range(4, TILE_SIZE - 6)
				for dx in range(-2, 3):
					for dy in range(-2, 3):
						if rng.randf() < 0.5:
							img.set_pixel(clamp(mx + dx, 0, TILE_SIZE - 1), clamp(my + dy, 0, TILE_SIZE - 1), Color(0.14, 0.32, 0.12))
			# Champignons
			if rng.randf() < 0.3:
				var mx: int = rng.randi_range(10, TILE_SIZE - 14)
				var my: int = rng.randi_range(10, TILE_SIZE - 14)
				img.set_pixel(mx, my, Color(0.72, 0.55, 0.35))
				img.set_pixel(mx + 1, my, Color(0.72, 0.55, 0.35))
				img.set_pixel(mx, my + 1, Color(0.55, 0.42, 0.28))
	
	return img

func _generate_map_image() -> ImageTexture:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	var w: int = 60
	var h: int = 40
	
	# === COULEURS HOMM3 (plus riches) ===
	var C_GRASS: Color = Color(0.28, 0.50, 0.18)      # Herbe principale
	var C_GRASS_LIGHT: Color = Color(0.40, 0.58, 0.26)  # Herbe claire/prairie
	var C_DIRT: Color = Color(0.58, 0.48, 0.34)        # Terre/sable
	var C_WATER: Color = Color(0.10, 0.32, 0.58)       # Eau profonde
	var C_WATER_SHALLOW: Color = Color(0.14, 0.36, 0.62)  # Eau peu profonde
	var C_MOUNTAIN: Color = Color(0.48, 0.46, 0.42)    # Montagne
	var C_MOUNTAIN_DARK: Color = Color(0.38, 0.36, 0.32)  # Montagne sombre
	var C_FOREST: Color = Color(0.12, 0.30, 0.10)      # Forêt dense
	var C_SAND: Color = Color(0.72, 0.62, 0.46)        # Sable (bordure eau)
	var C_ROCK: Color = Color(0.56, 0.52, 0.48)         # Roche (bordure montagne)
	
	var base_colors: Array[Color] = [C_GRASS, C_DIRT, C_WATER, C_MOUNTAIN, C_FOREST, C_GRASS_LIGHT]
	
	# Grille de terrain (stockée globalement)
	_terrain_grid = []
	for x in range(w):
		_terrain_grid.append([])
		for y in range(h):
			_terrain_grid[x].append(0)  # Herbe par défaut
	
	# === 1. ZONES DE TERRE (plus grandes) ===
	for _i in range(3):
		var blob_x: int = rng.randi_range(3, w - 4)
		var blob_y: int = rng.randi_range(3, h - 4)
		var blob_size: int = rng.randi_range(2, 4)
		for dx in range(-blob_size, blob_size + 1):
			for dy in range(-blob_size, blob_size + 1):
				var dist: float = sqrt(dx * dx + dy * dy)
				if dist <= blob_size and rng.randf() < (1.0 - dist / blob_size * 0.6):
					var px: int = blob_x + dx
					var py: int = blob_y + dy
					if px >= 0 and px < w and py >= 0 and py < h:
						_terrain_grid[px][py] = 1
	
	# === 2. LACS (plus grands) ===
	for _i in range(3):
		var lake_x: int = rng.randi_range(4, w - 5)
		var lake_y: int = rng.randi_range(4, h - 5)
		var lake_size: int = rng.randi_range(2, 4)
		for dx in range(-lake_size, lake_size + 1):
			for dy in range(-lake_size, lake_size + 1):
				if sqrt(dx * dx + dy * dy) <= lake_size + rng.randf() * 0.8:
					var px: int = lake_x + dx
					var py: int = lake_y + dy
					if px >= 0 and px < w and py >= 0 and py < h:
						_terrain_grid[px][py] = 2
	
	# === 3. CHAÎNES DE MONTAGNES (plus longues) ===
	for _i in range(2):
		var start_x: int = rng.randi_range(2, w - 3)
		var start_y: int = rng.randi_range(2, h - 3)
		var chain_length: int = rng.randi_range(5, 10)
		var dir_x: int = rng.randi_range(-1, 1)
		var dir_y: int = rng.randi_range(-1, 1)
		if dir_x == 0 and dir_y == 0:
			dir_x = 1
		var cur_x: int = start_x
		var cur_y: int = start_y
		for _j in range(chain_length):
			if cur_x >= 0 and cur_x < w and cur_y >= 0 and cur_y < h:
				_terrain_grid[cur_x][cur_y] = 3
				# Épaissir la chaîne
				for _k in range(rng.randi_range(1, 3)):
					var adj_x: int = cur_x + rng.randi_range(-1, 1)
					var adj_y: int = cur_y + rng.randi_range(-1, 1)
					if adj_x >= 0 and adj_x < w and adj_y >= 0 and adj_y < h:
						_terrain_grid[adj_x][adj_y] = 3
			cur_x += dir_x + rng.randi_range(-1, 1)
			cur_y += dir_y + rng.randi_range(-1, 1)
			cur_x = clamp(cur_x, 0, w - 1)
			cur_y = clamp(cur_y, 0, h - 1)
	
	# === 4. FORÊTS DENSES (beaucoup plus) ===
	for _i in range(8):
		var forest_x: int = rng.randi_range(2, w - 3)
		var forest_y: int = rng.randi_range(2, h - 3)
		var forest_size: int = rng.randi_range(2, 4)
		for dx in range(-forest_size, forest_size + 1):
			for dy in range(-forest_size, forest_size + 1):
				var dist: float = sqrt(dx * dx + dy * dy)
				if dist <= forest_size and rng.randf() < (1.0 - dist / forest_size * 0.5):
					var px: int = forest_x + dx
					var py: int = forest_y + dy
					if px >= 0 and px < w and py >= 0 and py < h and _terrain_grid[px][py] == 0:
						_terrain_grid[px][py] = 4
	
	# === 5. RIVIÈRE (plus sinueuse) ===
	var river_x: int = rng.randi_range(5, w - 6)
	for ry in range(h):
		# Rivière de 1-2 tuiles de large
		_terrain_grid[river_x][ry] = 2
		if rng.randf() < 0.35 and river_x > 0:
			_terrain_grid[river_x - 1][ry] = 2
		if rng.randf() < 0.35 and river_x < w - 1:
			_terrain_grid[river_x + 1][ry] = 2
		river_x += rng.randi_range(-1, 1)
		river_x = clamp(river_x, 3, w - 4)
	
	# === 6. ROUTES (plus fines - 1 tuile) ===
	var road_y: int = h / 2
	for x in range(w):
		if _terrain_grid[x][road_y] != 2:  # Pas sur l'eau
			_terrain_grid[x][road_y] = 1
	
	var road_x: int = w / 2
	for y in range(h):
		if _terrain_grid[road_x][y] != 2:  # Pas sur l'eau
			_terrain_grid[road_x][y] = 1
	
	# === 7. PRAIRIES ===
	for _i in range(6):
		var meadow_x: int = rng.randi_range(2, w - 3)
		var meadow_y: int = rng.randi_range(2, h - 3)
		var meadow_size: int = rng.randi_range(2, 3)
		for dx in range(-meadow_size, meadow_size + 1):
			for dy in range(-meadow_size, meadow_size + 1):
				var dist: float = abs(dx) + abs(dy)
				if dist <= meadow_size and rng.randf() < (1.0 - dist / float(meadow_size + 1) * 0.3):
					var px: int = meadow_x + dx
					var py: int = meadow_y + dy
					if px >= 0 and px < w and py >= 0 and py < h and _terrain_grid[px][py] == 0:
						_terrain_grid[px][py] = 5
	
	# === 8. LISSAGE montagnes isolées ===
	for x in range(1, w - 1):
		for y in range(1, h - 1):
			if _terrain_grid[x][y] == 3:
				var neighbors_mountain: int = 0
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						if _terrain_grid[x + dx][y + dy] == 3:
							neighbors_mountain += 1
				if neighbors_mountain < 2:
					_terrain_grid[x][y] = 0
	
	# === 9. ZONE PROPRE autour du spawn ===
	var hero_tile_x: int = w / 2
	var hero_tile_y: int = h / 2
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var px: int = hero_tile_x + dx
			var py: int = hero_tile_y + dy
			if px >= 0 and px < w and py >= 0 and py < h:
				_terrain_grid[px][py] = 0
	
	# === COULEURS DE TERRAIN (plus riches et saturées) ===
	var colors: Array[Color] = [
		Color(0.28, 0.46, 0.18),  # 0: Herbe
		Color(0.58, 0.48, 0.32),  # 1: Terre
		Color(0.10, 0.28, 0.52),  # 2: Eau
		Color(0.45, 0.42, 0.38),  # 3: Montagne
		Color(0.12, 0.28, 0.10),  # 4: Forêt
		Color(0.40, 0.56, 0.26),  # 5: Herbe claire
	]
	
	# === DESSINER L'IMAGE AVEC TUILES TEXTURÉES ===
	var img_width: int = w * TILE_SIZE
	var img_height: int = h * TILE_SIZE
	var map_image: Image = Image.create(img_width, img_height, false, Image.FORMAT_RGBA8)
	
	for x in range(w):
		for y in range(h):
			var tx: int = x * TILE_SIZE
			var ty: int = y * TILE_SIZE
			var tile_type: int = _terrain_grid[x][y]
			
			# Générer la tuile texturée détaillée
			var tile_img: Image = _generate_tile_texture(tile_type, rng)
			
			# Copier la tuile sur la carte
			for px in range(TILE_SIZE):
				for py in range(TILE_SIZE):
					map_image.set_pixel(tx + px, ty + py, tile_img.get_pixel(px, py))
	
	# === TRANSITIONS DOUCES ENTRE BIOMES (pixel-perfect avec bruit) ===
	# Pour chaque tuile, on regarde ses voisins et on crée des transitions douces
	for x in range(w):
		for y in range(h):
			var tx: int = x * TILE_SIZE
			var ty: int = y * TILE_SIZE
			var current_type: int = _terrain_grid[x][y]
			
			# Vérifier les voisins pour les transitions
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx: int = x + dx
					var ny: int = y + dy
					if nx < 0 or nx >= w or ny < 0 or ny >= h:
						continue
					
					var neighbor_type: int = _terrain_grid[nx][ny]
					if neighbor_type == current_type:
						continue
					
					# Pour chaque pixel sur le bord de la tuile actuelle
					var start_px: int = 0 if dx != 1 else TILE_SIZE - 8
					var start_py: int = 0 if dy != 1 else TILE_SIZE - 8
					var end_px: int = TILE_SIZE if dx != -1 else 8
					var end_py: int = TILE_SIZE if dy != -1 else 8
					
					for px in range(start_px, end_px):
						for py in range(start_py, end_py):
							# Distance au bord (0 = au bord, 1 = au centre)
							var dist_to_edge: float = 0.0
							if dx == -1:
								dist_to_edge = px / 8.0
							elif dx == 1:
								dist_to_edge = (TILE_SIZE - 1 - px) / 8.0
							if dy == -1:
								dist_to_edge = max(dist_to_edge, py / 8.0)
							elif dy == 1:
								dist_to_edge = max(dist_to_edge, (TILE_SIZE - 1 - py) / 8.0)
							
							dist_to_edge = clamp(dist_to_edge, 0.0, 1.0)
							
							# Ajouter du bruit pour des bords irréguliers
							var noise: float = rng.randf_range(-0.3, 0.3)
							var blend: float = clamp(dist_to_edge + noise, 0.0, 1.0)
							
							# Ne mélanger que sur les 8 pixels du bord
							if dist_to_edge < 1.0:
								var current_color: Color = map_image.get_pixel(tx + px, ty + py)
								var neighbor_base: Color = base_colors[neighbor_type]
								
								# Spécial: eau → sable, montagne → roche
								var blend_color: Color = neighbor_base
								if current_type == 2:
									blend_color = C_SAND
								elif current_type == 3:
									blend_color = C_ROCK
								
								# Mélanger avec alpha
								var alpha: float = 1.0 - blend
								var result: Color = current_color.lerp(blend_color, alpha * 0.5)
								map_image.set_pixel(tx + px, ty + py, result)
	
	# === EFFET DE VIGNETTE (coins plus foncés pour l'atmosphère) ===
	for x in range(w):
		for y in range(h):
			var tx: int = x * TILE_SIZE
			var ty: int = y * TILE_SIZE
			# Calculer la distance aux bords (0 au centre, 1 aux bords)
			var dist_x: float = abs(x - w / 2.0) / (w / 2.0)
			var dist_y: float = abs(y - h / 2.0) / (h / 2.0)
			var vignette: float = max(dist_x, dist_y)
			vignette = vignette * vignette * 0.15  # Effet subtil
			
			if vignette > 0.02:
				for px in range(TILE_SIZE):
					for py in range(TILE_SIZE):
						var c: Color = map_image.get_pixel(tx + px, ty + py)
						c.r = clamp(c.r - vignette, 0, 1)
						c.g = clamp(c.g - vignette, 0, 1)
						c.b = clamp(c.b - vignette, 0, 1)
						map_image.set_pixel(tx + px, ty + py, c)
	
	# === TEXTURATION DES ROUTES (cailloux, traces, bordures) ===
	for x in range(w):
		for y in range(h):
			if _terrain_grid[x][y] == 1:  # C'est une route/terre
				var tx: int = x * TILE_SIZE
				var ty: int = y * TILE_SIZE
				# Vérifier si c'est une route (connectée à d'autres routes)
				var is_road: bool = false
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx: int = x + dx
						var ny: int = y + dy
						if nx >= 0 and nx < w and ny >= 0 and ny < h:
							if _terrain_grid[nx][ny] == 1:
								is_road = true
								break
						if is_road:
							break
				
				if is_road:
					# Cailloux sur la route
					for _i in range(12):
						var rx: int = tx + rng.randi_range(2, TILE_SIZE - 4)
						var ry: int = ty + rng.randi_range(2, TILE_SIZE - 4)
						var rcol: Color = Color(0.62, 0.52, 0.38)
						if rng.randf() < 0.4:
							rcol = Color(0.68, 0.58, 0.42)
						map_image.set_pixel(rx, ry, rcol)
						if rng.randf() < 0.5:
							map_image.set_pixel(rx + 1, ry, rcol)
					
					# Traces de pas (lignes plus foncées)
					if rng.randf() < 0.5:
						var track_x: int = tx + rng.randi_range(8, TILE_SIZE - 16)
						var track_y: int = ty + rng.randi_range(10, TILE_SIZE - 14)
						for dx in range(rng.randi_range(4, 10)):
							map_image.set_pixel(track_x + dx, track_y, Color(0.48, 0.38, 0.24))
							map_image.set_pixel(track_x + dx, track_y + 2, Color(0.48, 0.38, 0.24))
					
					# Bordures de route (herbe qui dépasse)
					for dx in range(-1, 2):
						for dy in range(-1, 2):
							if dx == 0 and dy == 0:
								continue
							var nx: int = x + dx
							var ny: int = y + dy
							if nx >= 0 and nx < w and ny >= 0 and ny < h:
								if _terrain_grid[nx][ny] == 0 or _terrain_grid[nx][ny] == 5:  # Herbe voisine
									# Petites touffes d'herbe qui débordent
									var edge_px: int = tx + (TILE_SIZE - 4 if dx == 1 else 4) if dx != 0 else tx + rng.randi_range(4, TILE_SIZE - 4)
									var edge_py: int = ty + (TILE_SIZE - 4 if dy == 1 else 4) if dy != 0 else ty + rng.randi_range(4, TILE_SIZE - 4)
									for _j in range(3):
										var gx: int = edge_px + rng.randi_range(-2, 2)
										var gy: int = edge_py + rng.randi_range(-2, 2)
										map_image.set_pixel(clamp(gx, tx, tx + TILE_SIZE - 1), clamp(gy, ty, ty + TILE_SIZE - 1), Color(0.24, 0.46, 0.14))
	
	# === BORDS DE PLAGE (sable) autour de l'eau ===
	for x in range(w):
		for y in range(h):
			if _terrain_grid[x][y] == 2:  # Eau
				var tx: int = x * TILE_SIZE
				var ty: int = y * TILE_SIZE
				# Pour chaque voisin non-eau, dessiner du sable sur le bord
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx: int = x + dx
						var ny: int = y + dy
						if nx < 0 or nx >= w or ny < 0 or ny >= h:
							continue
						if _terrain_grid[nx][ny] != 2:  # Voisin = terre/herbe
							# Bord de plage sur la tuile d'eau (côté du voisin)
							var beach_w: int = 10  # Largeur plage en pixels
							if dx == -1:  # Voisin à gauche
								for px in range(beach_w):
									for py in range(TILE_SIZE):
										var alpha: float = 1.0 - (px / float(beach_w))
										if rng.randf() < alpha * 0.6:
											var sand_col: Color = Color(0.72 + rng.randf() * 0.08, 0.62 + rng.randf() * 0.06, 0.44 + rng.randf() * 0.04)
											map_image.set_pixel(tx + px, ty + py, sand_col)
							elif dx == 1:  # Voisin à droite
								for px in range(TILE_SIZE - beach_w, TILE_SIZE):
									for py in range(TILE_SIZE):
										var alpha: float = (px - (TILE_SIZE - beach_w)) / float(beach_w)
										if rng.randf() < alpha * 0.6:
											var sand_col: Color = Color(0.72 + rng.randf() * 0.08, 0.62 + rng.randf() * 0.06, 0.44 + rng.randf() * 0.04)
											map_image.set_pixel(tx + px, ty + py, sand_col)
							if dy == -1:  # Voisin en haut
								for px in range(TILE_SIZE):
									for py in range(beach_w):
										var alpha: float = 1.0 - (py / float(beach_w))
										if rng.randf() < alpha * 0.6:
											var sand_col: Color = Color(0.72 + rng.randf() * 0.08, 0.62 + rng.randf() * 0.06, 0.44 + rng.randf() * 0.04)
											map_image.set_pixel(tx + px, ty + py, sand_col)
							elif dy == 1:  # Voisin en bas
								for px in range(TILE_SIZE):
									for py in range(TILE_SIZE - beach_w, TILE_SIZE):
										var alpha: float = (py - (TILE_SIZE - beach_w)) / float(beach_w)
										if rng.randf() < alpha * 0.6:
											var sand_col: Color = Color(0.72 + rng.randf() * 0.08, 0.62 + rng.randf() * 0.06, 0.44 + rng.randf() * 0.04)
											map_image.set_pixel(tx + px, ty + py, sand_col)
	
	# === DÉTAILS DE SOL (hautes herbes, buissons, souches) ===
	for x in range(w):
		for y in range(h):
			if _terrain_grid[x][y] == 0 or _terrain_grid[x][y] == 5:  # Herbe uniquement
				var tx: int = x * TILE_SIZE
				var ty: int = y * TILE_SIZE
				
				# Hautes herbes (touffes vert foncé)
				for _i in range(rng.randi_range(0, 3)):
					var hx: int = tx + rng.randi_range(4, TILE_SIZE - 8)
					var hy: int = ty + rng.randi_range(4, TILE_SIZE - 8)
					for dy in range(rng.randi_range(2, 4)):
						for dx in range(rng.randi_range(2, 3)):
							map_image.set_pixel(hx + dx, hy + dy, Color(0.18, 0.40, 0.10, 0.9))
				
				# Souches d'arbres
				if rng.randf() < 0.05:
					var sx: int = tx + rng.randi_range(12, TILE_SIZE - 16)
					var sy: int = ty + rng.randi_range(12, TILE_SIZE - 16)
					for dy in range(3):
						for dx in range(4):
							map_image.set_pixel(sx + dx, sy + dy, Color(0.38, 0.24, 0.12))
					# Anneaux de croissance
					map_image.set_pixel(sx + 1, sy + 1, Color(0.50, 0.35, 0.18))
					map_image.set_pixel(sx + 2, sy + 1, Color(0.50, 0.35, 0.18))
					map_image.set_pixel(sx + 1, sy + 2, Color(0.42, 0.28, 0.14))
					map_image.set_pixel(sx + 2, sy + 2, Color(0.42, 0.28, 0.14))
				
				# Petits buissons
				if rng.randf() < 0.08:
					var bx: int = tx + rng.randi_range(8, TILE_SIZE - 12)
					var by: int = ty + rng.randi_range(8, TILE_SIZE - 12)
					for dy in range(-2, 3):
						for dx in range(-2, 3):
							if dx*dx + dy*dy <= 5 and rng.randf() < 0.7:
								var bcol: Color = Color(0.20, 0.44, 0.12) if rng.randf() < 0.5 else Color(0.26, 0.50, 0.16)
								map_image.set_pixel(bx + dx, by + dy, bcol)
				
				# Fleurs colorées (plus nombreuses)
				if rng.randf() < 0.35:
					for _j in range(rng.randi_range(2, 5)):
						var fx: int = tx + rng.randi_range(8, TILE_SIZE - 12)
						var fy: int = ty + rng.randi_range(8, TILE_SIZE - 12)
						var flower_type: float = rng.randf()
						var fcol: Color = Color(0.85, 0.20, 0.20)  # Rouge
						if flower_type < 0.33:
							fcol = Color(0.85, 0.78, 0.20)  # Jaune
						elif flower_type < 0.66:
							fcol = Color(0.72, 0.55, 0.82)  # Violet
						else:
							fcol = Color(0.20, 0.60, 0.85)  # Bleu
						map_image.set_pixel(fx, fy, fcol)
						map_image.set_pixel(fx + 1, fy, fcol)
						map_image.set_pixel(fx, fy + 1, Color(0.20, 0.42, 0.12))
				
				# Cailloux sur l'herbe
				if rng.randf() < 0.25:
					for _j in range(rng.randi_range(2, 4)):
						var cx: int = tx + rng.randi_range(4, TILE_SIZE - 6)
						var cy: int = ty + rng.randi_range(4, TILE_SIZE - 6)
						var ccol: Color = Color(0.55, 0.52, 0.48)
						if rng.randf() < 0.5:
							ccol = Color(0.60, 0.58, 0.52)
						map_image.set_pixel(cx, cy, ccol)
						if rng.randf() < 0.5:
							map_image.set_pixel(cx + 1, cy, ccol)
	
	print("✓ Terrain professionnel: ", img_width, "x", img_height, " avec transitions douces, routes texturées, plages et détails de sol")
	return ImageTexture.create_from_image(map_image)

func _create_decorations() -> void:
	# Créer des arbres et rochers sur la carte pour la rendre plus vivante
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	# === NOUVEAU SYSTÈME ARBRES : images individuelles avec 2 arbres par image ===
	# Chaque image fait 224x128 → 2 arbres de 112x128 chacun
	var tree_files: Array[String] = [
		"res://assets/external/arbre/autumn.png",
		"res://assets/external/arbre/autumn 2.png",
		"res://assets/external/arbre/autumn 3.png",
		"res://assets/external/arbre/blue trees.png",
		"res://assets/external/arbre/brown trees.png",
		"res://assets/external/arbre/brown trees 2.png",
		"res://assets/external/arbre/cherry_blossom_trees.png",
		"res://assets/external/arbre/green trees.png",
		"res://assets/external/arbre/yellow.png",
		"res://assets/external/arbre/yellow 2.png"
	]
	# Charger toutes les textures disponibles
	var tree_textures: Array[Texture2D] = []
	for f in tree_files:
		var tex: Texture2D = load(f)
		if tex != null:
			tree_textures.append(tex)
	
	# === CRÉER DES VRAIES FORÊTS ET ARBRES SOLITAIRES ===
	# Grille pour tracker les positions occupées (éviter les superpositions)
	var occupied: Dictionary = {}
	
	for i in range(TREE_COUNT):
		var center_x: int = rng.randi_range(2, _zone_w - 3)
		var center_y: int = rng.randi_range(2, _zone_h - 3)
		
		# Déterminer le type d'emplacement
		var density_roll: float = rng.randf()
		var is_forest: bool = density_roll < 0.28      # 28% = VRAIE FORÊT (8-16 arbres sur 3×3 tuiles)
		var is_group: bool = density_roll < 0.55 and not is_forest  # 27% = Petit groupe (2-4 arbres sur 2×2)
		# 45% = Arbre solitaire
		
		# Choisir UNE image d'arbre pour toute la forêt/groupe
		var tex_idx: int = rng.randi_range(0, tree_textures.size() - 1)
		var base_tex: Texture2D = tree_textures[tex_idx]
		var tex_size: Vector2 = base_tex.get_size()
		var half_w: float = tex_size.x / 2.0
		var full_h: float = tex_size.y
		
		# Régions gauche et droite
		var region_left: Rect2 = Rect2(0, 0, half_w, full_h)
		var region_right: Rect2 = Rect2(half_w, 0, half_w, full_h)
		
		# Taille cible d'un arbre en jeu
		var target_h: float = rng.randf_range(68.0, 88.0)
		var base_scale: float = target_h / full_h
		
		if is_forest:
			# === VRAIE FORÊT : 8-16 arbres sur 3×3 tuiles ===
			var forest_size: int = rng.randi_range(8, 16)
			var placed: int = 0
			var attempts: int = 0
			
			while placed < forest_size and attempts < 50:
				attempts += 1
				var dx: int = rng.randi_range(-1, 1)
				var dy: int = rng.randi_range(-1, 1)
				var tx: int = center_x + dx
				var ty: int = center_y + dy
				var key: String = str(tx) + "," + str(ty)
				
				if occupied.has(key):
					continue
				occupied[key] = true
				
				var world_x: float = (tx * TILE_SIZE) + TILE_SIZE / 2
				var world_y: float = (ty * TILE_SIZE) + TILE_SIZE / 2
				
				var tree_node: Node2D = Node2D.new()
				tree_node.name = "Tree_F" + str(i) + "_" + str(placed)
				tree_node.position = Vector2(world_x, world_y)
				add_child(tree_node)
				
				# Choisir gauche ou droite aléatoirement
				var atlas: AtlasTexture = AtlasTexture.new()
				atlas.atlas = base_tex
				atlas.region = region_left if rng.randf() < 0.5 else region_right
				
				var tree_sprite: Sprite2D = Sprite2D.new()
				tree_sprite.texture = atlas
				var svar: float = rng.randf_range(0.82, 1.12)
				tree_sprite.scale = Vector2(base_scale * svar, base_scale * svar)
				
				# Position légèrement aléatoire dans la tuile
				var offset_x: float = rng.randf_range(-18.0, 18.0)
				var offset_y: float = rng.randf_range(-10.0, 8.0)
				tree_sprite.position = Vector2(offset_x, offset_y - target_h * 0.35)
				tree_sprite.set_z_index(int(offset_y))
				tree_node.add_child(tree_sprite)
				
				_create_elliptical_shadow(tree_node, 24, 8, 6, 0.22)
				_decorations.append(tree_node)
				placed += 1
			
			if placed >= 3:
				# Ombre de forêt plus grande sous le groupe
				var forest_shadow: Node2D = Node2D.new()
				forest_shadow.position = Vector2(center_x * TILE_SIZE + TILE_SIZE / 2, center_y * TILE_SIZE + TILE_SIZE / 2)
				add_child(forest_shadow)
				_create_elliptical_shadow(forest_shadow, 90, 32, 14, 0.12)
				_decorations.append(forest_shadow)
		
		elif is_group:
			# === PETIT GROUPE : 2-4 arbres sur 2×2 tuiles ===
			var group_size: int = rng.randi_range(2, 4)
			var placed: int = 0
			var attempts: int = 0
			
			while placed < group_size and attempts < 20:
				attempts += 1
				var dx: int = rng.randi_range(0, 1)
				var dy: int = rng.randi_range(0, 1)
				var tx: int = center_x + dx
				var ty: int = center_y + dy
				var key: String = str(tx) + "," + str(ty)
				
				if occupied.has(key):
					continue
				occupied[key] = true
				
				var world_x: float = (tx * TILE_SIZE) + TILE_SIZE / 2
				var world_y: float = (ty * TILE_SIZE) + TILE_SIZE / 2
				
				var tree_node: Node2D = Node2D.new()
				tree_node.name = "Tree_G" + str(i) + "_" + str(placed)
				tree_node.position = Vector2(world_x, world_y)
				add_child(tree_node)
				
				var atlas: AtlasTexture = AtlasTexture.new()
				atlas.atlas = base_tex
				atlas.region = region_left if rng.randf() < 0.5 else region_right
				
				var tree_sprite: Sprite2D = Sprite2D.new()
				tree_sprite.texture = atlas
				var svar: float = rng.randf_range(0.85, 1.15)
				tree_sprite.scale = Vector2(base_scale * svar, base_scale * svar)
				tree_sprite.position = Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-8.0, 4.0) - target_h * 0.35)
				tree_node.add_child(tree_sprite)
				
				_create_elliptical_shadow(tree_node, 26, 9, 7, 0.24)
				_decorations.append(tree_node)
				placed += 1
		
		else:
			# === ARBRE SOLITAIRE ===
			var key: String = str(center_x) + "," + str(center_y)
			if not occupied.has(key):
				occupied[key] = true
				
				var world_x: float = (center_x * TILE_SIZE) + TILE_SIZE / 2
				var world_y: float = (center_y * TILE_SIZE) + TILE_SIZE / 2
				
				var tree_node: Node2D = Node2D.new()
				tree_node.name = "Tree_S" + str(i)
				tree_node.position = Vector2(world_x, world_y)
				add_child(tree_node)
				
				var atlas: AtlasTexture = AtlasTexture.new()
				atlas.atlas = base_tex
				atlas.region = region_left if rng.randf() < 0.5 else region_right
				
				var tree_sprite: Sprite2D = Sprite2D.new()
				tree_sprite.texture = atlas
				var svar: float = rng.randf_range(0.88, 1.18)
				tree_sprite.scale = Vector2(base_scale * svar, base_scale * svar)
				tree_sprite.position = Vector2(0, -target_h * 0.35)
				tree_node.add_child(tree_sprite)
				
				_create_elliptical_shadow(tree_node, 28, 10, 8, 0.26)
				_decorations.append(tree_node)
	
	# Créer des rochers (dans la zone colorée 16×9)
	for i in range(ROCK_COUNT):
		var rock_x: int = rng.randi_range(1, _zone_w - 2)
		var rock_y: int = rng.randi_range(1, _zone_h - 2)
		var world_x: float = (rock_x * TILE_SIZE) + TILE_SIZE / 2
		var world_y: float = (rock_y * TILE_SIZE) + TILE_SIZE / 2
		var rock_pos: Vector2 = Vector2(world_x, world_y)
		
		# Créer le rocher
		var rock_node: Node2D = Node2D.new()
		rock_node.name = "Rock_" + str(i)
		rock_node.position = rock_pos
		add_child(rock_node)
		
		# Sprite procédural rocher
		var rock_sprite: Sprite2D = Sprite2D.new()
		rock_sprite.texture = _generate_sprite("rock", 96, rock_x * 1000 + rock_y)
		rock_sprite.position = Vector2(0, -24)
		rock_node.add_child(rock_sprite)

		# Ombre elliptique sous le rocher
		_create_elliptical_shadow(rock_node, 28, 10, 8, 0.30)
		
		_decorations.append(rock_node)
	
	# Créer des tours abandonnées (dans la zone colorée 16×9)
	for i in range(TOWER_COUNT):
		var tower_x: int = rng.randi_range(2, _zone_w - 3)
		var tower_y: int = rng.randi_range(2, _zone_h - 3)
		var world_x: float = (tower_x * TILE_SIZE) + TILE_SIZE / 2
		var world_y: float = (tower_y * TILE_SIZE) + TILE_SIZE / 2
		var tower_pos: Vector2 = Vector2(world_x, world_y)
		
		# Créer la tour
		var tower_node: Node2D = Node2D.new()
		tower_node.name = "Tower_" + str(i)
		tower_node.position = tower_pos
		add_child(tower_node)
		
		# Sprite procédural tour
		var tower_sprite: Sprite2D = Sprite2D.new()
		tower_sprite.texture = _generate_sprite("tower", 96, tower_x * 1000 + tower_y)
		tower_sprite.position = Vector2(0, -24)
		tower_node.add_child(tower_sprite)
		
		# Ombre elliptique sous la tour
		_create_elliptical_shadow(tower_node, 48, 14, 16, 0.35)
		
		_decorations.append(tower_node)
	
	print("✓ ", TREE_COUNT, " arbres, ", ROCK_COUNT, " rochers et ", TOWER_COUNT, " tours créés")

func _create_mountain_sprites() -> void:
	# Créer des sprites de montagnes sur les tuiles montagne (type 3)
	# Les montagnes débordent sur les tuiles voisines pour un effet imposant
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	# Collecter toutes les positions montagne
	var mountain_positions: Array[Vector2] = []
	for x in range(_zone_w):
		for y in range(_zone_h):
			if _terrain_grid[x][y] == 3:
				mountain_positions.append(Vector2(x, y))
	
	# Pour chaque zone de montagne, créer un sprite imposant
	for mpos in mountain_positions:
		var mx: int = int(mpos.x)
		var my: int = int(mpos.y)
		var world_x: float = (mx * TILE_SIZE) + TILE_SIZE / 2
		var world_y: float = (my * TILE_SIZE) + TILE_SIZE / 2
		
		var mountain_node: Node2D = Node2D.new()
		mountain_node.name = "Mountain_" + str(mx) + "_" + str(my)
		mountain_node.position = Vector2(world_x, world_y)
		mountain_node.set_z_index(2)  # Au-dessus du terrain
		add_child(mountain_node)
		
		# Générer sprite de montagne procédural
		var m_img: Image = Image.create(96, 80, false, Image.FORMAT_RGBA8)
		m_img.fill(Color(0, 0, 0, 0))  # Transparent
		
		# Base rocheuse (forme trapézoïdale)
		var base_w: int = 72
		var base_h: int = 24
		var peak_h: int = 44
		for py in range(base_h + peak_h):
			var y_ratio: float = float(py) / float(base_h + peak_h)
			var current_w: float = base_w * (1.0 - y_ratio * 0.6)  # Rétrécit vers le haut
			var center_x: int = 48
			var start_x: int = int(center_x - current_w / 2.0)
			var end_x: int = int(center_x + current_w / 2.0)
			for px in range(start_x, end_x):
				if px >= 0 and px < 96 and py >= 0 and py < 80:
					# Couleur avec variation
					var rock_col: Color = Color(0.50, 0.48, 0.44)
					if rng.randf() < 0.3:
						rock_col = Color(0.56, 0.54, 0.50)
					if rng.randf() < 0.15:
						rock_col = Color(0.44, 0.42, 0.38)
					# Plus clair en haut (neige)
					if y_ratio < 0.25 and rng.randf() < 0.6:
						rock_col = Color(0.78, 0.76, 0.74)
					m_img.set_pixel(px, py, rock_col)
		
		# Strates horizontales (bandes de roche)
		for sy in [20, 32, 44, 56]:
			for px in range(12, 84):
				if sy < 80 and m_img.get_pixel(px, sy).a > 0.1:
					var streak: Color = Color(0.40, 0.38, 0.34)
					if rng.randf() < 0.5:
						streak = Color(0.60, 0.58, 0.54)
					m_img.set_pixel(px, sy + rng.randi_range(-1, 1), streak)
		
		# Fissures verticales
		for _i in range(2):
			var fx: int = rng.randi_range(24, 72)
			for fy in range(rng.randi_range(10, 30)):
				if fy < 80 and m_img.get_pixel(fx, fy).a > 0.1:
					m_img.set_pixel(fx + rng.randi_range(-1, 1), fy, Color(0.28, 0.26, 0.22))
		
		# Créer la texture
		var m_tex: ImageTexture = ImageTexture.create_from_image(m_img)
		var m_sprite: Sprite2D = Sprite2D.new()
		m_sprite.texture = m_tex
		m_sprite.position = Vector2(0, -28)
		mountain_node.add_child(m_sprite)
		
		# Ombre sous la montagne
		_create_elliptical_shadow(mountain_node, 34, 10, 8, 0.30)
		
		_decorations.append(mountain_node)

func _create_bridges() -> void:
	# Détecter où les routes (type 1) croisent l'eau (type 2) et placer des ponts
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	for x in range(1, _zone_w - 1):
		for y in range(1, _zone_h - 1):
			if _terrain_grid[x][y] == 2:  # Eau
				# Vérifier si une route est de chaque côté (horizontal ou vertical)
				var has_left_road: bool = _terrain_grid[x - 1][y] == 1
				var has_right_road: bool = _terrain_grid[x + 1][y] == 1
				var has_top_road: bool = _terrain_grid[x][y - 1] == 1
				var has_bottom_road: bool = _terrain_grid[x][y + 1] == 1
				
				var world_x: float = (x * TILE_SIZE) + TILE_SIZE / 2
				var world_y: float = (y * TILE_SIZE) + TILE_SIZE / 2
				
				if has_left_road and has_right_road:
					# Pont horizontal
					var bridge_node: Node2D = Node2D.new()
					bridge_node.name = "Bridge_H_" + str(x) + "_" + str(y)
					bridge_node.position = Vector2(world_x, world_y)
					bridge_node.set_z_index(3)
					add_child(bridge_node)
					
					var b_img: Image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
					b_img.fill(Color(0, 0, 0, 0))
					
					# Planches de bois
					for by in range(20, 44):
						for bx in range(2, TILE_SIZE - 2):
							var plank: Color = Color(0.55, 0.40, 0.22)
							if (bx % 8) < 2:
								plank = Color(0.45, 0.32, 0.16)  # Joint
							b_img.set_pixel(bx, by, plank)
					
					# Garde-corps
					for bx in range(2, TILE_SIZE - 2):
						b_img.set_pixel(bx, 18, Color(0.35, 0.22, 0.12))
						b_img.set_pixel(bx, 46, Color(0.35, 0.22, 0.12))
					# Poteaux
					for bx in [6, 18, 30, 42, 54]:
						for py in range(14, 22):
							b_img.set_pixel(bx, py, Color(0.30, 0.18, 0.10))
						for py in range(42, 50):
							b_img.set_pixel(bx, py, Color(0.30, 0.18, 0.10))
					
					var b_tex: ImageTexture = ImageTexture.create_from_image(b_img)
					var b_sprite: Sprite2D = Sprite2D.new()
					b_sprite.texture = b_tex
					bridge_node.add_child(b_sprite)
					_decorations.append(bridge_node)
				
				elif has_top_road and has_bottom_road:
					# Pont vertical
					var bridge_node: Node2D = Node2D.new()
					bridge_node.name = "Bridge_V_" + str(x) + "_" + str(y)
					bridge_node.position = Vector2(world_x, world_y)
					bridge_node.set_z_index(3)
					add_child(bridge_node)
					
					var b_img: Image = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
					b_img.fill(Color(0, 0, 0, 0))
					
					# Planches de bois (rotation 90° = x et y inversés)
					for bx in range(20, 44):
						for by in range(2, TILE_SIZE - 2):
							var plank: Color = Color(0.55, 0.40, 0.22)
							if (by % 8) < 2:
								plank = Color(0.45, 0.32, 0.16)
							b_img.set_pixel(bx, by, plank)
					
					# Garde-corps verticaux
					for by in range(2, TILE_SIZE - 2):
						b_img.set_pixel(18, by, Color(0.35, 0.22, 0.12))
						b_img.set_pixel(46, by, Color(0.35, 0.22, 0.12))
					
					var b_tex: ImageTexture = ImageTexture.create_from_image(b_img)
					var b_sprite: Sprite2D = Sprite2D.new()
					b_sprite.texture = b_tex
					bridge_node.add_child(b_sprite)
					_decorations.append(bridge_node)
	
	# Créer les coffres au trésor
	_create_treasures()

func _create_treasures() -> void:
	# Créer des coffres au trésor contenant des récompenses
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(TREASURE_COUNT):
		var chest_x: int = rng.randi_range(1, _zone_w - 2)
		var chest_y: int = rng.randi_range(1, _zone_h - 2)
		var world_x: float = (chest_x * TILE_SIZE) + TILE_SIZE / 2
		var world_y: float = (chest_y * TILE_SIZE) + TILE_SIZE / 2
		var chest_pos: Vector2 = Vector2(world_x, world_y)
		
		# Données du coffre
		var chest_data: Dictionary = {
			"position": chest_pos,
			"opened": false,
			"gold_reward": rng.randi_range(20, 50),
			"xp_reward": rng.randi_range(15, 30)
		}
		_treasures.append(chest_data)
		
		# Créer le visuel du coffre
		var chest_node: Node2D = Node2D.new()
		chest_node.name = "Treasure_" + str(i)
		chest_node.position = chest_pos
		add_child(chest_node)
		
		# Sprite procédural coffre
		var chest_sprite: Sprite2D = Sprite2D.new()
		chest_sprite.texture = _generate_sprite("chest", 64, chest_x * 1000 + chest_y)
		chest_sprite.position = Vector2(0, -8)
		chest_node.add_child(chest_sprite)
		
		# Ombre elliptique sous le coffre
		_create_elliptical_shadow(chest_node, 36, 12, 8, 0.35)
		
		# Glow doré autour du coffre (effet de trésor)
		var chest_glow: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
		chest_glow.fill(Color(0, 0, 0, 0))
		for gx in range(48):
			for gy in range(48):
				var gnx: float = (gx - 24) / 22.0
				var gny: float = (gy - 24) / 22.0
				var gdist: float = sqrt(gnx * gnx + gny * gny)
				if gdist <= 1.0:
					var galpha: float = (1.0 - gdist) * 0.2
					chest_glow.set_pixel(gx, gy, Color(1.0, 0.85, 0.2, galpha))
		var chest_glow_sprite: Sprite2D = Sprite2D.new()
		chest_glow_sprite.name = "ChestGlow"
		chest_glow_sprite.texture = ImageTexture.create_from_image(chest_glow)
		chest_glow_sprite.position = Vector2(0, -8)
		chest_glow_sprite.set_z_index(-1)
		chest_node.add_child(chest_glow_sprite)
		
		_treasure_visuals.append(chest_node)
	
	print("✓ ", TREASURE_COUNT, " coffres au trésor créés")

func _create_hero() -> void:
	# Supprimer l'ancien héros s'il existe (éviter les doublons)
	if _hero != null:
		_hero.queue_free()
		_hero = null
	
	# Créer le héros comme un Node2D
	_hero = Node2D.new()
	_hero.name = "Hero"
	add_child(_hero)

	# Positionner le héros au centre de la zone colorée en haut à gauche
	var center_tile_x: int = _zone_w / 2
	var center_tile_y: int = _zone_h / 2
	var hero_world_x: float = (center_tile_x * TILE_SIZE) + TILE_SIZE / 2
	var hero_world_y: float = (center_tile_y * TILE_SIZE) + TILE_SIZE / 2
	_hero.position = Vector2(hero_world_x, hero_world_y)
	
	# === VISUEL DU HÉROS avec sprites LPC ===
	_create_hero_sprites()
	
func _create_hero_sprites() -> void:
	"""Crée le héros avec le sprite HoMM3 knight"""
	# Charger le sprite knight
	var knight_path: String = "res://assets/units/knight.png"
	var texture: Texture2D = load(knight_path) if ResourceLoader.exists(knight_path) else null
	
	if texture:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "KnightSprite"
		sprite.texture = texture
		sprite.scale = Vector2(2.0, 2.0)  # Agrandir si nécessaire
		sprite.position = Vector2(0, -16)  # Légèrement au-dessus du centre
		_hero.add_child(sprite)
		print("✓ Héros créé avec sprite HoMM3 knight")
	else:
		# Fallback : sprite héros procédural
		var fallback: Sprite2D = Sprite2D.new()
		fallback.texture = _generate_sprite("hero", 64, 42)
		fallback.position = Vector2(0, -16)
		_hero.add_child(fallback)
		print("⚠ Sprite knight non trouvé, fallback procédural")
	
	# === HALO LUMINEUX AUTOUR DU HÉROS ===
	var glow_texture: Image = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	glow_texture.fill(Color(0, 0, 0, 0))
	var glow_hw: int = 40
	var glow_hh: int = 40
	for gx in range(80):
		for gy in range(80):
			var gnx: float = (gx - glow_hw) / 38.0
			var gny: float = (gy - glow_hh) / 38.0
			var gdist: float = sqrt(gnx * gnx + gny * gny)
			if gdist <= 1.0:
				var galpha: float = (1.0 - gdist) * 0.25
				glow_texture.set_pixel(gx, gy, Color(1.0, 0.9, 0.5, galpha))
	var glow_sprite: Sprite2D = Sprite2D.new()
	glow_sprite.name = "HeroGlow"
	glow_sprite.texture = ImageTexture.create_from_image(glow_texture)
	glow_sprite.position = Vector2(0, -16)
	glow_sprite.set_z_index(-3)
	_hero.add_child(glow_sprite)
	
	# Anneau de sélection avec coins (amélioré)
	var selection_ring: ColorRect = ColorRect.new()
	selection_ring.name = "SelectionRing"
	selection_ring.size = Vector2(64, 64)
	selection_ring.position = Vector2(-32, -32)
	selection_ring.color = Color(1.0, 0.85, 0.3, 0.25)
	_hero.add_child(selection_ring)
	selection_ring.set_z_index(-2)
	
	# Coins dorés décoratifs
	for corner in range(4):
		var corner_marker: ColorRect = ColorRect.new()
		corner_marker.size = Vector2(6, 6)
		var cx: float = -32 if corner % 2 == 0 else 26
		var cy: float = -32 if corner < 2 else 26
		corner_marker.position = Vector2(cx, cy)
		corner_marker.color = Color(1.0, 0.75, 0.15)
		_hero.add_child(corner_marker)
		corner_marker.set_z_index(-1)
	
	# Créer la caméra centrée sur la zone colorée (centre de la map 60×40)
	var cam_x: float = (_zone_w / 2.0) * TILE_SIZE  # Centre de la zone 60×40
	var cam_y: float = (_zone_h / 2.0) * TILE_SIZE
	_camera = Camera2D.new()
	_camera.position = Vector2(cam_x, cam_y)
	_camera.enabled = true
	add_child(_camera)  # IMPORTANT: Ajouter la caméra à la scène !
	
	# Calculer le zoom exact pour que la zone 60×40 (toute la map) remplisse l'écran 1280×720
	var zone_width_pixels: float = _zone_w * TILE_SIZE   # 60 * 64 = 3840
	var zone_height_pixels: float = _zone_h * TILE_SIZE  # 40 * 64 = 2560
	
	var screen_width: float = 1280.0
	var screen_height: float = 720.0
	
	var zoom_x: float = screen_width / zone_width_pixels   # 1280 / 3840 = 0.333
	var zoom_y: float = screen_height / zone_height_pixels  # 720 / 2560 = 0.281
	var optimal_zoom: float = min(zoom_x, zoom_y)         # 0.28
	
	_camera.zoom = Vector2(optimal_zoom, optimal_zoom)
	
	print("Caméra centrée sur la zone colorée: ", _camera.position)
	print("Zone: ", _zone_w, "×", _zone_h, " tuiles (", zone_width_pixels, "×", zone_height_pixels, " pixels)")
	print("Écran: ", screen_width, "×", screen_height, " pixels")
	print("Zoom optimal appliqué: ", optimal_zoom)
	
	print("Héros créé avec visuel à la position : ", _hero.position)
	print("Caméra créée pour suivre le héros")
	
	# Créer l'indicateur de portée de déplacement
	_create_movement_indicator()

func _add_sprite_layer(parent: Node2D, texture_path: String, name: String) -> void:
	"""Ajoute une couche de sprite"""
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = name
	
	# Charger la texture
	var texture: Texture2D = load(texture_path) if ResourceLoader.exists(texture_path) else null
	
	if texture:
		sprite.texture = texture
		sprite.centered = false
		# Les sprites LPC sont des spritesheets 8x1 (8 frames horizontales)
		# Configurer pour n'afficher qu'une seule frame
		sprite.hframes = 8  # 8 frames horizontaux
		sprite.vframes = 1  # 1 frame vertical
		sprite.frame = 0    # Afficher la première frame
		parent.add_child(sprite)
	else:
		push_warning("Texture non trouvée: " + texture_path)

func _create_movement_indicator() -> void:
	# Créer un indicateur visuel montrant la portée de déplacement du héros
	_movement_indicator = Node2D.new()
	_movement_indicator.name = "MovementIndicator"
	add_child(_movement_indicator)
	
	# Créer une grille de tuiles colorées autour du héros (portée de 3 tuiles)
	var move_range: int = 3  # Portée de déplacement en tuiles
	
	for dx in range(-move_range, move_range + 1):
		for dy in range(-move_range, move_range + 1):
			# Distance de Manhattan (comme dans HoMM3)
			var distance: int = abs(dx) + abs(dy)
			if distance <= move_range and distance > 0:  # Exclure la position du héros
				var indicator: ColorRect = ColorRect.new()
				indicator.size = Vector2(TILE_SIZE - 8, TILE_SIZE - 8)
				
				# Couleur selon la distance
				var alpha: float = 0.3 - (distance * 0.08)  # Plus transparent avec la distance
				indicator.color = Color(0.2, 0.8, 0.4, alpha)  # Vert avec transparence
				
				# Position relative au héros (sera mis à jour dans _process)
				indicator.position = Vector2(
					dx * TILE_SIZE - (TILE_SIZE - 8) / 2,
					dy * TILE_SIZE - (TILE_SIZE - 8) / 2
				)
				
				_movement_indicator.add_child(indicator)
	
	_movement_indicator.position = _hero.position
	print("✓ Indicateur de portée créé (", move_range, " tuiles)")

func _input(event: InputEvent) -> void:
	# Déplacer le héros avec les clics de souris (système HoMM avec MP)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _hero_mp <= 0:
			print("⛔ Plus de Points de Mouvement ! Finissez le tour.")
			_create_floating_text("Pas de MP !", Color(0.9, 0.2, 0.2), _hero.position)
			return
		
		var mouse_pos: Vector2 = get_global_mouse_position()
		var tile_x: int = int(mouse_pos.x / TILE_SIZE)
		var tile_y: int = int(mouse_pos.y / TILE_SIZE)
		tile_x = clamp(tile_x, 0, _zone_w - 1)
		tile_y = clamp(tile_y, 0, _zone_h - 1)
		
		# Position actuelle du héros en tuiles
		var current_tile_x: int = int(_hero.position.x / TILE_SIZE)
		var current_tile_y: int = int(_hero.position.y / TILE_SIZE)
		
		# Vérifier que le déplacement est adjacent (1 tuile max, pas de téléportation)
		var dx: int = abs(tile_x - current_tile_x)
		var dy: int = abs(tile_y - current_tile_y)
		if dx > 1 or dy > 1:
			print("⛔ Déplacement trop loin ! Déplacez-vous d'une tuile à la fois.")
			return
		
		# Vérifier le type de terrain et le coût
		var target_terrain: int = _terrain_grid[tile_x][tile_y]
		var move_cost: int = _terrain_move_cost.get(target_terrain, 1)
		
		if move_cost >= 999:
			print("⛔ Impossible de marcher sur l'eau !")
			return
		
		if _hero_mp < move_cost:
			print("⛔ Pas assez de MP ! Coût: ", move_cost, " | MP restants: ", _hero_mp)
			_create_floating_text("MP insuffisants !", Color(0.9, 0.2, 0.2), _hero.position)
			return
		
		# Payer le coût de déplacement
		_hero_mp -= move_cost
		print("🚶 Déplacement: -", move_cost, " MP | MP restants: ", _hero_mp, "/", _hero_max_mp)
		
		# Déplacer le héros
		var grid_pos: Vector2 = Vector2(
			tile_x * TILE_SIZE + TILE_SIZE / 2,
			tile_y * TILE_SIZE + TILE_SIZE / 2
		)
		_hero.position = grid_pos
		_camera.position = grid_pos
		
		if _movement_indicator:
			_movement_indicator.position = grid_pos
		
		# Mettre à jour le brouillard de guerre
		_update_fog_of_war()
		
		# Vérifier les interactions
		_update_minimap()
		_check_city_visit()
		_check_enemy_encounter()
		_check_resource_collection()
		
		# Mettre à jour l'affichage des MP
		if _label_mp != null:
			_label_mp.text = str(_hero_mp) + "/" + str(_hero_max_mp)
	
	# Zoom avec la molette
	if _camera != null and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var new_zoom: float = _camera.zoom.x + ZOOM_STEP
			new_zoom = clamp(new_zoom, ZOOM_MIN, ZOOM_MAX)
			_camera.zoom = Vector2(new_zoom, new_zoom)
			print("🔍 Zoom IN: ", new_zoom)
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var new_zoom: float = _camera.zoom.x - ZOOM_STEP
			new_zoom = clamp(new_zoom, ZOOM_MIN, ZOOM_MAX)
			_camera.zoom = Vector2(new_zoom, new_zoom)
			print("🔍 Zoom OUT: ", new_zoom)
	
	# Raccourcis clavier HoMM
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_T:
				# Fin de tour rapide
				_end_turn()
				print("🔄 Fin de tour (touche T)")
			KEY_C:
				# Construire dans la ville sélectionnée
				if _town_screen_open and _selected_city_index >= 0:
					print("=== CONSTRUCTION ===")
					print("Tapez le numéro du bâtiment à construire:")
					var idx: int = 1
					for b_key in CITY_BUILDINGS:
						var b_data: Dictionary = CITY_BUILDINGS[b_key]
						print("  ", idx, ": ", b_data["name"], " (", b_data["cost_g"], "🪙, ", b_data["cost_w"], "🪵, ", b_data["cost_o"], "💎)")
						idx += 1
				print("  0: Annuler")
			KEY_R:
				# Recruter dans la ville sélectionnée
				if _town_screen_open and _selected_city_index >= 0:
					print("=== RECRUTEMENT ===")
					print("Tapez le numéro de l'unité à recruter:")
					var idx: int = 1
					for u_key in UNIT_TYPES:
						var u_data: Dictionary = UNIT_TYPES[u_key]
						print("  ", idx, ": ", u_data["name"], " (", u_data["cost_g"], "🪙)")
						idx += 1
				print("  0: Annuler")
			KEY_Q:
				# Quitter l'écran de ville
				if _town_screen_open:
					_town_screen_open = false
					_selected_city_index = -1
					print("=== FERMÉ ===")
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0:
				# Construction ou recrutement par numéro
				if _town_screen_open and _selected_city_index >= 0:
					var num: int = event.keycode - KEY_1 + 1
					if event.keycode == KEY_0:
						num = 0
					print("Sélection: ", num)

func _process(delta: float) -> void:
	var time: float = Time.get_time_dict_from_system()["second"]
	var pulse: float = (sin(Time.get_time_dict_from_system()["second"] * 3.0) + 1.0) / 2.0
	
	# Animation du halo du héros (pulsation douce)
	if _hero != null:
		var hero_glow: Sprite2D = _hero.get_node_or_null("HeroGlow")
		if hero_glow != null:
			hero_glow.modulate.a = 0.6 + pulse * 0.4
			hero_glow.scale = Vector2(1.0 + pulse * 0.1, 1.0 + pulse * 0.1)
	
	# Animation du glow des coffres (scintillement doré)
	for chest_node in _treasure_visuals:
		if chest_node.visible:
			var chest_glow: Sprite2D = chest_node.get_node_or_null("ChestGlow")
			if chest_glow != null:
				var chest_pulse: float = (sin(time * 4.0 + chest_node.position.x * 0.1) + 1.0) / 2.0
				chest_glow.modulate.a = 0.5 + chest_pulse * 0.5
	
	# Animation de la fumée des châteaux
	var elapsed: float = Time.get_time_dict_from_system()["second"]
	for smoke_data in _smoke_particles:
		var smoke: Sprite2D = smoke_data["sprite"]
		var s_offset: float = smoke_data["offset"]
		var s_speed: float = smoke_data["speed"]
		var cycle: float = fmod(elapsed + s_offset, s_speed) / s_speed
		# Monter
		smoke.position.y = smoke_data["base_pos"].y - cycle * 20
		# Dériver légèrement
		smoke.position.x = smoke_data["base_pos"].x + sin(cycle * 6.28) * 3
		# Grossir et s'estomper
		var s_scale: float = 1.0 + cycle * 1.5
		smoke.scale = Vector2(s_scale, s_scale)
		smoke.modulate.a = 1.0 - cycle
	
	# Mettre à jour la position de l'indicateur de mouvement pour qu'il suive le héros
	if _movement_indicator != null and _hero != null:
		_movement_indicator.position = _hero.position

# ============================================================
# SYSTÈME HOMM : BROUILLARD DE GUERRE
# ============================================================
func _init_fog_of_war() -> void:
	"""Initialise la grille de brouillard de guerre"""
	_fog_grid = []
	for x in range(_zone_w):
		_fog_grid.append([])
		for y in range(_zone_h):
			_fog_grid[x].append(0)  # 0 = inconnu (noir)
	print("✓ Brouillard de guerre initialisé: ", _zone_w, "x", _zone_h)

func _update_fog_of_war() -> void:
	"""Met à jour le brouillard de guerre autour du héros"""
	if _fog_grid.is_empty() or _hero == null:
		return
	
	var hero_tx: int = int(_hero.position.x / TILE_SIZE)
	var hero_ty: int = int(_hero.position.y / TILE_SIZE)
	
	# Marquer toutes les tuiles comme "découvertes" (1) si elles étaient inconnues (0)
	# et "visibles" (2) dans la portée de vision
	for x in range(_zone_w):
		for y in range(_zone_h):
			var dist: int = abs(x - hero_tx) + abs(y - hero_ty)
			if dist <= FOG_VISION_RANGE:
				if _fog_grid[x][y] == 0:
					_fog_grid[x][y] = 1  # Découvert
				_fog_grid[x][y] = 2  # Visible
			elif _fog_grid[x][y] == 2:
				_fog_grid[x][y] = 1  # Retombe à "découvert" si hors de portée
	
	# TODO: Masquer les objets dans le brouillard
	# Pour l'instant, le brouillard est logique (mémorisation du terrain)

# ============================================================
# SYSTÈME HOMM : ARMÉES ENNEMIES
# ============================================================
func _init_enemy_armies() -> void:
	"""Initialise les armées des ennemis avec composition variée"""
	_enemy_armies = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(_enemies.size()):
		var army: Array = []
		var army_size: int = rng.randi_range(1, 3)
		
		for _j in range(army_size):
			var unit_types: Array = ["pikeman", "archer", "griffin", "swordsman"]
			var unit_type: String = unit_types[rng.randi_range(0, unit_types.size() - 1)]
			var unit_data: Dictionary = UNIT_TYPES[unit_type]
			var count: int = rng.randi_range(3, 15)
			
			army.append({
				"type": unit_type,
				"count": count,
				"hp": unit_data["hp"],
				"max_hp": unit_data["hp"],
				"attack": unit_data["attack"],
				"defense": unit_data["defense"]
			})
		
		_enemy_armies.append(army)
	
	print("✓ ", _enemy_armies.size(), " armées ennemies initialisées")

# ============================================================
# SYSTÈME HOMM : FIN DE TOUR
# ============================================================
func _create_end_turn_button() -> void:
	"""Crée le bouton 'Fin de Tour' dans le panneau latéral"""
	var canvas_layer: CanvasLayer = get_node_or_null("UI")
	if canvas_layer == null:
		return
	
	var side_panel: Panel = canvas_layer.get_node_or_null("SidePanel")
	if side_panel == null:
		return
	
	_end_turn_button = Button.new()
	_end_turn_button.name = "EndTurnButton"
	_end_turn_button.text = "FIN DE TOUR"
	_end_turn_button.size = Vector2(180, 40)
	_end_turn_button.position = Vector2(20, 580)
	
	# Style HoMM3
	var button_style: StyleBoxFlat = StyleBoxFlat.new()
	button_style.bg_color = Color(0.25, 0.15, 0.05)
	button_style.border_color = Color(0.72, 0.52, 0.25)
	button_style.border_width_left = 3
	button_style.border_width_right = 3
	button_style.border_width_top = 3
	button_style.border_width_bottom = 3
	_end_turn_button.add_theme_stylebox_override("normal", button_style)
	_end_turn_button.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	_end_turn_button.add_theme_font_size_override("font_size", 16)
	
	_end_turn_button.pressed.connect(_end_turn)
	side_panel.add_child(_end_turn_button)
	
	# Label MP
	_label_mp = Label.new()
	_label_mp.name = "MPLabel"
	_label_mp.text = str(_hero_mp) + "/" + str(_hero_max_mp)
	_label_mp.position = Vector2(20, 545)
	_label_mp.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
	_label_mp.add_theme_font_size_override("font_size", 18)
	side_panel.add_child(_label_mp)
	
	print("✓ Bouton 'Fin de Tour' et MP créés")

func _end_turn() -> void:
	"""Gère la fin de tour (HoMM style)"""
	print("=== FIN DE TOUR ===")
	
	# 1. Restaurer les MP
	_hero_mp = _hero_max_mp
	print("🚶 MP restaurés: ", _hero_mp, "/", _hero_max_mp)
	
	# 2. Incrémenter le temps
	_game_day += 1
	if _game_day > 7:
		_game_day = 1
		_game_week += 1
		print("📅 Nouvelle semaine ! Semaine ", _game_week)
		
		# Événement de semaine
		if _game_week > 4:
			_game_week = 1
			_game_month += 1
			print("📅 Nouveau mois ! Mois ", _game_month)
	
	# 3. Revenus des villes possédées
	var city_income: int = 0
	for city_data in _cities_data:
		if city_data.get("owned", false):
			city_income += city_data.get("income", 500)
			# Bonus du silo
			if "resource_silo" in city_data["buildings"]:
				_wood += 1
				_ore += 1
	
	if city_income > 0:
		_gold += city_income
		print("💰 Revenus des villes: +", city_income, " Or")
		_create_floating_text("+" + str(city_income) + " 🪙/jour", Color(1.0, 0.85, 0.2), _hero.position)
	
	# 4. Mettre à jour l'interface
	if _label_date:
		_label_date.text = "Month %d  Week %d  Day %d" % [_game_month, _game_week, _game_day]
	if _label_mp != null:
		_label_mp.text = str(_hero_mp) + "/" + str(_hero_max_mp)
	if _label_gold:
		_label_gold.text = str(_gold)
	if _label_wood:
		_label_wood.text = str(_wood)
	if _label_ore:
		_label_ore.text = str(_ore)
	
	print("Date : Month ", _game_month, ", Week ", _game_week, ", Day ", _game_day)
	print("=== NOUVEAU TOUR ===")

func _check_resource_collection() -> void:
	# Vérifier si le héros est proche d'une ressource
	for i in range(_resources.size()):
		var res_data: Dictionary = _resources[i]
		
		# Ignorer les ressources déjà collectées
		if res_data["collected"]:
			continue
		
		var res_pos: Vector2 = res_data["position"]
		var distance: float = _hero.position.distance_to(res_pos)
		
		# Si le héros est assez proche (moins d'une tuile), il collecte la ressource
		if distance < TILE_SIZE:
			var res_type: String = res_data["type"]
			var res_name: String = res_data["name"]
			
			print("⛏️ Ressource collectée : ", res_name, " !")
			
			# Bonus selon le type + textes flottants
			match res_type:
				"gold":
					_gold += 30
					print("   🪙 +30 Or !")
					_create_floating_text("+30 🪙", Color(1.0, 0.85, 0.2), _hero.position)
				"wood":
					_wood += 20
					print("   🪵 +20 Bois !")
					_create_floating_text("+20 🪵", Color(0.6, 0.9, 0.4), _hero.position)
				"ore":
					_ore += 15
					print("   💎 +15 Minerai !")
					_create_floating_text("+15 💎", Color(0.75, 0.75, 0.85), _hero.position)
			
			# Mettre à jour l'interface
			if _label_gold:
				_label_gold.text = str(_gold)
			if _label_wood:
				_label_wood.text = str(_wood)
			if _label_ore:
				_label_ore.text = str(_ore)
			
			# Marquer comme collectée
			res_data["collected"] = true
			
			# Cacher le visuel de la ressource
			if i < _resource_visuals.size():
				_resource_visuals[i].visible = false
			
			# Gain d'expérience
			print("   ⭐ +", XP_COLLECT_RESOURCE, " XP !")
			_gain_xp(XP_COLLECT_RESOURCE)
			
			break  # Ne collecter qu'une ressource à la fois

func _check_enemy_encounter() -> void:
	# Vérifier si le héros est proche d'un ennemi
	for i in range(_enemies.size()):
		var enemy_data: Dictionary = _enemies[i]
		
		# Ignorer les ennemis morts
		if not enemy_data["alive"]:
			continue
		
		var enemy_pos: Vector2 = enemy_data["position"]
		var distance: float = _hero.position.distance_to(enemy_pos)
		
		# Si le héros est assez proche (moins d'une tuile), combat !
		if distance < TILE_SIZE:
			_start_combat(i)
			break

func _start_combat(enemy_index: int) -> void:
	if _in_combat:
		return
	
	_in_combat = true
	_current_enemy_index = enemy_index
	var enemy_army: Array = _enemy_armies[enemy_index] if enemy_index < _enemy_armies.size() else []
	
	print("⚔️ COMBAT HOMM3 !")
	print("   Votre armée vs Armée ennemie ", enemy_index + 1)
	
	# Lancer le Combat Manager
	if _combat_manager:
		_combat_manager.start_combat(_hero_army, enemy_army, enemy_index)
	else:
		_in_combat = false
		print("ERREUR: Combat Manager non initialisé !")

func _count_total_units(army: Array) -> int:
	var total: int = 0
	for unit in army:
		total += unit["count"]
	return total

func _find_alive_unit(army: Array):
	for unit in army:
		if unit["count"] > 0:
			return unit
	return null

func _print_army_status(name: String, army: Array) -> void:
	print("   ", name, " armée:")
	for unit in army:
		if unit["count"] > 0:
			print("      ", unit["count"], " ", UNIT_TYPES[unit["type"]]["name"])

func _on_combat_victory(gold_reward: int, xp_reward: int) -> void:
	print("🎉 VICTOIRE ! +", gold_reward, " Or, +", xp_reward, " XP")
	
	var enemy_data: Dictionary = _enemies[_current_enemy_index]
	enemy_data["alive"] = false
	
	_create_floating_text("☠️ VAINCU!", Color(0.9, 0.1, 0.1), enemy_data["position"] - Vector2(0, 30))
	_create_floating_text("+" + str(gold_reward) + " 🪙", Color(1.0, 0.85, 0.2), _hero.position - Vector2(0, 40))
	
	_gold += gold_reward
	if _label_gold:
		_label_gold.text = str(_gold)
	
	_gain_xp(xp_reward)
	
	if _current_enemy_index < _enemy_visuals.size():
		_enemy_visuals[_current_enemy_index].visible = false
	
	_in_combat = false

func _on_combat_defeat() -> void:
	print("💀 DÉFAITE ! Votre armée a été anéantie...")
	_hero_hp = 0
	_in_combat = false
	# TODO: Écran de Game Over

func _on_combat_fled() -> void:
	print("🏃 Vous avez fui le combat !")
	_in_combat = false

func _victory_combat(enemy_index: int, enemy_data: Dictionary) -> void:
	# OBSOLETE - remplacé par _on_combat_victory
	pass

func _combat_round(enemy_index: int) -> void:
	# OBSOLETE - remplacé par le CombatManager
	pass

func _check_city_visit() -> void:
	# Vérifier si le héros est proche d'une ville
	for i in range(_cities.size()):
		var city_pos: Vector2 = _cities[i]
		var distance: float = _hero.position.distance_to(city_pos)
		
		if distance < TILE_SIZE:
			print("🏛️ Bienvenue à la Ville ", i + 1, " !")
			_selected_city_index = i
			_open_town_screen(i)
			break

func _open_town_screen(city_index: int) -> void:
	"""Ouvre l'écran de ville HoMM avec construction et recrutement"""
	if _town_screen_open:
		return
	
	_town_screen_open = true
	var city_data: Dictionary = _cities_data[city_index]
	var city_name: String = "Ville " + str(city_index + 1)
	
	print("=== ÉCRAN DE VILLE: ", city_name, " ===")
	print("   Bâtiments construits: ", city_data["buildings"])
	print("   Or: ", _gold, " | Bois: ", _wood, " | Minerai: ", _ore)
	print("   Tapez 'c' pour construire, 'r' pour recruter, 'q' pour quitter")
	
	# Afficher les options disponibles
	print("   Bâtiments disponibles:")
	for b_key in CITY_BUILDINGS:
		var b_data: Dictionary = CITY_BUILDINGS[b_key]
		var built: String = " [CONSTRUIT]" if b_key in city_data["buildings"] else ""
		print("     ", b_data["name"], " - ", b_data["desc"], " (", b_data["cost_g"], "🪙, ", b_data["cost_w"], "🪵, ", b_data["cost_o"], "💎)", built)
	
	print("   Unités disponibles:")
	for u_key in UNIT_TYPES:
		var u_data: Dictionary = UNIT_TYPES[u_key]
		print("     ", u_data["name"], " - ", u_data["hp"], "HP, ", u_data["attack"], "ATK, ", u_data["defense"], "DEF (", u_data["cost_g"], "🪙)")

func _build_city_building(city_index: int, building_key: String) -> void:
	"""Construit un bâtiment dans une ville"""
	var city_data: Dictionary = _cities_data[city_index]
	
	if building_key in city_data["buildings"]:
		print("⛔ Déjà construit !")
		return
	
	var b_data: Dictionary = CITY_BUILDINGS[building_key]
	
	# Vérifier les ressources
	if _gold < b_data["cost_g"] or _wood < b_data["cost_w"] or _ore < b_data["cost_o"]:
		print("⛔ Ressources insuffantes !")
		print("   Besoin: ", b_data["cost_g"], "🪙, ", b_data["cost_w"], "🪵, ", b_data["cost_o"], "💎")
		print("   Vous avez: ", _gold, "🪙, ", _wood, "🪵, ", _ore, "💎")
		return
	
	# Payer
	_gold -= b_data["cost_g"]
	_wood -= b_data["cost_w"]
	_ore -= b_data["cost_o"]
	city_data["buildings"].append(building_key)
	
	# Effets spéciaux
	if building_key == "town_hall":
		city_data["income"] += 500
	
	print("✅ ", b_data["name"], " construit !")
	_create_floating_text("+" + b_data["name"], Color(0.5, 0.9, 0.5), _cities[city_index])
	
	# Mettre à jour l'UI
	if _label_gold:
		_label_gold.text = str(_gold)
	if _label_wood:
		_label_wood.text = str(_wood)
	if _label_ore:
		_label_ore.text = str(_ore)

func _recruit_unit(city_index: int, unit_type: String, count: int) -> void:
	"""Recrute des unités dans une ville"""
	var city_data: Dictionary = _cities_data[city_index]
	var unit_data: Dictionary = UNIT_TYPES[unit_type]
	var total_cost: int = unit_data["cost_g"] * count
	
	if _gold < total_cost:
		print("⛔ Pas assez d'or ! Besoin: ", total_cost, "🪙")
		return
	
	# Vérifier si le bâtiment nécessaire existe
	var required_building: String = ""
	match unit_type:
		"pikeman": required_building = "barracks"
		"archer": required_building = "archery_range"
		"griffin": required_building = "griffin_tower"
		"swordsman": required_building = "training_ground"
		"cavalier": required_building = "stables"
		"angel": required_building = "angel_statue"
	
	if required_building != "" and not required_building in city_data["buildings"]:
		print("⛔ Bâtiment requis: ", CITY_BUILDINGS[required_building]["name"])
		return
	
	# Payer et recruter
	_gold -= total_cost
	
	# Ajouter à l'armée du héros ou à la garnison
	var found: bool = false
	for unit in _hero_army:
		if unit["type"] == unit_type:
			unit["count"] += count
			found = true
			break
	
	if not found:
		_hero_army.append({
			"type": unit_type,
			"count": count,
			"hp": unit_data["hp"],
			"attack": unit_data["attack"],
			"defense": unit_data["defense"]
		})
	
	print("✅ ", count, " ", unit_data["name"], " recrutés !")
	_create_floating_text("+" + str(count) + " " + unit_data["name"], Color(0.5, 0.7, 1.0), _hero.position)
	
	# Mettre à jour l'UI
	if _label_gold:
		_label_gold.text = str(_gold)
	if _label_wood:
		_label_wood.text = str(_wood)
	if _label_ore:
		_label_ore.text = str(_ore)

func _create_ui() -> void:
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.name = "UI"
	add_child(canvas_layer)

	# === CADRE DÉCORATIF AUTOUR DE LA ZONE DE CARTE ===
	var frame_layer: CanvasLayer = CanvasLayer.new()
	frame_layer.name = "FrameLayer"
	frame_layer.layer = 5
	add_child(frame_layer)

	# Bordure haute
	var top_bar: ColorRect = ColorRect.new()
	top_bar.size = Vector2(1060, 6)
	top_bar.color = Color(0.72, 0.52, 0.25)
	frame_layer.add_child(top_bar)

	# Bordure basse (séparation avec barre ressources)
	var bot_bar: ColorRect = ColorRect.new()
	bot_bar.size = Vector2(1060, 4)
	bot_bar.position = Vector2(0, 671)
	bot_bar.color = Color(0.72, 0.52, 0.25)
	frame_layer.add_child(bot_bar)

	# Bordure gauche
	var left_bar: ColorRect = ColorRect.new()
	left_bar.size = Vector2(4, 675)
	left_bar.color = Color(0.72, 0.52, 0.25)
	frame_layer.add_child(left_bar)

	# Bordure droite (séparation avec panneau latéral)
	var right_bar: ColorRect = ColorRect.new()
	right_bar.size = Vector2(4, 675)
	right_bar.position = Vector2(1056, 0)
	right_bar.color = Color(0.72, 0.52, 0.25)
	frame_layer.add_child(right_bar)

	# Coins dorés (carrés 8x8 aux 4 coins)
	for corner in range(4):
		var c: ColorRect = ColorRect.new()
		c.size = Vector2(8, 8)
		var cx: float = 0 if corner % 2 == 0 else 1052
		var cy: float = 0 if corner < 2 else 667
		c.position = Vector2(cx, cy)
		c.color = Color(0.9, 0.7, 0.25)
		frame_layer.add_child(c)

	# === PANNEAU DROIT (220 x 720) — style barre latérale HoMM3 ===
	var side_panel: Panel = Panel.new()
	side_panel.name = "SidePanel"
	side_panel.size = Vector2(220, 720)
	side_panel.position = Vector2(1060, 0)
	var side_style: StyleBoxFlat = StyleBoxFlat.new()
	side_style.bg_color = Color(0.10, 0.07, 0.03)
	side_style.border_color = Color(0.72, 0.52, 0.25)
	side_style.border_width_left = 4
	side_style.border_width_right = 4
	side_style.border_width_top = 4
	side_style.border_width_bottom = 4
	side_panel.add_theme_stylebox_override("panel", side_style)
	canvas_layer.add_child(side_panel)

	# --- MINIMAP (intégrée dans le panneau droit, tout en haut) ---
	_create_minimap(side_panel)

	# --- PORTRAIT + STATS HÉROS (sous la minimap) ---
	var hero_block: Control = Control.new()
	hero_block.name = "HeroBlock"
	hero_block.position = Vector2(10, 220)
	hero_block.size = Vector2(200, 180)
	side_panel.add_child(hero_block)

	# Portrait (style cadre doré HoMM3)
	var portrait_bg: Panel = _create_decorated_panel(Vector2(70, 70))
	portrait_bg.position = Vector2(0, 0)
	hero_block.add_child(portrait_bg)
	var portrait_rect: ColorRect = ColorRect.new()
	portrait_rect.size = Vector2(60, 60)
	portrait_rect.position = Vector2(5, 5)
	portrait_rect.color = Color(0.18, 0.30, 0.50)
	portrait_bg.add_child(portrait_rect)

	# Visage (peau)
	var face: ColorRect = ColorRect.new()
	face.size = Vector2(28, 24)
	face.position = Vector2(16, 16)
	face.color = Color(0.85, 0.70, 0.55)
	portrait_rect.add_child(face)

	# Barbe
	var beard: ColorRect = ColorRect.new()
	beard.size = Vector2(20, 10)
	beard.position = Vector2(20, 28)
	beard.color = Color(0.45, 0.30, 0.15)
	portrait_rect.add_child(beard)

	# Casque haut
	var helmet_top: ColorRect = ColorRect.new()
	helmet_top.size = Vector2(32, 14)
	helmet_top.position = Vector2(14, 6)
	helmet_top.color = Color(0.50, 0.55, 0.65)
	portrait_rect.add_child(helmet_top)

	# Casque front
	var helmet_front: ColorRect = ColorRect.new()
	helmet_front.size = Vector2(32, 6)
	helmet_front.position = Vector2(14, 14)
	helmet_front.color = Color(0.40, 0.45, 0.55)
	portrait_rect.add_child(helmet_front)

	# Plume rouge sur le casque
	var plume: ColorRect = ColorRect.new()
	plume.size = Vector2(4, 16)
	plume.position = Vector2(28, 2)
	plume.color = Color(0.8, 0.15, 0.1)
	portrait_rect.add_child(plume)

	# Stats à droite du portrait
	var stats_vbox: VBoxContainer = VBoxContainer.new()
	stats_vbox.position = Vector2(80, 5)
	stats_vbox.size = Vector2(110, 160)
	stats_vbox.add_theme_constant_override("separation", 4)
	hero_block.add_child(stats_vbox)

	# --- NOM DU HÉROS ---
	_label_hero_name = Label.new()
	_label_hero_name.text = "Votre Héros"
	_label_hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_hero_name.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	_label_hero_name.add_theme_font_size_override("font_size", 14)
	stats_vbox.add_child(_label_hero_name)

	# --- BARRE DE NIVEAU ---
	_label_level = Label.new()
	_label_level.text = "Niveau %d" % _hero_level
	_label_level.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
	_label_level.add_theme_font_size_override("font_size", 13)
	stats_vbox.add_child(_label_level)

	# Barre XP
	var xp_panel = Panel.new()
	xp_panel.custom_minimum_size = Vector2(170, 22)
	var xp_style = StyleBoxFlat.new()
	xp_style.bg_color = Color(0.08, 0.06, 0.04)
	xp_style.corner_radius_top_left = 8
	xp_style.corner_radius_top_right = 8
	xp_style.corner_radius_bottom_left = 8
	xp_style.corner_radius_bottom_right = 8
	xp_panel.add_theme_stylebox_override("panel", xp_style)
	stats_vbox.add_child(xp_panel)

	_xp_bar_bg = ColorRect.new()
	_xp_bar_bg.position = Vector2(4, 4)
	_xp_bar_bg.size = Vector2(162, 14)
	_xp_bar_bg.color = Color(0.15, 0.12, 0.08)
	xp_panel.add_child(_xp_bar_bg)

	_xp_bar_fill = ColorRect.new()
	_xp_bar_fill.position = Vector2(4, 4)
	_xp_bar_fill.size = Vector2(162 * float(_hero_xp) / _hero_xp_to_next, 14)
	_xp_bar_fill.color = Color(0.85, 0.65, 0.15)
	xp_panel.add_child(_xp_bar_fill)

	_label_xp = Label.new()
	_label_xp.position = Vector2(0, -2)
	_label_xp.size = Vector2(170, 22)
	_label_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_xp.text = "%d / %d XP" % [_hero_xp, _hero_xp_to_next]
	_label_xp.add_theme_font_size_override("font_size", 10)
	_label_xp.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	xp_panel.add_child(_label_xp)

	# --- BARRE DE HP ---
	var hp_panel = Panel.new()
	hp_panel.custom_minimum_size = Vector2(170, 22)
	var hp_style = StyleBoxFlat.new()
	hp_style.bg_color = Color(0.08, 0.06, 0.04)
	hp_style.corner_radius_top_left = 8
	hp_style.corner_radius_top_right = 8
	hp_style.corner_radius_bottom_left = 8
	hp_style.corner_radius_bottom_right = 8
	hp_panel.add_theme_stylebox_override("panel", hp_style)
	stats_vbox.add_child(hp_panel)

	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.position = Vector2(4, 4)
	_hp_bar_bg.size = Vector2(162, 14)
	_hp_bar_bg.color = Color(0.15, 0.08, 0.08)
	hp_panel.add_child(_hp_bar_bg)

	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.position = Vector2(4, 4)
	var hp_ratio = float(_hero_hp) / _hero_max_hp if _hero_max_hp > 0 else 0
	_hp_bar_fill.size = Vector2(162 * hp_ratio, 14)
	if hp_ratio > 0.5:
		_hp_bar_fill.color = Color(0.2, 0.7, 0.25)
	elif hp_ratio > 0.25:
		_hp_bar_fill.color = Color(0.85, 0.55, 0.1)
	else:
		_hp_bar_fill.color = Color(0.8, 0.15, 0.15)
	hp_panel.add_child(_hp_bar_fill)

	_label_hp = Label.new()
	_label_hp.position = Vector2(0, -2)
	_label_hp.size = Vector2(170, 22)
	_label_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_hp.text = "HP %d / %d" % [_hero_hp, _hero_max_hp]
	_label_hp.add_theme_font_size_override("font_size", 10)
	_label_hp.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	hp_panel.add_child(_label_hp)

	# --- ATK / DEF ---
	var atk_def_label: Label = Label.new()
	atk_def_label.text = "ATK %d   DEF %d" % [_hero_attack, _hero_defense]
	atk_def_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	atk_def_label.add_theme_font_size_override("font_size", 12)
	atk_def_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_vbox.add_child(atk_def_label)

	# --- RESSOURCES ---
	var res_title: Label = Label.new()
	res_title.text = "Ressources"
	res_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res_title.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	res_title.add_theme_font_size_override("font_size", 12)
	stats_vbox.add_child(res_title)

	# Or
	var gold_row = HBoxContainer.new()
	gold_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var gold_icon = ColorRect.new()
	gold_icon.custom_minimum_size = Vector2(10, 10)
	gold_icon.color = Color(0.95, 0.8, 0.15)
	gold_row.add_child(gold_icon)
	_resource_gold_label = Label.new()
	_resource_gold_label.text = " %d" % _gold
	_resource_gold_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	_resource_gold_label.add_theme_font_size_override("font_size", 12)
	gold_row.add_child(_resource_gold_label)
	stats_vbox.add_child(gold_row)

	# Bois
	var wood_row = HBoxContainer.new()
	wood_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var wood_icon = ColorRect.new()
	wood_icon.custom_minimum_size = Vector2(10, 10)
	wood_icon.color = Color(0.55, 0.35, 0.15)
	wood_row.add_child(wood_icon)
	_resource_wood_label = Label.new()
	_resource_wood_label.text = " %d" % _wood
	_resource_wood_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.25))
	_resource_wood_label.add_theme_font_size_override("font_size", 12)
	wood_row.add_child(_resource_wood_label)
	stats_vbox.add_child(wood_row)

	# Minerai
	var ore_row = HBoxContainer.new()
	ore_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var ore_icon = ColorRect.new()
	ore_icon.custom_minimum_size = Vector2(10, 10)
	ore_icon.color = Color(0.45, 0.45, 0.55)
	ore_row.add_child(ore_icon)
	_resource_ore_label = Label.new()
	_resource_ore_label.text = " %d" % _ore
	_resource_ore_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.75))
	_resource_ore_label.add_theme_font_size_override("font_size", 12)
	ore_row.add_child(_resource_ore_label)
	stats_vbox.add_child(ore_row)

	# --- DATE DU JEU (sous les stats) ---
	var date_panel: Panel = _create_decorated_panel(Vector2(180, 40))
	date_panel.position = Vector2(0, 120)
	hero_block.add_child(date_panel)
	_label_date = Label.new()
	_label_date.text = "Month %d  Week %d  Day %d" % [_game_month, _game_week, _game_day]
	_label_date.size = Vector2(170, 30)
	_label_date.position = Vector2(5, 5)
	_label_date.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	_label_date.add_theme_font_size_override("font_size", 11)
	_label_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_panel.add_child(_label_date)

	# --- BOUTON FIN DE TOUR ---
	var btn_panel: Panel = _create_decorated_panel(Vector2(180, 50))
	btn_panel.position = Vector2(20, 660)
	side_panel.add_child(btn_panel)
	var btn_end_turn: Button = Button.new()
	btn_end_turn.text = "FIN DE TOUR"
	btn_end_turn.size = Vector2(160, 38)
	btn_end_turn.position = Vector2(10, 6)
	var btn_normal: StyleBoxFlat = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.55, 0.35, 0.15)
	btn_normal.border_color = Color(0.85, 0.65, 0.35)
	btn_normal.border_width_left = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_bottom = 2
	btn_normal.corner_radius_top_left = 4
	btn_normal.corner_radius_top_right = 4
	btn_normal.corner_radius_bottom_left = 4
	btn_normal.corner_radius_bottom_right = 4
	btn_end_turn.add_theme_stylebox_override("normal", btn_normal)
	var btn_hover: StyleBoxFlat = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.7, 0.5, 0.28)
	btn_hover.border_color = Color(0.95, 0.75, 0.45)
	btn_hover.border_width_left = 2
	btn_hover.border_width_right = 2
	btn_hover.border_width_top = 2
	btn_hover.border_width_bottom = 2
	btn_hover.corner_radius_top_left = 4
	btn_hover.corner_radius_top_right = 4
	btn_hover.corner_radius_bottom_left = 4
	btn_hover.corner_radius_bottom_right = 4
	btn_end_turn.add_theme_stylebox_override("hover", btn_hover)
	btn_end_turn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	btn_end_turn.add_theme_font_size_override("font_size", 12)
	btn_end_turn.pressed.connect(_on_end_turn_pressed)
	btn_panel.add_child(btn_end_turn)

	# === BARRE DU BAS (1060 x 45) — ressources style HoMM3 ===
	var bottom_panel: Panel = Panel.new()
	bottom_panel.name = "BottomPanel"
	bottom_panel.size = Vector2(1060, 45)
	bottom_panel.position = Vector2(0, 675)
	var bottom_style: StyleBoxFlat = StyleBoxFlat.new()
	bottom_style.bg_color = Color(0.10, 0.07, 0.03)
	bottom_style.border_color = Color(0.72, 0.52, 0.25)
	bottom_style.border_width_top = 3
	bottom_style.border_width_bottom = 3
	bottom_style.border_width_left = 3
	bottom_panel.add_theme_stylebox_override("panel", bottom_style)
	canvas_layer.add_child(bottom_panel)

	# Conteneur ressources horizontal
	var res_hbox: HBoxContainer = HBoxContainer.new()
	res_hbox.size = Vector2(1040, 40)
	res_hbox.position = Vector2(10, 2)
	res_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	res_hbox.add_theme_constant_override("separation", 60)
	bottom_panel.add_child(res_hbox)

	# --- Status Window (centre, style HoMM3) ---
	var status_label: Label = Label.new()
	status_label.text = "Status Window"
	status_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	status_label.add_theme_font_size_override("font_size", 13)
	res_hbox.add_child(status_label)

	# --- Or ---
	var gold_icon_label: Label = Label.new()
	gold_icon_label.text = "G"
	gold_icon_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	gold_icon_label.add_theme_font_size_override("font_size", 16)
	res_hbox.add_child(gold_icon_label)
	_label_gold = Label.new()
	_label_gold.text = str(_gold)
	_label_gold.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_label_gold.add_theme_font_size_override("font_size", 16)
	res_hbox.add_child(_label_gold)

	# --- Bois ---
	var wood_icon_label: Label = Label.new()
	wood_icon_label.text = "W"
	wood_icon_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.4))
	wood_icon_label.add_theme_font_size_override("font_size", 16)
	res_hbox.add_child(wood_icon_label)
	_label_wood = Label.new()
	_label_wood.text = str(_wood)
	_label_wood.add_theme_color_override("font_color", Color(0.6, 0.9, 0.4))
	_label_wood.add_theme_font_size_override("font_size", 16)
	res_hbox.add_child(_label_wood)

	# --- Minerai ---
	var ore_icon_label: Label = Label.new()
	ore_icon_label.text = "M"
	ore_icon_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	ore_icon_label.add_theme_font_size_override("font_size", 16)
	res_hbox.add_child(ore_icon_label)
	_label_ore = Label.new()
	_label_ore.text = str(_ore)
	_label_ore.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	_label_ore.add_theme_font_size_override("font_size", 16)
	res_hbox.add_child(_label_ore)

	# --- Bouton Sauvegarder ---
	var btn_save: Button = Button.new()
	btn_save.text = "💾 Sauver"
	btn_save.custom_minimum_size = Vector2(90, 30)
	btn_save.add_theme_font_size_override("font_size", 12)
	btn_save.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
	var save_style = StyleBoxFlat.new()
	save_style.bg_color = Color(0.12, 0.10, 0.06)
	save_style.border_color = Color(0.45, 0.38, 0.22)
	save_style.border_width_left = 1
	save_style.border_width_right = 1
	save_style.border_width_top = 1
	save_style.border_width_bottom = 3
	save_style.corner_radius_top_left = 6
	save_style.corner_radius_top_right = 6
	save_style.corner_radius_bottom_left = 6
	save_style.corner_radius_bottom_right = 6
	btn_save.add_theme_stylebox_override("normal", save_style)
	var save_hover = save_style.duplicate()
	save_hover.bg_color = Color(0.22, 0.18, 0.10)
	btn_save.add_theme_stylebox_override("hover", save_hover)
	btn_save.pressed.connect(_on_save_game_pressed)
	res_hbox.add_child(btn_save)

	# --- Bouton Menu ---
	var btn_menu: Button = Button.new()
	btn_menu.text = "☰ Menu"
	btn_menu.custom_minimum_size = Vector2(80, 30)
	btn_menu.add_theme_font_size_override("font_size", 12)
	btn_menu.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
	var menu_style = StyleBoxFlat.new()
	menu_style.bg_color = Color(0.12, 0.10, 0.06)
	menu_style.border_color = Color(0.45, 0.38, 0.22)
	menu_style.border_width_left = 1
	menu_style.border_width_right = 1
	menu_style.border_width_top = 1
	menu_style.border_width_bottom = 3
	menu_style.corner_radius_top_left = 6
	menu_style.corner_radius_top_right = 6
	menu_style.corner_radius_bottom_left = 6
	menu_style.corner_radius_bottom_right = 6
	btn_menu.add_theme_stylebox_override("normal", menu_style)
	var menu_hover = menu_style.duplicate()
	menu_hover.bg_color = Color(0.22, 0.18, 0.10)
	btn_menu.add_theme_stylebox_override("hover", menu_hover)
	btn_menu.pressed.connect(_on_menu_pressed)
	res_hbox.add_child(btn_menu)

	print("✓ Interface HoMM3 (panneau droit + barre du bas) créée")

func _create_decorated_panel(size: Vector2) -> Panel:
	var panel: Panel = Panel.new()
	panel.size = size
	
	# Style avec fond marron et bordure dorée
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.14, 0.08)  # Marron moyen
	style.border_color = Color(0.72, 0.52, 0.25)  # Doré HoMM3
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	
	return panel

func _on_end_turn_pressed() -> void:
	_end_turn()

# Variables pour la minimap
var _minimap_panel: Control = null
var _minimap_hero_dot: ColorRect = null
const MINIMAP_SIZE: int = 200
const MINIMAP_SCALE: float = 10.0  # Échelle pour convertir la position du héros en coordonnées minimap

# Zoom constants
const ZOOM_MIN: float = 0.15  # Dézoom max (voir la map entière)
const ZOOM_MAX: float = 2.0   # Zoom max (voir les détails)
const ZOOM_STEP: float = 0.1  # Pas de zoom par tick de molette

# Villes sur la carte
var _cities: Array = []
var _city_visuals: Array = []
const CITY_COUNT: int = 8
const CITY_SIZE: int = 48

# Ennemis sur la carte
var _enemies: Array = []
var _enemy_visuals: Array = []
const ENEMY_COUNT: int = 40
const ENEMY_SIZE: int = 40

# Système de combat
var _hero_hp: int = 100
var _hero_max_hp: int = 100
var _hero_attack: int = 15
var _hero_defense: int = 5
var _in_combat: bool = false
var _combat_manager: CanvasLayer = null
var _current_enemy_index: int = -1

# Système de niveau et expérience
var _hero_level: int = 1
var _hero_xp: int = 0
var _hero_xp_to_next: int = 100
const XP_PER_LEVEL: int = 100
const XP_KILL_ENEMY: int = 50
const XP_COLLECT_RESOURCE: int = 20
const XP_VISIT_CITY: int = 30

# Temps du jeu (HoMM3 style)
var _game_month: int = 1
var _game_week: int = 1
var _game_day: int = 1
var _label_date: Label = null

# Ressources sur la carte (mines, scieries)
var _resources: Array = []
var _resource_visuals: Array = []
const RESOURCE_COUNT: int = 15
const RESOURCE_SIZE: int = 36
const RESOURCE_TYPES: Array = ["gold", "wood", "ore", "gold", "wood", "ore", "gold", "wood", "ore", "gold", "wood", "ore", "gold", "wood", "ore"]  # 15 éléments pour RESOURCE_COUNT = 15

# Décorations sur la carte (arbres, rochers, tours)
var _decorations: Array = []
const TREE_COUNT: int = 40
const ROCK_COUNT: int = 25
const TOWER_COUNT: int = 15
const DECORATION_SIZE: int = 32

# Coffres au trésor
var _treasures: Array = []
var _treasure_visuals: Array = []
const TREASURE_COUNT: int = 15
const TREASURE_SIZE: int = 28

# Particules de fumée (châteaux)
var _smoke_particles: Array = []

# Grille du terrain (stockée globalement pour accéder au coût de mouvement)
var _terrain_grid: Array = []

# ============================================================
# SYSTÈME HOMM : POINTS DE MOUVEMENT
# ============================================================
var _hero_mp: int = 0          # Points de mouvement actuels
var _hero_max_mp: int = 20     # Points de mouvement max par jour
var _terrain_move_cost: Dictionary = {
	0: 1,   # Herbe = 1
	1: 1,   # Route/Terre = 1 (chemin)
	2: 999, # Eau = impossible
	3: 3,   # Montagne = 3
	4: 2,   # Forêt = 2
	5: 1    # Prairie = 1
}
var _turn_in_progress: bool = false
var _current_path: Array = []  # Chemin de tuiles calculé

# ============================================================
# SYSTÈME HOMM : BROUILLARD DE GUERRE
# ============================================================
var _fog_grid: Array = []        # Grille du brouillard: 0=inconnu, 1=découvert, 2=visible
const FOG_VISION_RANGE: int = 5  # Portée de vision du héros
var _map_sprite: Sprite2D = null  # Référence au sprite de la carte

# ============================================================
# SYSTÈME HOMM : ARMÉE DU HÉROS
# ============================================================
# Unités de type: nom, hp, attack, defense, speed, sprite_type
const UNIT_TYPES: Dictionary = {
	"pikeman":    {"name": "Piquier",    "hp": 10, "attack": 4, "defense": 5, "speed": 4, "cost_g": 60,  "cost_w": 0,  "cost_o": 0},
	"archer":     {"name": "Archer",     "hp": 8,  "attack": 6, "defense": 3, "speed": 4, "cost_g": 100, "cost_w": 0,  "cost_o": 0},
	"griffin":    {"name": "Griffon",    "hp": 25, "attack": 8, "defense": 8, "speed": 6, "cost_g": 200, "cost_w": 0,  "cost_o": 0},
	"swordsman":  {"name": "Épéiste",    "hp": 35, "attack": 10, "defense": 12, "speed": 5, "cost_g": 300, "cost_w": 0, "cost_o": 0},
	"cavalier":   {"name": "Cavalier",   "hp": 40, "attack": 15, "defense": 15, "speed": 7, "cost_g": 400, "cost_w": 0, "cost_o": 0},
	"angel":      {"name": "Ange",       "hp": 80, "attack": 25, "defense": 25, "speed": 9, "cost_g": 1000, "cost_w": 0, "cost_o": 0}
}
# Armée du héros: [{"type": "pikeman", "count": 12, "hp": 10}, ...]
var _hero_army: Array = [
	{"type": "pikeman", "count": 12, "hp": 10},
	{"type": "archer", "count": 8, "hp": 8}
]
# Armées ennemies: même format, indexé par enemy_index
var _enemy_armies: Array = []

# ============================================================
# SYSTÈME HOMM : VILLES ET CONSTRUCTION
# ============================================================
# Bâtiments de ville: nom, cost_gold, cost_wood, cost_ore, effect
const CITY_BUILDINGS: Dictionary = {
	"town_hall":     {"name": "Hôtel de ville",   "cost_g": 500,  "cost_w": 5, "cost_o": 0,  "desc": "Revenus +500/jour"},
	"tavern":        {"name": "Taverne",          "cost_g": 500,  "cost_w": 5, "cost_o": 0,  "desc": "+1 Moral"},
	"barracks":      {"name": "Caserne",          "cost_g": 1000, "cost_w": 10, "cost_o": 0, "desc": "Recruter Piquiers"},
	"archery_range": {"name": "Stand de tir",     "cost_g": 1000, "cost_w": 5, "cost_o": 5, "desc": "Recruter Archers"},
	"griffin_tower": {"name": "Tour du Griffon",  "cost_g": 2000, "cost_w": 10, "cost_o": 10, "desc": "Recruter Griffons"},
	"training_ground": {"name": "Terrain d'entraînement", "cost_g": 3000, "cost_w": 10, "cost_o": 15, "desc": "Recruter Épéistes"},
	"stables":       {"name": "Écuries",          "cost_g": 2000, "cost_w": 10, "cost_o": 5, "desc": "Recruter Cavaliers"},
	"angel_statue":  {"name": "Statue de l'Ange", "cost_g": 5000, "cost_w": 20, "cost_o": 20, "desc": "Recruter Anges"},
	"fort":          {"name": "Fort",             "cost_g": 2000, "cost_w": 20, "cost_o": 20, "desc": "Défense +50%"},
	"resource_silo": {"name": "Silo",             "cost_g": 500,  "cost_w": 0, "cost_o": 0,  "desc": "+1 Bois/Minerai/jour"}
}
# État des villes: [{"position": Vector2, "buildings": [], "garrison": [], "income": 500}, ...]
var _cities_data: Array = []
var _selected_city_index: int = -1
var _town_screen_open: bool = false

# ============================================================
# SYSTÈME HOMM : FIN DE TOUR
# ============================================================
var _end_turn_button: Button = null
var _label_mp: Label = null  # Label pour afficher les MP

func _create_cities() -> void:
	# Créer des villes à des positions aléatoires sur la carte
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(CITY_COUNT):
		var city_x: int = rng.randi_range(2, _zone_w - 3)
		var city_y: int = rng.randi_range(2, _zone_h - 3)
		var world_x: float = (city_x * TILE_SIZE) + TILE_SIZE / 2
		var world_y: float = (city_y * TILE_SIZE) + TILE_SIZE / 2
		var city_pos: Vector2 = Vector2(world_x, world_y)
		
		# Stocker la position de la ville
		_cities.append(city_pos)
		
		# Créer le visuel du château (2x2 tuiles = 128x128)
		var city_node: Node2D = Node2D.new()
		city_node.name = "City_" + str(i)
		city_node.position = city_pos
		add_child(city_node)
		
		# === CHÂTEAU PRINCIPAL vs CASERNES ===
		# Ville 0 = Château principal (castle.png), plus grand et majestueux
		# Villes 1+ = Casernes (barracks.png), bâtiments militaires plus petits
		var castle_sprite: Sprite2D = Sprite2D.new()
		var is_main_castle: bool = (i == 0)
		
		if is_main_castle:
			# === CHÂTEAU PRINCIPAL ===
			var castle_texture: Texture2D = load("res://assets/external/castle.png")
			if castle_texture != null:
				castle_sprite.texture = castle_texture
				# Château plus grand et plus imposant (cible ~256px)
				var target_size: float = 256.0
				var tex_size: Vector2 = castle_texture.get_size()
				var scale_factor: float = target_size / max(tex_size.x, tex_size.y)
				castle_sprite.scale = Vector2(scale_factor, scale_factor)
			else:
				# Fallback procédural plus grand
				castle_sprite.texture = _generate_sprite("castle", 256, i * 1337)
			castle_sprite.position = Vector2(0, -90)
		else:
			# === CASERNES (barracks.png) ===
			var barracks_texture: Texture2D = load("res://assets/external/barracks.png")
			if barracks_texture != null:
				castle_sprite.texture = barracks_texture
				# Casernes plus modestes (cible ~192px)
				var target_size: float = 192.0
				var tex_size: Vector2 = barracks_texture.get_size()
				var scale_factor: float = target_size / max(tex_size.x, tex_size.y)
				castle_sprite.scale = Vector2(scale_factor, scale_factor)
			else:
				# Fallback procédural standard
				castle_sprite.texture = _generate_sprite("castle", 192, i * 1337)
			castle_sprite.position = Vector2(0, -64)
		city_node.add_child(castle_sprite)
		
		# === FUMÉE DES CHEMINÉES ===
		# Le château principal a plus de fumée et plus haute
		var chimney_count: int = rng.randi_range(2, 4)
		if is_main_castle:
			chimney_count = rng.randi_range(4, 7)
		for chimney in range(chimney_count):
			var smoke: Sprite2D = Sprite2D.new()
			var smoke_img: Image = Image.create(12, 12, false, Image.FORMAT_RGBA8)
			smoke_img.fill(Color(0, 0, 0, 0))
			for sx in range(12):
				for sy in range(12):
					var sdist: float = sqrt((sx - 6)**2 + (sy - 6)**2)
					if sdist < 5:
						var salpha: float = (1.0 - sdist / 5.0) * 0.4
						smoke_img.set_pixel(sx, sy, Color(0.8, 0.8, 0.8, salpha))
			smoke.texture = ImageTexture.create_from_image(smoke_img)
			# Fumée plus haute pour le château principal
			var smoke_y: float = -110 if not is_main_castle else -150
			smoke.position = Vector2(rng.randi_range(-40, 40), smoke_y)
			smoke.set_z_index(1)
			city_node.add_child(smoke)
			_smoke_particles.append({
				"sprite": smoke,
				"base_pos": smoke.position,
				"speed": rng.randf_range(2.0, 5.0),
				"offset": rng.randf() * 10.0,
				"size": 1.0
			})
		
		# === BANNIERE DU CHÂTEAU PRINCIPAL ===
		if is_main_castle:
			var banner: Sprite2D = Sprite2D.new()
			var banner_img: Image = Image.create(8, 24, false, Image.FORMAT_RGBA8)
			banner_img.fill(Color(0, 0, 0, 0))
			# Poteau
			for by in range(24):
				banner_img.set_pixel(3, by, Color(0.4, 0.3, 0.2))
				banner_img.set_pixel(4, by, Color(0.35, 0.25, 0.18))
			# Drapeau rouge
			for bx in range(4, 8):
				for by in range(4, 14):
					if rng.randf() < 0.8:
						var bcol: Color = Color(0.72, 0.08, 0.08)
						if rng.randf() < 0.3:
							bcol = Color(0.62, 0.06, 0.06)
						banner_img.set_pixel(bx, by, bcol)
			# Blason doré sur le drapeau
			banner_img.set_pixel(5, 8, Color(0.9, 0.75, 0.2))
			banner_img.set_pixel(6, 8, Color(0.85, 0.7, 0.15))
			banner_img.set_pixel(5, 9, Color(0.85, 0.7, 0.15))
			banner_img.set_pixel(6, 9, Color(0.9, 0.75, 0.2))
			banner.texture = ImageTexture.create_from_image(banner_img)
			banner.position = Vector2(60, -160)
			banner.set_z_index(2)
			city_node.add_child(banner)
		
		_city_visuals.append(city_node)
		
		# Initialiser les données de ville pour le système HoMM
		_cities_data.append({
			"position": city_pos,
			"buildings": [],
			"garrison": [],
			"income": 500,
			"owned": i == 0  # Première ville possédée par défaut
		})
		
		print("Ville ", i + 1, " créée à la position : ", city_pos)

func _create_enemies() -> void:
	# Créer des ennemis à des positions aléatoires sur la carte
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(ENEMY_COUNT):
		var enemy_x: int = rng.randi_range(3, _zone_w - 4)
		var enemy_y: int = rng.randi_range(3, _zone_h - 4)
		var world_x: float = (enemy_x * TILE_SIZE) + TILE_SIZE / 2
		var world_y: float = (enemy_y * TILE_SIZE) + TILE_SIZE / 2
		var enemy_pos: Vector2 = Vector2(world_x, world_y)
		
		# Stocker la position de l'ennemi avec ses stats
		var enemy_data: Dictionary = {
			"position": enemy_pos,
			"hp": 50,
			"max_hp": 50,
			"attack": 10,
			"alive": true
		}
		_enemies.append(enemy_data)
		
		# Créer le visuel de l'ennemi
		var enemy_node: Node2D = Node2D.new()
		enemy_node.name = "Enemy_" + str(i)
		enemy_node.position = enemy_pos
		add_child(enemy_node)

		# Charger un sprite HoMM3 selon le type d'ennemi
		var enemy_sprites: Array = [
			"res://assets/units/skeleton.png",
			"res://assets/units/goblin.png",
			"res://assets/units/archer.png",
			"res://assets/units/swordsman.png",
		]
		var sprite_path: String = enemy_sprites[i % enemy_sprites.size()]
		var texture: Texture2D = load(sprite_path) if ResourceLoader.exists(sprite_path) else null
		
		if texture:
			var sprite: Sprite2D = Sprite2D.new()
			sprite.texture = texture
			sprite.scale = Vector2(1.5, 1.5)
			sprite.position = Vector2(0, -16)
			enemy_node.add_child(sprite)
		else:
			# Fallback : sprite procédural selon le type
			var enemy_types: Array = ["enemy_skeleton", "enemy_goblin", "enemy_archer", "enemy_swordsman"]
			var sprite_type: String = enemy_types[i % enemy_types.size()]
			var enemy_sprite: Sprite2D = Sprite2D.new()
			enemy_sprite.texture = _generate_sprite(sprite_type, 64, i * 7919)
			enemy_sprite.position = Vector2(0, -16)
			enemy_node.add_child(enemy_sprite)
		
		_enemy_visuals.append(enemy_node)
		
		print("Ennemi ", i + 1, " créé à la position : ", enemy_pos, " (HP: 50)")

func _create_resources() -> void:
	# Créer des ressources à collecter sur la carte (mines, scieries)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(RESOURCE_COUNT):
		var res_x: int = rng.randi_range(1, _zone_w - 2)
		var res_y: int = rng.randi_range(1, _zone_h - 2)
		var world_x: float = (res_x * TILE_SIZE) + TILE_SIZE / 2
		var world_y: float = (res_y * TILE_SIZE) + TILE_SIZE / 2
		var res_pos: Vector2 = Vector2(world_x, world_y)
		
		# Type de ressource
		var res_type: String = RESOURCE_TYPES[i]
		var res_name: String = ""
		var res_color: Color
		
		match res_type:
			"gold":
				res_name = "Mine d'Or"
				res_color = Color(0.9, 0.7, 0.1)  # Or
			"wood":
				res_name = "Scierie"
				res_color = Color(0.4, 0.25, 0.1)  # Marron bois
			"ore":
				res_name = "Mine de Minerai"
				res_color = Color(0.5, 0.5, 0.5)  # Gris
		
		# Stocker les données de la ressource
		var res_data: Dictionary = {
			"position": res_pos,
			"type": res_type,
			"name": res_name,
			"collected": false
		}
		_resources.append(res_data)
		
		# Créer le visuel de la ressource (détaillé selon le type)
		var res_node: Node2D = Node2D.new()
		res_node.name = "Resource_" + str(i)
		res_node.position = res_pos
		add_child(res_node)
		
		# === SPRITE PROCÉDURAL POUR LA RESSOURCE ===
		var sprite_type: String = ""
		match res_type:
			"gold":
				res_name = "Mine d'Or"
				res_color = Color(0.9, 0.7, 0.1)
				sprite_type = "mine_gold"
			"wood":
				res_name = "Scierie"
				res_color = Color(0.4, 0.25, 0.1)
				sprite_type = "mine_wood"
			"ore":
				res_name = "Mine de Minerai"
				res_color = Color(0.5, 0.5, 0.5)
				sprite_type = "mine_ore"
		
		var res_sprite: Sprite2D = Sprite2D.new()
		res_sprite.texture = _generate_sprite(sprite_type, 96, i * 3571)
		res_sprite.position = Vector2(0, -24)
		res_node.add_child(res_sprite)
		
		# Ombre elliptique sous la ressource
		_create_elliptical_shadow(res_node, 44, 14, 14, 0.30)
		
		_resource_visuals.append(res_node)
		
		print("Ressource ", i + 1, " créée : ", res_name, " à la position : ", res_pos)

func _create_minimap(parent: Control) -> void:
	# Conteneur avec cadre doré - ratio 60:40 pour correspondre à toute la map
	var minimap_width: float = 300.0  # Grande minimap pour voir toute la map 60×40
	var minimap_height: float = minimap_width * float(_zone_h) / float(_zone_w)  # 300 * 40/60 = 200
	
	var container: Panel = Panel.new()
	container.name = "MinimapContainer"
	container.size = Vector2(minimap_width, minimap_height)
	container.position = Vector2(10, 10)
	var container_style: StyleBoxFlat = StyleBoxFlat.new()
	container_style.bg_color = Color(0.15, 0.10, 0.05)
	container_style.border_color = Color(0.72, 0.52, 0.25)
	container_style.border_width_left = 3
	container_style.border_width_right = 3
	container_style.border_width_top = 3
	container_style.border_width_bottom = 3
	container_style.corner_radius_top_left = 6
	container_style.corner_radius_top_right = 6
	container_style.corner_radius_bottom_left = 6
	container_style.corner_radius_bottom_right = 6
	container.add_theme_stylebox_override("panel", container_style)
	parent.add_child(container)

	_minimap_panel = Control.new()
	_minimap_panel.name = "MinimapZone"
	_minimap_panel.size = Vector2(minimap_width - 6, minimap_height - 6)
	_minimap_panel.position = Vector2(3, 3)
	container.add_child(_minimap_panel)

	# Fond vert (représente l'herbe de la zone de jeu)
	var bg: ColorRect = ColorRect.new()
	bg.size = Vector2(minimap_width - 6, minimap_height - 6)
	bg.color = Color(0.2, 0.5, 0.2)  # Vert herbe comme la zone de jeu
	_minimap_panel.add_child(bg)

	# Calculer le scale pour que la zone 60×40 (toute la map) remplisse exactement la minimap
	var scale_x: float = (minimap_width - 6) / float(_zone_w * TILE_SIZE)
	var scale_y: float = (minimap_height - 6) / float(_zone_h * TILE_SIZE)
	var scale: float = min(scale_x, scale_y)

	for city_pos in _cities:
		var dot: ColorRect = ColorRect.new()
		dot.size = Vector2(8, 8)
		dot.color = Color(1, 0, 0)
		dot.position = Vector2(city_pos.x * scale - 4, city_pos.y * scale - 4)
		_minimap_panel.add_child(dot)

	for enemy in _enemies:
		var dot: ColorRect = ColorRect.new()
		dot.size = Vector2(6, 6)
		dot.color = Color(0.8, 0, 0.8)
		dot.position = Vector2(enemy["position"].x * scale - 3, enemy["position"].y * scale - 3)
		_minimap_panel.add_child(dot)

	for res in _resources:
		var dot: ColorRect = ColorRect.new()
		dot.size = Vector2(5, 5)
		dot.color = Color(1, 0.8, 0)
		dot.position = Vector2(res["position"].x * scale - 2.5, res["position"].y * scale - 2.5)
		_minimap_panel.add_child(dot)

	for chest in _treasures:
		var dot: ColorRect = ColorRect.new()
		dot.size = Vector2(6, 6)
		dot.color = Color(1, 1, 1)
		dot.position = Vector2(chest["position"].x * scale - 3, chest["position"].y * scale - 3)
		_minimap_panel.add_child(dot)

	# Héros (position centrée sur la zone 60×40 - toute la map)
	var start_hero_x: float = (_zone_w / 2.0) * TILE_SIZE + TILE_SIZE / 2.0
	var start_hero_y: float = (_zone_h / 2.0) * TILE_SIZE + TILE_SIZE / 2.0
	_minimap_hero_dot = ColorRect.new()
	_minimap_hero_dot.size = Vector2(10, 10)
	_minimap_hero_dot.color = Color(0, 0.5, 1)
	_minimap_hero_dot.position = Vector2(start_hero_x * scale - 5, start_hero_y * scale - 5)
	_minimap_panel.add_child(_minimap_hero_dot)

	var hero_border: ColorRect = ColorRect.new()
	hero_border.size = Vector2(12, 12)
	hero_border.position = Vector2(-1, -1)
	hero_border.color = Color(1, 1, 1)
	_minimap_hero_dot.add_child(hero_border)

	print("✓ Minimap créée: ", _cities.size(), " villes, ", _enemies.size(), " ennemis, ", _resources.size(), " ressources, ", _treasures.size(), " coffres")

func _update_minimap() -> void:
	if _minimap_hero_dot == null:
		return

	var hero_x: float = _hero.position.x
	var hero_y: float = _hero.position.y
	
	# Recalculer le scale comme dans _create_minimap
	var minimap_width: float = 300.0
	var minimap_height: float = minimap_width * float(_zone_h) / float(_zone_w)
	var scale_x: float = (minimap_width - 6) / float(_zone_w * TILE_SIZE)
	var scale_y: float = (minimap_height - 6) / float(_zone_h * TILE_SIZE)
	var scale: float = min(scale_x, scale_y)
	
	var minimap_x: float = hero_x * scale - 5
	var minimap_y: float = hero_y * scale - 5
	_minimap_hero_dot.position = Vector2(minimap_x, minimap_y)

func _create_floating_text(text: String, color: Color, pos: Vector2) -> void:
	# Créer un texte flottant qui monte et s'efface (effet visuel de gain)
	# Note: attaché à la scène principale, pas un CanvasLayer, pour suivre la caméra
	var label: Label = Label.new()
	label.name = "FloatingText"
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Position dans le monde (au-dessus du héros/objet)
	label.position = pos - Vector2(40, 60)  # Décalé au-dessus
	
	add_child(label)
	
	# Animation simple : monter et s'effacer
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	
	# Monter de 40 pixels en 1.5 secondes
	tween.tween_property(label, "position:y", label.position.y - 40, 1.5)
	# S'effacer
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	
	# Supprimer après l'animation
	tween.chain().tween_callback(func():
		label.queue_free()
	)

func _gain_xp(amount: int) -> void:
	_hero_xp += amount
	print("   XP total : ", _hero_xp, "/", _hero_xp_to_next)
	_update_hero_panel()
	
	# Texte flottant XP
	_create_floating_text("+" + str(amount) + " XP", Color(0.9, 0.7, 0.3), _hero.position)
	
	# Vérifier si le héros monte de niveau
	while _hero_xp >= _hero_xp_to_next:
		_level_up()

func _level_up() -> void:
	_hero_level += 1
	_hero_xp -= _hero_xp_to_next
	_hero_xp_to_next = _hero_level * XP_PER_LEVEL
	
	# Augmenter les stats du héros
	_hero_max_hp += 20
	_hero_hp = _hero_max_hp  # Soigner complètement
	_hero_attack += 5
	_hero_defense += 3
	
	# Texte flottant LEVEL UP (gros et doré)
	_create_floating_text("★ LEVEL UP! ★", Color(1.0, 0.85, 0.2), _hero.position)
	_create_floating_text("Niveau " + str(_hero_level), Color(0.9, 0.9, 0.5), _hero.position - Vector2(0, 30))
	
	print("🆙 LEVEL UP ! Niveau ", _hero_level, " atteint !")
	_update_hero_panel()

# ============================================
# SAUVEGARDE / CHARGEMENT
# ============================================

func _on_save_game_pressed() -> void:
	_save_game()
	# Feedback visuel
	_create_floating_text("💾 Partie sauvegardée !", Color(0.4, 0.8, 0.4), _hero.position)

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _save_game() -> void:
	var save_data = {
		"hero_level": _hero_level,
		"hero_xp": _hero_xp,
		"hero_xp_to_next": _hero_xp_to_next,
		"hero_hp": _hero_hp,
		"hero_max_hp": _hero_max_hp,
		"hero_attack": _hero_attack,
		"hero_defense": _hero_defense,
		"gold": _gold,
		"wood": _wood,
		"ore": _ore,
		"hero_pos": {"x": _hero.position.x, "y": _hero.position.y},
		"hero_tile": {"x": _hero_tile.x, "y": _hero_tile.y},
		"day": _game_day,
		"week": _game_week,
		"month": _game_month,
	}
	
	var json_string = JSON.stringify(save_data)
	var file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("💾 Partie sauvegardée avec succès!")
	else:
		print("❌ Erreur lors de la sauvegarde")

func _load_game() -> void:
	if not FileAccess.file_exists("user://save_game.json"):
		print("❌ Aucune sauvegarde trouvée")
		return
	
	var file = FileAccess.open("user://save_game.json", FileAccess.READ)
	if not file:
		print("❌ Impossible d'ouvrir le fichier de sauvegarde")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("❌ Erreur de parsing JSON: ", json.get_error_message())
		return
	
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		print("❌ Données de sauvegarde invalides")
		return
	
	_hero_level = data.get("hero_level", 1)
	_hero_xp = data.get("hero_xp", 0)
	_hero_xp_to_next = data.get("hero_xp_to_next", XP_PER_LEVEL)
	_hero_hp = data.get("hero_hp", 100)
	_hero_max_hp = data.get("hero_max_hp", 100)
	_hero_attack = data.get("hero_attack", 10)
	_hero_defense = data.get("hero_defense", 5)
	_gold = data.get("gold", 500)
	_wood = data.get("wood", 10)
	_ore = data.get("ore", 5)
	
	var pos = data.get("hero_pos", {})
	if pos.has("x") and pos.has("y"):
		_hero.position = Vector2(pos.x, pos.y)
	
	var tile = data.get("hero_tile", {})
	if tile.has("x") and tile.has("y"):
		_hero_tile = Vector2i(tile.x, tile.y)
	
	_game_day = data.get("day", 1)
	_game_week = data.get("week", 1)
	_game_month = data.get("month", 1)
	
	# Mettre à jour la caméra
	_camera.position = _hero.position
	
	# Mettre à jour l'UI
	_update_hero_panel()
	_update_date_label()
	
	print("📂 Partie chargée avec succès! Niveau ", _hero_level)

func _update_hero_panel() -> void:
	if _label_level != null:
		_label_level.text = "Niveau %d" % _hero_level
	
	if _xp_bar_fill != null:
		var xp_ratio = float(_hero_xp) / _hero_xp_to_next if _hero_xp_to_next > 0 else 0
		_xp_bar_fill.size = Vector2(162 * xp_ratio, 14)
	
	if _label_xp != null:
		_label_xp.text = "%d / %d XP" % [_hero_xp, _hero_xp_to_next]
	
	if _hp_bar_fill != null:
		var hp_ratio = float(_hero_hp) / _hero_max_hp if _hero_max_hp > 0 else 0
		_hp_bar_fill.size = Vector2(162 * hp_ratio, 14)
		if hp_ratio > 0.5:
			_hp_bar_fill.color = Color(0.2, 0.7, 0.25)
		elif hp_ratio > 0.25:
			_hp_bar_fill.color = Color(0.85, 0.55, 0.1)
		else:
			_hp_bar_fill.color = Color(0.8, 0.15, 0.15)
	
	if _label_hp != null:
		_label_hp.text = "HP %d / %d" % [_hero_hp, _hero_max_hp]
	
	if _resource_gold_label != null:
		_resource_gold_label.text = " %d" % _gold
	if _resource_wood_label != null:
		_resource_wood_label.text = " %d" % _wood
	if _resource_ore_label != null:
		_resource_ore_label.text = " %d" % _ore
	print("   ❤️ HP max : +20 (", _hero_max_hp, ")")
	print("   ⚔️ ATK : +5 (", _hero_attack, ")")
	print("   💚 Héros complètement soigné !")
	print("   Prochain niveau : ", _hero_xp_to_next, " XP")

func _update_date_label() -> void:
	if _label_date != null:
		_label_date.text = "Month %d  Week %d  Day %d" % [_game_month, _game_week, _game_day]
