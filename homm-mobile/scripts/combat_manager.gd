extends CanvasLayer

signal combat_ended(won: bool)
signal combat_victory(gold_reward: int, xp_reward: int)
signal combat_defeat()
signal combat_fled()

# ============================================
# COMBAT MANAGER - Gestionnaire de combat
# ============================================

# Références UI
var _combat_panel: Panel
var _action_bar: HBoxContainer
var _hero_container: HBoxContainer
var _enemy_container: HBoxContainer
var _hero_info_label: Label
var _enemy_info_label: Label
var _combat_log: RichTextLabel
var _combat_title: Label
var _round_label: Label
var _turn_label: Label
var _result_panel: Panel
var _result_title: Label
var _result_desc: RichTextLabel
var _result_button: Button
var _enemy_target_label: Label
var _spell_panel: Panel
var _spell_buttons: Array = []
var _defense_indicator: Label
var _rage_indicator: Label

# Données de combat
var _hero_units: Array = []
var _enemy_units: Array = []
var _current_turn: int = 0  # 0 = héros, 1 = ennemi
var _round_count: int = 1
var _in_combat: bool = false
var _selected_target: int = -1
var _hero_defending: bool = false  # Bonus de défense actif
var _hero_attack_buff: bool = false  # Bonus d'attaque actif

# Données du joueur
var _hero_data: Dictionary = {}
var _enemy_data: Dictionary = {}
var _enemy_index: int = -1

# Styles enrichis
var _top_bar_style: StyleBoxFlat
var _action_btn_normal: StyleBoxFlat
var _action_btn_hover: StyleBoxFlat
var _action_btn_pressed: StyleBoxFlat
var _result_panel_style: StyleBoxFlat
var _result_btn_normal: StyleBoxFlat
var _result_btn_hover: StyleBoxFlat
var _result_btn_pressed: StyleBoxFlat

# Couleurs
const COLOR_HERO := Color(0.12, 0.32, 0.55)
const COLOR_ENEMY := Color(0.55, 0.12, 0.12)
const COLOR_NEUTRAL := Color(0.35, 0.30, 0.25)
const COLOR_GOLD := Color(0.85, 0.70, 0.20)
const COLOR_RED := Color(0.75, 0.18, 0.12)
const COLOR_GREEN := Color(0.18, 0.65, 0.22)

func _ready() -> void:
	visible = false
	_setup_ui()
	_setup_styles()

