extends Button

func _pressed() -> void:
	if GameData.current_mode != GameData.SelectionMode.HERO:
		return
	if GameData.current_id < 0 or GameData.current_id >= GameData.heroes.size():
		return
	
	var hero = GameData.heroes[GameData.current_id]
	var dest = GameData.current_tile
	
	# Emission du signal → MapInputController décide si c’est un déplacement ou autre action
	GameData.emit_signal("move_requested", hero, dest)

