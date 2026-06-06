extends CanvasLayer

class_name LLMDialogueScreen

signal dialogue_ended(outcome: Dictionary)

const MAX_TURNS: int = 5
const MSG_PLAYER: String = "player"
const MSG_ENEMY: String = "enemy"
const MSG_SYSTEM: String = "system"

var _llm_client: LLMClient
var _personality: Dictionary
var _enemy_data: Dictionary
var _player_history: Dictionary
var _messages: Array[Dictionary] = []
var _turn_count: int = 0
var _is_waiting: bool = false
var _resolved: bool = false

var _panel: Panel
var _header_label: Label
var _sub_header_label: Label
var _chat_scroll: ScrollContainer
var _chat_container: VBoxContainer
var _input_box: LineEdit
var _send_btn: Button
var _close_btn: Button
var _status_label: Label


func _ready() -> void:
	layer = 30
	_build_ui()


func _build_ui() -> void:
	var screen_size := get_viewport().get_visible_rect().size
	var margin := screen_size.x * 0.03

	_panel = Panel.new()
	_panel.position = Vector2.ZERO
	_panel.size = screen_size
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.92)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.position = Vector2(screen_size.x - 52, 8)
	_close_btn.size = Vector2(44, 44)
	_close_btn.pressed.connect(_on_close)
	_panel.add_child(_close_btn)

	_header_label = Label.new()
	_header_label.position = Vector2(margin, 16)
	_header_label.size = Vector2(screen_size.x - margin * 2 - 50, 36)
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header_label.add_theme_font_size_override("font_size", 22)
	_header_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	_panel.add_child(_header_label)

	_sub_header_label = Label.new()
	_sub_header_label.position = Vector2(margin, 52)
	_sub_header_label.size = Vector2(screen_size.x - margin * 2, 28)
	_sub_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_sub_header_label.add_theme_font_size_override("font_size", 16)
	_sub_header_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_panel.add_child(_sub_header_label)

	var separator := ColorRect.new()
	separator.position = Vector2(margin, 84)
	separator.size = Vector2(screen_size.x - margin * 2, 2)
	separator.color = Color(0.3, 0.3, 0.5, 0.5)
	_panel.add_child(separator)

	var chat_top := 96.0
	var chat_bottom := 80.0
	var input_height := 50.0
	_chat_scroll = ScrollContainer.new()
	_chat_scroll.position = Vector2(margin, chat_top)
	_chat_scroll.size = Vector2(screen_size.x - margin * 2, screen_size.y - chat_top - chat_bottom - input_height)
	_chat_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_panel.add_child(_chat_scroll)

	_chat_container = VBoxContainer.new()
	_chat_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_container.anchors_preset = Control.PRESET_FULL_RECT
	_chat_scroll.add_child(_chat_container)

	_status_label = Label.new()
	_status_label.position = Vector2(margin, screen_size.y - chat_bottom - input_height - 4)
	_status_label.size = Vector2(screen_size.x - margin * 2, 24)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_status_label.visible = false
	_panel.add_child(_status_label)

	_input_box = LineEdit.new()
	_input_box.position = Vector2(margin, screen_size.y - chat_bottom - 2)
	_input_box.size = Vector2(screen_size.x - margin * 2 - 60, 40)
	_input_box.placeholder_text = "Votre message..."
	_input_box.text_submitted.connect(_on_text_submitted)
	_panel.add_child(_input_box)

	_send_btn = Button.new()
	_send_btn.text = "Envoyer"
	_send_btn.position = Vector2(screen_size.x - margin - 54, screen_size.y - chat_bottom - 2)
	_send_btn.size = Vector2(54, 40)
	_send_btn.pressed.connect(_on_send_pressed)
	_panel.add_child(_send_btn)


func start_dialogue(enemy_data: Dictionary, personality: Dictionary, player_history: Dictionary, llm_client: LLMClient) -> void:
	_enemy_data = enemy_data
	_personality = personality
	_player_history = player_history
	_llm_client = llm_client
	_messages = []
	_turn_count = 0
	_resolved = false
	_is_waiting = false

	_header_label.text = personality.get("name_display", "Ennemi")
	_sub_header_label.text = "%s — %s" % [personality.get("archetype", ""), personality.get("mood", "")]

	_add_message(MSG_ENEMY, personality.get("greeting", "..."))
	_focus_input()