func _setup_styles() -> void:
	# Style barre supérieure
	_top_bar_style = StyleBoxFlat.new()
	_top_bar_style.bg_color = Color(0.08, 0.06, 0.04)
	_top_bar_style.border_color = Color(0.45, 0.35, 0.20)
	_top_bar_style.border_width_bottom = 3
	_top_bar_style.corner_radius_bottom_left = 12
	_top_bar_style.corner_radius_bottom_right = 12
	_top_bar_style.shadow_color = Color(0, 0, 0, 0.50)
	_top_bar_style.shadow_size = 8
	_top_bar_style.shadow_offset = Vector2(0, 4)

	# Style bouton action normal
	_action_btn_normal = StyleBoxFlat.new()
	_action_btn_normal.bg_color = Color(0.18, 0.14, 0.10)
	_action_btn_normal.border_color = Color(0.50, 0.40, 0.25)
	_action_btn_normal.border_width_left = 2
	_action_btn_normal.border_width_right = 2
	_action_btn_normal.border_width_top = 2
	_action_btn_normal.border_width_bottom = 4
	_action_btn_normal.corner_radius_top_left = 10
	_action_btn_normal.corner_radius_top_right = 10
	_action_btn_normal.corner_radius_bottom_left = 10
	_action_btn_normal.corner_radius_bottom_right = 10
	_action_btn_normal.shadow_color = Color(0, 0, 0, 0.40)
	_action_btn_normal.shadow_size = 6
	_action_btn_normal.shadow_offset = Vector2(0, 3)

	# Style bouton action hover
	_action_btn_hover = StyleBoxFlat.new()
	_action_btn_hover.bg_color = Color(0.28, 0.22, 0.14)
	_action_btn_hover.border_color = Color(0.70, 0.55, 0.30)
	_action_btn_hover.border_width_left = 2
	_action_btn_hover.border_width_right = 2
	_action_btn_hover.border_width_top = 2
	_action_btn_hover.border_width_bottom = 4
	_action_btn_hover.corner_radius_top_left = 10
	_action_btn_hover.corner_radius_top_right = 10
	_action_btn_hover.corner_radius_bottom_left = 10
	_action_btn_hover.corner_radius_bottom_right = 10
	_action_btn_hover.shadow_color = Color(0, 0, 0, 0.50)
	_action_btn_hover.shadow_size = 8
	_action_btn_hover.shadow_offset = Vector2(0, 4)

	# Style bouton action pressed
	_action_btn_pressed = StyleBoxFlat.new()
	_action_btn_pressed.bg_color = Color(0.12, 0.10, 0.06)
	_action_btn_pressed.border_color = Color(0.40, 0.32, 0.18)
	_action_btn_pressed.border_width_left = 2
	_action_btn_pressed.border_width_right = 2
	_action_btn_pressed.border_width_top = 4
	_action_btn_pressed.border_width_bottom = 2
	_action_btn_pressed.corner_radius_top_left = 10
	_action_btn_pressed.corner_radius_top_right = 10
	_action_btn_pressed.corner_radius_bottom_left = 10
	_action_btn_pressed.corner_radius_bottom_right = 10
	_action_btn_pressed.shadow_color = Color(0, 0, 0, 0.20)
	_action_btn_pressed.shadow_size = 3
	_action_btn_pressed.shadow_offset = Vector2(0, 1)

	# Style panel résultat
	_result_panel_style = StyleBoxFlat.new()
	_result_panel_style.bg_color = Color(0.06, 0.05, 0.04, 0.95)
	_result_panel_style.border_color = Color(0.55, 0.42, 0.22)
	_result_panel_style.border_width_left = 3
	_result_panel_style.border_width_right = 3
	_result_panel_style.border_width_top = 3
	_result_panel_style.border_width_bottom = 3
	_result_panel_style.corner_radius_top_left = 20
	_result_panel_style.corner_radius_top_right = 20
	_result_panel_style.corner_radius_bottom_left = 20
	_result_panel_style.corner_radius_bottom_right = 20
	_result_panel_style.shadow_color = Color(0, 0, 0, 0.60)
	_result_panel_style.shadow_size = 20
	_result_panel_style.shadow_offset = Vector2(0, 8)

	# Style bouton résultat normal
	_result_btn_normal = StyleBoxFlat.new()
	_result_btn_normal.bg_color = Color(0.18, 0.50, 0.20)
	_result_btn_normal.border_color = Color(0.30, 0.70, 0.32)
	_result_btn_normal.border_width_left = 2
	_result_btn_normal.border_width_right = 2
	_result_btn_normal.border_width_top = 2
	_result_btn_normal.border_width_bottom = 4
	_result_btn_normal.corner_radius_top_left = 12
	_result_btn_normal.corner_radius_top_right = 12
	_result_btn_normal.corner_radius_bottom_left = 12
	_result_btn_normal.corner_radius_bottom_right = 12
	_result_btn_normal.shadow_color = Color(0, 0, 0, 0.40)
	_result_btn_normal.shadow_size = 6
	_result_btn_normal.shadow_offset = Vector2(0, 3)

	# Style bouton résultat hover
	_result_btn_hover = StyleBoxFlat.new()
	_result_btn_hover.bg_color = Color(0.25, 0.65, 0.28)
	_result_btn_hover.border_color = Color(0.40, 0.85, 0.42)
	_result_btn_hover.border_width_left = 2
	_result_btn_hover.border_width_right = 2
	_result_btn_hover.border_width_top = 2
	_result_btn_hover.border_width_bottom = 4
	_result_btn_hover.corner_radius_top_left = 12
	_result_btn_hover.corner_radius_top_right = 12
	_result_btn_hover.corner_radius_bottom_left = 12
	_result_btn_hover.corner_radius_bottom_right = 12
	_result_btn_hover.shadow_color = Color(0, 0, 0, 0.50)
	_result_btn_hover.shadow_size = 8
	_result_btn_hover.shadow_offset = Vector2(0, 4)

	# Style bouton résultat pressed
	_result_btn_pressed = StyleBoxFlat.new()
	_result_btn_pressed.bg_color = Color(0.12, 0.35, 0.14)
	_result_btn_pressed.border_color = Color(0.25, 0.55, 0.28)
	_result_btn_pressed.border_width_left = 2
	_result_btn_pressed.border_width_right = 2
	_result_btn_pressed.border_width_top = 2
	_result_btn_pressed.border_width_bottom = 2
	_result_btn_pressed.corner_radius_top_left = 12
	_result_btn_pressed.corner_radius_top_right = 12
	_result_btn_pressed.corner_radius_bottom_left = 12
	_result_btn_pressed.corner_radius_bottom_right = 12
	_result_btn_pressed.shadow_color = Color(0, 0, 0, 0.20)
	_result_btn_pressed.shadow_size = 3
	_result_btn_pressed.shadow_offset = Vector2(0, 1)

