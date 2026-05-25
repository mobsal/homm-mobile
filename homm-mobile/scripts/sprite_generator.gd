class_name SpriteGenerator extends RefCounted
# Generateur de sprites pixel art proceduraux - extrait de tile_map_world.gd

const TILE_SIZE: int = 64
var _sprite_cache: Dictionary = {}  # "type_size_seed" -> ImageTexture
# ============================================================
# GÉNÉRATEUR DE SPRITES PROCÉDURAUX PIXEL ART
# ============================================================
func _generate_sprite(type: String, size: int, variant_seed: int = -1) -> ImageTexture:
	var cache_key: String = "%s_%d_%d" % [type, size, maxi(variant_seed, 0)]
	if _sprite_cache.has(cache_key):
		return _sprite_cache[cache_key]
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
		"enemy_tengu":
			_generate_enemy_sprite(img, size, rng, "tengu")
		"enemy_kappa":
			_generate_enemy_sprite(img, size, rng, "kappa")
		"enemy_ninja":
			_generate_enemy_sprite(img, size, rng, "ninja")
		"enemy_monk":
			_generate_enemy_sprite(img, size, rng, "monk")
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

	var result := ImageTexture.create_from_image(img)
	_sprite_cache[cache_key] = result
	return result

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

# --- CHÂTEAU JAPONAIS 192x192 (Shiro) ---
func _generate_castle_sprite(img: Image, size: int, rng: RandomNumberGenerator) -> void:
	var s: int = size
	var hs: int = s / 2
	
	# === 1. OMBRE AU SOL ===
	_draw_rect(img, 10, s - 12, s - 20, 12, Color(0, 0, 0, 0.30))
	
	# === 2. FONDATION EN PIERRE (ishigaki) ===
	_draw_rect(img, 8, hs + 8, s - 16, hs - 12, Color(0.45, 0.42, 0.40))
	_add_noise_to_rect(img, 8, hs + 8, s - 16, hs - 12, Color(0.45, 0.42, 0.40), 0.04, rng)
	# Lignes de maçonnerie
	for fy in range(hs + 16, s - 8, 8):
		_draw_rect(img, 8, fy, s - 16, 1, Color(0.35, 0.32, 0.30))
	
	# === 3. MURS BLANCS (shirokabe) avec bois noir ===
	var wall_base: int = hs - 40
	var wall_h: int = 60
	# Mur principal blanc
	_add_noise_to_rect(img, hs - 50, wall_base, 100, wall_h, Color(0.92, 0.90, 0.85), 0.02, rng)
	# Poutres en bois noir (horizontal)
	for py in [wall_base + 8, wall_base + 24, wall_base + 40]:
		_draw_rect(img, hs - 52, py, 104, 3, Color(0.12, 0.08, 0.06))
	# Poutres verticales
	for px in [hs - 40, hs - 20, hs, hs + 20, hs + 40]:
		_draw_rect(img, px, wall_base, 3, wall_h, Color(0.12, 0.08, 0.06))
	
	# === 4. TOIT COURBÉ IRIMOYA (niveaux superposés) ===
	# Premier niveau (toit inférieur)
	for level in range(4):
		var roof_y: int = wall_base - 10 - (level * 22)
		var roof_w: int = 110 - (level * 18)
		var roof_x: int = hs - roof_w / 2
		
		# Couche de tuiles sombres
		for ty in range(12):
			var tw: int = roof_w - abs(ty - 6) * 2
			var tx: int = hs - tw / 2
			var shade: float = 0.18 + ty * 0.015
			_draw_rect(img, tx, roof_y - ty, tw, 2, Color(shade, shade * 0.12, shade * 0.08))
		
		# Bordure du toit (kawara)
		_draw_rect(img, roof_x - 2, roof_y + 10, roof_w + 4, 3, Color(0.20, 0.12, 0.08))
		# Extrémités courbées
		_draw_circle(img, roof_x - 4, roof_y + 8, 4, Color(0.18, 0.10, 0.06))
		_draw_circle(img, roof_x + roof_w + 4, roof_y + 8, 4, Color(0.18, 0.10, 0.06))
	
	# === 5. DONJON CENTRAL (tenshu) ===
	var tenshu_x: int = hs - 20
	var tenshu_y: int = wall_base - 100
	var tenshu_w: int = 40
	var tenshu_h: int = 50
	
	# Mur blanc du tenshu
	_add_noise_to_rect(img, tenshu_x, tenshu_y, tenshu_w, tenshu_h, Color(0.92, 0.90, 0.85), 0.02, rng)
	# Poutres horizontales
	for py in [tenshu_y + 8, tenshu_y + 24, tenshu_y + 40]:
		_draw_rect(img, tenshu_x - 2, py, tenshu_w + 4, 3, Color(0.12, 0.08, 0.06))
	# Poutres verticales
	for px in [tenshu_x + 8, tenshu_x + 20, tenshu_x + 32]:
		_draw_rect(img, px, tenshu_y, 3, tenshu_h, Color(0.12, 0.08, 0.06))
	
	# Toit du tenshu (courbé)
	for ty in range(14):
		var tw: int = tenshu_w + 8 - abs(ty - 7) * 2
		var tx: int = hs - tw / 2
		var shade: float = 0.18 + ty * 0.015
		_draw_rect(img, tx, tenshu_y - 14 - ty, tw, 2, Color(shade, shade * 0.12, shade * 0.08))
	
	# === 6. FENÊTRES JAPONAISES (shoji) ===
	var window_positions: Array = [
		Vector2(hs - 35, wall_base + 12), Vector2(hs - 15, wall_base + 12), Vector2(hs + 5, wall_base + 12), Vector2(hs + 25, wall_base + 12),
		Vector2(hs - 35, wall_base + 32), Vector2(hs - 15, wall_base + 32), Vector2(hs + 5, wall_base + 32), Vector2(hs + 25, wall_base + 32)
	]
	for wp in window_positions:
		var wx: int = int(wp.x)
		var wy: int = int(wp.y)
		# Cadre en bois noir
		_draw_rect(img, wx - 5, wy - 5, 14, 14, Color(0.12, 0.08, 0.06))
		# Papier shoji (blanc translucide)
		_draw_rect(img, wx - 3, wy - 3, 10, 10, Color(0.95, 0.93, 0.88))
		# Grille en bois
		_draw_rect(img, wx, wy - 3, 1, 10, Color(0.12, 0.08, 0.06))
		_draw_rect(img, wx - 3, wy, 10, 1, Color(0.12, 0.08, 0.06))
	
	# === 7. PORTE PRINCIPALE (ōtemon) ===
	var gate_w: int = 28
	var gate_h: int = 24
	var gate_x: int = hs - gate_w / 2
	var gate_y: int = hs + 12
	
	# Piliers en bois
	_draw_rect(img, gate_x - 4, gate_y - 8, 6, gate_h + 8, Color(0.12, 0.08, 0.06))
	_draw_rect(img, gate_x + gate_w - 2, gate_y - 8, 6, gate_h + 8, Color(0.12, 0.08, 0.06))
	# Linteau
	_draw_rect(img, gate_x - 6, gate_y - 12, gate_w + 12, 6, Color(0.12, 0.08, 0.06))
	# Porte en bois
	_add_noise_to_rect(img, gate_x + 2, gate_y, gate_w - 4, gate_h, Color(0.18, 0.12, 0.06), 0.03, rng)
	# Panneaux de la porte
	_draw_rect(img, gate_x + 2, gate_y, gate_w / 2 - 2, gate_h, Color(0.15, 0.10, 0.05))
	# Poignées en métal
	_draw_rect(img, gate_x + gate_w / 2 - 2, gate_y + 10, 4, 4, Color(0.65, 0.55, 0.45))
	
	# === 8. TORII (porte shintoïste) ===
	var torii_x: int = hs + 55
	var torii_y: int = hs + 4
	# Piliers rouges (vermilion)
	_draw_rect(img, torii_x, torii_y - 20, 4, 28, Color(0.85, 0.25, 0.25))
	_draw_rect(img, torii_x + 14, torii_y - 20, 4, 28, Color(0.85, 0.25, 0.25))
	# Linteau supérieur (kasagi) courbé
	for tx in range(torii_x - 4, torii_x + 22):
		var curve: int = 2 if tx < torii_x + 2 or tx > torii_x + 16 else 0
		_draw_rect(img, tx, torii_y - 24 - curve, 2, 6, Color(0.85, 0.25, 0.25))
	# Linteau inférieur (nuki)
	_draw_rect(img, torii_x - 2, torii_y - 8, 22, 3, Color(0.85, 0.25, 0.25))
	
	# === 9. BANNIÈRE (nobori) ===
	var banner_x: int = hs - 60
	var banner_y: int = wall_base - 60
	# Poteau
	_draw_rect(img, banner_x, banner_y - 30, 3, 50, Color(0.45, 0.35, 0.25))
	# Drapeau rouge avec cercle du soleil
	for i in range(20):
		var wv: int = 2 if i % 2 == 0 else 0
		_draw_rect(img, banner_x + 4 + wv, banner_y - 28 + i, 18, 2, Color(0.85, 0.25, 0.25))
	# Cercle du soleil (hinomaru)
	_draw_circle(img, banner_x + 13, banner_y - 18, 5, Color(0.95, 0.85, 0.20))
	
	# === 10. SAKURA (cerisiers en fleurs) ===
	for tree in [[hs - 55, hs + 20], [hs + 55, hs + 18]]:
		var tx: int = tree[0]
		var ty: int = tree[1]
		# Tronc
		_draw_rect(img, tx, ty - 20, 6, 24, Color(0.35, 0.22, 0.12))
		# Branches
		_draw_rect(img, tx - 8, ty - 28, 12, 4, Color(0.32, 0.20, 0.10))
		_draw_rect(img, tx + 4, ty - 32, 10, 4, Color(0.32, 0.20, 0.10))
		# Fleurs de sakura (rose pâle)
		for fx in range(tx - 12, tx + 14, 4):
			for fy in range(ty - 36, ty - 20, 4):
				if rng.randf() < 0.6:
					var petal_color: Color = Color(0.95, 0.75, 0.85) if rng.randf() < 0.5 else Color(0.90, 0.65, 0.78)
					_draw_circle(img, fx, fy, 3, petal_color)
	
	# === 11. JARDIN ZEN (gauche) ===
	var zen_x: int = hs - 65
	var zen_y: int = hs + 10
	# Sol de gravier
	_draw_rect(img, zen_x, zen_y, 20, 16, Color(0.65, 0.60, 0.55))
	_add_noise_to_rect(img, zen_x, zen_y, 20, 16, Color(0.65, 0.60, 0.55), 0.03, rng)
	# Pierres zen
	_draw_circle(img, zen_x + 5, zen_y + 8, 4, Color(0.45, 0.42, 0.40))
	_draw_circle(img, zen_x + 14, zen_y + 5, 3, Color(0.48, 0.45, 0.43))
	# Bambou
	for bx in [zen_x + 8, zen_x + 16]:
		_draw_rect(img, bx, zen_y - 8, 2, 18, Color(0.25, 0.45, 0.30))
		_draw_rect(img, bx, zen_y - 10, 2, 2, Color(0.30, 0.50, 0.35))


