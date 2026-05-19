extends CanvasLayer

@onready var gbi_texture = $InfoPanel/GBI   # TextureRect
@onready var gbt_label = $InfoPanel/GBT     # Label
@onready var dbi_label = $BottomBar/DBI     # Label (tour ou icône sous-menu)
@onready var dbt_button = $BottomBar/DBT    # Button
@onready var bt1_label = $TopBar/BT1        # Label
@onready var bt2_color = $TopBar/BT2        # ColorRect
@onready var bt3_label = $TopBar/BT3
@onready var bt4_label = $TopBar/BT4
@onready var cn_label = $InfoPanel/Cn       # Label (créature / nombre)

var _last_mode: GameData.SelectionMode = GameData.SelectionMode.NONE
var _last_id: int = -1
var _last_tile: Vector2i = Vector2i.ZERO

func _ready() -> void:
	GameData.selection_changed.connect(_on_selection_changed)
	GameData.turn_ended.connect(_on_turn_ended)
	_clear_all()

func _on_selection_changed(mode, id, tile):
	var gd = GameData

	match mode:
		GameData.SelectionMode.HERO:
			if id >= 0 and id < gd.heroes.size():
				var h = gd.heroes[id]
				gbi_texture.texture = h.sprite
				gbt_label.text = h.name
				_fill_top_bar(h.owner, "", "", "")
				cn_label.text = ""   # pas de créature sur le héros
		GameData.SelectionMode.CITY:
			if id >= 0 and id < gd.cities.size():
				var c = gd.cities[id]
				gbi_texture.texture = preload("res://assets/ui/city_icon.png")
				gbt_label.text = c.name
				_fill_top_bar(c.owner, c.resource_type, str(c.resource_per_day), "")
				cn_label.text = ""
		GameData.SelectionMode.BUILDING:
			if id >= 0 and id < gd.buildings.size():
				var b = gd.buildings[id]
				gbi_texture.texture = preload("res://assets/ui/building_icon.png")
				gbt_label.text = b.type
				_fill_top_bar(b.owner, b.resource_type, str(b.resource_per_day), "")
				cn_label.text = ""
		GameData.SelectionMode.TILE:
			var creature = _creature_on_tile(tile)
			if creature:
				cn_label.text = "%s × %d" % [creature.name, creature.amount]
			else:
				cn_label.text = ""
			gbi_texture.texture = null
			gbt_label.text = ""
			_clear_top_bar()
		_:
			_clear_all()

func _on_turn_ended(counter, max):
	dbi_label.text = "Tour %d / %d" % [counter, max]
	dbt_button.text = "Terminer le tour"

func _fill_top_bar(owner_id: int, res_type: String, res_amount: String, extra: String):
	bt1_label.text = "Joueur %d" % owner_id
	# couleur du joueur
	if owner_id >= 0 and owner_id < GameData.player_colors.size():
		bt2_color.color = GameData.player_colors[owner_id]
	else:
		bt2_color.color = Color.TRANSPARENT
	bt3_label.text = res_amount
	bt4_label.text = res_type

func _clear_top_bar():
	bt1_label.text = ""
	bt2_color.color = Color.TRANSPARENT
	bt3_label.text = ""
	bt4_label.text = ""

func _clear_all():
	gbi_texture.texture = null
	gbt_label.text = ""
	_clear_top_bar()
	cn_label.text = ""

func _creature_on_tile(pos: Vector2i) -> GameData.Creature:
	# Récupérer les créatures sur cette case depuis GameData
	if GameData.creatures_on_tile.has(pos):
		return GameData.creatures_on_tile[pos]
	return null
