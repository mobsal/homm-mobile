extends CanvasLayer

var gbi_texture: TextureRect
var gbt_label: Label
var dbi_label: Label
var dbt_button: Button

var bt1_label: Label
var bt2_color: ColorRect
var bt3_label: Label
var bt4_label: Label
var creature_bar: HBoxContainer

var h_btns: Array[Button] = []
var v_btns: Array[Button] = []
var gh_btn: Button
var dh_btn: Button
var gm_btn: Button
var dm_btn: Button

var selection_panel: Panel

# Resource / info labels (referenced from tile_map_world.gd)
var label_gold: Label
var label_wood: Label
var label_ore: Label
var label_mp: Label
var label_date: Label

var _in_submenu: bool = false

signal hero_selected(id: int)
signal city_selected(id: int)
signal gh_pressed()
signal dh_pressed()
signal gm_pressed()
signal dm_pressed()
signal dbt_pressed()

func _ready() -> void:
	_build_layout()
	GameData.selection_changed.connect(_on_selection_changed)
	GameData.turn_ended.connect(_on_turn_ended)
	_clear_all()

func _build_layout():
	var vp_size = get_viewport().get_visible_rect().size
	var W = vp_size.x
	var H = vp_size.y

	_ensure_font_support()

	# --- Top bar (180px) ---
	var top = Control.new()
	top.name = "TopBar"
	top.size = Vector2(W, 180)
	top.position = Vector2(0, 0)
	add_child(top)

	# Hero buttons column (left)
	var hero_col = VBoxContainer.new()
	hero_col.name = "HeroButtons"
	hero_col.position = Vector2(4, 4)
	hero_col.size = Vector2(160, 172)
	hero_col.add_theme_constant_override("separation", 4)
	top.add_child(hero_col)
	for i in range(3):
		var btn = _make_top_btn("H%d" % (i+1))
		btn.custom_minimum_size = Vector2(160, 54)
		btn.pressed.connect(_on_hero_btn_pressed.bind(i))
		hero_col.add_child(btn)
		h_btns.append(btn)

	# City buttons column (right) — individual buttons, absolute right edge
	var v_col_w = 200.0
	for i in range(3):
		var btn = _make_top_btn("V%d" % (i+1))
		btn.name = "V%d" % (i+1)
		btn.custom_minimum_size = Vector2(v_col_w, 54)
		btn.pressed.connect(_on_city_btn_pressed.bind(i))
		top.add_child(btn)
		btn.position = Vector2(W - v_col_w, 4 + i * 58)
		btn.size = Vector2(v_col_w, 54)
		v_btns.append(btn)

	# Center buttons (GH, DH, GM, DM) — 2x2 grid, centered
	var center = Control.new()
	center.name = "CenterButtons"
	center.size = Vector2(400, 172)
	center.position = Vector2(W / 2 - 200, 4)
	top.add_child(center)

	gh_btn = _make_top_btn("GH")
	gh_btn.custom_minimum_size = Vector2(190, 80)
	gh_btn.position = Vector2(4, 4)
	gh_btn.pressed.connect(func(): gh_pressed.emit())
	center.add_child(gh_btn)

	dh_btn = _make_top_btn("DH")
	dh_btn.custom_minimum_size = Vector2(190, 80)
	dh_btn.position = Vector2(206, 4)
	dh_btn.pressed.connect(func(): dh_pressed.emit())
	center.add_child(dh_btn)

	gm_btn = _make_top_btn("GM")
	gm_btn.custom_minimum_size = Vector2(190, 80)
	gm_btn.position = Vector2(4, 90)
	gm_btn.pressed.connect(func(): gm_pressed.emit())
	center.add_child(gm_btn)

	dm_btn = _make_top_btn("DM")
	dm_btn.custom_minimum_size = Vector2(190, 80)
	dm_btn.position = Vector2(206, 90)
	dm_btn.pressed.connect(func(): dm_pressed.emit())
	center.add_child(dm_btn)

	# --- Selection Panel (shows when something selected) ---
	selection_panel = Panel.new()
	selection_panel.name = "SelectionPanel"
	selection_panel.size = Vector2(W, 280)
	selection_panel.position = Vector2(0, 180)
	selection_panel.visible = false
	var sp_style = StyleBoxFlat.new()
	sp_style.bg_color = Color(0.10, 0.08, 0.06, 0.95)
	sp_style.border_color = Color(0.85, 0.25, 0.25)
	sp_style.border_width_top = 2
	sp_style.border_width_bottom = 2
	selection_panel.add_theme_stylebox_override("panel", sp_style)
	add_child(selection_panel)

	# Top row: BT1 (name) | BT2 (color) | BT3 (res amount)
	var top_row = HBoxContainer.new()
	top_row.name = "TopRow"
	top_row.position = Vector2(10, 8)
	top_row.size = Vector2(W - 20, 30)
	top_row.add_theme_constant_override("separation", 12)
	selection_panel.add_child(top_row)

	bt1_label = Label.new()
	bt1_label.name = "BT1"
	bt1_label.add_theme_font_size_override("font_size", 14)
	bt1_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.75))
	bt1_label.custom_minimum_size = Vector2(200, 30)
	top_row.add_child(bt1_label)

	bt2_color = ColorRect.new()
	bt2_color.name = "BT2"
	bt2_color.custom_minimum_size = Vector2(24, 24)
	bt2_color.color = Color.TRANSPARENT
	top_row.add_child(bt2_color)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	bt3_label = Label.new()
	bt3_label.name = "BT3"
	bt3_label.add_theme_font_size_override("font_size", 14)
	bt3_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	bt3_label.custom_minimum_size = Vector2(100, 30)
	bt3_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_row.add_child(bt3_label)

	# Creature bar: C1-C7
	creature_bar = HBoxContainer.new()
	creature_bar.name = "CreatureBar"
	creature_bar.position = Vector2(10, 44)
	creature_bar.size = Vector2(W - 20, 160)
	creature_bar.add_theme_constant_override("separation", 6)
	selection_panel.add_child(creature_bar)
	for i in range(7):
		var btn = Button.new()
		btn.name = "C%d" % (i+1)
		btn.custom_minimum_size = Vector2((W - 76) / 7, 160)
		btn.visible = false
		var cs = StyleBoxFlat.new()
		cs.bg_color = Color(0.15, 0.10, 0.08)
		cs.border_color = Color(0.45, 0.38, 0.22)
		cs.border_width_left = 1
		cs.border_width_right = 1
		cs.border_width_top = 1
		cs.border_width_bottom = 2
		cs.corner_radius_top_left = 4
		cs.corner_radius_top_right = 4
		cs.corner_radius_bottom_left = 4
		cs.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", cs)
		var ch = cs.duplicate()
		ch.bg_color = Color(0.25, 0.18, 0.10)
		btn.add_theme_stylebox_override("hover", ch)
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8))
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		creature_bar.add_child(btn)

	# Bottom row: BT4 (res type)
	var bottom_row = HBoxContainer.new()
	bottom_row.name = "BottomRow"
	bottom_row.position = Vector2(10, 212)
	bottom_row.size = Vector2(W - 20, 24)
	bottom_row.add_theme_constant_override("separation", 12)
	bottom_row.alignment = BoxContainer.ALIGNMENT_END
	selection_panel.add_child(bottom_row)

	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(spacer2)

	bt4_label = Label.new()
	bt4_label.name = "BT4"
	bt4_label.add_theme_font_size_override("font_size", 13)
	bt4_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	bt4_label.custom_minimum_size = Vector2(200, 24)
	bt4_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bottom_row.add_child(bt4_label)

	# --- Minimap container (hidden by default, toggled via GH) ---
	_minimap_container = Control.new()
	_minimap_container.name = "MinimapContainer"
	_minimap_container.size = Vector2(200, 136)
	_minimap_container.position = Vector2(W / 2 - 100, 464)
	_minimap_container.visible = false
	var mc_style = StyleBoxFlat.new()
	mc_style.bg_color = Color(0.15, 0.10, 0.05, 0.95)
	mc_style.border_color = Color(0.72, 0.52, 0.25)
	mc_style.border_width_left = 3
	mc_style.border_width_right = 3
	mc_style.border_width_top = 3
	mc_style.border_width_bottom = 3
	mc_style.corner_radius_top_left = 6
	mc_style.corner_radius_top_right = 6
	mc_style.corner_radius_bottom_left = 6
	mc_style.corner_radius_bottom_right = 6
	var mc_panel = Panel.new()
	mc_panel.size = Vector2(200, 136)
	mc_panel.add_theme_stylebox_override("panel", mc_style)
	_minimap_container.add_child(mc_panel)
	add_child(_minimap_container)

	# --- Bottom bar (180px) ---
	var bot = Control.new()
	bot.name = "BottomBar"
	bot.size = Vector2(W, 180)
	bot.position = Vector2(0, H - 180)
	add_child(bot)

	# Left block: GBI + GBT
	# Center info: resources + MP + date
	var info_center = VBoxContainer.new()
	info_center.name = "InfoCenter"
	info_center.position = Vector2(190, 4)
	info_center.size = Vector2(W - 370, 172)
	info_center.add_theme_constant_override("separation", 4)
	bot.add_child(info_center)

	var res_hbox = HBoxContainer.new()
	res_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	res_hbox.add_theme_constant_override("separation", 20)
	info_center.add_child(res_hbox)

	var gold_lbl = Label.new()
	gold_lbl.text = "🪙"
	gold_lbl.add_theme_font_size_override("font_size", 16)
	res_hbox.add_child(gold_lbl)
	label_gold = Label.new()
	label_gold.add_theme_font_size_override("font_size", 16)
	label_gold.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	res_hbox.add_child(label_gold)

	var wood_lbl = Label.new()
	wood_lbl.text = "🪵"
	wood_lbl.add_theme_font_size_override("font_size", 16)
	res_hbox.add_child(wood_lbl)
	label_wood = Label.new()
	label_wood.add_theme_font_size_override("font_size", 16)
	label_wood.add_theme_color_override("font_color", Color(0.6, 0.9, 0.4))
	res_hbox.add_child(label_wood)

	var ore_lbl = Label.new()
	ore_lbl.text = "⛏"
	ore_lbl.add_theme_font_size_override("font_size", 16)
	res_hbox.add_child(ore_lbl)
	label_ore = Label.new()
	label_ore.add_theme_font_size_override("font_size", 16)
	label_ore.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	res_hbox.add_child(label_ore)

	label_mp = Label.new()
	label_mp.add_theme_font_size_override("font_size", 14)
	label_mp.add_theme_color_override("font_color", Color(0.35, 0.65, 0.45))
	label_mp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_center.add_child(label_mp)

	label_date = Label.new()
	label_date.add_theme_font_size_override("font_size", 12)
	label_date.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	label_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_center.add_child(label_date)

	var left_block = Control.new()
	left_block.name = "LeftBlock"
	left_block.size = Vector2(180, 176)
	left_block.position = Vector2(4, 2)
	bot.add_child(left_block)

	gbi_texture = TextureRect.new()
	gbi_texture.name = "GBI"
	gbi_texture.size = Vector2(80, 80)
	gbi_texture.position = Vector2(4, 4)
	gbi_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var gbi_bg = StyleBoxFlat.new()
	gbi_bg.bg_color = Color(0.15, 0.10, 0.08)
	gbi_bg.border_color = Color(0.45, 0.38, 0.22)
	gbi_bg.border_width_left = 1
	gbi_bg.border_width_right = 1
	gbi_bg.border_width_top = 1
	gbi_bg.border_width_bottom = 2
	gbi_bg.corner_radius_top_left = 4
	gbi_bg.corner_radius_top_right = 4
	gbi_bg.corner_radius_bottom_left = 4
	gbi_bg.corner_radius_bottom_right = 4
	gbi_texture.add_theme_stylebox_override("normal", gbi_bg)
	left_block.add_child(gbi_texture)

	gbt_label = Label.new()
	gbt_label.name = "GBT"
	gbt_label.size = Vector2(170, 86)
	gbt_label.position = Vector2(4, 88)
	gbt_label.add_theme_font_size_override("font_size", 12)
	gbt_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
	gbt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_block.add_child(gbt_label)

	# Right block: DBI + DBT
	var right_block = Control.new()
	right_block.name = "RightBlock"
	right_block.size = Vector2(180, 176)
	right_block.position = Vector2(W - 184, 2)
	bot.add_child(right_block)

	dbi_label = Label.new()
	dbi_label.name = "DBI"
	dbi_label.size = Vector2(172, 40)
	dbi_label.position = Vector2(4, 4)
	dbi_label.add_theme_font_size_override("font_size", 16)
	dbi_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	dbi_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_block.add_child(dbi_label)

	dbt_button = Button.new()
	dbt_button.name = "DBT"
	dbt_button.size = Vector2(172, 126)
	dbt_button.position = Vector2(4, 46)
	dbt_button.text = "Terminer le tour"
	dbt_button.add_theme_font_size_override("font_size", 13)
	dbt_button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	var dbt_normal = StyleBoxFlat.new()
	dbt_normal.bg_color = Color(0.65, 0.20, 0.20)
	dbt_normal.border_color = Color(0.90, 0.35, 0.35)
	dbt_normal.border_width_left = 2
	dbt_normal.border_width_right = 2
	dbt_normal.border_width_top = 2
	dbt_normal.border_width_bottom = 2
	dbt_normal.corner_radius_top_left = 6
	dbt_normal.corner_radius_top_right = 6
	dbt_normal.corner_radius_bottom_left = 6
	dbt_normal.corner_radius_bottom_right = 6
	dbt_button.add_theme_stylebox_override("normal", dbt_normal)
	var dbt_hover = dbt_normal.duplicate()
	dbt_hover.bg_color = Color(0.80, 0.30, 0.30)
	dbt_button.add_theme_stylebox_override("hover", dbt_hover)
	dbt_button.pressed.connect(func(): dbt_pressed.emit())
	right_block.add_child(dbt_button)

