class_name SFXManager
extends Node

var _players: Array[AudioStreamPlayer] = []
var _player_idx: int = 0
const MAX_PLAYERS := 10
var _master_volume: float = 0.0

func _ready() -> void:
	for i in range(MAX_PLAYERS):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.volume_db = _master_volume
		add_child(p)
		_players.append(p)

func get_volume() -> float:
	return _master_volume

func set_volume(value: float) -> void:
	_master_volume = value
	for p in _players:
		if is_instance_valid(p):
			p.volume_db = value

func _play_stream(data: PackedByteArray, sr: int, vol_db: float = 0.0) -> void:
	pass # Désactivé en attendant les fichiers audio importés

static func _gen_sine(freq: float, dur: float, sr: int, vol: float = 0.4, fade_out: bool = true) -> PackedByteArray:
	var n := int(sr * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(sr)
		var env := 1.0
		if fade_out:
			env = maxf(0.0, 1.0 - t / dur)
		var s := sin(TAU * freq * t) * vol * env
		var s16 := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return data

static func _gen_sweep(freq_start: float, freq_end: float, dur: float, sr: int, vol: float = 0.3) -> PackedByteArray:
	var n := int(sr * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var t := float(i) / float(sr)
		var freq := freq_start + (freq_end - freq_start) * (t / dur)
		phase += freq / float(sr)
		phase = fmod(phase, 1.0)
		var env := maxf(0.0, 1.0 - t / dur)
		var s := sin(TAU * phase) * vol * env
		var s16 := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return data

static func _gen_noise_burst(dur: float, sr: int, vol: float = 0.2) -> PackedByteArray:
	var n := int(sr * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(sr)
		var env := maxf(0.0, 1.0 - t / dur)
		var s := randf_range(-1.0, 1.0) * vol * env
		var s16 := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return data

static func _gen_chord(freqs: Array, dur: float, sr: int, vol: float = 0.3) -> PackedByteArray:
	var n := int(sr * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(sr)
		var env := maxf(0.0, 1.0 - t / dur)
		var s := 0.0
		for f in freqs:
			s += sin(TAU * float(f) * t)
		s = s / freqs.size() * vol * env
		var s16 := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	return data

static func _mix_audio(layers: Array, dur: float, sr: int) -> PackedByteArray:
	var n := int(sr * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var s := 0.0
		for layer in layers:
			var layer_data: PackedByteArray = layer
			if i * 2 + 1 < layer_data.size():
				var s16 := int(layer_data[i * 2]) | (int(layer_data[i * 2 + 1]) << 8)
				if s16 >= 32768:
					s16 -= 65536
				s += float(s16) / 32767.0
		s = clampf(s, -1.0, 1.0)
		var final_s16 := int(s * 32767.0)
		data[i * 2] = final_s16 & 0xFF
		data[i * 2 + 1] = (final_s16 >> 8) & 0xFF
	return data

func play_click() -> void:
	var sr := 22050
	var d := _gen_sine(600, 0.04, sr, 0.3)
	_play_stream(d, sr, -3.0)

func play_hover() -> void:
	var sr := 22050
	var d := _gen_sine(400, 0.02, sr, 0.15)
	_play_stream(d, sr, -6.0)

func play_sword_hit() -> void:
	var sr := 22050
	var noise := _gen_noise_burst(0.08, sr, 0.3)
	var thud := _gen_sine(120, 0.12, sr, 0.4)
	var d := _mix_audio([noise, thud], 0.12, sr)
	_play_stream(d, sr)

func play_fireball() -> void:
	var sr := 22050
	var sweep := _gen_sweep(200, 600, 0.25, sr, 0.3)
	var noise := _gen_noise_burst(0.2, sr, 0.15)
	var d := _mix_audio([sweep, noise], 0.25, sr)
	_play_stream(d, sr, -2.0)

func play_lightning() -> void:
	var sr := 22050
	var crackle := _gen_noise_burst(0.15, sr, 0.4)
	var boom := _gen_sine(80, 0.2, sr, 0.5)
	var d := _mix_audio([crackle, boom], 0.2, sr)
	_play_stream(d, sr)

func play_heal() -> void:
	var sr := 22050
	var c1 := _gen_sine(523.25, 0.15, sr, 0.25)
	var c2 := _gen_sine(659.25, 0.2, sr, 0.2)
	var c3 := _gen_sine(783.99, 0.25, sr, 0.15)
	var d := _mix_audio([c1, c2, c3], 0.25, sr)
	_play_stream(d, sr, -2.0)

func play_ice() -> void:
	var sr := 22050
	var shatter := _gen_noise_burst(0.1, sr, 0.25)
	var ping := _gen_sine(1200, 0.08, sr, 0.15)
	var ping2 := _gen_sine(1800, 0.06, sr, 0.1)
	var d := _mix_audio([shatter, ping, ping2], 0.12, sr)
	_play_stream(d, sr, -1.0)

func play_explosion() -> void:
	var sr := 22050
	var boom := _gen_sine(60, 0.3, sr, 0.6)
	var noise := _gen_noise_burst(0.25, sr, 0.25)
	var d := _mix_audio([boom, noise], 0.3, sr)
	_play_stream(d, sr, 2.0)

func play_death() -> void:
	var sr := 22050
	var d := _gen_sine(180, 0.3, sr, 0.3)
	_play_stream(d, sr, -1.0)

func play_critical() -> void:
	var sr := 22050
	var chord := _gen_chord([392.0, 523.25, 659.25], 0.15, sr, 0.35)
	var noise := _gen_noise_burst(0.1, sr, 0.2)
	var d := _mix_audio([chord, noise], 0.15, sr)
	_play_stream(d, sr, 1.0)

func play_victory() -> void:
	var sr := 22050
	var n1 := _gen_sine(523.25, 0.2, sr, 0.25)
	var n2 := _gen_sine(659.25, 0.2, sr, 0.25)
	var n3 := _gen_sine(783.99, 0.3, sr, 0.3)
	var chord := _gen_chord([523.25, 659.25, 783.99], 0.4, sr, 0.35)
	var d := _mix_audio([n1, n2, n3, chord], 0.4, sr)
	_play_stream(d, sr, 2.0)

func play_defeat() -> void:
	var sr := 22050
	var d := _gen_sine(200, 0.5, sr, 0.25)
	_play_stream(d, sr, -2.0)

func play_coin() -> void:
	var sr := 22050
	var n1 := _gen_sine(880, 0.06, sr, 0.2)
	var n2 := _gen_sine(1100, 0.08, sr, 0.2)
	var d := _mix_audio([n1, n2], 0.1, sr)
	_play_stream(d, sr, -1.0)

func play_step() -> void:
	var sr := 22050
	var d := _gen_sine(200, 0.06, sr, 0.15, false)
	_play_stream(d, sr, -6.0)

func play_arrow() -> void:
	var sr := 22050
	var d := _gen_sweep(400, 800, 0.1, sr, 0.2)
	_play_stream(d, sr, -3.0)

func play_wind() -> void:
	var sr := 11025
	var n := int(sr * 2.0)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(sr)
		var env := maxf(0.0, 1.0 - t / 2.0)
		var sample := randf_range(-1.0, 1.0) * 0.06 * env
		sample += sin(TAU * 120.0 * t) * 0.04 * env
		var s16 := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	_play_stream(data, sr, -12.0)

func play_ambient_birds() -> void:
	var sr := 22050
	var d := _gen_sweep(800, 1200, 0.08, sr, 0.06)
	_play_stream(d, sr, -10.0)

func play_ambient_cricket() -> void:
	var sr := 22050
	var n := int(sr * 0.15)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(sr)
		var sample := sin(TAU * 2400.0 * t) * 0.04 * maxf(0.0, 1.0 - t / 0.15)
		if int(t * 40.0) % 2 == 0:
			sample = 0.0
		var s16 := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	_play_stream(data, sr, -14.0)