func _setup_ui() -> void:
	# Panel principal de combat
	_combat_panel = Panel.new()
	_combat_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_combat_panel.visible = false
	add_child(_combat_panel)

	# Style du panel principal
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.05, 0.04, 0.92)
	panel_style.border_color = Color(0.35, 0.28, 0.18)
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.shadow_color = Color(0, 0, 0, 0.70)
	panel_style.shadow_size = 24
	panel_style.shadow_offset = Vector2(0, 10)
	_combat_panel.add_theme_stylebox_override("panel", panel_style)

	# Barre supérieure avec style enrichi
	var top_bar = Panel.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, 56)
	top_bar.add_theme_stylebox_override("panel", _top_bar_style)
	_combat_panel.add_child(top_bar)

	# Titre du combat
	_combat_title = Label.new()
	_combat_title.text = "COMBAT"
	_combat_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_combat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combat_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combat_title.custom_minimum_size = Vector2(0, 56)
	var title_font = _combat_title.get_theme_font("")
	if title_font:
		_combat_title.add_theme_font_size_override("font_size", 28)
	_combat_title.add_theme_color_override("font_color", COLOR_GOLD)
	_combat_panel.add_child(_combat_title)

	# Labels de round et tour
	_round_label = Label.new()
	_round_label.position = Vector2(20, 16)
	_round_label.text = "Round 1"
	_round_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_combat_panel.add_child(_round_label)

	_turn_label = Label.new()
	_turn_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_turn_label.position = Vector2(-20, 16)
	_turn_label.text = "Votre tour"
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_turn_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.9))
	_combat_panel.add_child(_turn_label)

	# Label cible ennemie
	_enemy_target_label = Label.new()
	_enemy_target_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_enemy_target_label.position = Vector2(0, 70)
	_enemy_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_target_label.add_theme_color_override("font_color", Color(0.85, 0.3, 0.3))
	_enemy_target_label.add_theme_font_size_override("font_size", 14)
	_combat_panel.add_child(_enemy_target_label)

	# Indicateur de défense
	_defense_indicator = Label.new()
	_defense_indicator.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_defense_indicator.position = Vector2(40, -80)
	_defense_indicator.text = "🛡️ DÉFENSE ACTIVE"
	_defense_indicator.add_theme_color_override("font_color", Color(0.3, 0.8, 0.9))
	_defense_indicator.add_theme_font_size_override("font_size", 16)
	_defense_indicator.visible = false
	_combat_panel.add_child(_defense_indicator)

	# Indicateur de rage
	_rage_indicator = Label.new()
	_rage_indicator.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_rage_indicator.position = Vector2(40, -60)
	_rage_indicator.text = "⚔️ FUREUR ACTIVE"
	_rage_indicator.add_theme_color_override("font_color", Color(0.95, 0.5, 0.1))
	_rage_indicator.add_theme_font_size_override("font_size", 16)
	_rage_indicator.visible = false
	_combat_panel.add_child(_rage_indicator)

	# Conteneur héros (gauche)
	_hero_container = HBoxContainer.new()
	_hero_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hero_container.position = Vector2(40, -180)
	_hero_container.custom_minimum_size = Vector2(400, 140)
	_hero_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_combat_panel.add_child(_hero_container)

	# Conteneur ennemi (droite)
	_enemy_container = HBoxContainer.new()
	_enemy_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_enemy_container.position = Vector2(-440, -180)
	_enemy_container.custom_minimum_size = Vector2(400, 140)
	_enemy_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_combat_panel.add_child(_enemy_container)

	# Infos héros
	_hero_info_label = Label.new()
	_hero_info_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hero_info_label.position = Vector2(40, -40)
	_hero_info_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.9))
	_combat_panel.add_child(_hero_info_label)

	# Infos ennemi
	_enemy_info_label = Label.new()
	_enemy_info_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_enemy_info_label.position = Vector2(-200, -40)
	_enemy_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_enemy_info_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	_combat_panel.add_child(_enemy_info_label)

	# Barre d'actions
	_action_bar = HBoxContainer.new()
	_action_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_action_bar.position = Vector2(-200, -60)
	_action_bar.custom_minimum_size = Vector2(400, 50)
	_action_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_action_bar.add_theme_constant_override("separation", 20)
	_combat_panel.add_child(_action_bar)

	# Boutons d'action
	_add_action_button("Attaquer", _on_attack_pressed, Color(0.75, 0.18, 0.12))
	_add_action_button("Defendre", _on_defend_pressed, Color(0.18, 0.55, 0.65))
	_add_action_button("Magie", _on_magic_pressed, Color(0.55, 0.18, 0.65))
	_add_action_button("Fuir", _on_flee_pressed, Color(0.35, 0.30, 0.25))

	# Log de combat
	_combat_log = RichTextLabel.new()
	_combat_log.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_combat_log.position = Vector2(40, 90)
	_combat_log.size = Vector2(-80, 120)
	_combat_log.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_combat_log.bbcode_enabled = true
	_combat_log.add_theme_color_override("default_color", Color(0.8, 0.8, 0.8))
	_combat_log.add_theme_font_size_override("normal_font_size", 12)
	_combat_panel.add_child(_combat_log)

	# Panel de résultat
	_result_panel = Panel.new()
	_result_panel.set_anchors_preset(Control.PRESET_CENTER)
	_result_panel.custom_minimum_size = Vector2(400, 280)
	_result_panel.visible = false
	_result_panel.add_theme_stylebox_override("panel", _result_panel_style)
	_combat_panel.add_child(_result_panel)

	# Panel de sélection de sorts
	_spell_panel = Panel.new()
	_spell_panel.set_anchors_preset(Control.PRESET_CENTER)
	_spell_panel.custom_minimum_size = Vector2(380, 200)
	_spell_panel.visible = false
	var spell_style = StyleBoxFlat.new()
	spell_style.bg_color = Color(0.08, 0.06, 0.04, 0.95)
	spell_style.border_color = Color(0.55, 0.18, 0.65)
	spell_style.border_width_left = 3
	spell_style.border_width_right = 3
	spell_style.border_width_top = 3
	spell_style.border_width_bottom = 3
	spell_style.corner_radius_top_left = 12
	spell_style.corner_radius_top_right = 12
	spell_style.corner_radius_bottom_left = 12
	spell_style.corner_radius_bottom_right = 12
	_spell_panel.add_theme_stylebox_override("panel", spell_style)
	_combat_panel.add_child(_spell_panel)

	# Titre panel sorts
	var spell_title = Label.new()
	spell_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	spell_title.position = Vector2(0, 15)
	spell_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spell_title.text = "Choisir un sort"
	spell_title.add_theme_font_size_override("font_size", 20)
	spell_title.add_theme_color_override("font_color", Color(0.85, 0.5, 0.95))
	_spell_panel.add_child(spell_title)

	# Boutons de sorts
	var spell_container = HBoxContainer.new()
	spell_container.set_anchors_preset(Control.PRESET_CENTER)
	spell_container.position = Vector2(-150, 50)
	spell_container.custom_minimum_size = Vector2(300, 100)
	spell_container.alignment = BoxContainer.ALIGNMENT_CENTER
	spell_container.add_theme_constant_override("separation", 15)
	_spell_panel.add_child(spell_container)

	_add_spell_button("Boule de Feu", Color(0.95, 0.35, 0.15), "fireball", spell_container)
	_add_spell_button("Éclair", Color(0.65, 0.75, 0.95), "lightning", spell_container)
	_add_spell_button("Soin", Color(0.25, 0.75, 0.35), "heal", spell_container)
	_add_spell_button("Fureur", Color(0.95, 0.65, 0.15), "rage", spell_container)

	# Titre résultat
	_result_title = Label.new()
	_result_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_result_title.position = Vector2(0, 30)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title.add_theme_font_size_override("font_size", 32)
	_result_panel.add_child(_result_title)

	# Description résultat
	_result_desc = RichTextLabel.new()
	_result_desc.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_result_desc.position = Vector2(30, 90)
	_result_desc.size = Vector2(-60, 100)
	_result_desc.bbcode_enabled = true
	_result_desc.add_theme_color_override("default_color", Color(0.8, 0.8, 0.8))
	_result_desc.add_theme_font_size_override("normal_font_size", 14)
	_result_panel.add_child(_result_desc)

	# Bouton résultat
	_result_button = Button.new()
	_result_button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_result_button.position = Vector2(60, -70)
	_result_button.size = Vector2(-120, 0)
	_result_button.custom_minimum_size = Vector2(0, 48)
	_result_button.text = "Continuer"
	_result_button.add_theme_font_size_override("font_size", 18)
	_result_button.add_theme_color_override("font_color", Color(0.9, 0.95, 0.9))
	_result_button.add_theme_stylebox_override("normal", _result_btn_normal)
	_result_button.add_theme_stylebox_override("hover", _result_btn_hover)
	_result_button.add_theme_stylebox_override("pressed", _result_btn_pressed)
	_result_button.pressed.connect(_on_result_button_pressed)
	_result_panel.add_child(_result_button)

