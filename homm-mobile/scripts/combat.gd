extends Node2D

## Scène de combat tactique (inspiration Heroes III) : grille 10×8, tours joueur / IA,
## déplacement, attaque au corps à corps, PV affichés, victoire / défaite.

const GRID_W: int = 10
const GRID_H: int = 8
const TILE_SIZE: int = 80
const UNIT_SIZE: int = 60
const UNIT_MARGIN: int = (TILE_SIZE - UNIT_SIZE) / 2 # 10 px — centre la tuile 60×60 dans 80×80

const MOV_RANGE: int = 3
const BASE_HP: int = 10
const BASE_ATK: int = 2
const BASE_DEF: int = 1

const DIRS4: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

enum Phase { PLAYER, ENEMY, GAME_OVER }

## Données d’une unité (non lié à l’arbre de scène)
class CombatUnit extends RefCounted:
	var grid_pos: Vector2i
	var hp: int = BASE_HP
	var atk: int = BASE_ATK
	var def: int = BASE_DEF
	var is_player: bool = true
	var has_acted: bool = false
	# Référence au nœud graphique (évite une référence circulaire typée avec UnitVisual)
	var visual: Node2D


## Fond bleu-gris + quadrillage
class GridDrawer extends Node2D:
	func _draw() -> void:
		var w: float = GRID_W * TILE_SIZE
		var h: float = GRID_H * TILE_SIZE
		draw_rect(Rect2(0, 0, w, h), Color(0.34, 0.44, 0.54))
		for i in range(GRID_W + 1):
			var x: float = i * TILE_SIZE
			draw_line(Vector2(x, 0), Vector2(x, h), Color(0.2, 0.26, 0.34), 1.5)
		for j in range(GRID_H + 1):
			var y: float = j * TILE_SIZE
			draw_line(Vector2(0, y), Vector2(w, y), Color(0.2, 0.26, 0.34), 1.5)


## Représentation graphique : carré coloré + PV sous le sprite (texte)
class UnitVisual extends Node2D:
	var unit_data: CombatUnit
	var combat: Node2D

	func _draw() -> void:
		if unit_data.hp <= 0:
			return
		var base: Color = (
			Color(0.22, 0.48, 0.95) if unit_data.is_player else Color(0.92, 0.22, 0.22)
		)
		if combat._is_selected(unit_data):
			base = base.lightened(0.32)
		draw_rect(Rect2(Vector2.ZERO, Vector2(UNIT_SIZE, UNIT_SIZE)), base)
		var border: Color = Color(0.95, 0.95, 1.0) if combat._is_selected(unit_data) else Color(0.08, 0.08, 0.1)
		draw_rect(Rect2(Vector2.ZERO, Vector2(UNIT_SIZE, UNIT_SIZE)), border, false, 2.0)
		var fnt := ThemeDB.fallback_font
		var fs := 13
		var txt := "PV: %d" % unit_data.hp
		var sz := fnt.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var tx: float = (UNIT_SIZE - sz.x) * 0.5
		# Position verticale du texte (baseline) juste sous le carré 60×60
		var ty: float = float(UNIT_SIZE) + 14.0
		draw_string(fnt, Vector2(tx, ty), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.95, 0.95, 0.95))


@onready var _btn_retour: Button = $CanvasLayer/UI/BtnRetour
@onready var _label_end: Label = $CanvasLayer/UI/LabelEnd

var _phase: Phase = Phase.PLAYER
var _units: Array[CombatUnit] = []
var _occupant: Dictionary = {} # Vector2i -> CombatUnit
var _selected: CombatUnit = null

var _world_root: Node2D


func _ready() -> void:
	_world_root = Node2D.new()
	_world_root.name = "World"
	add_child(_world_root)

	var grid := GridDrawer.new()
	grid.z_index = -10
	_world_root.add_child(grid)

	_btn_retour.pressed.connect(_on_retour_pressed)
	_label_end.visible = false

	_spawn_armies()
	_phase = Phase.PLAYER


