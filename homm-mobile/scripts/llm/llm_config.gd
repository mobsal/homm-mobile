extends Resource

class_name LLMConfig

const SETTINGS_PATH: String = "user://llm_settings.cfg"

var endpoint: String = "http://127.0.0.1:8081/v1/chat/completions"
var api_key: String = "not-needed"
var model: String = "qwen2.5-1.5b-instruct"
var max_tokens: int = 512
var temperature: float = 0.8
var enabled: bool = true


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("llm", "endpoint", endpoint)
	cfg.set_value("llm", "api_key", api_key)
	cfg.set_value("llm", "model", model)
	cfg.set_value("llm", "max_tokens", max_tokens)
	cfg.set_value("llm", "temperature", temperature)
	cfg.set_value("llm", "enabled", enabled)
	cfg.save(SETTINGS_PATH)


func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err == OK:
		enabled = cfg.get_value("llm", "enabled", enabled)


func is_ready() -> bool:
	return enabled