func _add_action_button(text: String, callback: Callable, accent_color: Color) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(100, 44)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.9))
	btn.add_theme_color_override("font_pressed_color", Color(0.8, 0.8, 0.75))
	btn.add_theme_stylebox_override("normal", _action_btn_normal)
	btn.add_theme_stylebox_override("hover", _action_btn_hover)
	btn.add_theme_stylebox_override("pressed", _action_btn_pressed)
	btn.pressed.connect(callback)
	_action_bar.add_child(btn)

func _add_spell_button(text: String, accent_color: Color, spell_type: String, container: HBoxContainer) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(70, 80)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
	var spell_normal = StyleBoxFlat.new()
	spell_normal.bg_color = accent_color.darkened(0.4)
	spell_normal.border_color = accent_color
	spell_normal.border_width_left = 2
	spell_normal.border_width_right = 2
	spell_normal.border_width_top = 2
	spell_normal.border_width_bottom = 2
	spell_normal.corner_radius_top_left = 8
	spell_normal.corner_radius_top_right = 8
	spell_normal.corner_radius_bottom_left = 8
	spell_normal.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", spell_normal)
	btn.pressed.connect(func(): _on_spell_selected(spell_type))
	container.add_child(btn)
	_spell_buttons.append(btn)

# ============================================
# COMBAT LOGIC
# ============================================

func start_combat(hero_data: Dictionary, enemy_data: Dictionary, enemy_index: int = -1) -> void:
	_hero_data = hero_data
	_enemy_data = enemy_data
	_enemy_index = enemy_index
	_hero_units = hero_data.get("units", []).duplicate(true)
	_enemy_units = enemy_data.get("units", []).duplicate(true)
	_current_turn = 0
	_round_count = 1
	_in_combat = true
	_selected_target = -1
	_hero_defending = false  # Reset defense bonus
	_hero_attack_buff = false  # Reset attack bonus

	_combat_title.text = "COMBAT"
	_round_label.text = "Round 1"
	_turn_label.text = "Votre tour"
	_combat_log.clear()
	_result_panel.visible = false
	_action_bar.visible = true
	_defense_indicator.visible = false
	_rage_indicator.visible = false

	_update_unit_displays()
	_log_message("[color=#6ec3e0]Le combat commence![/color]")
	_log_message("Vous affrontez " + enemy_data.get("name", "l'ennemi"))

	visible = true
	_combat_panel.visible = true
	_combat_panel.modulate.a = 0.0
	_combat_panel.scale = Vector2(0.9, 0.9)

	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_combat_panel, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(_combat_panel, "scale", Vector2(1.0, 1.0), 0.4)

