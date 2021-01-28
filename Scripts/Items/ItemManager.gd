extends Node2D

onready var ui_sprite_base = preload("res://Scenes/UI/ItemBase.tscn")
onready var world_sprite_base = preload("res://Scenes/Loot/WorldItem.tscn")
onready var shader = preload("res://Resources/OutlineShader.tres")
onready var game = get_tree().get_root().get_node("Game")
onready var inventory = get_tree().get_root().get_node("Game/CanvasLayer/UI/InventoryScreen")

var world_items = []
var alt_down = false

func spawn_item(pos, item=null, spawn_radius=50):
	if item == null:
		var equipment = Equipment.new()
		equipment.create_randomised_equipment(game.player.level)
		item = equipment

	if item.ui_sprite == null:
		var ui_icon = self.ui_sprite_base.instance()
		var width = item.inventory_size[0]
		var height = item.inventory_size[1]
		ui_icon.rect_min_size = Vector2(width * 64, height * 64)
		ui_icon.texture = load(item.icon_path)
		ui_icon.data = item
		item.ui_sprite = ui_icon

	if item.world_sprite == null or !is_instance_valid(item.world_sprite):
		var world_sprite = self.world_sprite_base.instance()
		world_sprite.get_node("Sprite").texture = load(item.world_icon_path)
		world_sprite.get_node("Sprite").material = self.shader.duplicate()
		world_sprite.item_data = item
		item.world_sprite = world_sprite
	
	var spawn_point = Mathf.randv_circle(spawn_radius * 0.25, spawn_radius)
	item.world_sprite.global_position = pos + spawn_point
	var nav = self.get_tree().get_root().get_node("Game/NavigationMap")
	nav.add_child(item.world_sprite)
	nav.move_child(item.world_sprite, 2)
	item.world_sprite.animation.play("Drop")
	self.world_items.append(item)

func pickup(item):
	self.world_items.remove(self.world_items.find(item))
	if self.inventory.pickup_item(item):
		print("Removing world item... ", item.world_sprite)
		item.world_sprite.queue_free()
	else:
		self.spawn_item(self.game.player.global_position, item, 1)
