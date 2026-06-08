extends CanvasLayer

class_name LLMConfigScreen

signal closed

var _config: LLMConfig
var _panel: Panel
var _endpoint_input: LineEdit
var _key_input: LineEdit
var _model_input: LineEdit
var _toggle: CheckBox
var _status_label: Label


func _ready() -> void:
	layer = 200
	_config = LLMConfig.new()
	_config.load_from_disk()
	_build_ui()


func _build_ui() -> void:
	var screen_size := get_viewport().get_visible_rect().size
	var margin := screen_size.x * 0.05
	var panel_w := screen_size.x - margin * 2
	var panel_h := 460.0
	var panel_x := margin
	var panel_y := (screen_size.y - panel_h) / 2

	_panel = Panel.new()
	_panel.position = Vector2(0, 0)
	_panel.size = screen_size
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.75)
	_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(_panel)

	var inner_panel := Panel.new()
	inner_panel.position = Vector2(panel_x, panel_y)
	inner_panel.size = Vector2(panel_w, panel_h)
	var ip_style := StyleBoxFlat.new()
	ip_style.bg_color = Color(0.08, 0.06, 0.12, 0.95)
	ip_style.corner_radius_top_left = 12
	ip_style.corner_radius_top_right = 12
	ip_style.corner_radius_bottom_left = 12
	ip_style.corner_radius_bottom_right = 12
	inner_panel.add_theme_stylebox_override("panel", ip_style)
	_panel.add_child(inner_panel)

	var y := 20.0
	var label := Label.new()
	label.text = "Configuration IA (LLM)"
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	label.position = Vector2(20, y)
	label.size = Vector2(panel_w - 40, 36)
	inner_panel.add_child(label)
	y += 50

	# Embedded server status bar
	var embedded_label := Label.new()
	var status := "Serveur embarqué : non disponible (desktop)"
	if LlamaServer and LlamaServer.is_server_ready():
		status = "Serveur embarqué : ACTIF (port %d)" % LlamaServer.SERVER_PORT
	elif OS.get_name() == "Android":
		status = "Serveur embarqué : démarrage en cours..."
	embedded_label.text = status
	embedded_label.add_theme_font_size_override("font_size", 11)
	embedded_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	embedded_label.position = Vector2(20, y)
	embedded_label.size = Vector2(panel_w - 40, 20)
	inner_panel.add_child(embedded_label)
	y += 24

	var fields := [
		["Endpoint API", "endpoint", _config.endpoint],
		["Clé API", "key", _config.api_key],
		["Modèle", "model", _config.model],
	]

	for f in fields:
		var f_label := Label.new()
		f_label.text = f[0]
		f_label.add_theme_font_size_override("font_size", 14)
		f_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		f_label.position = Vector2(20, y)
		f_label.size = Vector2(panel_w - 40, 24)
		inner_panel.add_child(f_label)
		y += 26

		var input := LineEdit.new()
		input.position = Vector2(20, y)
		input.size = Vector2(panel_w - 40, 36)
		input.text = f[2]
		if f[1] == "key":
			input.secret = true
			_key_input = input
		elif f[1] == "endpoint":
			_endpoint_input = input
		elif f[1] == "model":
			_model_input = input
		inner_panel.add_child(input)
		y += 50

	var toggle_label := Label.new()
	toggle_label.text = "Activer l'IA"
	toggle_label.add_theme_font_size_override("font_size", 14)
	toggle_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	toggle_label.position = Vector2(20, y)
	toggle_label.size = Vector2(120, 30)
	inner_panel.add_child(toggle_label)

	_toggle = CheckBox.new()
	_toggle.position = Vector2(150, y + 2)
	_toggle.size = Vector2(30, 30)
	_toggle.button_pressed = _config.enabled
	inner_panel.add_child(_toggle)
	y += 50

	_status_label = Label.new()
	_status_label.position = Vector2(20, y)
	_status_label.size = Vector2(panel_w - 40, 24)
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	inner_panel.add_child(_status_label)
	y += 30

	var btn_save := Button.new()
	btn_save.text = "Sauvegarder"
	btn_save.position = Vector2(20, y)
	btn_save.size = Vector2(panel_w / 2 - 30, 44)
	btn_save.pressed.connect(_on_save)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.2, 0.35, 0.2)
	bs.corner_radius_top_left = 6
	bs.corner_radius_top_right = 6
	bs.corner_radius_bottom_left = 6
	bs.corner_radius_bottom_right = 6
	btn_save.add_theme_stylebox_override("normal", bs)
	inner_panel.add_child(btn_save)

	var btn_close := Button.new()
	btn_close.text = "Fermer"
	btn_close.position = Vector2(panel_w / 2 + 10, y)
	btn_close.size = Vector2(panel_w / 2 - 30, 44)
	btn_close.pressed.connect(_on_close)
	var bs2 := StyleBoxFlat.new()
	bs2.bg_color = Color(0.3, 0.2, 0.2)
	bs2.corner_radius_top_left = 6
	bs2.corner_radius_top_right = 6
	bs2.corner_radius_bottom_left = 6
	bs2.corner_radius_bottom_right = 6
	btn_close.add_theme_stylebox_override("normal", bs2)
	inner_panel.add_child(btn_close)


func _on_save() -> void:
	_config.endpoint = _endpoint_input.text.strip_edges()
	_config.api_key = _key_input.text.strip_edges()
	_config.model = _model_input.text.strip_edges()
	_config.enabled = _toggle.button_pressed
	_config.save()
	_status_label.text = "✓ Configuration sauvegardée !"
	_status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))


func _on_close() -> void:
	closed.emit()
	queue_free()
