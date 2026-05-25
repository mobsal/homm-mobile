extends Node

const DOTGOTHIC_FONT := preload("res://assets/fonts/DotGothic16-Regular.ttf")
const NOTO_FONT := preload("res://assets/fonts/NotoSansJP.ttf")

func _ready() -> void:
	_load_global_fonts()

func _load_global_fonts() -> void:
	var main_font: FontFile = DOTGOTHIC_FONT
	if not main_font:
		return
	main_font.hinting = TextServer.HINTING_NONE

	var fb: FontFile = NOTO_FONT
	if fb:
		main_font.fallbacks = [fb]

	ThemeDB.fallback_font = main_font
	print("✓ Polices globales appliquées (ThemeDB.default_theme)")
