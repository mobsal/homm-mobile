class_name CombatVFX
extends RefCounted

var _parent: Node
var _particles: Array = []

func _init(parent: Node) -> void:
	_parent = parent

func fire_explosion(position: Vector2, scale: float = 1.0) -> void:
	for i in range(20):
		var p := ColorRect.new()
		p.size = Vector2(randf_range(4, 12) * scale, randf_range(4, 12) * scale)
		var colors: Array = [Color(1.0, 0.6, 0.1), Color(1.0, 0.3, 0.05), Color(1.0, 0.8, 0.2), Color(0.8, 0.1, 0.0)]
		p.color = colors[randi() % colors.size()]
		p.position = position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_parent.add_child(p)
		var angle := randf() * TAU
		var speed := randf_range(80, 200) * scale
		var target := position + Vector2(cos(angle), sin(angle)) * speed * 0.3
		var tween := _parent.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(p, "position", target, 0.3)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.3)
		tween.tween_callback(p.queue_free)

func ice_explosion(position: Vector2, scale: float = 1.0) -> void:
	for i in range(15):
		var p := ColorRect.new()
		p.size = Vector2(randf_range(3, 8) * scale, randf_range(8, 16) * scale)
		p.color = Color(0.7, 0.85, 1.0, 0.9)
		p.position = position + Vector2(randf_range(-3, 3), randf_range(-3, 3))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_parent.add_child(p)
		var angle := randf() * TAU
		var speed := randf_range(100, 250) * scale
		var target := position + Vector2(cos(angle), sin(angle)) * speed * 0.3
		p.rotation = randf() * TAU
		var tween := _parent.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(p, "position", target, 0.35)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.35)
		tween.parallel().tween_property(p, "rotation", p.rotation + randf_range(3, 6), 0.35)
		tween.tween_callback(p.queue_free)

func lightning_strike(position: Vector2, duration: float = 0.15) -> void:
	for i in range(3):
		var bolt := ColorRect.new()
		bolt.size = Vector2(randf_range(2, 5), randf_range(60, 120))
		bolt.color = Color(0.8, 0.9, 1.0, 0.8)
		bolt.position = position + Vector2(randf_range(-20, 20), -bolt.size.y / 2)
		bolt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_parent.add_child(bolt)
		var tween := _parent.create_tween()
		tween.tween_property(bolt, "modulate:a", 0.0, duration).from(0.9)
		tween.tween_callback(bolt.queue_free)

func heal_burst(position: Vector2) -> void:
	for i in range(12):
		var p := ColorRect.new()
		p.size = Vector2(randf_range(4, 8), randf_range(4, 8))
		p.color = Color(0.3, 0.9, 0.5, 0.7)
		p.position = position + Vector2(randf_range(-4, 4), randf_range(-4, 4))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_parent.add_child(p)
		var angle := randf() * TAU
		var speed := randf_range(60, 140)
		var target := position + Vector2(cos(angle), sin(angle)) * speed * 0.3
		var tween := _parent.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(p, "position", target, 0.4)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.4)
		tween.tween_callback(p.queue_free)

func magic_rays(center: Vector2, color: Color = Color(0.6, 0.4, 1.0), count: int = 8) -> void:
	for i in range(count):
		var angle := (float(i) / float(count)) * TAU
		var ray := ColorRect.new()
		ray.size = Vector2(randf_range(2, 4), randf_range(20, 40))
		ray.color = color
		ray.position = center
		ray.rotation = angle
		ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_parent.add_child(ray)
		var target_pos := center + Vector2(cos(angle), sin(angle)) * randf_range(30, 60)
		var tween := _parent.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(ray, "position", target_pos, 0.2)
		tween.parallel().tween_property(ray, "modulate:a", 0.0, 0.3)
		tween.tween_callback(ray.queue_free)