func _add_message(who: String, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(0, 28)

	if who == MSG_ENEMY:
		label.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
		label.text = "%s : %s" % ["🏯 " + _header_label.text, text]
	elif who == MSG_PLAYER:
		label.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))
		label.text = "🧑 Vous : %s" % text
	else:
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.4))
		label.text = text

	_chat_container.add_child(label)

	await get_tree().process_frame
	_chat_scroll.scroll_vertical = _chat_container.size.y


func _add_separator() -> void:
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 8)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_container.add_child(sep)


func _focus_input() -> void:
	if not _resolved and not _is_waiting:
		_input_box.grab_focus()


func _on_send_pressed() -> void:
	if _input_box.text.strip_edges().is_empty():
		return
	_send_message(_input_box.text.strip_edges())


func _on_text_submitted(text: String) -> void:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return
	_send_message(trimmed)


func _send_message(text: String) -> void:
	if _is_waiting or _resolved:
		return

	_turn_count += 1
	_add_message(MSG_PLAYER, text)

	_messages.append({"role": "user", "content": text})

	if _turn_count >= MAX_TURNS:
		_resolve_outcome("negotiate", "Le dialogue s'achève sur une impasse. L'ennemi est indécis.")
		return

	_is_waiting = true
	_input_box.editable = false
	_send_btn.disabled = true
	_input_box.text = ""
	_status_label.text = "L'ennemi réfléchit..."
	_status_label.visible = true

	if _llm_client.is_ready():
		if not _llm_client.response_received.is_connected(_on_llm_response):
			_llm_client.response_received.connect(_on_llm_response, CONNECT_ONE_SHOT)
		var system_prompt := _build_system_prompt()
		_llm_client.send_prompt(system_prompt, _messages)
	else:
		_on_llm_response(false, {"error": "LLM non configuré"})


func _on_llm_response(success: bool, data: Dictionary) -> void:
	_is_waiting = false
	_input_box.editable = true
	_send_btn.disabled = false
	_status_label.visible = false

	if not success:
		var error_msg: String = data.get("error", "Erreur inconnue")
		var raw: String = data.get("raw", "")
		_add_message(MSG_ENEMY, "... *silence gênant*")
		_add_separator()
		_add_message(MSG_SYSTEM, "⚠ Erreur LLM : " + error_msg)
		if not raw.is_empty():
			_add_message(MSG_SYSTEM, "Réponse brute : " + raw.left(200))
		await get_tree().create_timer(3.0).timeout
		if not is_inside_tree():
			return
		_resolve_outcome("attack", error_msg)
		return

	var action: String = data.get("action", "attack")
	var message: String = data.get("message", "...")

	_messages.append({"role": "assistant", "content": message})

	_add_separator()

	if action == "negotiate":
		_add_message(MSG_ENEMY, message)
		_focus_input()
		return

	_add_message(MSG_ENEMY, message)
	_add_separator()
	_show_outcome(action, data)


func _show_outcome(action: String, data: Dictionary) -> void:
	_resolved = true

	var outcome_text: String = ""
	var outcome_color: Color
	match action:
		"attack":
			outcome_text = "⚔ L'ennemi attaque ! Prépare-toi au combat !"
			outcome_color = Color(1, 0.3, 0.3)
		"flee":
			outcome_text = "🏃 L'ennemi s'enfuit ! Tu peux passer."
			outcome_color = Color(0.3, 1, 0.3)
		"help":
			outcome_text = "⭐ L'ennemi t'offre son aide !"
			outcome_color = Color(1, 0.85, 0.4)
		_:
			outcome_text = "L'issue reste incertaine."
			outcome_color = Color(0.7, 0.7, 0.7)

	var outcome_label := Label.new()
	outcome_label.text = outcome_text
	outcome_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outcome_label.add_theme_font_size_override("font_size", 20)
	outcome_label.add_theme_color_override("font_color", outcome_color)
	outcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outcome_label.custom_minimum_size = Vector2(0, 40)
	_chat_container.add_child(outcome_label)

	var continue_btn := Button.new()
	continue_btn.text = "Continuer"
	continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_btn.custom_minimum_size = Vector2(200, 48)
	continue_btn.add_theme_font_size_override("font_size", 18)
	continue_btn.pressed.connect(func():
		var outcome: Dictionary = {
			"action": action,
			"message": data.get("message", ""),
			"reason": data.get("reason", ""),
			"enemy_data": _enemy_data,
		}
		dialogue_ended.emit(outcome)
	)
	_chat_container.add_child(continue_btn)


