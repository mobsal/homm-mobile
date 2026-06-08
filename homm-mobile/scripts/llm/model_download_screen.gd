extends CanvasLayer
## ModelDownloadScreen — Full-screen overlay shown during model download.
##
## Displays a progress bar, download speed, and status messages.
## Automatically shown by main_menu.gd when LlamaServer starts downloading.
## Dismisses itself when download completes or fails.

class_name ModelDownloadScreen

signal download_done(success: bool)
signal retry_requested

const COLOR_GOLD := Color(0.95, 0.80, 0.20)
const COLOR_DARK := Color(0.06, 0.04, 0.02, 0.96)

var _panel: Panel
var _title_label: Label
var _status_label: Label
var _progress_bar: ProgressBar
var _progress_label: Label
var _speed_label: Label
var _detail_label: Label
var _retry_btn: Button
var _skip_btn: Button

var _total_bytes: int = 0
var _last_bytes: int = 0
var _last_time: float = 0.0
var _speed: float = 0.0
var _is_done: bool = false

func _ready() -> void:
	layer = 250
	_build_ui()
	_connect_signals()


func _build_ui() -> void:
	var screen_size := get_viewport().get_visible_rect().size
	var panel_w := screen_size.x * 0.85
	var panel_h := 340.0

	# Full-screen dark backdrop
	_panel = Panel.new()
	_panel.position = Vector2.ZERO
	_panel.size = screen_size
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_DARK
	_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(_panel)

	# Inner card
	var inner := Panel.new()
	inner.position = Vector2((screen_size.x - panel_w) / 2, (screen_size.y - panel_h) / 2)
	inner.size = Vector2(panel_w, panel_h)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.10, 0.08, 0.05, 0.97)
	card_style.border_color = Color(0.50, 0.40, 0.25)
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 16
	card_style.corner_radius_top_right = 16
	card_style.corner_radius_bottom_left = 16
	card_style.corner_radius_bottom_right = 16
	inner.add_theme_stylebox_override("panel", card_style)
	_panel.add_child(inner)

	var y := 24.0

	# Title
	_title_label = Label.new()
	_title_label.text = "⬇ Téléchargement du modèle IA"
	_title_label.position = Vector2(20, y)
	_title_label.size = Vector2(panel_w - 40, 32)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", COLOR_GOLD)
	inner.add_child(_title_label)
	y += 46

	# Detail (model name + size)
	_detail_label = Label.new()
	_detail_label.text = "Modèle : Qwen2.5 1.5B (~1.1 GB)"
	_detail_label.position = Vector2(20, y)
	_detail_label.size = Vector2(panel_w - 40, 22)
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.add_theme_font_size_override("font_size", 13)
	_detail_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	inner.add_child(_detail_label)
	y += 32

	# Progress bar
	_progress_bar = ProgressBar.new()
	_progress_bar.position = Vector2(30, y)
	_progress_bar.size = Vector2(panel_w - 60, 28)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.12, 0.10, 0.06)
	bar_style.border_color = Color(0.40, 0.32, 0.20)
	bar_style.border_width_left = 1
	bar_style.border_width_right = 1
	bar_style.border_width_top = 1
	bar_style.border_width_bottom = 1
	bar_style.corner_radius_top_left = 4
	bar_style.corner_radius_top_right = 4
	bar_style.corner_radius_bottom_left = 4
	bar_style.corner_radius_bottom_right = 4
	_progress_bar.add_theme_stylebox_override("background", bar_style)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.25, 0.45, 0.25)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	_progress_bar.add_theme_stylebox_override("fill", fill_style)
	inner.add_child(_progress_bar)
	y += 36

	# Progress text
	_progress_label = Label.new()
	_progress_label.text = "0% — Connexion en cours..."
	_progress_label.position = Vector2(20, y)
	_progress_label.size = Vector2(panel_w - 40, 22)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 13)
	_progress_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8))
	inner.add_child(_progress_label)
	y += 28

	# Speed
	_speed_label = Label.new()
	_speed_label.text = ""
	_speed_label.position = Vector2(20, y)
	_speed_label.size = Vector2(panel_w - 40, 20)
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed_label.add_theme_font_size_override("font_size", 11)
	_speed_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	inner.add_child(_speed_label)
	y += 38

	# Status
	_status_label = Label.new()
	_status_label.text = "Le téléchargement peut prendre quelques minutes.\nUne connexion Wi-Fi est recommandée."
	_status_label.position = Vector2(20, y)
	_status_label.size = Vector2(panel_w - 40, 36)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.55))
	inner.add_child(_status_label)
	y += 46

	# Buttons
	var btn_w := (panel_w - 60) / 2

	_retry_btn = Button.new()
	_retry_btn.text = "Réessayer"
	_retry_btn.position = Vector2(20, y)
	_retry_btn.size = Vector2(btn_w, 42)
	_retry_btn.add_theme_font_size_override("font_size", 15)
	_retry_btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	_retry_btn.visible = false
	var btn_normal := _make_button_style(Color(0.15, 0.12, 0.08), Color(0.50, 0.40, 0.25))
	var btn_hover := _make_button_style(Color(0.25, 0.20, 0.12), Color(0.65, 0.52, 0.33))
	_retry_btn.add_theme_stylebox_override("normal", btn_normal)
	_retry_btn.add_theme_stylebox_override("hover", btn_hover)
	_retry_btn.pressed.connect(func(): retry_requested.emit())
	inner.add_child(_retry_btn)

	_skip_btn = Button.new()
	_skip_btn.text = "Jouer sans IA"
	_skip_btn.position = Vector2(30 + btn_w, y)
	_skip_btn.size = Vector2(btn_w, 42)
	_skip_btn.add_theme_font_size_override("font_size", 15)
	_skip_btn.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	var skip_normal := _make_button_style(Color(0.10, 0.08, 0.05), Color(0.30, 0.25, 0.15))
	var skip_hover := _make_button_style(Color(0.18, 0.14, 0.09), Color(0.40, 0.33, 0.20))
	_skip_btn.add_theme_stylebox_override("normal", skip_normal)
	_skip_btn.add_theme_stylebox_override("hover", skip_hover)
	_skip_btn.pressed.connect(func():
		_is_done = true
		queue_free()
	)
	inner.add_child(_skip_btn)


