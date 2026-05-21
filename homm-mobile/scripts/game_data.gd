extends Node

# Singleton pour partager des données entre scènes

var should_load_save: bool = false
var player_name: String = "Héros"

# -------------------------------------------------
# STRUCTURES DE JEU
# -------------------------------------------------
class Creature:
	var name: String
	var amount: int

class Hero:
	var id: int
	var name: String
	var sprite: Texture2D
	var position: Vector2i       # coordonnées tile (x, y)
	var owner: int               # id du joueur
	var creatures: Array = []

class City:
	var id: int
	var name: String
	var position: Vector2i
	var owner: int
	var resource_type: String
	var resource_per_day: int
	var creatures: Array = []

class Building:
	var id: int
	var type: String
	var position: Vector2i
	var owner: int
	var resource_type: String = ""
	var resource_per_day: int = 0

# Collections
var heroes: Array[Hero] = []
var cities: Array[City] = []
var buildings: Array[Building] = []

# Example collection for creatures on tiles (from suggested edit)
var creatures_on_tile: Dictionary = {}   # clé = Vector2i, valeur = Creature


# Couleurs des joueurs
var player_colors: Array[Color] = [
	Color.RED,
	Color.BLUE,
	Color.GREEN,
	Color.YELLOW
]

# Sélection courante
enum SelectionMode { NONE, HERO, CITY, BUILDING, TILE }
var current_mode: SelectionMode = SelectionMode.NONE

# Signals
signal selection_changed(mode, id, tile)   # emitted when the current selection changes
signal turn_ended(counter, max)          # emitted when a turn finishes (used by the HUD)
signal move_requested(hero, dest)        # emitted by UI when a move is requested (tap‑tap)

# Turn counter (displayed in DBI/DBT)
var turn_counter: int = 0
var max_turns: int = 30   # configurable from the options menu

# Current selection details
var current_id: int = -1          # id of the selected element
var current_tile: Vector2i = Vector2i.ZERO

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

func set_selection(mode: SelectionMode, id: int = -1, tile: Vector2i = Vector2i.ZERO) -> void:
	current_mode = mode
	current_id = id
	current_tile = tile
	emit_signal("selection_changed", mode, id, tile)

func end_turn() -> void:
	turn_counter += 1
	emit_signal("turn_ended", turn_counter, max_turns)
	# Reset selection for the next turn
	set_selection(SelectionMode.NONE)

func save_game() -> void:
	var file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file == null:
		push_error("Impossible d'ouvrir le fichier de sauvegarde en écriture.")
		return
	var data = {
		"player_name": player_name,
		"turn_counter": turn_counter,
		"heroes": [],
		"cities": [],
		"buildings": [],
		"creatures_on_tile": []
	}
	for h in heroes:
		data["heroes"].append({
			"id": h.id,
			"name": h.name,
			"owner": h.owner,
			"position": [h.position.x, h.position.y]
		})
	for c in cities:
		data["cities"].append({
			"id": c.id,
			"name": c.name,
			"owner": c.owner,
			"position": [c.position.x, c.position.y],
			"resource_type": c.resource_type,
			"resource_per_day": c.resource_per_day
		})
	for b in buildings:
		data["buildings"].append({
			"id": b.id,
			"type": b.type,
			"owner": b.owner,
			"position": [b.position.x, b.position.y],
			"resource_type": b.resource_type,
			"resource_per_day": b.resource_per_day
		})
	for tile_pos in creatures_on_tile:
		var creature = creatures_on_tile[tile_pos]
		data["creatures_on_tile"].append({
			"position": [tile_pos.x, tile_pos.y],
			"name": creature.name,
			"amount": creature.amount
		})
	var json = JSON.stringify(data)
	file.store_string(json)
	file.close()


func load_game() -> void:
	if not FileAccess.file_exists("user://save_game.json"):
		push_warning("Aucune sauvegarde trouvée.")
		return
	var file = FileAccess.open("user://save_game.json", FileAccess.READ)
	if file == null:
		push_error("Impossible d'ouvrir le fichier de sauvegarde en lecture.")
		return
	var json_text = file.get_as_text()
	file.close()
	var json_parser = JSON.new()
	var result = json_parser.parse(json_text)
	if result.error != OK:
		push_error("Erreur de parsing JSON de sauvegarde : %s" % result.error_string)
		return
	var data = result.result
	player_name = data.get("player_name", "Héros")
	heroes.clear()
	for h_data in data.get("heroes", []):
		var h = Hero.new()
		h.id = h_data.get("id", -1)
		h.name = h_data.get("name", "")
		h.owner = h_data.get("owner", 0)
		var pos = h_data.get("position", [0,0])
		h.position = Vector2i(pos[0], pos[1])
		heroes.append(h)
	cities.clear()
	for c_data in data.get("cities", []):
		var c = City.new()
		c.id = c_data.get("id", -1)
		c.name = c_data.get("name", "")
		c.owner = c_data.get("owner", 0)
		var pos = c_data.get("position", [0,0])
		c.position = Vector2i(pos[0], pos[1])
		c.resource_type = c_data.get("resource_type", "")
		c.resource_per_day = c_data.get("resource_per_day", 0)
		cities.append(c)
	buildings.clear()
	for b_data in data.get("buildings", []):
		var b = Building.new()
		b.id = b_data.get("id", -1)
		b.type = b_data.get("type", "")
		b.owner = b_data.get("owner", 0)
		var pos = b_data.get("position", [0,0])
		b.position = Vector2i(pos[0], pos[1])
		b.resource_type = b_data.get("resource_type", "")
		b.resource_per_day = b_data.get("resource_per_day", 0)
		buildings.append(b)
	creatures_on_tile.clear()
	for c_data in data.get("creatures_on_tile", []):
		var pos = c_data.get("position", [0, 0])
		var tile_pos = Vector2i(pos[0], pos[1])
		var creature = Creature.new()
		creature.name = c_data.get("name", "")
		creature.amount = c_data.get("amount", 0)
		creatures_on_tile[tile_pos] = creature

func _ready() -> void:
	# Charger la sauvegarde si demandée
	if should_load_save:
		load_game()
	else:
		# Initialisation d'une nouvelle partie (exemple simple)
		player_name = "Héros"
		heroes.clear()
		cities.clear()
		buildings.clear()
		creatures_on_tile.clear()
		# TODO: ajouter la logique de création du monde initial

# Nettoyage lors de la fermeture du jeu
func _exit_tree() -> void:
	if should_load_save:
		save_game()