func _end_combat(won: bool) -> void:
	_in_combat = false
	_action_bar.visible = false

	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_combat_panel, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(_combat_panel, "scale", Vector2(0.9, 0.9), 0.5)
	tween.tween_callback(func():
		_result_panel.visible = true
		_result_panel.modulate.a = 0.0
		_result_panel.scale = Vector2(0.8, 0.8)

		if won:
			_result_title.text = "VICTOIRE!"
			_result_title.add_theme_color_override("font_color", COLOR_GREEN)
			_result_desc.text = "[center]Vous avez vaincu " + _enemy_data.get("name", "l'ennemi") + "![/center]\n\n"
			_result_desc.text += "[color=#d4a017]Experience gagnee:[/color] " + str(_enemy_data.get("xp", 100)) + "\n"
			_result_desc.text += "[color=#d4a017]Or gagne:[/color] " + str(_enemy_data.get("gold", 50))
		else:
			_result_title.text = "DEFAITE"
			_result_title.add_theme_color_override("font_color", COLOR_RED)
			_result_desc.text = "[center]Vous avez ete vaincu...[/center]\n\n"
			_result_desc.text += "Vos troupes ont ete repoussees."

		var result_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		result_tween.tween_property(_result_panel, "modulate:a", 1.0, 0.5)
		result_tween.parallel().tween_property(_result_panel, "scale", Vector2(1.0, 1.0), 0.5)
	)

func _on_result_button_pressed() -> void:
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_combat_panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		visible = false
		_combat_panel.visible = false
		combat_ended.emit(_result_title.text == "VICTOIRE!")
	)

func _on_attack_pressed() -> void:
	if not _in_combat or _current_turn != 0:
		return
	_process_hero_attack()

func _on_defend_pressed() -> void:
	if not _in_combat or _current_turn != 0:
		return
	_hero_defending = true
	_defense_indicator.visible = true
	_log_message("[color=#5a9eb8]Vous prenez une position defensive. (+50% defense)[/color]")
	_process_next_turn()

func _on_magic_pressed() -> void:
	if not _in_combat or _current_turn != 0:
		return
	_spell_panel.visible = true
	_spell_panel.modulate.a = 0.0
	_spell_panel.scale = Vector2(0.8, 0.8)
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_spell_panel, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(_spell_panel, "scale", Vector2(1.0, 1.0), 0.3)

func _on_spell_selected(spell_type: String) -> void:
	_spell_panel.visible = false
	_cast_spell(spell_type)

func _cast_spell(spell_type: String) -> void:
	match spell_type:
		"fireball":
			_cast_fireball()
		"lightning":
			_cast_lightning()
		"heal":
			_cast_heal()
		"rage":
			_cast_rage()

func _cast_fireball() -> void:
	if _enemy_units.is_empty():
		_end_combat(true)
		return
	
	var attacker = _hero_units[0] if not _hero_units.is_empty() else {"magic": 15, "name": "Heros"}
	var base_damage = attacker.get("magic", 15)
	
	_log_message("[color=#ff5522]Vous lancez Boule de Feu![/color]")
	_flash_screen(Color(1.0, 0.4, 0.1), 0.2)
	
	var total_damage = 0
	for i in range(_enemy_units.size() - 1, -1, -1):
		var target = _enemy_units[i]
		var magic_res = target.get("magic_res", 2)
		var damage = max(1, int((base_damage - magic_res) * randf_range(0.9, 1.1)))
		target["hp"] = max(0, target["hp"] - damage)
		total_damage += damage
		
		_show_damage_number(_enemy_container.get_child(i), damage, true)
		
		if target["hp"] <= 0:
			_log_message("[color=#ff4444]" + target.get("name", "Ennemi") + " est brûlé vif![/color]")
			_enemy_units.remove_at(i)
	
	_log_message("[color=#ff5522]Boule de Feu inflige [color=#ff4444]" + str(total_damage) + "[/color] dégâts totaux![/color]")
	_shake_panel(5.0, 0.3)
	_update_unit_displays()
	
	if _enemy_units.is_empty():
		_end_combat(true)
		return
	
	_process_next_turn()

func _cast_lightning() -> void:
	if _enemy_units.is_empty():
		_end_combat(true)
		return
	
	var target_idx = _selected_target
	if target_idx < 0 or target_idx >= _enemy_units.size() or _enemy_units[target_idx].get("hp", 0) <= 0:
		target_idx = _find_first_alive_unit(_enemy_units)
		if target_idx < 0:
			_end_combat(true)
			return
	
	var attacker = _hero_units[0] if not _hero_units.is_empty() else {"magic": 20, "name": "Heros"}
	var target = _enemy_units[target_idx]
	var base_damage = attacker.get("magic", 20)
	var magic_res = target.get("magic_res", 2)
	var damage = max(1, int((base_damage - magic_res) * randf_range(1.2, 1.5)))  # Higher damage
	
	target["hp"] = max(0, target["hp"] - damage)
	
	_log_message("[color=#5588ff]Vous lancez Éclair sur " + target.get("name", "Ennemi") + "![/color]")
	_log_message("[color=#5588ff]Éclair inflige [color=#ff4444]" + str(damage) + "[/color] dégâts![/color]")
	_flash_screen(Color(0.6, 0.8, 1.0), 0.15)
	_shake_panel(6.0, 0.25)
	_animate_unit_card_hit(_enemy_container.get_child(target_idx))
	_show_damage_number(_enemy_container.get_child(target_idx), damage, true)
	_animate_attack_projectile(_hero_container.get_child(0), _enemy_container.get_child(target_idx), true)
	_update_unit_displays()
	
	if target["hp"] <= 0:
		_log_message("[color=#ff4444]" + target.get("name", "Ennemi") + " est électrocuté![/color]")
		_enemy_units.remove_at(target_idx)
		
		if _enemy_units.is_empty():
			_end_combat(true)
			return
	
	_process_next_turn()

