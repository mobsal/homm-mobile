extends Node

var _player: AudioStreamPlayer
var _theme: String = "exploration"

var _menu_player: AudioStreamPlayer
var _menu_restart_timer: Timer
var _menu_stream: AudioStreamMP3

var _hirajoshi: Array[float] = [220.0, 233.08, 277.18, 311.13, 349.23, 440.0]
var _hirajoshi_high: Array[float] = [440.0, 466.16, 554.37, 622.25, 698.46, 880.0]
var _pentatonic: Array[float] = [261.63, 293.66, 329.63, 392.0, 440.0, 523.25, 587.33, 659.25]

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "BGMPlayer"
	_player.volume_db = -10.0
	add_child(_player)

	_menu_player = AudioStreamPlayer.new()
	_menu_player.name = "MenuPlayer"
	_menu_player.volume_db = -10.0
	add_child(_menu_player)
	_menu_player.finished.connect(_on_menu_finished)

	_menu_restart_timer = Timer.new()
	_menu_restart_timer.one_shot = true
	_menu_restart_timer.timeout.connect(_restart_menu_music)
	add_child(_menu_restart_timer)

	_menu_stream = load("res://assets/music/menu.mp3")
	if _menu_stream:
		print("✓ Menu music loaded")
	else:
		print("⚠ Failed to load menu.mp3")

func _on_menu_finished() -> void:
	_menu_restart_timer.start(2.0)

func _restart_menu_music() -> void:
	_menu_player.play()

func play_menu() -> void:
	if not _menu_stream:
		return
	if _player.playing:
		_player.stop()
	_menu_player.stream = _menu_stream
	_menu_player.play()

func stop_menu() -> void:
	_menu_player.stop()
	_menu_restart_timer.stop()
	_start_bgm()

func play() -> void:
	if _player and not _player.playing:
		_player.play()

func stop() -> void:
	if _player:
		_player.stop()

func set_volume_db(value: float) -> void:
	if _player:
		_player.volume_db = value
	if _menu_player:
		_menu_player.volume_db = value

func get_volume() -> float:
	return _player.volume_db if _player else -10.0

func set_volume(value: float) -> void:
	if _player:
		_player.volume_db = value
	if _menu_player:
		_menu_player.volume_db = value

func switch_to_combat() -> void:
	if _theme == "combat":
		return
	_menu_player.stop()
	_menu_restart_timer.stop()
	_theme = "combat"
	_player.stream = _build_combat_loop()
	_player.play()

func switch_to_exploration() -> void:
	if _theme == "exploration":
		return
	_menu_player.stop()
	_menu_restart_timer.stop()
	_theme = "exploration"
	_player.stream = _build_exploration_loop()
	_player.play()

func _start_bgm() -> void:
	_theme = "exploration"
	_player.stream = _build_exploration_loop()
	_player.play()

func _flute_wave(phase: float, t: float) -> float:
	var vibrato := sin(TAU * 5.0 * t) * 0.005
	var p := phase + vibrato
	var w := sin(TAU * p) + 0.3 * sin(TAU * p * 2.0) + 0.1 * sin(TAU * p * 3.0)
	return w / 1.4

func _koto_wave(phase: float, t: float) -> float:
	var decay: float = exp(-t * 8.0)
	var w: float = sin(TAU * phase) * decay
	w += 0.2 * sin(TAU * phase * 2.0) * decay * 0.5
	w += 0.1 * sin(TAU * phase * 4.0) * decay * 0.25
	return w

