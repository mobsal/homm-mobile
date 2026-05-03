extends Node2D

## Scène de carte 20×20 en tuiles carrées 64×64 avec placement aléatoire,
## héros (carré rouge), pathfinding A*, points de mouvement par tour et UI.
## Caméra : pan (1 doigt / clic gauche glissé), pinch, molette.

const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 20
const TILE_SIZE: int = 64

const ATLAS_GRASS: Vector2i = Vector2i(0, 0)
const ATLAS_FOREST: Vector2i = Vector2i(1, 0)
const ATLAS_MOUNTAIN: Vector2i = Vector2i(2, 0)

const SOURCE_ID: int = 0

const ZOOM_MIN: float = 0.2
const ZOOM_MAX: float = 8.0

# Points de mouvement max par tour (chaque tuile traversée en coûte 1)
const MOVEMENT_POINTS_MAX: int = 5
# Au-delà de ce déplacement en pixels, un clic souris est considéré comme un pan
const MOUSE_DRAG_CLICK_THRESHOLD: float = 12.0
const TAP_DRAG_THRESHOLD: float = 14.0

const COLOR_GRASS: Color = Color(0.45, 0.82, 0.38)
const COLOR_FOREST: Color = Color(0.08, 0.32, 0.12)
const COLOR_MOUNTAIN: Color = Color(0.78, 0.80, 0.82)

@onready var _tile_layer: TileMapLayer = $TileMapLayer
@onready var _camera: Camera2D = $Camera2D
@onready var _hero: Node2D = $Hero
@onready var _label_movement: Label = $CanvasLayer/UI/LabelMovement
@onready var _btn_end_turn: Button = $CanvasLayer/UI/BtnEndTurn

var _touches: Dictionary = {}
var _last_pinch_distance: float = -1.0
var _mouse_panning: bool = false
var _mouse_drag_accum: float = 0.0
# Cumul du déplacement par index de doigt (détection tap vs pan tactile)
var _touch_drag_amount: Dictionary = {}
# True si deux doigts ont été vus pendant le geste courant (évite un « tap » au relâché après un pinch)
var _gesture_had_pinch: bool = false

var _movement_points: int = MOVEMENT_POINTS_MAX
var _hero_cell: Vector2i = Vector2i.ZERO
var _hero_moving: bool = false


func _ready() -> void:
	_tile_layer.tile_set = _build_tile_set()
	_randomize_tiles()
	_spawn_hero_random_cell()
	_update_movement_label()
	_btn_end_turn.pressed.connect(_on_fin_de_tour_pressed)
	call_deferred("_center_camera_and_fit_zoom")


func _build_tile_set() -> TileSet:
	var img := Image.create(TILE_SIZE * 3, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(0, 0, TILE_SIZE, TILE_SIZE), COLOR_GRASS)
	img.fill_rect(Rect2i(TILE_SIZE, 0, TILE_SIZE, TILE_SIZE), COLOR_FOREST)
	img.fill_rect(Rect2i(TILE_SIZE * 2, 0, TILE_SIZE, TILE_SIZE), COLOR_MOUNTAIN)

	var tex := ImageTexture.create_from_image(img)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	atlas.create_tile(ATLAS_GRASS)
	atlas.create_tile(ATLAS_FOREST)
	atlas.create_tile(ATLAS_MOUNTAIN)

	var tileset := TileSet.new()
	tileset.add_source(atlas, SOURCE_ID)
	return tileset


func _randomize_tiles() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var atlas_coords := _random_atlas_coords()
			_tile_layer.set_cell(Vector2i(x, y), SOURCE_ID, atlas_coords)


func _random_atlas_coords() -> Vector2i:
	match randi_range(0, 2):
		0:
			return ATLAS_GRASS
		1:
			return ATLAS_FOREST
		_:
			return ATLAS_MOUNTAIN


func _map_size_px() -> Vector2:
	return Vector2(GRID_WIDTH * TILE_SIZE, GRID_HEIGHT * TILE_SIZE)


