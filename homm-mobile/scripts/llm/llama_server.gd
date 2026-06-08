extends Node
## LlamaServer — Manages the lifecycle of the embedded llama.cpp HTTP server.
##
## NOTE: This script is an autoload singleton. Do NOT rename or add class_name.
##       The global is accessed as `LlamaServer` (the autoload name).
##
## Architecture:
##   - On Android: downloads the GGUF model on first launch (from HuggingFace
##     or a configured mirror), caches it in user://, then launches llama-server
##     via the native plugin. Checks model_version.json for updates.
##   - On desktop/editor: falls back to llm_client.gd's configured endpoint
##     (e.g. local Ollama or a remote server).
##
## Signals:
##   - download_progress(bytes_received, total_bytes) — emitted during model download
##   - download_complete() — model cached and ready
##   - server_started(port) — llama-server is running
##   - server_stopped
##   - server_error(message)

# ── Signals ────────────────────────────────────────────────────────────
signal download_progress(bytes_received: int, total_bytes: int)
signal download_complete()
signal download_error(message: String)
signal server_started(port: int)
signal server_stopped
signal server_error(message: String)

# ── Constants ──────────────────────────────────────────────────────────
const SERVER_PORT: int = 8081
const SERVER_HOST: String = "127.0.0.1"
const MODEL_FILENAME: String = "qwen2.5-1.5b-instruct-q4_k_m.gguf"
const VERSION_FILENAME: String = "model_version.json"

# Model download URL — change this to your own mirror in production.
# HuggingFace raw downloads are rate-limited; use a CDN mirror for scale.
const MODEL_DOWNLOAD_URL: String = \
	"https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf"
const MODEL_VERSION_URL: String = \
	"https://raw.githubusercontent.com/mobsal/homm-mobile/refs/heads/main/model_version.json"

# Fallback mirrors (tried in order on failure)
const MIRRORS: Array[String] = []

# Expected SHA256 of the model (empty = skip check).
# Set this after computing the hash locally with: sha256sum model.gguf
const EXPECTED_SHA256: String = "6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e"

# ── State ──────────────────────────────────────────────────────────────
var _is_running: bool = false
var _is_downloading: bool = false
var _model_path: String = ""
var _binary_path: String = ""
var _cached_version: String = ""
var _remote_version: String = ""
var _current_http: HTTPRequest = null
var _download_file: FileAccess = null


# ── Lifecycle ──────────────────────────────────────────────────────────
func _ready() -> void:
	if OS.get_name() == "Android":
		_start_embedded()
	else:
		print("[LlamaServer] Desktop mode — using external LLM endpoint.")


func _exit_tree() -> void:
	if _is_downloading:
		_cancel_download()
	stop_server()


# ── Entry Point ────────────────────────────────────────────────────────
func _start_embedded() -> void:
	print("[LlamaServer] Starting embedded LLM on Android...")

	var cache_dir := OS.get_user_data_dir()
	_model_path = cache_dir.path_join(MODEL_FILENAME)
	_binary_path = cache_dir.path_join("llama-server")

	# Check if we have a cached model and if an update is available
	_check_for_updates()


# ── Version Check ──────────────────────────────────────────────────────
func _check_for_updates() -> void:
	# Read locally cached version
	var version_path := OS.get_user_data_dir().path_join(VERSION_FILENAME)
	if FileAccess.file_exists(version_path):
		var f := FileAccess.open(version_path, FileAccess.READ)
		if f:
			var data: Variant = JSON.parse_string(f.get_as_text())
			f.close()
			if data is Dictionary:
				_cached_version = data.get("version", "")

	# Fetch remote version manifest
	var http := HTTPRequest.new()
	add_child(http)
	http.timeout = 10
	http.request_completed.connect(_on_version_response.bind(http))
	var err := http.request(MODEL_VERSION_URL)
	if err != OK:
		# Can't reach version server — use cached model if available
		print("[LlamaServer] Cannot reach version server; using cached model if any.")
		_on_version_check_done(false)