# --- MAISON JAPONAISE (Minka) ---
func _generate_house_sprite(img: Image, size: int, rng: RandomNumberGenerator) -> void:
	var s: int = size
	var hs: int = s / 2
	
	# Sol de terre battue
	_draw_rect(img, 6, hs + 8, s - 12, hs - 10, Color(0.55, 0.45, 0.35))
	_add_noise_to_rect(img, 6, hs + 8, s - 12, hs - 10, Color(0.55, 0.45, 0.35), 0.03, rng)
	
	# Mur principal (bois sombre avec papier shoji)
	_add_noise_to_rect(img, hs - 18, hs - 6, 36, 24, Color(0.35, 0.25, 0.18), 0.04, rng)
	
	# Poutres de bois (verticales)
	for px in [hs - 14, hs - 6, hs + 2, hs + 10, hs + 18]:
		_draw_rect(img, px, hs - 6, 3, 24, Color(0.12, 0.08, 0.06))
	
	# Poutres horizontales
	for py in [hs + 2, hs + 12]:
		_draw_rect(img, hs - 18, py, 36, 2, Color(0.12, 0.08, 0.06))
	
	# Fenêtre shoji (papier translucide)
	_draw_rect(img, hs - 8, hs - 2, 8, 10, Color(0.95, 0.93, 0.88))
	# Grille en bois
	_draw_rect(img, hs - 4, hs - 2, 1, 10, Color(0.12, 0.08, 0.06))
	_draw_rect(img, hs - 8, hs + 2, 8, 1, Color(0.12, 0.08, 0.06))
	_draw_rect(img, hs, hs - 2, 1, 10, Color(0.12, 0.08, 0.06))
	
	# Toit courbé irimoya (tuiles sombres)
	for ty in range(16):
		var tw: int = 38 - abs(ty - 8) * 2
		var tx: int = hs - tw / 2
		var shade: float = 0.18 + ty * 0.012
		_draw_rect(img, tx, hs - 20 - ty, tw, 2, Color(shade, shade * 0.12, shade * 0.08))
	
	# Bordure du toit (kawara)
	_draw_rect(img, hs - 20, hs - 6, 40, 3, Color(0.20, 0.12, 0.08))
	# Extrémités courbées
	_draw_circle(img, hs - 22, hs - 8, 4, Color(0.18, 0.10, 0.06))
	_draw_circle(img, hs + 22, hs - 8, 4, Color(0.18, 0.10, 0.06))
	
	# Porte coulissante (shoji)
	_draw_rect(img, hs + 8, hs + 4, 8, 14, Color(0.95, 0.93, 0.88))
	_draw_rect(img, hs + 10, hs + 4, 1, 14, Color(0.12, 0.08, 0.06))
	_draw_rect(img, hs + 8, hs + 8, 8, 1, Color(0.12, 0.08, 0.06))
	_draw_rect(img, hs + 8, hs + 12, 8, 1, Color(0.12, 0.08, 0.06))
	
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