## Au démarrage : centre de la carte 1280×1280 (640, 640) et zoom fixe pour l’éditeur.
func _center_camera_and_fit_zoom() -> void:
	_camera.position = Vector2(640, 640)
	_camera.zoom = Vector2(0.5, 0.5)
	_camera.make_current()


func _spawn_hero_random_cell() -> void:
	_hero_cell = Vector2i(randi_range(0, GRID_WIDTH - 1), randi_range(0, GRID_HEIGHT - 1))
	_place_hero_at_cell(_hero_cell)


## Place le coin haut-gauche du sprite 64×64 sur l’origine de la tuile en coordonnées carte.
func _place_hero_at_cell(c: Vector2i) -> void:
	_hero_cell = c
	_hero.global_position = _tile_layer.to_global(_tile_layer.map_to_local(c))


func _update_movement_label() -> void:
	_label_movement.text = "Mouvement restant : %d / %d" % [_movement_points, MOVEMENT_POINTS_MAX]


func _on_fin_de_tour_pressed() -> void:
	_movement_points = MOVEMENT_POINTS_MAX
	_update_movement_label()


func _is_point_over_end_turn_button(screen_pos: Vector2) -> bool:
	return _btn_end_turn.get_global_rect().has_point(screen_pos)


func _screen_to_world_global(screen_pos: Vector2) -> Vector2:
	var viewport := get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * screen_pos


func _world_global_to_map_cell(world_global: Vector2) -> Vector2i:
	var local_on_layer := _tile_layer.to_local(world_global)
	return _tile_layer.local_to_map(local_on_layer)


func _try_move_hero_to_screen(screen_pos: Vector2) -> void:
	if _hero_moving or _movement_points <= 0:
		return
	if _is_point_over_end_turn_button(screen_pos):
		return
	var world := _screen_to_world_global(screen_pos)
	var target_cell := _world_global_to_map_cell(world)
	if not _in_bounds(target_cell):
		return
	_request_move_to_cell(target_cell)


func _request_move_to_cell(target_cell: Vector2i) -> void:
	var path := _find_path_astar(_hero_cell, target_cell)
	if path.size() < 2:
		return
	var steps_available: int = path.size() - 1
	var steps_to_walk: int = mini(steps_available, _movement_points)
	if steps_to_walk <= 0:
		return
	_movement_points -= steps_to_walk
	_update_movement_label()
	_animate_hero_along_path(path, steps_to_walk)


func _animate_hero_along_path(path: Array, steps_to_walk: int) -> void:
	_hero_moving = true
	var tween := create_tween()
	tween.set_parallel(false)
	for i in range(1, steps_to_walk + 1):
		var cell: Vector2i = path[i]
		var gpos: Vector2 = _tile_layer.to_global(_tile_layer.map_to_local(cell))
		tween.tween_property(_hero, "global_position", gpos, 0.11)
	tween.finished.connect(
		func():
			_hero_cell = path[steps_to_walk]
			_hero_moving = false
	)