func screen_shatter(duration: float = 0.5) -> void:
	var shards := 24
	for i in range(shards):
		var shard := ColorRect.new()
		shard.size = Vector2(randf_range(4, 20), randf_range(4, 20))
		shard.color = Color(0.7, 0.7, 0.75, 0.6)
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shard.set_anchors_preset(Control.PRESET_FULL_RECT)
		_parent.add_child(shard)
		var angle := randf() * TAU
		var speed := randf_range(200, 500)
		var tween := _parent.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(shard, "position", Vector2(cos(angle), sin(angle)) * speed, duration)
		tween.parallel().tween_property(shard, "modulate:a", 0.0, duration)
		tween.parallel().tween_property(shard, "rotation", randf_range(-3, 3), duration)
		tween.tween_callback(shard.queue_free)

func sword_slash(position: Vector2, direction: Vector2 = Vector2.RIGHT, scale: float = 1.0) -> void:
	var arc_parts := 8
	for i in range(arc_parts):
		var seg := ColorRect.new()
		seg.size = Vector2(16 * scale, randf_range(2, 4) * scale)
		var t := float(i) / float(arc_parts)
		var angle_offset := (t - 0.5) * 1.8
		var dir := direction.rotated(angle_offset)
		seg.position = position + dir * (10 + t * 20) * scale
		seg.rotation = dir.angle()
		seg.color = Color(0.95, 0.85, 0.6, 0.7 * (1.0 - t))
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_parent.add_child(seg)
		var tween := _parent.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(seg, "modulate:a", 0.0, 0.15)
		tween.parallel().tween_property(seg, "position", seg.position + dir * 20 * scale, 0.15)
		tween.tween_callback(seg.queue_free)

func hit_impact(position: Vector2, scale: float = 1.0) -> void:
	var ring := ColorRect.new()
	ring.size = Vector2(4 * scale, 4 * scale)
	ring.color = Color(1.0, 0.9, 0.7, 0.8)
	ring.position = position - ring.size / 2
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_parent.add_child(ring)
	var rt := _parent.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	rt.tween_property(ring, "size", Vector2(60 * scale, 60 * scale), 0.2)
	rt.parallel().tween_property(ring, "modulate:a", 0.0, 0.2)
	rt.parallel().tween_property(ring, "position", position - Vector2(30 * scale, 30 * scale), 0.2)
	rt.tween_callback(ring.queue_free)
	spark_burst(position, 6, Color(1.0, 0.85, 0.5), scale)

func spark_burst(position: Vector2, count: int = 8, color: Color = Color(1.0, 0.8, 0.3), scale: float = 1.0) -> void:
	for i in range(count):
		var s := ColorRect.new()
		s.size = Vector2(randf_range(2, 5) * scale, randf_range(1, 3) * scale)
		s.color = color
		s.position = position + Vector2(randf_range(-2, 2), randf_range(-2, 2))
		s.rotation = randf() * TAU
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_parent.add_child(s)
		var angle := randf() * TAU
		var dist := randf_range(20, 50) * scale
		var target := position + Vector2(cos(angle), sin(angle)) * dist
		var tween := _parent.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(s, "position", target, 0.2)
		tween.parallel().tween_property(s, "modulate:a", 0.0, 0.25)
		tween.parallel().tween_property(s, "rotation", s.rotation + randf_range(-2, 2), 0.2)
		tween.tween_callback(s.queue_free)