func _build_exploration_loop() -> AudioStreamWAV:
	var sr: int = 22050
	var bpm: float = 72.0
	var spb: float = 60.0 / bpm
	var beats: int = 32
	var duration: float = beats * spb
	var n: int = int(sr * duration)
	var data := PackedByteArray()
	data.resize(n * 2)

	var melody_beats: Array[int] = [0, 2, 4, 5, 4, 2, 0, 2, 4, 5, 3, 1, 0, 1, 3, 5, 4, 5, 4, 2, 0, -1, 4, 5, 4, 2, 1, 0, 1, 2, 0, -1]
	var bass_beats: Array[int] = [0, 0, 2, 2, 4, 4, 5, 5, 0, 0, 1, 1, 3, 3, 4, 4, 0, 0, 2, 2, 4, 4, 5, 5, 0, 0, 1, 1, 3, 3, 4, 4]

	var flute_phase: float = 0.0
	var koto_phase: Array[float] = [0.0, 0.0, 0.0]

	for i in range(n):
		var t: float = float(i) / float(sr)
		var beat: int = int(t / spb) % beats
		var beat_t: float = fmod(t, spb) / spb
		var next_beat: int = (beat + 1) % beats

		var flute_note := melody_beats[beat]
		var flute_next := melody_beats[next_beat]
		var bass_note := bass_beats[beat]

		var flute_freq: float = 0.0
		if flute_note >= 0 and flute_note < _hirajoshi_high.size():
			flute_freq = _hirajoshi_high[flute_note]
		var flute_next_freq: float = 0.0
		if flute_next >= 0 and flute_next < _hirajoshi_high.size():
			flute_next_freq = _hirajoshi_high[flute_next]

		var legato: float = 0.1
		var current_freq: float
		if beat_t < legato and flute_note >= 0 and flute_next >= 0:
			var lt := beat_t / legato
			current_freq = flute_freq + (flute_next_freq - flute_freq) * lt
		else:
			current_freq = flute_freq

		var flute_env: float = 1.0
		if beat_t < 0.05:
			flute_env = beat_t / 0.05
		var beat_end := 0.75
		if beat_t > beat_end:
			flute_env *= maxf(0.0, 1.0 - (beat_t - beat_end) / (1.0 - beat_end))

		flute_phase += current_freq / float(sr)
		if flute_phase > 1.0:
			flute_phase -= 1.0

		var flute_level: float = 0.0
		if current_freq > 0 and flute_note >= 0:
			flute_level = _flute_wave(flute_phase, t) * flute_env * 0.25

		var koto_level: float = 0.0
		for k in range(3):
			var k_beat := (beat + k * 8) % beats
			var k_note := melody_beats[k_beat]
			if k_note >= 0 and k_note < _hirajoshi.size() and beat_t < 0.1:
				var k_freq := _hirajoshi[k_note]
				var k_trigger := (beat_t < 0.05)
				if k_trigger:
					koto_phase[k] = 0.0
				if koto_phase[k] < 0.5:
					koto_phase[k] += k_freq / float(sr)
					if koto_phase[k] >= 0.5:
						koto_phase[k] = 0.0
				var k_env := maxf(0.0, 1.0 - t * 2.0)
				koto_level += _koto_wave(koto_phase[k], t) * 0.12 * k_env

		var bass_freq: float = _hirajoshi[bass_note % _hirajoshi.size()] * 0.5
		var bass_env: float = maxf(0.0, 1.0 - beat_t / 0.3)
		var bass: float = sin(TAU * bass_freq * t) * bass_env * 0.12

		var taiko: float = 0.0
		if beat_t < 0.04 and (beat % 4 == 0 or beat % 8 == 6):
			var td := beat_t / 0.04
			taiko = sin(TAU * 60.0 * t) * (1.0 - td) * 0.18

		var sample := clampf(flute_level + koto_level + bass + taiko, -1.0, 1.0)
		var s16 := int(sample * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sr
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.data = data
	return stream

func _build_combat_loop() -> AudioStreamWAV:
	var sr: int = 22050
	var bpm: float = 130.0
	var spb: float = 60.0 / bpm
	var beats: int = 32
	var duration: float = beats * spb
	var n: int = int(sr * duration)
	var data := PackedByteArray()
	data.resize(n * 2)

	var bass_beats: Array[int] = [0, 0, 2, 2, 4, 4, 5, 5, 0, 0, 3, 3, 4, 4, 5, 5, 0, 0, 2, 2, 4, 4, 5, 5, 0, 0, 3, 3, 4, 4, 5, 5]
	var _accent: Array[bool] = [true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false, true, false, false, false]

	for i in range(n):
		var t: float = float(i) / float(sr)
		var beat: int = int(t / spb) % beats
		var beat_t: float = fmod(t, spb) / spb
		var _sub_beat: float = fmod(t, spb / 2.0)

		var bass_note := bass_beats[beat]
		var bass_freq: float = _pentatonic[bass_note % _pentatonic.size()] * 0.5

		var bass_vol: float = 0.22 if beat_t < 0.08 else 0.08
		if beat % 2 == 1:
			bass_vol *= 0.4
		var bass_env: float = maxf(0.0, 1.0 - beat_t * 4.0)
		var bass: float = sin(TAU * bass_freq * t) * bass_env * bass_vol

		var lead_freq: float = _pentatonic[(bass_note + 4) % _pentatonic.size()] * 1.0
		var lead_trigger := beat % 4 == 0
		var lead_env: float = 0.0
		if lead_trigger and beat_t < 0.2:
			lead_env = maxf(0.0, 1.0 - beat_t * 5.0)
		var lead: float = sin(TAU * lead_freq * t) * lead_env * 0.2
		lead += sin(TAU * lead_freq * 2.0 * t) * lead_env * 0.08

		var drum_vol: float = 0.25
		if beat % 4 == 0:
			drum_vol = 0.35
		if beat_t < 0.03:
			var dd := beat_t / 0.03
			var drum := sin(TAU * 80.0 * t) * (1.0 - dd) * drum_vol
			bass += drum

		var hihat: float = 0.0
		if beat_t < 0.01 or (beat_t > 0.4 and beat_t < 0.41) or (beat_t > 0.2 and beat_t < 0.21):
			hihat = randf_range(-0.08, 0.08)

		var sample := clampf(bass + lead + hihat, -1.0, 1.0)
		var s16 := int(sample * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sr
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.data = data
	return stream