func _on_version_response(result: int, code: int, _headers: Array, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_on_version_check_done(false)
		return

	var json_str := body.get_string_from_utf8()
	var data: Variant = JSON.parse_string(json_str)
	if data is Dictionary:
		_remote_version = data.get("version", "")

	_on_version_check_done(true)


func _on_version_check_done(got_remote: bool) -> void:
	var model_exists := FileAccess.file_exists(_model_path)
	var needs_download := false

	if not model_exists:
		print("[LlamaServer] No cached model found — must download.")
		needs_download = true
	elif got_remote and _remote_version != "" and _remote_version != _cached_version:
		print("[LlamaServer] New model version available: %s → %s" % [_cached_version, _remote_version])
		needs_download = true
	else:
		print("[LlamaServer] Cached model is up to date (version %s)." % _cached_version)

	if needs_download:
		_start_download()
	else:
		_launch_server()


# ── Model Download ─────────────────────────────────────────────────────
func _start_download() -> void:
	print("[LlamaServer] Starting model download from %s ..." % MODEL_DOWNLOAD_URL)
	_is_downloading = true

	# Remove any partial download
	var temp_path := _model_path + ".tmp"
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(temp_path)

	# Start HTTP download
	_current_http = HTTPRequest.new()
	add_child(_current_http)
	_current_http.timeout = 0  # no timeout for large download
	_current_http.download_chunk_size = 65536  # 64 KB chunks for progress
	_current_http.request_completed.connect(_on_download_done)

	var err := _current_http.request(MODEL_DOWNLOAD_URL)
	if err != OK:
		download_error.emit("Failed to start download (err=%d)" % err)
		_is_downloading = false
		return

	# Open temp file for writing
	_download_file = FileAccess.open(temp_path, FileAccess.WRITE)
	if not _download_file:
		download_error.emit("Failed to create temp file")
		_is_downloading = false
		return

	# Monitor progress in a timer (Godot HTTPRequest doesn't emit progress natively,
	# but chunk signals are available in Godot 4.3+)
	_check_download_progress()


func _check_download_progress() -> void:
	# Poll file size during download
	if not _is_downloading or not _download_file:
		return

	var temp_path := _model_path + ".tmp"
	if FileAccess.file_exists(temp_path):
		var f := FileAccess.open(temp_path, FileAccess.READ)
		if f:
			var size := f.get_length()
			f.close()
			# Emit progress — total is unknown from HTTP, but we report file growth
			download_progress.emit(size, 0)

	# Continue polling
	if _is_downloading:
		var timer := get_tree().create_timer(0.5)
		timer.timeout.connect(_check_download_progress)


func _on_download_done(result: int, code: int, _headers: Array, body: PackedByteArray) -> void:
	_current_http.queue_free()
	_current_http = null

	if _download_file:
		_download_file.close()
		_download_file = null

	var temp_path := _model_path + ".tmp"

	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_is_downloading = false
		DirAccess.remove_absolute(temp_path)

		# Try mirrors
		# TODO: implement mirror fallback loop

		download_error.emit("Model download failed (HTTP %d)" % code)
		return

	# Rename temp to final
	if FileAccess.file_exists(_model_path):
		DirAccess.remove_absolute(_model_path)

	var dir := DirAccess.open("res://")  # dummy to get DirAccess instance
	# Godot doesn't have a direct rename; use copy + remove
	DirAccess.copy_absolute(temp_path, _model_path)
	DirAccess.remove_absolute(temp_path)

	_is_downloading = false

	# Verify checksum if configured
	if not EXPECTED_SHA256.is_empty():
		if not _verify_checksum():
			download_error.emit("Model checksum verification failed — file may be corrupted")
			return

	# Save version info
	_save_version_info()

	print("[LlamaServer] Model downloaded successfully.")
	download_complete.emit()

	# Launch the server
	_launch_server()


func _save_version_info() -> void:
	var version_path := OS.get_user_data_dir().path_join(VERSION_FILENAME)
	var data := {
		"version": _remote_version,
		"model": MODEL_FILENAME,
		"downloaded_at": Time.get_unix_time_from_system(),
	}
	var f := FileAccess.open(version_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))
		f.close()


