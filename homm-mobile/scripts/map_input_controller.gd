extends Node

enum MoveMode { DRAG, TAP_VALIDATE }

@export var move_mode: MoveMode = MoveMode.DRAG

@onready var tilemap: TileMap = get_parent()

var _dragging_hero: GameData.Hero = null
var _drag_start_tile: Vector2i
var _preview_sprite: Sprite2D = null
var _tap_selected_hero: GameData.Hero = null
var _tap_target_tile: Vector2i = Vector2i.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_pressed(event.position)
		else:
			_handle_touch_released(event.position)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_touch_pressed(event.position)
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_touch_released(event.position)

func _handle_touch_pressed(screen_pos: Vector2):
	var tile = tilemap.local_to_map(tilemap.to_local(screen_pos))
	
	var hero = _hero_at_tile(tile)
	if hero:
		GameData.set_selection(GameData.SelectionMode.HERO, hero.id, tile)
		if move_mode == MoveMode.DRAG:
			_dragging_hero = hero
			_drag_start_tile = tile
		else:
			_tap_selected_hero = hero
			_tap_target_tile = Vector2i.ZERO
		return

	var city = _city_at_tile(tile)
	if city:
		GameData.set_selection(GameData.SelectionMode.CITY, city.id, tile)
		return
	
	var bld = _building_at_tile(tile)
	if bld:
		GameData.set_selection(GameData.SelectionMode.BUILDING, bld.id, tile)
		return

	# Clique sur une tuile vide
	if move_mode == MoveMode.TAP_VALIDATE and _tap_selected_hero != null:
		_tap_target_tile = tile
		_show_preview_move(_tap_selected_hero, tile)
		return

	GameData.set_selection(GameData.SelectionMode.TILE, -1, tile)

func _handle_touch_drag(screen_pos: Vector2):
	if move_mode != MoveMode.DRAG or _dragging_hero == null:
		return
	
	var tile = tilemap.local_to_map(tilemap.to_local(screen_pos))
	_show_preview_move(_dragging_hero, tile)

func _handle_touch_released(screen_pos: Vector2):
	if move_mode == MoveMode.DRAG and _dragging_hero:
		var target_tile = tilemap.local_to_map(tilemap.to_local(screen_pos))
		if _can_move_to(_dragging_hero, target_tile):
			_execute_move(_dragging_hero, target_tile)
		_dragging_hero = null
		_hide_preview_move()
		return

func get_tap_target() -> Dictionary:
	if _tap_selected_hero and _tap_target_tile != Vector2i.ZERO and _tap_target_tile != _tap_selected_hero.position:
		return {"hero": _tap_selected_hero, "dest": _tap_target_tile}
	return {}

func validate_tap_move() -> bool:
	var target = get_tap_target()
	if not target.is_empty():
		var hero = target["hero"] as GameData.Hero
		var dest = target["dest"] as Vector2i
		if _can_move_to(hero, dest):
			_execute_move(hero, dest)
			_tap_selected_hero = null
			_tap_target_tile = Vector2i.ZERO
			_hide_preview_move()
			return true
	return false

func cancel_tap_move():
	_tap_selected_hero = null
	_tap_target_tile = Vector2i.ZERO
	_hide_preview_move()

func _execute_move(hero: GameData.Hero, dest_tile: Vector2i) -> void:
	if not _can_move_to(hero, dest_tile):
		print("Mouvement impossible")
		return
	
	hero.position = dest_tile
	_move_hero_sprite(hero, dest_tile)

func _can_move_to(hero: GameData.Hero, dest: Vector2i) -> bool:
	if dest == hero.position:
		return false
	return true

func _move_hero_sprite(hero: GameData.Hero, dest: Vector2i) -> void:
	var sprite_node = get_node_or_null("../Heroes/%d" % hero.id)
	if sprite_node:
		sprite_node.position = tilemap.map_to_local(dest)

func _hero_at_tile(t: Vector2i) -> GameData.Hero:
	for h in GameData.heroes:
		if h.position == t:
			return h
	return null

func _city_at_tile(t: Vector2i) -> GameData.City:
	for c in GameData.cities:
		if c.position == t:
			return c
	return null

func _building_at_tile(t: Vector2i) -> GameData.Building:
	for b in GameData.buildings:
		if b.position == t:
			return b
	return null

func _show_preview_move(hero: GameData.Hero, target: Vector2i) -> void:
	if _preview_sprite == null:
		_preview_sprite = Sprite2D.new()
		_preview_sprite.modulate = Color(1, 1, 1, 0.5)
		get_parent().add_child(_preview_sprite)
	
	if hero.sprite:
		_preview_sprite.texture = hero.sprite
		_preview_sprite.position = tilemap.map_to_local(target)

func _hide_preview_move():
	if _preview_sprite:
		_preview_sprite.queue_free()
		_preview_sprite = null
