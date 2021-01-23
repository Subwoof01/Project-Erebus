extends Node
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

func _ready():
	pass # Replace with function body.

