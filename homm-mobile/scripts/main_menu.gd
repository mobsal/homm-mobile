extends Control

# ============================================
# MAIN MENU - Écran titre du jeu
# ============================================

var _title_label: Label
var _subtitle_label: Label
var _btn_new_game: Button
var _btn_continue: Button
var _btn_quit: Button

# Couleurs
const COLOR_GOLD := Color(0.95, 0.80, 0.20)
const COLOR_DARK_BG := Color(0.04, 0.03, 0.02)
const COLOR_ACCENT := Color(0.35, 0.28, 0.18)

func _ready() -> void:
	# Fond sombre
	var bg = ColorRect.new()
	bg.color = COLOR_DARK_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Ajouter un pattern de tuiles procédural en fond
	_create_background_tiles(bg)

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

	# Styles des boutons
	var btn_normal = _create_btn_style(Color(0.12, 0.10, 0.06), Color(0.50, 0.40, 0.25))
	var btn_hover = _create_btn_style(Color(0.22, 0.18, 0.10), Color(0.75, 0.60, 0.35))
	var btn_pressed = _create_btn_style(Color(0.08, 0.06, 0.03), Color(0.35, 0.28, 0.15))

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
	btn_container.add_child(_btn_continue)

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
	btn_container.add_child(_btn_quit)

	# Version
	var version_label = Label.new()
	version_label.text = "v0.1"
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

func _create_btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 4
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0, 0, 0, 0.40)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style

func _create_background_tiles(parent: Control) -> void:
	# Créer un pattern de tuiles simple en fond
	var tile_colors = [
		Color(0.08, 0.12, 0.06),  # Vert foncé
		Color(0.10, 0.14, 0.08),  # Vert
		Color(0.12, 0.16, 0.10),  # Vert clair
		Color(0.09, 0.11, 0.07),  # Vert très foncé
	]
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var screen_size = get_viewport_rect().size
	var tile_size = 48
	for x in range(0, int(screen_size.x), tile_size):
		for y in range(0, int(screen_size.y), tile_size):
			var tile = ColorRect.new()
			tile.position = Vector2(x, y)
			tile.size = Vector2(tile_size, tile_size)
			tile.color = tile_colors[rng.randi_range(0, tile_colors.size() - 1)]
			tile.color.a = 0.3
			parent.add_child(tile)

func _has_save_file() -> bool:
	return FileAccess.file_exists("user://save_game.json")

func _on_new_game_pressed() -> void:
	# Supprimer la sauvegarde existante
	if FileAccess.file_exists("user://save_game.json"):
		var da = DirAccess.open("user://")
		if da:
			da.remove("save_game.json")
	
	GameData.should_load_save = false
	
	# Transition vers le jeu
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/tile_map_world.tscn")
	)

func _on_continue_pressed() -> void:
	GameData.should_load_save = true
	
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/tile_map_world.tscn")
	)

func _on_quit_pressed() -> void:
	get_tree().quit()
