extends Node
## LlamaServer — Manages the lifecycle of the embedded llama.cpp HTTP server.
##
## Architecture:
##   - On Android: copies llama-server binary + model from APK assets to app cache,
##     then launches it via OS.create_process(). The existing llm_client.gd
##     connects to http://127.0.0.1:8081/v1/chat/completions.
##   - On desktop/editor: falls back to llm_client.gd's configured endpoint
##     (e.g. local Ollama or a remote server).

class_name LlamaServer

signal server_started(port: int)
signal server_stopped
signal server_error(message: String)

const SERVER_PORT: int = 8081
const SERVER_HOST: String = "127.0.0.1"
const MODEL_FILENAME: String = "qwen2.5-1.5b-instruct-q4_k_m.gguf"

var _server_pid: int = -1
var _is_running: bool = false
var _model_path: String = ""
var _binary_path: String = ""


func _ready() -> void:
	# Only auto-start on Android (embedded mode).
	# On desktop, the developer uses their own Ollama/llama-server.
	if OS.get_name() == "Android":
		_start_embedded_server()
	else:
		print("[LlamaServer] Desktop mode — using external LLM endpoint.")


func _exit_tree() -> void:
	stop_server()


## Launch the embedded llama.cpp server on Android.
func _start_embedded_server() -> void:
	print("[LlamaServer] Starting embedded LLM on Android...")

	var cache_dir: String = OS.get_user_data_dir()
	_model_path = cache_dir.path_join(MODEL_FILENAME)
	_binary_path = cache_dir.path_join("llama-server")

	# Step 1 — Extract binary from APK assets
	if not _extract_binary():
		server_error.emit("Failed to extract llama-server binary")
		return

	# Step 2 — Extract model from APK assets (only if not already cached)
	if not FileAccess.file_exists(_model_path):
		if not _extract_model():
			server_error.emit("Failed to extract model file")
			return

	# Step 3 — Make binary executable
	_ensure_executable(_binary_path)

	# Step 4 — Launch the server
	var args := PackedStringArray([
		_binary_path,
		"-m", _model_path,
		"--host", SERVER_HOST,
		"--port", str(SERVER_PORT),
		"-ngl", "99",           # Offload all layers to GPU (Vulkan)
		"-c", "8192",           # Context size
		"--no-webui",           # No browser UI on mobile
		"--threads", "4",       # CPU threads for fallback
	])

	var err := OS.create_process(_binary_path, args)
	if err != OK:
		server_error.emit("Failed to launch llama-server (err=%d)" % err)
		return

	# The PID is not exposed by create_process in Godot 4.
	# We track status via a health-check timer.
	_is_running = true

	# Give the server a moment to bind the port, then check.
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(_check_server_health)


func _check_server_health() -> void:
	if not _is_running:
		return

	var http := HTTPRequest.new()
	add_child(http)
	http.timeout = 3
	http.request_completed.connect(_on_health_response.bind(http))
	var err := http.request("http://%s:%d/health" % [SERVER_HOST, SERVER_PORT])
	if err != OK:
		server_error.emit("Health check request failed")
		http.queue_free()


func _on_health_response(result: int, code: int, _headers: Array, _body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()

	if code == 200:
		print("[LlamaServer] Embedded LLM is ready on port %d" % SERVER_PORT)
		server_started.emit(SERVER_PORT)
	else:
		# The server might need more time. Retry once.
		var timer := get_tree().create_timer(3.0)
		timer.timeout.connect(_retry_health_check)


func _retry_health_check() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.timeout = 3
	http.request_completed.connect(func(result, code, _h, _b):
		http.queue_free()
		if code == 200:
			print("[LlamaServer] Embedded LLM is ready (retry OK)")
			server_started.emit(SERVER_PORT)
		else:
			server_error.emit("llama-server health check failed after retry")
	)
	http.request("http://%s:%d/health" % [SERVER_HOST, SERVER_PORT])


func _extract_binary() -> bool:
	# On Android, the binary should be placed in the APK's lib directory
	# (android/build/libs/arm64-v8a/) and loaded via JNI.
	# For now, this is a placeholder — the actual binary loading is done
	# via the Android plugin's native libs.
	#
	# If we bundle a standalone llama-server executable in assets,
	# we'd extract it here using:
	#   DirAccess.copy_absolute("res://assets/llm/llama-server", _binary_path)
	#
	# For the initial implementation, we rely on the Android plugin to
	# provide the native entry point.

	if FileAccess.file_exists("res://assets/llm/llama-server"):
		var err := DirAccess.copy_absolute("res://assets/llm/llama-server", _binary_path)
		return err == OK
	else:
		# Binary provided by native plugin — _binary_path is not used directly.
		print("[LlamaServer] No standalone binary in assets; using native plugin path.")
		_binary_path = ""  # Will be handled by native code
		return true


func _extract_model() -> bool:
	print("[LlamaServer] Extracting model to %s ..." % _model_path)
	var err := DirAccess.copy_absolute("res://assets/llm/%s" % MODEL_FILENAME, _model_path)
	if err != OK:
		printerr("[LlamaServer] Failed to copy model: %d" % err)
		return false
	return true


func _ensure_executable(path: String) -> void:
	# On Android, chmod via Java Runtime.exec
	if OS.get_name() == "Android":
		OS.execute("chmod", ["+x", path])


## Stop the embedded server.
func stop_server() -> void:
	if not _is_running:
		return

	_is_running = false
	print("[LlamaServer] Stopping embedded server...")

	if OS.get_name() == "Android":
		# Kill process by name on Android
		OS.execute("am", ["force-stop", "com.faez.homura"])
		# More precisely: kill the specific llama-server process
		OS.execute("pkill", ["-f", "llama-server"])

	server_stopped.emit()


## Returns true if the embedded server is running.
func is_server_ready() -> bool:
	return _is_running


## Returns the endpoint URL for the LLM client.
func get_endpoint() -> String:
	return "http://%s:%d/v1/chat/completions" % [SERVER_HOST, SERVER_PORT]