func _cast_heal() -> void:
	if _hero_units.is_empty():
		_end_combat(false)
		return
	
	var healer = _hero_units[0] if not _hero_units.is_empty() else {"magic": 12, "name": "Heros"}
	var heal_power = healer.get("magic", 12)
	
	_log_message("[color=#22aa44]Vous lancez Soin![/color]")
	_flash_screen(Color(0.3, 0.9, 0.4), 0.2)
	
	var total_healed = 0
	for i in range(_hero_units.size()):
		var unit = _hero_units[i]
		var max_hp = unit.get("max_hp", unit.get("hp", 1))
		var current_hp = unit.get("hp", 0)
		var heal_amount = min(heal_power, max_hp - current_hp)
		unit["hp"] = min(max_hp, current_hp + heal_amount)
		total_healed += heal_amount
		
		if heal_amount > 0:
			_show_heal_number(_hero_container.get_child(i), heal_amount)
	
	_log_message("[color=#22aa44]Soin restaure [color=#44ff66]" + str(total_healed) + "[/color] PV![/color]")
	_update_unit_displays()
	_process_next_turn()

func _cast_rage() -> void:
	_hero_attack_buff = true
	_rage_indicator.visible = true
	_log_message("[color=#ff8822]Vous lancez Fureur! (+50% attaque)[/color]")
	_flash_screen(Color(1.0, 0.5, 0.1), 0.2)
	_process_next_turn()

func _on_flee_pressed() -> void:
	if not _in_combat or _current_turn != 0:
		return
	_log_message("[color=#8a8a8a]Vous tentez de fuir...[/color]")
	if randf() < 0.5:
		_log_message("[color=#5a9eb8]Fuite reussie![/color]")
		_end_combat(false)
	else:
		_log_message("[color=#c85a5a]Fuite echouee![/color]")
		_process_next_turn()

func _process_hero_attack(is_magic: bool = false) -> void:
	if _enemy_units.is_empty():
		_end_combat(true)
		return

	var target_idx = _selected_target
	if target_idx < 0 or target_idx >= _enemy_units.size() or _enemy_units[target_idx].get("hp", 0) <= 0:
		target_idx = _find_first_alive_unit(_enemy_units)
		if target_idx < 0:
			_end_combat(true)
			return

	var attacker = _hero_units[0] if not _hero_units.is_empty() else {"attack": 10, "name": "Heros"}
	var target = _enemy_units[target_idx]

	var damage = _calculate_damage(attacker, target, is_magic)
	target["hp"] = max(0, target["hp"] - damage)

	_log_message("[color=#6ec3e0]" + attacker.get("name", "Heros") + "[/color] inflige [color=#ff4444]" + str(damage) + "[/color] degats a " + target.get("name", "Ennemi"))

	_flash_screen(Color(1.0, 0.3, 0.2), 0.1)
	_shake_panel(4.0, 0.2)
	_animate_unit_card_hit(_enemy_container.get_child(target_idx))
	_show_damage_number(_enemy_container.get_child(target_idx), damage, is_magic)
	_animate_attack_projectile(_hero_container.get_child(0), _enemy_container.get_child(target_idx), is_magic)

	if target["hp"] <= 0:
		_log_message("[color=#ff4444]" + target.get("name", "Ennemi") + " est vaincu![/color]")
		_enemy_units.remove_at(target_idx)

		if _enemy_units.is_empty():
			_end_combat(true)
			return

	# Update HP bars after damage
	_update_unit_displays()

	_process_next_turn()

func _process_enemy_turn() -> void:
	if not _in_combat:
		return

	if _hero_units.is_empty():
		_end_combat(false)
		return

	var attacker = _enemy_units[0] if not _enemy_units.is_empty() else {"attack": 8, "name": "Ennemi"}
	var target_idx = _select_enemy_target()
	if target_idx < 0:
		_end_combat(false)
		return

	var target = _hero_units[target_idx]
	var damage = _calculate_damage(attacker, target, false)
	target["hp"] = max(0, target["hp"] - damage)

	_log_message("[color=#ff6666]" + attacker.get("name", "Ennemi") + "[/color] inflige [color=#ff4444]" + str(damage) + "[/color] degats a " + target.get("name", "Heros"))

	_flash_screen(Color(0.8, 0.1, 0.1), 0.1)
	_shake_panel(6.0, 0.25)
	_animate_unit_card_hit(_hero_container.get_child(target_idx))
	_show_damage_number(_hero_container.get_child(target_idx), damage, false)
	_animate_attack_projectile(_enemy_container.get_child(0), _hero_container.get_child(target_idx), false)
	
	# Update HP bars after damage
	_update_unit_displays()

	if target["hp"] <= 0:
		_log_message("[color=#ff4444]" + target.get("name", "Heros") + " est vaincu![/color]")
		_hero_units.remove_at(target_idx)

		if _hero_units.is_empty():
			_end_combat(false)
			return

	_process_next_turn()