func _spawn_armies() -> void:
	var blues: Array[Vector2i] = [Vector2i(1, 2), Vector2i(1, 4), Vector2i(1, 6)]
	var reds: Array[Vector2i] = [Vector2i(8, 2), Vector2i(8, 4), Vector2i(8, 6)]
	for p in blues:
		_create_unit(p, true)
	for p in reds:
		_create_unit(p, false)


func _create_unit(cell: Vector2i, is_player: bool) -> void:
	var u := CombatUnit.new()
	u.grid_pos = cell
	u.is_player = is_player
	u.hp = BASE_HP
	u.atk = BASE_ATK
	u.def = BASE_DEF
	u.has_acted = false

	var vis := UnitVisual.new()
	vis.unit_data = u
	vis.combat = self
	vis.position = _cell_top_left(cell) + Vector2(UNIT_MARGIN, UNIT_MARGIN)
	u.visual = vis
	_world_root.add_child(vis)

	_units.append(u)
	_occupant[cell] = u


func _cell_top_left(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE_SIZE, cell.y * TILE_SIZE)


func _in_grid(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < GRID_W and c.y >= 0 and c.y < GRID_H


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _occupant_at(c: Vector2i) -> CombatUnit:
	return _occupant.get(c, null)


func _is_selected(u: CombatUnit) -> bool:
	return u != null and u == _selected


func _get_alive_units(player_team: bool) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	for u in _units:
		if u.hp > 0 and u.is_player == player_team:
			out.append(u)
	return out


func _all_player_units_acted() -> bool:
	var alive := _get_alive_units(true)
	if alive.is_empty():
		return false
	for u in alive:
		if not u.has_acted:
			return false
	return true


func _screen_to_cell(screen: Vector2) -> Vector2i:
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	var world: Vector2 = inv * screen
	var gx := int(floor(world.x / float(TILE_SIZE)))
	var gy := int(floor(world.y / float(TILE_SIZE)))
	return Vector2i(gx, gy)


func _is_over_ui(screen_pos: Vector2) -> bool:
	if _btn_retour.get_global_rect().has_point(screen_pos):
		return true
	if _label_end.visible and _label_end.get_global_rect().has_point(screen_pos):
		return true
	return false


func _input(event: InputEvent) -> void:
	if _phase == Phase.GAME_OVER:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _is_over_ui(event.position):
			return
		if _phase != Phase.PLAYER:
			return
		_handle_player_click(event.position)


func _handle_player_click(screen_pos: Vector2) -> void:
	var cell := _screen_to_cell(screen_pos)
	if not _in_grid(cell):
		return
	var clicked: CombatUnit = _occupant_at(cell)

	# Sélection : unité bleue qui n’a pas encore agi ce tour
	if clicked != null and clicked.is_player and not clicked.has_acted:
		if _selected == clicked:
			_selected = null
		else:
			_selected = clicked
		_redraw_units()
		return

	if _selected == null:
		return

	# Attaque : case ennemie adjacente
	if clicked != null and not clicked.is_player:
		if _manhattan(_selected.grid_pos, cell) == 1:
			_resolve_attack(_selected, clicked)
			_finish_player_action(_selected)
		else:
			_selected = null
			_redraw_units()
		return

	# Déplacement : case vide atteignable
	if clicked == null:
		if _reachable_cells(_selected.grid_pos).has(cell) and cell != _selected.grid_pos:
			_move_unit(_selected, cell)
			_finish_player_action(_selected)
		else:
			_selected = null
			_redraw_units()


func _reachable_cells(from: Vector2i) -> Dictionary:
	# Parcours en largeur : cases vides à distance 1..MOV_RANGE (orthogonal)
	var result: Dictionary = {}
	var queue: Array[Vector2i] = [from]
	var depth: Dictionary = {from: 0}
	var head := 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		var d: int = depth[c]
		if d >= MOV_RANGE:
			continue
		for dir in DIRS4:
			var n: Vector2i = c + dir
			if not _in_grid(n):
				continue
			if depth.has(n):
				continue
			if _occupant_at(n) != null:
				continue
			depth[n] = d + 1
			result[n] = true
			queue.append(n)
	return result


func _move_unit(u: CombatUnit, dest: Vector2i) -> void:
	_occupant.erase(u.grid_pos)
	u.grid_pos = dest
	_occupant[dest] = u
	u.visual.position = _cell_top_left(dest) + Vector2(UNIT_MARGIN, UNIT_MARGIN)
	_redraw_units()


func _resolve_attack(attacker: CombatUnit, defender: CombatUnit) -> void:
	var dmg: int = maxi(1, attacker.atk - defender.def)
	defender.hp -= dmg
	defender.visual.queue_redraw()
	if defender.hp <= 0:
		_kill_unit(defender)
	_check_victory_after_action()


func _kill_unit(u: CombatUnit) -> void:
	_occupant.erase(u.grid_pos)
	var idx := _units.find(u)
	if idx >= 0:
		_units.remove_at(idx)
	if _selected == u:
		_selected = null
	if u.visual:
		u.visual.queue_free()
		u.visual = null


func _check_victory_after_action() -> void:
	if _get_alive_units(true).is_empty():
		_show_end(false)
	elif _get_alive_units(false).is_empty():
		_show_end(true)


func _show_end(victory: bool) -> void:
	_phase = Phase.GAME_OVER
	_selected = null
	_label_end.text = "Victoire !" if victory else "Défaite…"
	_label_end.visible = true
	_redraw_units()


func _finish_player_action(u: CombatUnit) -> void:
	u.has_acted = true
	_selected = null
	_redraw_units()
	if _phase == Phase.GAME_OVER:
		return
	if _check_victory_after_turn():
		return
	if _all_player_units_acted():
		_enemy_turn_sequence()


func _check_victory_after_turn() -> bool:
	if _get_alive_units(true).is_empty():
		_show_end(false)
		return true
	if _get_alive_units(false).is_empty():
		_show_end(true)
		return true
	return false


func _redraw_units() -> void:
	for u in _units:
		if u.visual:
			u.visual.queue_redraw()


func _enemy_turn_sequence() -> void:
	_phase = Phase.ENEMY
	_selected = null
	_redraw_units()
	await get_tree().process_frame
	var reds: Array[CombatUnit] = _get_alive_units(false)
	for u in reds:
		if _phase == Phase.GAME_OVER:
			return
		await get_tree().create_timer(0.4).timeout
		if _phase == Phase.GAME_OVER:
			return
		_ai_act(u)
		if _phase == Phase.GAME_OVER:
			return

	if _phase == Phase.GAME_OVER:
		return
	# Nouveau tour joueur
	_phase = Phase.PLAYER
	for b in _get_alive_units(true):
		b.has_acted = false
	_redraw_units()


## IA : s’approche de l’allié bleu le plus proche ; attaque si adjacente.
func _ai_act(u: CombatUnit) -> void:
	var target := _closest_alive_opponent(u)
	if target == null:
		return
	if _manhattan(u.grid_pos, target.grid_pos) == 1:
		_resolve_attack(u, target)
		return
	var step := _best_step_toward(u.grid_pos, target.grid_pos)
	if step != Vector2i.ZERO:
		_move_unit(u, u.grid_pos + step)


func _closest_alive_opponent(u: CombatUnit) -> CombatUnit:
	var opp: Array[CombatUnit] = _get_alive_units(not u.is_player)
	var best: CombatUnit = null
	var best_d: int = 1_000_000
	for o in opp:
		var d := _manhattan(u.grid_pos, o.grid_pos)
		if d < best_d:
			best_d = d
			best = o
	return best


func _best_step_toward(from: Vector2i, to: Vector2i) -> Vector2i:
	var best_dir := Vector2i.ZERO
	var best_dist := 1_000_000
	for dir in DIRS4:
		var n: Vector2i = from + dir
		if not _in_grid(n):
			continue
		if _occupant_at(n) != null:
			continue
		var d := _manhattan(n, to)
		if d < best_dist:
			best_dist = d
			best_dir = dir
	return best_dir


func _on_retour_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tile_map_world.tscn")
