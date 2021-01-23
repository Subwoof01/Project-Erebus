class_name Item

enum RARITY {
	Normal,
	Magic,
	Rare,
	Unique
}

var item_name 
var level: int
var rarity
var type: String
var inventory_size: Array
var icon_path: String
var ui_sprite
var world_icon_path: String
var world_sprite

func create_item(id) -> Item:
	var item_data = ItemDb.ITEMS[str(id)]
	self.item_name = item_data["ItemName"]
	self.level = 1
	self.rarity = RARITY.Normal
	self.type = item_data["ItemType"]
	self.inventory_size = [item_data["width"], item_data["height"]]
	self.icon_path = "res://Sprites/Items/" + self.type + "/" + item_data["icon"] + ".png"
	self.world_icon_path = "res://Sprites/Items/" + self.type + "/" + item_data["icon"] + "_World.png"
	return self

