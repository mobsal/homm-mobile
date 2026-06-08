extends Node

class_name LLMClient

signal response_received(success: bool, data: Dictionary)

var _config: LLMConfig
var _http: HTTPRequest


func _ready() -> void:
	_config = LLMConfig.new()
	_config.load_from_disk()
	_http = HTTPRequest.new()
	_http.timeout = 45  # longer timeout for embedded LLM
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)


func get_endpoint() -> String:
	# Use embedded LlamaServer if available (Android), else config endpoint
	if LlamaServer and LlamaServer.is_server_ready():
		return LlamaServer.get_endpoint()
	return _config.endpoint


func set_config(cfg: LLMConfig) -> void:
	_config = cfg


func get_config() -> LLMConfig:
	return _config


func is_ready() -> bool:
	# Ready if LlamaServer is running (embedded) OR LLM config is valid
	if LlamaServer and LlamaServer.is_server_ready():
		return true
	return _config.is_ready()


func send_prompt(system_prompt: String, messages: Array[Dictionary]) -> void:
	if not is_ready():
		push_error("LLMClient: non configuré (clé API manquante ou désactivé)")
		response_received.emit(false, {"error": "LLM non configuré"})
		return

	var body := {
		"model": _config.model,
		"messages": [{"role": "system", "content": system_prompt}] + messages,
		"max_tokens": _config.max_tokens,
		"temperature": _config.temperature,
	}
	var json_body := JSON.stringify(body)
	var actual_endpoint := get_endpoint()
	var actual_api_key := "not-needed" if LlamaServer and LlamaServer.is_server_ready() else _config.api_key

	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer " + actual_api_key,
	]

	var err := _http.request(actual_endpoint, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		push_error("LLMClient: échec de la requête HTTP — ", err)
		response_received.emit(false, {"error": "Échec de la requête HTTP"})


func _on_request_completed(result: int, code: int, _headers: Array, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		response_received.emit(false, {"error": "Erreur réseau (%d)" % result})
		return

	if code != 200:
		var err_text := body.get_string_from_utf8()
		push_error("LLMClient: API retourne %d — %s" % [code, err_text])
		response_received.emit(false, {"error": "API erreur %d" % code, "raw": err_text})
		return

	var json_str := body.get_string_from_utf8()
	var json := JSON.new()
	var parse_err := json.parse(json_str)
	if parse_err != OK:
		response_received.emit(false, {"error": "Erreur de parsing JSON réponse", "raw": json_str.left(500)})
		return

	var data: Dictionary = json.data
	var content: String = ""
	var choices: Array = data.get("choices", [])
	if choices.size() > 0:
		content = choices[0].get("message", {}).get("content", "")

	if content.is_empty():
		response_received.emit(false, {"error": "Réponse vide de l'API"})
		return

	var parsed := _parse_response(content)
	if parsed.is_empty():
		response_received.emit(false, {"error": "Impossible de parser la réponse", "raw": content})
		return

	response_received.emit(true, parsed)


func _parse_response(content: String) -> Dictionary:
	var trimmed := content.strip_edges()
	if trimmed.begins_with("```"):
		var start := trimmed.find("\n")
		if start >= 0:
			trimmed = trimmed.substr(start).strip_edges()
		var end := trimmed.find("```")
		if end >= 0:
			trimmed = trimmed.substr(0, end).strip_edges()

	var json := JSON.new()
	var err := json.parse(trimmed)
	if err != OK:
		return {}

	var data: Dictionary = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return {}

	if not data.has("action") or not data.has("message"):
		return {}

	var valid_actions := ["attack", "flee", "help", "negotiate"]
	var action: String = str(data["action"]).to_lower()
	if not valid_actions.has(action):
		return {}

	return {
		"action": action,
		"message": str(data.get("message", "")),
		"reason": str(data.get("reason", "")),
		"raw": content,
	}