# --- ENNEMI JAPONAIS 64x64 ---
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
			body_color = Color(0.75, 0.15, 0.15)  # Oni rouge
			head_color = Color(0.85, 0.20, 0.20)
			detail_color = Color(0.55, 0.10, 0.10)
			weapon_color = Color(0.35, 0.25, 0.15)  # Kanabo (club)
			eye_color = Color(0.95, 0.85, 0.20)
		"archer":
			body_color = Color(0.35, 0.25, 0.18)  # Kimono sombre
			head_color = Color(0.90, 0.75, 0.60)  # Peau japonaise
			detail_color = Color(0.20, 0.12, 0.08)
			weapon_color = Color(0.45, 0.30, 0.15)  # Yumi (arc)
			eye_color = Color(0.12, 0.08, 0.06)
		"swordsman":
			body_color = Color(0.12, 0.08, 0.06)  # Armure noire samurai
			head_color = Color(0.90, 0.75, 0.60)
			detail_color = Color(0.85, 0.25, 0.25)  # Vermilion accents
			weapon_color = Color(0.85, 0.82, 0.78)  # Katana
			eye_color = Color(0.12, 0.08, 0.06)
		"tengu":
			body_color = Color(0.45, 0.35, 0.25)  # Plumage marron
			head_color = Color(0.55, 0.45, 0.35)
			detail_color = Color(0.85, 0.65, 0.15)  # Bec jaune
			weapon_color = Color(0.35, 0.25, 0.18)  # Éventail
			eye_color = Color(0.85, 0.20, 0.10)
		"kappa":
			body_color = Color(0.25, 0.55, 0.65)  # Peau verte
			head_color = Color(0.30, 0.60, 0.70)
			detail_color = Color(0.20, 0.45, 0.55)
			weapon_color = Color(0.35, 0.25, 0.18)  # Éventail
			eye_color = Color(0.85, 0.85, 0.20)
		"ninja":
			body_color = Color(0.08, 0.08, 0.10)  # Tenue noire
			head_color = Color(0.10, 0.10, 0.12)
			detail_color = Color(0.20, 0.20, 0.22)
			weapon_color = Color(0.55, 0.55, 0.60)  # Kunai/Shuriken
			eye_color = Color(0.85, 0.85, 0.20)
		"monk":
			body_color = Color(0.85, 0.70, 0.45)  # Robe safran
			head_color = Color(0.90, 0.75, 0.60)
			detail_color = Color(0.70, 0.55, 0.30)
			weapon_color = Color(0.55, 0.45, 0.30)  # Bâton
			eye_color = Color(0.12, 0.08, 0.06)
	
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
		# Cornes d'Oni (rouges)
		_draw_triangle(img, hs - 12, hs - 18, hs - 18, hs - 28, hs - 8, hs - 22, head_color)
		_draw_triangle(img, hs + 12, hs - 18, hs + 18, hs - 28, hs + 8, hs - 22, head_color)
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
		# Casque samurai (kabuto) avec crête
		_draw_gradient_rect(img, hs - 12, hs - 24, 24, 12, Color(0.12, 0.08, 0.06), Color(0.08, 0.05, 0.04))
		_draw_rect(img, hs - 2, hs - 30, 4, 8, Color(0.85, 0.25, 0.25))  # Crête vermilion
		# Visière (mempo)
		_draw_gradient_rect(img, hs - 10, hs - 16, 20, 6, Color(0.15, 0.10, 0.08), Color(0.10, 0.06, 0.04))
		# Chignon samurai
		_draw_circle(img, hs + 8, hs - 20, 4, Color(0.06, 0.04, 0.02))
	elif enemy_type == "archer":
		# Chapeau conique (jingasa)
		_draw_gradient_rect(img, hs - 14, hs - 26, 28, 8, Color(0.35, 0.25, 0.18), Color(0.25, 0.18, 0.12))
		_draw_rect(img, hs - 2, hs - 28, 4, 4, Color(0.35, 0.25, 0.18))
	elif enemy_type == "tengu":
		# Masque de Tengu avec long nez
		_draw_shaded_circle(img, hs, hs - 14, 14, Color(0.55, 0.45, 0.35), Vector2(-0.3, -0.8))
		# Long nez rouge
		_draw_triangle(img, hs, hs - 16, hs + 4, hs - 32, hs - 4, hs - 16, Color(0.85, 0.20, 0.10))
		# Plumes sur la tête
		for py in [hs - 22, hs - 26, hs - 30]:
			_draw_rect(img, hs - 8, py, 16, 2, Color(0.45, 0.35, 0.25))
	elif enemy_type == "kappa":
		# Tête chauve avec assiette
		_draw_shaded_circle(img, hs, hs - 14, 14, Color(0.30, 0.60, 0.70), Vector2(-0.3, -0.8))
		# Assiette sur la tête
		_draw_circle(img, hs, hs - 20, 6, Color(0.65, 0.65, 0.60))
		_draw_circle(img, hs, hs - 20, 4, Color(0.55, 0.55, 0.50))
	elif enemy_type == "ninja":
		# Masque ninja avec seulement les yeux visibles
		_draw_shaded_circle(img, hs, hs - 14, 14, Color(0.10, 0.10, 0.12), Vector2(-0.3, -0.8))
		# Bandeau sur les yeux
		_draw_rect(img, hs - 12, hs - 16, 24, 4, Color(0.08, 0.08, 0.10))
	elif enemy_type == "monk":
		# Tête rasée
		_draw_shaded_circle(img, hs, hs - 14, 14, Color(0.90, 0.75, 0.60), Vector2(-0.3, -0.8))
		# Sourcils rasés
		_draw_rect(img, hs - 6, hs - 18, 12, 2, Color(0.90, 0.75, 0.60))
	
	# Bouche détaillée
	if enemy_type == "skeleton":
		_draw_rect(img, hs - 3, hs - 5, 6, 2, Color(0.05, 0.05, 0.05))
	else:
		_draw_rect(img, hs - 3, hs - 6, 6, 2, Color(0.12, 0.08, 0.06))
		_draw_rect(img, hs - 2, hs - 6, 4, 1, Color(0.75, 0.25, 0.20))  # Lèvre
	
	# Détail / armure sur le corps avec textures
	if enemy_type == "swordsman":
		# Armure samurai (do) avec lames laquées noires
		_draw_shaded_circle(img, hs, hs + 2, 14, Color(0.12, 0.08, 0.06), Vector2(-0.5, -0.8))
		_draw_gradient_rect(img, hs - 8, hs - 2, 16, 16, Color(0.15, 0.10, 0.08), Color(0.08, 0.05, 0.04))
		_add_bevel(img, hs - 8, hs - 2, 16, 16, Color(0.20, 0.12, 0.08), Color(0.06, 0.04, 0.02))
		# Bordures vermilion
		_draw_rect(img, hs - 8, hs - 2, 16, 2, Color(0.85, 0.25, 0.25))
		_draw_rect(img, hs - 8, hs + 14, 16, 2, Color(0.85, 0.25, 0.25))
		# Mon (crest) au centre
		_draw_circle(img, hs, hs + 6, 4, Color(0.85, 0.25, 0.25))
		_draw_circle(img, hs, hs + 6, 2, Color(0.95, 0.85, 0.20))
	elif enemy_type == "archer":
		# Kimono avec motifs
		_draw_gradient_rect(img, hs - 14, hs, 6, 20, Color(0.35, 0.25, 0.18), Color(0.22, 0.12, 0.08))
		_draw_gradient_rect(img, hs + 8, hs, 6, 20, Color(0.35, 0.25, 0.18), Color(0.22, 0.12, 0.08))
		_draw_gradient_rect(img, hs - 8, hs + 2, 16, 16, Color(0.42, 0.30, 0.20), Color(0.28, 0.18, 0.10))
		# Obi (ceinture) vermilion
		_draw_rect(img, hs - 8, hs + 10, 16, 4, Color(0.85, 0.25, 0.25))
		# Carquois avec flèches
		_draw_rect(img, hs - 16, hs - 10, 5, 14, Color(0.30, 0.18, 0.08))
		for ay in [hs - 12, hs - 8, hs - 4]:
			_draw_rect(img, hs - 18, ay, 2, 10, Color(0.55, 0.45, 0.30))
			_draw_rect(img, hs - 16, ay - 2, 2, 2, Color(0.55, 0.55, 0.60))
	elif enemy_type == "goblin":
		# Peau d'Oni avec muscles
		_draw_gradient_rect(img, hs - 8, hs, 16, 12, Color(0.75, 0.15, 0.15), Color(0.55, 0.10, 0.10))
		# Tatouages/scarifications
		for ry in [hs + 2, hs + 6]:
			_draw_rect(img, hs - 5, ry, 10, 2, Color(0.45, 0.08, 0.08))
		# Fundoshi (loincloth)
		_draw_rect(img, hs - 6, hs + 10, 12, 3, Color(0.85, 0.25, 0.25))
	elif enemy_type == "tengu":
		# Plumage sur le corps
		_draw_gradient_rect(img, hs - 8, hs, 16, 12, Color(0.45, 0.35, 0.25), Color(0.35, 0.25, 0.15))
		# Ailes pliées
		for wy in [hs - 2, hs + 2, hs + 6]:
			_draw_rect(img, hs - 14, wy, 6, 3, Color(0.50, 0.40, 0.30))
			_draw_rect(img, hs + 8, wy, 6, 3, Color(0.50, 0.40, 0.30))
	elif enemy_type == "kappa":
		# Carapace de tortue sur le dos
		_draw_gradient_rect(img, hs - 8, hs - 2, 16, 14, Color(0.25, 0.55, 0.65), Color(0.20, 0.45, 0.55))
		# Motifs de carapace
		for cy in [hs + 2, hs + 6]:
			_draw_rect(img, hs - 6, cy, 12, 2, Color(0.20, 0.50, 0.60))
	elif enemy_type == "ninja":
		# Tenue noire ajustée
		_draw_gradient_rect(img, hs - 8, hs, 16, 12, Color(0.08, 0.08, 0.10), Color(0.06, 0.06, 0.08))
		# Ceinture avec kunai
		_draw_rect(img, hs - 6, hs + 10, 12, 3, Color(0.15, 0.15, 0.18))
		_draw_rect(img, hs - 4, hs + 12, 3, 5, Color(0.55, 0.55, 0.60))
	elif enemy_type == "monk":
		# Robe de moine safran
		_draw_gradient_rect(img, hs - 10, hs, 20, 14, Color(0.85, 0.70, 0.45), Color(0.70, 0.55, 0.30))
		# Kesa (écharpe de moine)
		_draw_rect(img, hs - 8, hs + 2, 16, 4, Color(0.60, 0.45, 0.25))
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
		# Jambes musclées d'Oni
		_draw_gradient_rect(img, hs - 6, hs + 12, 5, 6, Color(0.75, 0.15, 0.15), Color(0.55, 0.10, 0.10))
		_draw_gradient_rect(img, hs + 1, hs + 12, 5, 6, Color(0.75, 0.15, 0.15), Color(0.55, 0.10, 0.10))
	elif enemy_type == "tengu":
		# Pattes d'oiseau avec griffes
		_draw_gradient_rect(img, hs - 6, hs + 12, 5, 6, Color(0.55, 0.45, 0.35), Color(0.45, 0.35, 0.25))
		_draw_gradient_rect(img, hs + 1, hs + 12, 5, 6, Color(0.55, 0.45, 0.35), Color(0.45, 0.35, 0.25))
		# Griffes
		_draw_triangle(img, hs - 6, hs + 18, hs - 8, hs + 22, hs - 4, hs + 18, Color(0.85, 0.65, 0.15))
		_draw_triangle(img, hs + 6, hs + 18, hs + 8, hs + 22, hs + 4, hs + 18, Color(0.85, 0.65, 0.15))
	elif enemy_type == "kappa":
		# Jambes palmées
		_draw_gradient_rect(img, hs - 6, hs + 12, 5, 6, Color(0.30, 0.60, 0.70), Color(0.20, 0.45, 0.55))
		_draw_gradient_rect(img, hs + 1, hs + 12, 5, 6, Color(0.30, 0.60, 0.70), Color(0.20, 0.45, 0.55))
		# Palmes
		_draw_rect(img, hs - 8, hs + 18, 6, 2, Color(0.25, 0.55, 0.65))
		_draw_rect(img, hs + 2, hs + 18, 6, 2, Color(0.25, 0.55, 0.65))
	elif enemy_type == "ninja":
		# Jambes ajustées
		_draw_gradient_rect(img, hs - 6, hs + 12, 5, 6, Color(0.08, 0.08, 0.10), Color(0.06, 0.06, 0.08))
		_draw_gradient_rect(img, hs + 1, hs + 12, 5, 6, Color(0.08, 0.08, 0.10), Color(0.06, 0.06, 0.08))
	elif enemy_type == "monk":
		# Robe longue
		_draw_gradient_rect(img, hs - 8, hs + 12, 16, 6, Color(0.85, 0.70, 0.45), Color(0.70, 0.55, 0.30))
		# Pieds nus
		_draw_rect(img, hs - 10, hs + 22, 8, 3, Color(0.55, 0.10, 0.10))
		_draw_rect(img, hs + 2, hs + 22, 8, 3, Color(0.55, 0.10, 0.10))
	elif enemy_type == "skeleton":
		# Os des jambes
		_draw_rect(img, hs - 6, hs + 16, 3, 10, Color(0.78, 0.82, 0.78))
		_draw_rect(img, hs + 3, hs + 16, 3, 10, Color(0.78, 0.82, 0.78))
		# Pieds osseux
		_draw_rect(img, hs - 8, hs + 24, 6, 3, Color(0.75, 0.78, 0.75))
		_draw_rect(img, hs + 2, hs + 24, 6, 3, Color(0.75, 0.78, 0.75))
	elif enemy_type == "swordsman":
		# Hakama (pantalon samurai)
		_draw_gradient_rect(img, hs - 8, hs + 16, 6, 10, Color(0.12, 0.08, 0.06), Color(0.08, 0.05, 0.04))
		_draw_gradient_rect(img, hs + 2, hs + 16, 6, 10, Color(0.12, 0.08, 0.06), Color(0.08, 0.05, 0.04))
		# Geta (sandales en bois)
		_draw_rect(img, hs - 9, hs + 24, 8, 3, Color(0.35, 0.25, 0.18))
		_draw_rect(img, hs + 1, hs + 24, 8, 3, Color(0.35, 0.25, 0.18))
		# Dents des geta
		_draw_rect(img, hs - 6, hs + 26, 2, 2, Color(0.35, 0.25, 0.18))
		_draw_rect(img, hs + 4, hs + 26, 2, 2, Color(0.35, 0.25, 0.18))
	elif enemy_type == "archer":
		# Hakama (pantalon archer)
		_draw_gradient_rect(img, hs - 7, hs + 16, 5, 10, Color(0.35, 0.25, 0.18), Color(0.22, 0.12, 0.08))
		_draw_gradient_rect(img, hs + 2, hs + 16, 5, 10, Color(0.35, 0.25, 0.18), Color(0.22, 0.12, 0.08))
		# Tabi (chaussettes)
		_draw_rect(img, hs - 8, hs + 24, 6, 3, Color(0.90, 0.90, 0.88))
		_draw_rect(img, hs + 2, hs + 24, 6, 3, Color(0.90, 0.90, 0.88))
	
	# Armes japonaises détaillées
	if enemy_type == "skeleton":
		# Katana rouillée à droite
		_draw_gradient_rect(img, hs + 18, hs - 6, 5, 26, Color(0.72, 0.75, 0.80), Color(0.55, 0.58, 0.62))
		_draw_rect(img, hs + 20, hs - 6, 2, 26, Color(0.82, 0.85, 0.90))  # Tranchant
		_draw_rect(img, hs + 16, hs - 10, 9, 6, Color(0.55, 0.55, 0.60))  # Tsuba (garde)
		_draw_rect(img, hs + 17, hs + 14, 7, 3, Color(0.45, 0.35, 0.25))  # Tsuka (poignée)
		_draw_rect(img, hs + 19, hs + 18, 3, 3, Color(0.65, 0.55, 0.30))  # Kashira (pommeau)
		# Rouille sur la lame
		_draw_rect(img, hs + 19, hs + 2, 2, 4, Color(0.55, 0.30, 0.15))
		_draw_rect(img, hs + 18, hs - 4, 2, 3, Color(0.55, 0.30, 0.15))
	elif enemy_type == "goblin":
		# Kanabo (massue à pointes d'Oni)
		_draw_rect(img, hs + 20, hs - 8, 4, 26, Color(0.42, 0.28, 0.15))  # Manche
		_draw_rect(img, hs + 18, hs - 12, 8, 10, Color(0.55, 0.55, 0.60))  # Lame haut
		_draw_rect(img, hs + 18, hs - 2, 8, 10, Color(0.55, 0.55, 0.60))  # Lame bas
		_draw_rect(img, hs + 20, hs - 14, 4, 14, Color(0.65, 0.65, 0.70))  # Tranchant
		# Pointes (spikes)
		for sy in [hs - 10, hs - 4, hs + 2]:
			_draw_rect(img, hs + 16, sy, 3, 3, Color(0.75, 0.75, 0.80))
			_draw_rect(img, hs + 23, sy, 3, 3, Color(0.75, 0.75, 0.80))
		# Sang sur la massue
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
		# Katana brillant à droite
		_draw_gradient_rect(img, hs + 18, hs - 8, 5, 28, Color(0.85, 0.82, 0.78), Color(0.70, 0.68, 0.65))
		_draw_rect(img, hs + 20, hs - 8, 2, 28, Color(0.92, 0.90, 0.88))  # Tranchant brillant
		_draw_rect(img, hs + 16, hs - 12, 9, 6, Color(0.85, 0.25, 0.25))  # Tsuba (garde vermilion)
		_draw_rect(img, hs + 17, hs + 16, 7, 4, Color(0.35, 0.25, 0.18))  # Tsuka (poignée en bois)
		# Same (tressage de la poignée)
		for ty in [hs + 17, hs + 19]:
			_draw_rect(img, hs + 17, ty, 7, 1, Color(0.25, 0.15, 0.10))
		_draw_rect(img, hs + 19, hs + 18, 3, 3, Color(0.85, 0.25, 0.25))  # Kashira (pommeau vermilion)
		# Menuki (décorations sur la poignée)
		_draw_circle(img, hs + 20, hs + 18, 1, Color(0.95, 0.85, 0.20))
		_draw_rect(img, hs + 21, hs - 10, 1, 8, Color(1.0, 1.0, 1.0))
		_draw_rect(img, hs + 23, hs, 1, 6, Color(1.0, 1.0, 1.0))
	elif enemy_type == "tengu":
		# Éventail plié (tessen)
		_draw_rect(img, hs + 18, hs - 4, 4, 20, Color(0.35, 0.25, 0.18))
		_draw_rect(img, hs + 16, hs - 2, 2, 16, Color(0.85, 0.65, 0.15))
		_draw_rect(img, hs + 20, hs - 2, 2, 16, Color(0.85, 0.65, 0.15))
		# Plumes de l'éventail
		for fy in [hs - 2, hs + 6, hs + 14]:
			_draw_rect(img, hs + 22, fy, 3, 2, Color(0.45, 0.35, 0.25))
	elif enemy_type == "kappa":
		# Éventail plié
		_draw_rect(img, hs + 18, hs - 4, 4, 20, Color(0.35, 0.25, 0.18))
		_draw_rect(img, hs + 16, hs - 2, 2, 16, Color(0.30, 0.60, 0.70))
		_draw_rect(img, hs + 20, hs - 2, 2, 16, Color(0.30, 0.60, 0.70))
	elif enemy_type == "ninja":
		# Kunai dans la main
		_draw_rect(img, hs + 18, hs - 2, 3, 16, Color(0.55, 0.55, 0.60))
		_draw_triangle(img, hs + 18, hs - 6, hs + 21, hs - 10, hs + 21, hs - 2, Color(0.55, 0.55, 0.60))
		# Shuriken (étoile)
		_draw_rect(img, hs + 22, hs + 8, 8, 2, Color(0.55, 0.55, 0.60))
		_draw_rect(img, hs + 24, hs + 4, 2, 8, Color(0.55, 0.55, 0.60))
	elif enemy_type == "monk":
		# Bâton de moine (shakujō)
		_draw_rect(img, hs + 18, hs - 8, 4, 28, Color(0.55, 0.45, 0.30))
		_draw_rect(img, hs + 19, hs - 8, 2, 28, Color(0.65, 0.55, 0.40))
		# Anneaux métalliques
		for ry in [hs - 4, hs + 4, hs + 12]:
			_draw_circle(img, hs + 20, ry, 3, Color(0.75, 0.72, 0.68))
			_draw_circle(img, hs + 20, ry, 2, Color(0.55, 0.55, 0.60))
		# Garde ornementée
		_draw_rect(img, hs + 16, hs + 18, 14, 5, Color(0.48, 0.42, 0.28))
		_draw_rect(img, hs + 18, hs + 16, 10, 3, Color(0.62, 0.55, 0.38))
		# Bouclier à gauche (swordsman uniquement)
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