func _in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < GRID_WIDTH and c.y >= 0 and c.y < GRID_HEIGHT


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## A* sur grille 4-voisins ; toutes les tuiles sont traversables (coût 1 par case).
func _find_path_astar(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if start == goal:
		return [start]

	var open_list: Array[Vector2i] = [start]
	var came_from: Dictionary = {} # Vector2i -> Vector2i
	var g_score: Dictionary = {start: 0} # Vector2i -> int
	var f_score: Dictionary = {start: _manhattan(start, goal)} # Vector2i -> int

	while not open_list.is_empty():
		var current: Vector2i = open_list[0]
		var best_f: int = 1_000_000_000
		for node in open_list:
			var f: int = f_score.get(node, 1_000_000_000)
			if f < best_f:
				best_f = f
				current = node

		if current == goal:
			return _reconstruct_path(came_from, current)

		var idx := open_list.find(current)
		if idx >= 0:
			open_list.remove_at(idx)

		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbor: Vector2i = current + dir
			if not _in_bounds(neighbor):
				continue
			var tentative_g: int = g_score[current] + 1
			if tentative_g < g_score.get(neighbor, 1_000_000_000):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _manhattan(neighbor, goal)
				if not open_list.has(neighbor):
					open_list.append(neighbor)

	return []


func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var rev: Array[Vector2i] = []
	var c: Vector2i = current
	while true:
		rev.append(c)
		if not came_from.has(c):
			break
		c = came_from[c]
	rev.reverse()
	return rev


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_screen_touch(event)
	elif event is InputEventScreenDrag:
		_on_screen_drag(event)
	elif event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion and _mouse_panning:
		_camera.position -= event.relative / _camera.zoom
		_mouse_drag_accum += event.relative.length()


func _on_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touches.is_empty():
			_gesture_had_pinch = false
		_touches[event.index] = event.position
		_touch_drag_amount[event.index] = 0.0
		if _touches.size() == 2:
			_gesture_had_pinch = true
			_last_pinch_distance = _pinch_distance()
	else:
		var was_only_finger: bool = _touches.size() == 1
		var drag_amt: float = _touch_drag_amount.get(event.index, 0.0)
		_touches.erase(event.index)
		_touch_drag_amount.erase(event.index)
		if _touches.size() < 2:
			_last_pinch_distance = -1.0
		# Tap : un seul doigt, peu de déplacement, pas pendant un déplacement du héros
		if (
			was_only_finger
			and not _gesture_had_pinch
			and drag_amt < TAP_DRAG_THRESHOLD
			and not _hero_moving
			and not _is_point_over_end_turn_button(event.position)
		):
			_try_move_hero_to_screen(event.position)


func _on_screen_drag(event: InputEventScreenDrag) -> void:
	if _touch_drag_amount.has(event.index):
		_touch_drag_amount[event.index] = _touch_drag_amount[event.index] + event.relative.length()

	_touches[event.index] = event.position
	if _touches.size() >= 2:
		_apply_pinch_zoom()
	elif _touches.size() == 1:
		_camera.position -= event.relative / _camera.zoom


func _pinch_distance() -> float:
	var keys := _touches.keys()
	keys.sort()
	if keys.size() < 2:
		return -1.0
	var a: Vector2 = _touches[keys[0]]
	var b: Vector2 = _touches[keys[1]]
	return a.distance_to(b)


func _apply_pinch_zoom() -> void:
	var dist := _pinch_distance()
	if dist <= 0.0:
		return
	if _last_pinch_distance > 0.0:
		var factor: float = dist / _last_pinch_distance
		var z := _camera.zoom * factor
		z.x = clampf(z.x, ZOOM_MIN, ZOOM_MAX)
		z.y = clampf(z.y, ZOOM_MIN, ZOOM_MAX)
		_camera.zoom = z
	_last_pinch_distance = dist


func _on_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_panning = true
			_mouse_drag_accum = 0.0
		else:
			_mouse_panning = false
			if (
				_mouse_drag_accum < MOUSE_DRAG_CLICK_THRESHOLD
				and not _hero_moving
				and not _is_point_over_end_turn_button(event.position)
			):
				_try_move_hero_to_screen(event.position)
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_zoom_camera_at_screen_point(1.1, event.position)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_zoom_camera_at_screen_point(1.0 / 1.1, event.position)


func _zoom_camera_at_screen_point(factor: float, screen_pos: Vector2) -> void:
	var viewport := get_viewport()
	var inv_before := viewport.get_canvas_transform().affine_inverse()
	var world_before: Vector2 = inv_before * screen_pos
	var new_zoom := _camera.zoom * factor
	new_zoom.x = clampf(new_zoom.x, ZOOM_MIN, ZOOM_MAX)
	new_zoom.y = clampf(new_zoom.y, ZOOM_MIN, ZOOM_MAX)
	_camera.zoom = new_zoom
	var inv_after := viewport.get_canvas_transform().affine_inverse()
	var world_after: Vector2 = inv_after * screen_pos
	_camera.global_position += world_before - world_after