func _select_enemy_target() -> int:
	if _hero_units.is_empty():
		return -1
	
	# Different AI strategies based on random chance
	var strategy = randf()
	
	if strategy < 0.4:
		# Target weakest unit (lowest HP)
		var weakest_idx = -1
		var lowest_hp = 999999
		for i in range(_hero_units.size()):
			if _hero_units[i].get("hp", 0) > 0 and _hero_units[i].get("hp", 0) < lowest_hp:
				lowest_hp = _hero_units[i].get("hp", 0)
				weakest_idx = i
		return weakest_idx if weakest_idx >= 0 else _find_first_alive_unit(_hero_units)
	elif strategy < 0.7:
		# Target strongest unit (highest attack)
		var strongest_idx = -1
		var highest_attack = -1
		for i in range(_hero_units.size()):
			if _hero_units[i].get("hp", 0) > 0 and _hero_units[i].get("attack", 0) > highest_attack:
				highest_attack = _hero_units[i].get("attack", 0)
				strongest_idx = i
		return strongest_idx if strongest_idx >= 0 else _find_first_alive_unit(_hero_units)
	else:
		# Random target
		var alive_units = []
		for i in range(_hero_units.size()):
			if _hero_units[i].get("hp", 0) > 0:
				alive_units.append(i)
		if alive_units.is_empty():
			return -1
		return alive_units[randi() % alive_units.size()]

func _calculate_damage(attacker: Dictionary, target: Dictionary, is_magic: bool) -> int:
	var base_dmg = attacker.get("attack", 10)
	var defense = target.get("defense", 5)
	var random_factor = randf_range(0.8, 1.2)

	if is_magic:
		base_dmg = attacker.get("magic", 10)
		defense = target.get("magic_res", 2)
	
	# Apply defense bonus if hero is defending
	if _hero_defending and not is_magic:
		defense = int(defense * 1.5)  # 50% defense bonus
	
	# Apply attack buff if hero has rage
	if _hero_attack_buff and not is_magic:
		base_dmg = int(base_dmg * 1.5)  # 50% attack bonus

	var damage = max(1, int((base_dmg - defense) * random_factor))
	return damage

func _find_first_alive_unit(units: Array) -> int:
	for i in range(units.size()):
		if units[i].get("hp", 0) > 0:
			return i
	return -1

func _process_next_turn() -> void:
	_current_turn = 1 - _current_turn

	if _current_turn == 0:
		_round_count += 1
		_round_label.text = "Round " + str(_round_count)
		_turn_label.text = "Votre tour"
		_turn_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.9))
		_action_bar.visible = true
		_hero_defending = false  # Reset defense bonus at start of hero turn
		_hero_attack_buff = false  # Reset attack buff at start of hero turn
		_defense_indicator.visible = false  # Hide defense indicator
		_rage_indicator.visible = false  # Hide rage indicator
	else:
		_turn_label.text = "Tour ennemi"
		_turn_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		_action_bar.visible = false
		await get_tree().create_timer(1.0).timeout
		_process_enemy_turn()

# ============================================
# UI UPDATES
# ============================================

func _update_unit_displays() -> void:
	# Clear containers
	for child in _hero_container.get_children():
		child.queue_free()
	for child in _enemy_container.get_children():
		child.queue_free()

	# Add hero units
	for unit in _hero_units:
		var card = _create_unit_card(unit, true)
		_hero_container.add_child(card)

	# Add enemy units
	for i in range(_enemy_units.size()):
		var unit = _enemy_units[i]
		var card = _create_unit_card(unit, false)
		card.gui_input.connect(func(event): _on_enemy_card_clicked(event, i))
		_enemy_container.add_child(card)

	# Update info labels
	var hero_total_hp = 0
	var hero_max_hp = 0
	for unit in _hero_units:
		hero_total_hp += unit.get("hp", 0)
		hero_max_hp += unit.get("max_hp", unit.get("hp", 1))

	var enemy_total_hp = 0
	var enemy_max_hp = 0
	for unit in _enemy_units:
		enemy_total_hp += unit.get("hp", 0)
		enemy_max_hp += unit.get("max_hp", unit.get("hp", 1))

	_hero_info_label.text = "HP: " + str(hero_total_hp) + "/" + str(hero_max_hp)
	_enemy_info_label.text = "HP: " + str(enemy_total_hp) + "/" + str(enemy_max_hp)