# --- HÉROS JAPONAIS 64x64 ---
func _generate_hero_sprite(img: Image, size: int, rng: RandomNumberGenerator) -> void:
	var s: int = size
	var hs: int = s / 2
	
	# Ombre elliptique
	for x in range(s):
		for y in range(s):
			var ox: float = (x - hs) / 16.0
			var oy: float = (y - (s - 4)) / 4.0
			var dist: float = ox * ox + oy * oy
			if dist <= 1.0:
				var alpha: float = 0.30 * (1.0 - dist * 0.5)
				img.set_pixel(x, y, Color(0, 0, 0, alpha))
	
	# Corps (kimono sombre avec armure)
	_draw_shaded_circle(img, hs, hs + 8, 18, Color(0.35, 0.25, 0.18), Vector2(-0.3, -0.8))
	_add_noise_to_rect(img, hs - 10, hs - 2, 20, 20, Color(0.35, 0.25, 0.18), 0.04, rng)
	
	# Armure de poitrine (do) - lames laquées noires
	_draw_shaded_circle(img, hs, hs + 2, 14, Color(0.12, 0.08, 0.06), Vector2(-0.5, -0.8))
	_draw_gradient_rect(img, hs - 8, hs - 2, 16, 16, Color(0.15, 0.10, 0.08), Color(0.08, 0.05, 0.04))
	_add_bevel(img, hs - 8, hs - 2, 16, 16, Color(0.20, 0.12, 0.08), Color(0.06, 0.04, 0.02))
	# Bordures vermilion
	_draw_rect(img, hs - 8, hs - 2, 16, 2, Color(0.85, 0.25, 0.25))
	_draw_rect(img, hs - 8, hs + 14, 16, 2, Color(0.85, 0.25, 0.25))
	# Mon (crest) au centre
	_draw_circle(img, hs, hs + 6, 4, Color(0.85, 0.25, 0.25))
	_draw_circle(img, hs, hs + 6, 2, Color(0.95, 0.85, 0.20))
	
	# Épaulettes (sode)
	_draw_gradient_rect(img, hs - 16, hs - 4, 8, 12, Color(0.12, 0.08, 0.06), Color(0.08, 0.05, 0.04))
	_draw_rect(img, hs - 16, hs - 4, 8, 2, Color(0.85, 0.25, 0.25))
	_draw_gradient_rect(img, hs + 8, hs - 4, 8, 12, Color(0.12, 0.08, 0.06), Color(0.08, 0.05, 0.04))
	_draw_rect(img, hs + 8, hs - 4, 8, 2, Color(0.85, 0.25, 0.25))
	
	# Tête (peau japonaise)
	_draw_shaded_circle(img, hs, hs - 12, 14, Color(0.90, 0.75, 0.60), Vector2(-0.3, -0.8))
	_draw_shaded_circle(img, hs - 3, hs - 15, 10, Color(0.92, 0.78, 0.65), Vector2(-0.3, -0.8))
	
	# Casque samurai (kabuto) avec crête
	_draw_gradient_rect(img, hs - 12, hs - 24, 24, 12, Color(0.12, 0.08, 0.06), Color(0.08, 0.05, 0.04))
	_draw_rect(img, hs - 2, hs - 30, 4, 8, Color(0.85, 0.25, 0.25))  # Crête vermilion
	# Visière (mempo)
	_draw_gradient_rect(img, hs - 10, hs - 16, 20, 6, Color(0.15, 0.10, 0.08), Color(0.10, 0.06, 0.04))
	# Chignon samurai
	_draw_circle(img, hs + 8, hs - 20, 4, Color(0.06, 0.04, 0.02))
	
	# Cheveux noirs visibles sous le casque
	_draw_shaded_circle(img, hs, hs - 18, 12, Color(0.06, 0.04, 0.02), Vector2(-0.3, -0.8))
	_draw_circle(img, hs + 6, hs - 22, 5, Color(0.06, 0.04, 0.02))  # Chignon
	
	# Yeux détaillés
	_draw_shaded_circle(img, hs - 5, hs - 14, 4, Color(0.95, 0.95, 0.95), Vector2(-0.2, -0.2))
	_draw_shaded_circle(img, hs + 5, hs - 14, 4, Color(0.95, 0.95, 0.95), Vector2(-0.2, -0.2))
	_draw_circle(img, hs - 5, hs - 14, 3, Color(0.12, 0.08, 0.06))
	_draw_circle(img, hs + 5, hs - 14, 3, Color(0.12, 0.08, 0.06))
	_draw_rect(img, hs - 6, hs - 15, 2, 2, Color(0.05, 0.05, 0.05))
	_draw_rect(img, hs + 4, hs - 15, 2, 2, Color(0.05, 0.05, 0.05))
	_draw_rect(img, hs - 4, hs - 15, 1, 1, Color(1, 1, 1))
	_draw_rect(img, hs + 5, hs - 15, 1, 1, Color(1, 1, 1))
	
	# Bouche
	_draw_rect(img, hs - 3, hs - 6, 6, 2, Color(0.12, 0.08, 0.06))
	_draw_rect(img, hs - 2, hs - 6, 4, 1, Color(0.75, 0.25, 0.20))
	
	# Obi (ceinture vermilion)
	_draw_rect(img, hs - 8, hs + 10, 16, 4, Color(0.85, 0.25, 0.25))
	
	# Hakama (pantalon)
	_draw_gradient_rect(img, hs - 8, hs + 16, 6, 10, Color(0.35, 0.25, 0.18), Color(0.22, 0.12, 0.08))
	_draw_gradient_rect(img, hs + 2, hs + 16, 6, 10, Color(0.35, 0.25, 0.18), Color(0.22, 0.12, 0.08))
	
	# Tabi (chaussettes)
	_draw_rect(img, hs - 8, hs + 24, 6, 3, Color(0.90, 0.90, 0.88))
	_draw_rect(img, hs + 2, hs + 24, 6, 3, Color(0.90, 0.90, 0.88))
	
	# Katana à droite
	_draw_gradient_rect(img, hs + 18, hs - 8, 5, 28, Color(0.85, 0.82, 0.78), Color(0.70, 0.68, 0.65))
	_draw_rect(img, hs + 20, hs - 8, 2, 28, Color(0.92, 0.90, 0.88))
	_draw_rect(img, hs + 16, hs - 12, 9, 6, Color(0.85, 0.25, 0.25))
	_draw_rect(img, hs + 17, hs + 16, 7, 4, Color(0.35, 0.25, 0.18))
	for ty in [hs + 17, hs + 19]:
		_draw_rect(img, hs + 17, ty, 7, 1, Color(0.25, 0.15, 0.10))
	_draw_rect(img, hs + 19, hs + 18, 3, 3, Color(0.85, 0.25, 0.25))
	_draw_circle(img, hs + 20, hs + 18, 1, Color(0.95, 0.85, 0.20))
	_draw_rect(img, hs + 21, hs - 10, 1, 8, Color(1.0, 1.0, 1.0))
	_draw_rect(img, hs + 23, hs, 1, 6, Color(1.0, 1.0, 1.0))

# ============================================================
# FIN GÉNÉRATEUR DE SPRITES
# ============================================================