func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	return s


func _connect_signals() -> void:
	if not LlamaServer:
		return

	LlamaServer.download_progress.connect(_on_progress)
	LlamaServer.download_complete.connect(_on_success)
	LlamaServer.download_error.connect(_on_error)
	LlamaServer.server_error.connect(_on_server_error)


func _on_progress(bytes_received: int, _total_bytes: int) -> void:
	if _is_done:
		return

	# Calculate speed
	var now := Time.get_ticks_msec() / 1000.0
	if _last_time > 0 and now > _last_time:
		var dt := now - _last_time
		var db := bytes_received - _last_bytes
		_speed = db / dt

	_last_time = now
	_last_bytes = bytes_received

	# Update UI
	var model_size := 1117320736  # Qwen2.5-1.5B Q4_K_M exact size
	var pct := minf(float(bytes_received) / float(model_size) * 100.0, 100.0)
	_progress_bar.value = pct

	var received_mb := bytes_received / 1048576.0
	var total_mb := model_size / 1048576.0

	if _speed > 0:
		var remaining := (model_size - bytes_received) / _speed
		var eta_text := _format_eta(remaining)
		_progress_label.text = "%.0f%% — %.0f / %.0f MB  (%s restant)" % [pct, received_mb, total_mb, eta_text]
		_speed_label.text = "%.1f MB/s" % (_speed / 1048576.0)
	else:
		_progress_label.text = "%.0f%% — %.0f / %.0f MB" % [pct, received_mb, total_mb]
		_speed_label.text = ""

	# Animate fill color based on progress
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.25, 0.45 + pct * 0.003, 0.25 + pct * 0.002)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	_progress_bar.add_theme_stylebox_override("fill", fill_style)


func _on_success() -> void:
	if _is_done:
		return
	_is_done = true

	_progress_bar.value = 100.0
	_progress_label.text = "✅ Téléchargement terminé !"
	_progress_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	_speed_label.text = ""
	_status_label.text = "Vérification du modèle..."

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.3, 0.6, 0.3)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	_progress_bar.add_theme_stylebox_override("fill", fill_style)

	_skip_btn.visible = false
	_retry_btn.visible = false

	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		queue_free()


func _on_error(message: String) -> void:
	if _is_done:
		return
	_is_done = true

	_title_label.text = "⚠ Erreur de téléchargement"
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
	_progress_label.text = "❌ Échec"
	_progress_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.5, 0.2, 0.2)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	_progress_bar.add_theme_stylebox_override("fill", fill_style)

	_detail_label.text = "Vérifiez votre connexion internet."
	_retry_btn.visible = true
	_speed_label.text = ""


func _on_server_error(_message: String) -> void:
	# Server can fail even after download — show but don't block
	if _is_done:
		return
	_status_label.text = "⚠ Le serveur IA n'a pas pu démarrer. Les dialogues ennemis seront désactivés."
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))


func _format_eta(seconds: float) -> String:
	if seconds < 60:
		return "%ds" % int(seconds)
	elif seconds < 3600:
		var m := int(seconds / 60)
		var s := int(int(seconds) % 60)
		return "%dm %ds" % [m, s]
	else:
		var h := int(seconds / 3600)
		var m := int(int(seconds) % 3600 / 60)
		return "%dh %dm" % [h, m]


func _input(event: InputEvent) -> void:
	# Block back button during download
	if event is InputEventKey and event.keycode == KEY_BACK and event.pressed:
		get_viewport().set_input_as_handled()