func _resolve_outcome(action: String, reason: String) -> void:
	_resolved = true
	_input_box.visible = false
	_send_btn.visible = false

	_show_outcome(action, {"message": reason, "reason": reason})


func _build_system_prompt() -> String:
	var hero_name: String = _player_history.get("hero_name", "le héros")
	var enemies_killed: int = _player_history.get("enemies_killed", 0)
	var enemies_spared: int = _player_history.get("enemies_spared", 0)
	var bosses_defeated: int = _player_history.get("bosses_defeated", 0)
	var hero_level: int = _player_history.get("hero_level", 1)
	var hero_hp: int = _player_history.get("hero_hp", 50)
	var hero_atk: int = _player_history.get("hero_attack", 10)
	var hero_def: int = _player_history.get("hero_defense", 5)
	var gold: int = _player_history.get("gold", 0)
	var quests_completed: int = _player_history.get("quests_completed", 0)
	var last_actions: Array = _player_history.get("recent_actions", [])

	var actions_str: String = ""
	for act in last_actions:
		actions_str += "- " + str(act) + "\n"

	var enemy_hp: int = _enemy_data.get("hp", 50)
	var enemy_max_hp: int = _enemy_data.get("max_hp", 50)
	var enemy_atk: int = _enemy_data.get("attack", 10)

	return """Tu es %s, un %s dans l'univers du jeu "Homura: Heroes of Conquest", un jeu de stratégie japonais médiéval.

INFORMATIONS SUR L'ENNEMI :
- Nom : %s
- Archétype : %s
- Personnalité : %s
- Style de parole : %s
- Humeur actuelle : %s
- PV : %d / %d
- Attaque : %d

INFORMATIONS SUR LE HÉROS (devant toi) :
- Nom : %s
- Niveau : %d
- PV : %d
- Attaque : %d | Défense : %d
- Or : %d

HISTORIQUE DES ACTIONS DU HÉROS (connues de tous) :
- Ennemis tués par le héros : %d
- Ennemis épargnés par le héros : %d
- Boss vaincus : %d
- Quêtes accomplies : %d

Actions récentes du héros :
%s
INSTRUCTION :
Tu es cet ennemi. Réponds au héros en te basant sur ta personnalité, ton humeur, et l'historique des actions du héros.

TON OBJECTIF : Décider si tu attaques, fuis, aides, ou négocie.

RÈGLES DE DÉCISION :
- Si le héros a tué beaucoup d'ennemis → plus de chance d'attaquer (sauf si tu es un personnage pacifique).
- Si le héros a épargné des ennemis → les personnages pacifiques peuvent aider.
- Si le héros est faible par rapport à toi → plus agressif.
- Si le héros est très fort par rapport à toi → fuis ou négocie.
- Certains ennemis sont plus persuadables que d'autres (les personnalités change).
- Reste cohérent avec ton archétype et ta personnalité.

RÉPONSE : Tu DOIS répondre UNIQUEMENT par un objet JSON valide (sans markdown) :

{
  "action": "attack" | "flee" | "help" | "negotiate",
  "message": "Ce que tu dis au héros (dans le ton de ton archétype)",
  "reason": "Raison courte de ta décision (en français)"
}

- "attack" → tu attaques, le combat commence
- "flee" → tu fuis, le héros passe sans encombre
- "help" → tu aides le héros (récompense ou information)
- "negotiate" → tu veux continuer la conversation avant de décider

IMPORTANT : Ne mets PAS de code markdown (```). Réponds UNIQUEMENT le JSON pur.""" % [
		_personality.get("name_display", "Ennemi"),
		_personality.get("archetype", "guerrier"),
		_personality.get("name_display", "Ennemi"),
		_personality.get("archetype", ""),
		_personality.get("personality", ""),
		_personality.get("speech_style", ""),
		_personality.get("mood", ""),
		enemy_hp, enemy_max_hp, enemy_atk,
		hero_name, hero_level, hero_hp, hero_atk, hero_def, gold,
		enemies_killed, enemies_spared, bosses_defeated, quests_completed,
		actions_str,
	]


func _on_close() -> void:
	if _resolved:
		return
	_resolved = true
	dialogue_ended.emit({"action": "attack", "enemy_data": _enemy_data, "closed": true})