func _ensure_font_support():
	if not Label.new().has_theme_font_size_override("font_size"):
		pass

func _make_top_btn(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.95, 0.85, 0.75))
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.10, 0.06)
	s.border_color = Color(0.45, 0.38, 0.22)
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 3
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", s)
	var sh = s.duplicate()
	sh.bg_color = Color(0.22, 0.18, 0.10)
	btn.add_theme_stylebox_override("hover", sh)
	return btn

func _on_selection_changed(mode, id, tile):
	_in_submenu = false
	selection_panel.visible = false

	var gd = GameData
	match mode:
		GameData.SelectionMode.HERO:
			if id >= 0 and id < gd.heroes.size():
				var h = gd.heroes[id]
				gbi_texture.texture = h.sprite
				gbt_label.text = h.name
				_fill_top_bar(h.owner, "", "", "")
				dbi_label.text = "⏳ %d/%d" % [GameData.turn_counter, GameData.max_turns]
				dbt_button.text = "Terminer le tour"

		GameData.SelectionMode.CITY:
			if id >= 0 and id < gd.cities.size():
				var c = gd.cities[id]
				gbi_texture.texture = null
				gbt_label.text = c.name
				_fill_top_bar(c.owner, c.resource_type, str(c.resource_per_day), "")
				dbi_label.text = "⏳ %d/%d" % [GameData.turn_counter, GameData.max_turns]
				dbt_button.text = "Terminer le tour"

		GameData.SelectionMode.BUILDING:
			if id >= 0 and id < gd.buildings.size():
				var b = gd.buildings[id]
				gbi_texture.texture = null
				gbt_label.text = b.type
				_fill_top_bar(b.owner, b.resource_type, str(b.resource_per_day), "")
				_clear_creature_bar()
				selection_panel.visible = true
				dbi_label.text = "⏳ %d/%d" % [GameData.turn_counter, GameData.max_turns]
				dbt_button.text = "Terminer le tour"

		GameData.SelectionMode.TILE:
			var creature = _creature_on_tile(tile)
			if creature:
				gbi_texture.texture = null
				gbt_label.text = "%s x%d" % [creature.name, creature.amount]
			else:
				gbi_texture.texture = null
				gbt_label.text = ""
			_clear_top_bar()
			_clear_creature_bar()
			selection_panel.visible = false
			dbi_label.text = "⏳ %d/%d" % [GameData.turn_counter, GameData.max_turns]
			dbt_button.text = "Terminer le tour"

		_:
			_clear_all()