func _create_unit_card(unit: Dictionary, is_hero: bool) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(90, 120)
	card.size = Vector2(90, 120)

	var style = StyleBoxFlat.new()
	if is_hero:
		style.bg_color = Color(0.10, 0.22, 0.35)
		style.border_color = Color(0.25, 0.50, 0.75)
	else:
		style.bg_color = Color(0.35, 0.12, 0.12)
		style.border_color = Color(0.75, 0.30, 0.25)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", style)

	# Unit icon placeholder
	var icon = ColorRect.new()
	icon.position = Vector2(15, 10)
	icon.size = Vector2(60, 60)
	icon.color = Color(0.5, 0.5, 0.5, 0.3)
	card.add_child(icon)

	# Unit name
	var name_label = Label.new()
	name_label.position = Vector2(5, 75)
	name_label.size = Vector2(80, 20)
	name_label.text = unit.get("name", "Unit")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
	card.add_child(name_label)

	# HP bar background
	var hp_bg = ColorRect.new()
	hp_bg.position = Vector2(10, 100)
	hp_bg.size = Vector2(70, 10)
	hp_bg.color = Color(0.2, 0.2, 0.2)
	card.add_child(hp_bg)

	# HP bar fill
	var max_hp = unit.get("max_hp", unit.get("hp", 1))
	var hp_ratio = float(unit.get("hp", 0)) / max_hp if max_hp > 0 else 0
	var hp_fill = ColorRect.new()
	hp_fill.position = Vector2(10, 100)
	hp_fill.size = Vector2(70 * hp_ratio, 10)
	if hp_ratio > 0.5:
		hp_fill.color = Color(0.2, 0.7, 0.3)
	elif hp_ratio > 0.25:
		hp_fill.color = Color(0.85, 0.65, 0.15)
	else:
		hp_fill.color = Color(0.8, 0.15, 0.15)
	card.add_child(hp_fill)

	# HP text
	var hp_label = Label.new()
	hp_label.position = Vector2(5, 112)
	hp_label.size = Vector2(80, 16)
	hp_label.text = str(unit.get("hp", 0)) + "/" + str(max_hp)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 9)
	card.add_child(hp_label)

	return card

func _on_enemy_card_clicked(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _current_turn == 0 and _in_combat:
			_selected_target = index
			_enemy_target_label.text = "Cible: " + _enemy_units[index].get("name", "Ennemi")
			for i in range(_enemy_container.get_child_count()):
				var card = _enemy_container.get_child(i)
				var style = card.get_theme_stylebox("panel").duplicate()
				if i == index:
					style.border_color = Color(0.95, 0.85, 0.25)
					style.border_width_left = 3
					style.border_width_right = 3
					style.border_width_top = 3
					style.border_width_bottom = 3
				else:
					style.border_color = Color(0.75, 0.30, 0.25)
					style.border_width_left = 2
					style.border_width_right = 2
					style.border_width_top = 2
					style.border_width_bottom = 2
				card.add_theme_stylebox_override("panel", style)

func _log_message(msg: String) -> void:
	_combat_log.text += msg + "\n"
	_combat_log.scroll_to_line(_combat_log.get_line_count())

# ============================================
# VISUAL EFFECTS
# ============================================

func _flash_screen(color: Color, duration: float = 0.15) -> void:
	var flash = ColorRect.new()
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(flash)

	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, duration).from(0.6)
	tween.tween_callback(flash.queue_free)

func _shake_panel(intensity: float, duration: float) -> void:
	var tween = create_tween()
	var original_pos = _combat_panel.position
	var steps = int(duration * 20)
	for i in range(steps):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(_combat_panel, "position", original_pos + offset, 0.03)
	tween.tween_property(_combat_panel, "position", original_pos, 0.05)

func _animate_unit_card_hit(card: Control) -> void:
	if not card:
		return
	var tween = create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate", Color(1.0, 0.3, 0.3), 0.05)
	tween.tween_property(card, "modulate", Color(1.0, 1.0, 1.0), 0.2)

func _show_damage_number(card: Control, damage: int, is_magic: bool) -> void:
	if not card:
		return
	
	var damage_label = Label.new()
	damage_label.text = "-" + str(damage)
	damage_label.add_theme_font_size_override("font_size", 24)
	if is_magic:
		damage_label.add_theme_color_override("font_color", Color(0.6, 0.4, 1.0))
	else:
		damage_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	
	var card_global_pos = card.global_position
	damage_label.position = card_global_pos + Vector2(card.size.x / 2 - 20, card.size.y / 2 - 20)
	add_child(damage_label)
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(damage_label, "position:y", damage_label.position.y - 50, 0.6)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(damage_label.queue_free)

func _show_heal_number(card: Control, heal_amount: int) -> void:
	if not card:
		return
	
	var heal_label = Label.new()
	heal_label.text = "+" + str(heal_amount)
	heal_label.add_theme_font_size_override("font_size", 24)
	heal_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	
	var card_global_pos = card.global_position
	heal_label.position = card_global_pos + Vector2(card.size.x / 2 - 20, card.size.y / 2 - 20)
	add_child(heal_label)
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(heal_label, "position:y", heal_label.position.y - 50, 0.6)
	tween.parallel().tween_property(heal_label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(heal_label.queue_free)

func _animate_attack_projectile(attacker: Control, target: Control, is_magic: bool) -> void:
	if not attacker or not target:
		return
	
	var projectile = ColorRect.new()
	projectile.size = Vector2(8, 8)
	if is_magic:
		projectile.color = Color(0.6, 0.4, 1.0)
	else:
		projectile.color = Color(1.0, 0.6, 0.2)
	
	var start_pos = attacker.global_position + attacker.size / 2
	var end_pos = target.global_position + target.size / 2
	projectile.position = start_pos
	add_child(projectile)
	
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(projectile, "position", end_pos, 0.2)
	tween.tween_callback(projectile.queue_free)
