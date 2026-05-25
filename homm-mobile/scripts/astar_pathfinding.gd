class_name AStarPathfinding extends RefCounted

# Calcule un chemin A* de start à end sur la grille de terrain.
# terrain_grid[x][y] = terrain_type
# move_cost[terrain_type] = coût en MP pour traverser cette case
# max_mp = limite de points de mouvement (0 = pas de limite)
# start, end = Vector2i
# Retourne un Array de Vector2i (le chemin complet, start inclu)
static func find_path(
	terrain_grid: Array,
	move_cost: Dictionary,
	start: Vector2i,
	end: Vector2i,
	max_mp: int = 0
) -> Array:
	var w: int = terrain_grid.size()
	if w == 0:
		return []
	var h: int = terrain_grid[0].size()
	if start.x < 0 or start.y < 0 or start.x >= w or start.y >= h:
		return []
	if end.x < 0 or end.y < 0 or end.x >= w or end.y >= h:
		return []

	if start == end:
		return [start]

	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {}
	var f_score: Dictionary = {}
	var key := func(v: Vector2i) -> String: return "%d,%d" % [v.x, v.y]

	g_score[key.call(start)] = 0
	f_score[key.call(start)] = _heuristic(start, end)

	while open_set.size() > 0:
		var current: Vector2i = _lowest_f(open_set, f_score, key)
		if current == end:
			return _reconstruct_path(came_from, current, key)
		open_set.erase(current)

		for neighbor in _get_neighbors(current, w, h):
			var terrain: int = terrain_grid[neighbor.x][neighbor.y]
			var step_cost: int = move_cost.get(terrain, 1)
			if step_cost >= 999:
				continue
			var tentative_g: int = g_score.get(key.call(current), 999999) + step_cost
			if max_mp > 0 and tentative_g > max_mp:
				continue
			if tentative_g < g_score.get(key.call(neighbor), 999999):
				came_from[key.call(neighbor)] = current
				g_score[key.call(neighbor)] = tentative_g
				f_score[key.call(neighbor)] = tentative_g + _heuristic(neighbor, end)
				if not open_set.has(neighbor):
					open_set.append(neighbor)

	return []

# Heuristique de Manhattan
static func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

static func _lowest_f(set: Array[Vector2i], f_score: Dictionary, key: Callable) -> Vector2i:
	var best: Vector2i = set[0]
	var best_f: int = f_score.get(key.call(best), 999999)
	for v in set:
		var f: int = f_score.get(key.call(v), 999999)
		if f < best_f:
			best = v
			best_f = f
	return best

static func _get_neighbors(pos: Vector2i, w: int, h: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var n: Vector2i = pos + d
		if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h:
			result.append(n)
	return result

static func _reconstruct_path(came_from: Dictionary, current: Vector2i, key: Callable) -> Array:
	var path: Array = [current]
	while came_from.has(key.call(current)):
		current = came_from[key.call(current)]
		path.push_front(current)
	return path

# Calcule le coût total d'un chemin
static func path_cost(
	path: Array,
	terrain_grid: Array,
	move_cost: Dictionary
) -> int:
	var total: int = 0
	for i in range(1, path.size()):
		var t: Vector2i = path[i]
		var terrain: int = terrain_grid[t.x][t.y]
		total += move_cost.get(terrain, 1)
	return total

# Calcule la zone de déplacement (portée max) depuis start
static func reachable_tiles(
	terrain_grid: Array,
	move_cost: Dictionary,
	start: Vector2i,
	max_mp: int
) -> Array[Vector2i]:
	var w: int = terrain_grid.size()
	if w == 0:
		return []
	var h: int = terrain_grid[0].size()

	var result: Array[Vector2i] = []
	var visited: Dictionary = {}
	var key := func(v: Vector2i) -> String: return "%d,%d" % [v.x, v.y]
	var queue: Array[Vector2i] = [start]
	visited[key.call(start)] = 0

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()
		var current_cost: int = visited.get(key.call(current), 0)
		if current != start:
			result.append(current)

		for neighbor in _get_neighbors(current, w, h):
			var terrain: int = terrain_grid[neighbor.x][neighbor.y]
			var step_cost: int = move_cost.get(terrain, 1)
			if step_cost >= 999:
				continue
			var new_cost: int = current_cost + step_cost
			if new_cost > max_mp:
				continue
			var existing: int = visited.get(key.call(neighbor), 999999)
			if new_cost < existing:
				visited[key.call(neighbor)] = new_cost
				queue.append(neighbor)

	return result
