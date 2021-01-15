extends Control

onready var ui_sprite_base = preload("res://Scenes/UI/ItemBase.tscn")
const tooltip_base = preload("res://Scenes/UI/ItemTooltip.tscn")

onready var equipment_slots = $EquipmentSlots
onready var grid_backpack = $GridBackPack
onready var game = get_tree().get_root().get_node("Game")

var item_held = null
var item_offset = Vector2()
var last_container = null
var last_pos = Vector2()

var current_tooltip = null
var last_tooltip_item = null

func _process(delta):
	var cursor_pos = self.get_global_mouse_position()
	if Input.is_action_just_pressed("inv_grab"):
		self.grab(cursor_pos)
	if Input.is_action_just_released("inv_grab"):
		self.release(cursor_pos)
	if Input.is_action_just_pressed("inv_instant_move"):
		self.instant_item_move()
	if item_held != null:
		item_held.rect_global_position = cursor_pos + item_offset

func _input(event):
	if !self.visible:
		if self.current_tooltip != null:
			self.current_tooltip.queue_free()
		return
	var cursor_pos = self.get_global_mouse_position()
	var item = self.get_item_under_cursor(cursor_pos)
	if item == null:
		if self.current_tooltip != null:
			self.current_tooltip.queue_free()
			self.current_tooltip = null
		self.last_tooltip_item = null
		return
	if item != self.last_tooltip_item:
		if self.current_tooltip != null:
			self.current_tooltip.queue_free()
			self.current_tooltip = null
		self.last_tooltip_item = item
		var tooltip = self.tooltip_base.instance()
		tooltip.setup(item, game)
		self.get_parent().add_child(tooltip)
		self.current_tooltip = tooltip

func instant_item_move():
	var cursor_pos = self.get_global_mouse_position()
	var c = self.get_container_under_cursor(cursor_pos)

	if c == self.grid_backpack:
		var item = self.grid_backpack.grab_item(cursor_pos)
		if item == null:
			return
		var equipped = self.equipment_slots.insert_item_assigned_slot(item)
		if !equipped:
			self.grid_backpack.insert_item_at_first_available_spot(item)

	elif c == self.equipment_slots:
		var item = self.equipment_slots.grab_item(cursor_pos)
		if item == null:
			return
		var unequipped = self.grid_backpack.insert_item_at_first_available_spot(item)
		if !unequipped:
			self.equipment_slots.insert_item_assigned_slot(item)

func grab(cursor_pos):
	var c = self.get_container_under_cursor(cursor_pos)
	if c != null and c.has_method("grab_item"):
		self.item_held = c.grab_item(cursor_pos)
		if self.item_held != null:
			
			var width = self.item_held.data.inventory_size[0]
			var height = self.item_held.data.inventory_size[1]
			self.item_held.rect_min_size = Vector2(width * 64, height * 64)
			self.last_container = c
			self.last_pos = self.item_held.rect_global_position
			self.item_offset = self.item_held.rect_global_position - cursor_pos
			self.move_child(self.item_held, self.get_child_count())

func release(cursor_pos):
	if self.item_held == null:
		return
	var c = self.get_container_under_cursor(cursor_pos)
	if c == null:
		self.drop_item()
	elif c.has_method("insert_item"):
		if c.insert_item(self.item_held):
			self.item_held = null
		else:
			self.return_item()
	else:
		self.return_item()

func get_container_under_cursor(cursor_pos):
	var containers = [grid_backpack, equipment_slots]
	for c in containers:
		if c.get_global_rect().has_point(cursor_pos):
			return c
	return null

func get_item_under_cursor(cursor_pos):
	var c = self.get_container_under_cursor(cursor_pos)
	var item = null
	if c == null:
		return null
	elif c.has_method("get_item_under_pos"):
		item = c.get_item_under_pos(cursor_pos)
	return item

func drop_item():
	ItemManager.spawn_item(self.game.player.global_position, self.item_held.data, 1)
	self.item_held.queue_free()
	self.item_held = null
	# Create in world item to fall on floor here.

func return_item():
	self.item_held.rect_global_position = self.last_pos
	self.last_container.insert_item(self.item_held)
	self.item_held = null

func pickup_item(item_data):
	var item = item_data.ui_sprite
	if item_data.ui_sprite == null:
		var ui_icon = self.ui_sprite_base.instance()
		var width = item_data.inventory_size[0]
		var height = item_data.inventory_size[1]
		ui_icon.rect_min_size = Vector2(width * 64, height * 64)
		ui_icon.texture = load(item_data.icon_path)
		ui_icon.data = item_data
		item = ui_icon
	self.add_child(item)
	if !self.grid_backpack.insert_item_at_first_available_spot(item):
		item.queue_free()
		return false
	return true
	# Pickup logic here:
	# if false show error message to player (not enough space)
	# if true remove item from game world
