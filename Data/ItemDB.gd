extends Node

const ICON_PATH = "res://Sprites/Items/"
var ITEMS
var EQUIPMENT = []

func _ready():
	var item_data_file = File.new()
	item_data_file.open("res://Data/ItemData.json", File.READ)
	var item_data_json = JSON.parse(item_data_file.get_as_text())
	item_data_file.close()
	ITEMS = item_data_json.result
	for item in ITEMS:
		if ITEMS[item]["ItemType"] == "Equipment":
			EQUIPMENT.append(ITEMS[item])

	print(EQUIPMENT)

func get_itm(item_id):
	if item_id in ITEMS:
		return ITEMS[item_id]
	else:
		return ITEMS["0"]