func _verify_checksum() -> bool:
	# SHA256 verification requires native code or a large GDScript impl.
	# For now, we rely on file size as a basic sanity check.
	# Full SHA256 would need a GDExtension or the Android plugin.
	var f := FileAccess.open(_model_path, FileAccess.READ)
	if not f:
		return false
	var size := f.get_length()
	f.close()

	# Qwen2.5-1.5B Q4_K_M is ~1.04 GiB
	if size < 900_000_000:  # less than 900 MB is suspicious
		printerr("[LlamaServer] Model file too small (%d bytes) — possible corruption." % size)
		return false

	return true


func _cancel_download() -> void:
	if _current_http:
		_current_http.cancel_request()
		_current_http.queue_free()
		_current_http = null

	if _download_file:
		_download_file.close()
		_download_file = null

	var temp_path := _model_path + ".tmp"
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(temp_path)

	_is_downloading = false


# ── Server Launch ──────────────────────────────────────────────────────
func _launch_server() -> void:
	if not FileAccess.file_exists(_model_path):
		server_error.emit("Model file not found at %s" % _model_path)
		return

	print("[LlamaServer] Launching llama.cpp server...")

	var args := PackedStringArray([
		"-m", _model_path,
		"--host", SERVER_HOST,
		"--port", str(SERVER_PORT),
		"-ngl", "99",
		"-c", "8192",
		"--no-webui",
		"--threads", "4",
	])

	# On Android, the binary is loaded via the native plugin (JNI).
	# The .so files in android/build/libs/ are bundled into the APK.
	# We call the native entry point via the plugin singleton.
	if Engine.has_singleton("LlamaServerPlugin"):
		var plugin = Engine.get_singleton("LlamaServerPlugin")
		plugin.launchServer(_model_path, SERVER_PORT, 8192, 99)
	else:
		# Fallback: try OS.create_process with a bundled binary
		# (requires llama-server binary in assets)
		if FileAccess.file_exists("res://assets/llm/llama-server"):
			DirAccess.copy_absolute("res://assets/llm/llama-server", _binary_path)
			OS.execute("chmod", ["+x", _binary_path])
			var full_args := PackedStringArray([_binary_path]) + args
			var err := OS.create_process(_binary_path, full_args)
			if err != OK:
				server_error.emit("Failed to launch llama-server (err=%d)" % err)
				return
		else:
			server_error.emit("No native plugin or binary found for llama-server")
			return

	_is_running = true

	# Health check after a short delay
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(_check_server_health)


# ── Health Checks ──────────────────────────────────────────────────────
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


func _on_health_response(_result: int, code: int, _headers: Array, _body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()

	if code == 200:
		print("[LlamaServer] LLM ready on port %d" % SERVER_PORT)
		server_started.emit(SERVER_PORT)
	else:
		var timer := get_tree().create_timer(3.0)
		timer.timeout.connect(_retry_health_check)


func _retry_health_check() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.timeout = 3
	http.request_completed.connect(func(_result, code, _h, _b):
		http.queue_free()
		if code == 200:
			print("[LlamaServer] LLM ready (retry OK)")
			server_started.emit(SERVER_PORT)
		else:
			server_error.emit("llama-server health check failed after retry")
	)
	http.request("http://%s:%d/health" % [SERVER_HOST, SERVER_PORT])


# ── Public API ─────────────────────────────────────────────────────────
func stop_server() -> void:
	if not _is_running:
		return

	_is_running = false
	print("[LlamaServer] Stopping server...")

	if OS.get_name() == "Android":
		OS.execute("pkill", ["-f", "llama-server"])

	server_stopped.emit()


func is_server_ready() -> bool:
	return _is_running


func is_downloading() -> bool:
	return _is_downloading


func get_model_version() -> String:
	return _cached_version


func get_remote_version() -> String:
	return _remote_version


func get_endpoint() -> String:
	return "http://%s:%d/v1/chat/completions" % [SERVER_HOST, SERVER_PORT]


## Forces a re-download of the model (useful after a version check failure).
func force_redownload() -> void:
	if _is_downloading:
		return
	if _is_running:
		stop_server()

	# Delete cached model + version
	if FileAccess.file_exists(_model_path):
		DirAccess.remove_absolute(_model_path)
	var version_path := OS.get_user_data_dir().path_join(VERSION_FILENAME)
	if FileAccess.file_exists(version_path):
		DirAccess.remove_absolute(version_path)

	_cached_version = ""
	_remote_version = ""
	_check_for_updates()
