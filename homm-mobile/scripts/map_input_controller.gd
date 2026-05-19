extends Node

enum MoveMode { DRAG, TAP_VALIDATE }

@export var move_mode: MoveMode = MoveMode.DRAG

# Référence au TileMap (ou à la grille) qui contient les tuiles
@onready var tilemap: TileMap = get_parent()

var _dragging_hero: GameData.Hero = null
var _drag_start_tile: Vector2i
var _preview_sprite: Sprite2D = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_pressed(event.position)
		else:
			_handle_touch_released(event.position)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event.position)

func _handle_touch_pressed(screen_pos: Vector2):
	var tile = tilemap.local_to_map(tilemap.to_local(screen_pos))
	
	# 1️⃣ Vérifier si on a touché un héros (ou ville, …)
	var hero = _hero_at_tile(tile)
	if hero:
		GameData.current_mode = GameData.SelectionMode.HERO
		GameData.current_id = hero.id
		GameData.current_tile = tile

		if move_mode == MoveMode.DRAG:
			_dragging_hero = hero
			_drag_start_tile = tile
		# si TAP_VALIDATE, on ne fait rien d'autre que sélectionner
		return

	# Si aucun héros, on peut sélectionner une ville/bâtiment…
	var city = _city_at_tile(tile)
	if city:
		GameData.current_mode = GameData.SelectionMode.CITY
		GameData.current_id = city.id
		GameData.current_tile = tile
		return
	
	var bld = _building_at_tile(tile)
	if bld:
		GameData.current_mode = GameData.SelectionMode.BUILDING
		GameData.current_id = bld.id
		GameData.current_tile = tile
		return

	# Sinon c'est simplement une case vide
	GameData.current_mode = GameData.SelectionMode.TILE
	GameData.current_tile = tile

func _handle_touch_drag(screen_pos: Vector2):
	if move_mode != MoveMode.DRAG or _dragging_hero == null:
		return
	
	var tile = tilemap.local_to_map(tilemap.to_local(screen_pos))
	# On montre visuellement le déplacement (ex: sprite temporaire)
	_show_preview_move(_dragging_hero, tile)

func _handle_touch_released(screen_pos: Vector2):
	if move_mode == MoveMode.DRAG and _dragging_hero:
		var target_tile = tilemap.local_to_map(tilemap.to_local(screen_pos))
		_execute_move(_dragging_hero, target_tile)
		_dragging_hero = null
		_hide_preview_move()
		return

	# Mode TAP_VALIDATE : rien à faire ici, l'action sera validée par le bouton DM
	# (le bouton DM déclenchera `_execute_move` avec le héros sélectionné + la tuile stockée)

func _execute_move(hero: GameData.Hero, dest_tile: Vector2i) -> void:
	# Vérifier déplacement valide (ex: portée, obstacle, etc.)
	if not _can_move_to(hero, dest_tile):
		print("Mouvement impossible")
		return
	
	hero.position = dest_tile
	# Mettre à jour la position dans le TileMap (déplacer le Sprite, etc.)
	_move_hero_sprite(hero, dest_tile)

func _can_move_to(hero: GameData.Hero, dest: Vector2i) -> bool:
	# Implémentation très basique – à étoffer avec la vraie logique de jeu
	# Vérifier que la destination n'est pas la même que la position actuelle
	if dest == hero.position:
		return false
	
	# Vérifier que la destination est dans les limites de la carte
	# (à implémenter selon la taille de votre carte)
	
	return true

func _move_hero_sprite(hero: GameData.Hero, dest: Vector2i) -> void:
	var sprite_node = get_node_or_null("../Heroes/%d" % hero.id)
	if sprite_node:
		sprite_node.position = tilemap.map_to_local(dest)

# -----------------------------------------------------------------
# Helpers de recherche (détecter héros / ville / bâtiment sur une tuile)
# -----------------------------------------------------------------
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
	# Crée ou met à jour un sprite semi-transparent qui suit la souris.
	# Cette fonction est purement visuelle – aucune donnée de jeu n'est modifiée.
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