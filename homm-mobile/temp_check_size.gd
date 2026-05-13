extends Node
func _ready():
	var img = Image.load_from_file("res://assets/external/plant_repack.png")
	if img:
		print("SIZE: " + str(img.get_width()) + "x" + str(img.get_height()))
	else:
		print("ERROR: Cannot load image")
	get_tree().quit()