func death_effect(position: Vector2) -> void:
	for i in range(10):
		var p := ColorRect.new()
		p.size = Vector2(randf_range(6, 14), randf_range(6, 14))
		p.color = Color(0.4, 0.05, 0.05, 0.8)
		p.position = position + Vector2(randf_range(-4, 4), randf_range(-4, 4))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_parent.add_child(p)
		var angle := randf() * TAU
		var speed := randf_range(60, 150)
		var target := position + Vector2(cos(angle), sin(angle)) * speed * 0.25
		var tween := _parent.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(p, "position", target, 0.4)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.4)
		tween.parallel().tween_property(p, "rotation", randf_range(-3, 3), 0.4)
		tween.parallel().tween_property(p, "size", p.size * 0.3, 0.4)
		tween.tween_callback(p.queue_free)
	
	var sk := ColorRect.new()
	sk.size = Vector2(30, 30)
	sk.color = Color(0.15, 0.08, 0.08, 0.6)
	sk.position = position - Vector2(15, 15)
	sk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sk.rotation = randf() * TAU
	_parent.add_child(sk)
	var st := _parent.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	st.tween_property(sk, "modulate:a", 0.0, 0.6)
	st.parallel().tween_property(sk, "rotation", sk.rotation + randf_range(1, 3), 0.6)
	st.parallel().tween_property(sk, "scale", Vector2(0.3, 0.3), 0.6)
	st.tween_callback(sk.queue_free)

func critical_hit(position: Vector2) -> void:
	var star_rays := 12
	for i in range(star_rays):
		var ray := ColorRect.new()
		ray.size = Vector2(3, randf_range(20, 40))
		var angle := (float(i) / float(star_rays)) * TAU
		ray.color = Color(1.0, 0.9, 0.4, 0.9)
		ray.position = position
		ray.rotation = angle
		ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_parent.add_child(ray)
		var target_pos := position + Vector2(cos(angle), sin(angle)) * randf_range(30, 50)
		var tween := _parent.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(ray, "position", target_pos, 0.25)
		tween.parallel().tween_property(ray, "modulate:a", 0.0, 0.3)
		tween.tween_callback(ray.queue_free)
	
	var flash := ColorRect.new()
	flash.size = Vector2(40, 40)
	flash.color = Color(1.0, 0.95, 0.7, 0.6)
	flash.position = position - Vector2(20, 20)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_parent.add_child(flash)
	var ft := _parent.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	ft.tween_property(flash, "modulate:a", 0.0, 0.2)
	ft.parallel().tween_property(flash, "size", Vector2(80, 80), 0.2)
	ft.parallel().tween_property(flash, "position", position - Vector2(40, 40), 0.2)
	ft.tween_callback(flash.queue_free)
	
	spark_burst(position, 12, Color(1.0, 0.9, 0.2), 1.2)

func projectile_trail(start_pos: Vector2, end_pos: Vector2, color: Color = Color(1.0, 0.8, 0.3), trail_length: int = 6) -> void:
	for i in range(trail_length):
		var trail := ColorRect.new()
		trail.size = Vector2(randf_range(4, 8), randf_range(4, 8))
		trail.color = Color(color.r, color.g, color.b, 0.5 - float(i) / (trail_length * 2))
		trail.position = start_pos
		trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_parent.add_child(trail)
		var t := float(i + 1) / float(trail_length)
		var offset := Vector2(randf_range(-3, 3), randf_range(-3, 3))
		var tt := _parent.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tt.tween_method(func(p: Vector2): trail.position = p, start_pos + offset, end_pos + offset, 0.2 * (0.3 + t * 0.7))
		tt.parallel().tween_property(trail, "modulate:a", 0.0, 0.2 * (0.3 + t * 0.7))
		tt.parallel().tween_property(trail, "size", Vector2(2, 2), 0.2 * (0.3 + t * 0.7))
		tt.tween_callback(trail.queue_free)
	
	var glow := ColorRect.new()
	glow.size = Vector2(12, 12)
	glow.color = Color(color.r, color.g, color.b, 0.4)
	glow.position = end_pos - Vector2(6, 6)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_parent.add_child(glow)
	var gt := _parent.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	gt.tween_property(glow, "modulate:a", 0.0, 0.15)
	gt.parallel().tween_property(glow, "size", Vector2(24, 24), 0.15)
	gt.parallel().tween_property(glow, "position", end_pos - Vector2(12, 12), 0.15)
	gt.tween_callback(glow.queue_free)
