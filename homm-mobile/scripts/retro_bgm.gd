extends Node

## Musique de fond chiptune pentatonique (générée au lancement).

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "BGMPlayer"
	_player.volume_db = -8.0
	add_child(_player)
	call_deferred("_start_bgm")

func _start_bgm() -> void:
	_player.stream = _build_loop()
	_player.play()

func play() -> void:
	if _player and not _player.playing:
		_player.play()

func stop() -> void:
	if _player:
		_player.stop()

func _build_loop() -> AudioStreamWAV:
	var sr: int = 22050
	var duration: float = 10.0
	var sample_count: int = int(sr * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	# Pentatonique : Do Re Mi Sol La Do
	var freqs: Array = [261.63, 293.66, 329.63, 392.0, 440.0, 523.25, 587.33]
	var melody: Array = [0, 2, 4, 5, 4, 2, 0, 2, 4, 5, 6, 5, 4, 2, 0, 0]
	var bpm: float = 88.0
	var spb: float = 60.0 / bpm
	var phase: float = 0.0
	for i in range(sample_count):
		var t: float = float(i) / float(sr)
		var beat: int = int(t / spb) % melody.size()
		var beat_t: float = fmod(t, spb) / spb
		var f: float = freqs[melody[beat]]
		var env: float = minf(1.0, beat_t * 10.0) * (1.0 - maxf(0.0, (beat_t - 0.72) * 4.0))
		phase += f / float(sr)
		var sq: float = 0.32 if sin(TAU * phase) > 0.0 else -0.32
		var bass: float = 0.1 * sin(TAU * freqs[melody[beat] % 5] * 0.5 * t)
		var click: float = 0.22 * (1.0 - beat_t / 0.04) if beat_t < 0.04 and int(t / spb) % 2 == 0 else 0.0
		var sample: float = clampf((sq * env + bass + click) * 0.5, -1.0, 1.0)
		var s16: int = int(sample * 32767.0 * 0.85)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sr
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.data = data
	return stream