func _on_turn_ended(counter, max):
	dbi_label.text = "⏳ %d/%d" % [counter, max]
	dbt_button.text = "Terminer le tour"
	_in_submenu = false

func enter_submenu(menu_title: String):
	_in_submenu = true
	dbi_label.text = "←"
	dbt_button.text = "Sortir"
	gbi_texture.texture = null
	gbt_label.text = menu_title
	selection_panel.visible = false

func exit_submenu():
	_in_submenu = false
	dbi_label.text = "⏳ %d/%d" % [GameData.turn_counter, GameData.max_turns]
	dbt_button.text = "Terminer le tour"

func _fill_top_bar(owner_id: int, res_type: String, res_amount: String, extra: String):
	bt1_label.text = "Joueur %d" % owner_id
	if owner_id >= 0 and owner_id < GameData.player_colors.size():
		bt2_color.color = GameData.player_colors[owner_id]
	else:
		bt2_color.color = Color.TRANSPARENT
	bt3_label.text = res_amount
	bt4_label.text = res_type

func _clear_top_bar():
	bt1_label.text = ""
	bt2_color.color = Color.TRANSPARENT
	bt3_label.text = ""
	bt4_label.text = ""

func _fill_creature_bar(creatures: Array):
	_clear_creature_bar()
	var slots = creature_bar.get_children()
	for i in range(min(creatures.size(), slots.size())):
		var c = creatures[i]
		var btn = slots[i] as Button
		btn.visible = true
		btn.text = "%s\nx%d" % [c.name, c.amount]

func _clear_creature_bar():
	for child in creature_bar.get_children():
		child.visible = false

func _clear_all():
	gbi_texture.texture = null
	gbt_label.text = ""
	_clear_top_bar()
	_clear_creature_bar()
	selection_panel.visible = false
	dbi_label.text = "⏳ 0/%d" % GameData.max_turns
	dbt_button.text = "Terminer le tour"

func _creature_on_tile(pos: Vector2i) -> GameData.Creature:
	if GameData.creatures_on_tile.has(pos):
		return GameData.creatures_on_tile[pos]
	return null

func _on_hero_btn_pressed(id: int):
	if id < GameData.heroes.size():
		GameData.set_selection(GameData.SelectionMode.HERO, id, GameData.heroes[id].position)

func _on_city_btn_pressed(id: int):
	if id < GameData.cities.size():
		GameData.set_selection(GameData.SelectionMode.CITY, id, GameData.cities[id].position)

func get_gold_label() -> Label:
	return label_gold

func get_wood_label() -> Label:
	return label_wood

func get_ore_label() -> Label:
	return label_ore

func get_date_label() -> Label:
	return label_date

func get_minimap_container() -> Control:
	return _minimap_container

var _minimap_container: Control
