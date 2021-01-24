extends Panel

var items = []

var grid = {}
export var cell_size = 64
export var grid_width = 8
export var grid_height = 4

onready var amount_label_theme = preload("res://Resources/UI_Font_22.tres")

func _ready():
	for x in range(grid_width):
		grid[x] = {}
		for y in range(grid_height):
			grid[x][y] = false

func insert_item(item):
	var item_pos = item.rect_global_position + Vector2(cell_size / 2, cell_size / 2)
	var g_pos = pos_to_grid_coord(item_pos)
	var item_size = get_grid_size(item)
	if is_grid_space_available(g_pos.x, g_pos.y, item_size.x, item_size.y):
		set_grid_space(g_pos.x, g_pos.y, item_size.x, item_size.y, true)
		item.rect_global_position = rect_global_position + Vector2(g_pos.x, g_pos.y) * cell_size
		
		var width = item.data.inventory_size[0]
		var height = item.data.inventory_size[1]
		item.rect_min_size = Vector2(width * 64, height * 64)
		items.append(item)
		return true
	else:
		return false

func grab_item(pos):
	var item = get_item_under_pos(pos)
	if item == null:
		return null
	
	var item_pos = item.rect_global_position + Vector2(cell_size / 2, cell_size / 2)
	var g_pos = pos_to_grid_coord(item_pos)
	var item_size = get_grid_size(item)
	set_grid_space(g_pos.x, g_pos.y, item_size.x, item_size.y, false)
	
	items.remove(items.find(item))
	return item

func pos_to_grid_coord(pos):
	var local_pos = pos - rect_global_position
	var results = {}
	results.x = int(local_pos.x / cell_size)
	results.y = int(local_pos.y / cell_size)
	return results

func get_grid_size(item):
	var results = {}
	# var s = item.rect_size
	# results.x = clamp(int(s.x / cell_size), 1, 500)
	# results.y = clamp(int(s.y / cell_size), 1, 500)
	results.x = item.data.inventory_size[0]
	results.y = item.data.inventory_size[1]
	return results

func is_grid_space_available(x, y, w ,h):
	if x < 0 or y < 0:
		return false
	if x + w > grid_width or y + h > grid_height:
		return false
	for i in range(x, x + w):
		for j in range(y, y + h):
			if grid[i][j]:
				return false
	return true

func set_grid_space(x, y, w, h, state):
	for i in range(x, x + w):
		for j in range(y, y + h):
			grid[i][j] = state

func get_item_under_pos(pos):
	for item in items:
		if item.get_global_rect().has_point(pos):
			return item
	return null

func increase_item_amount(item, amount):
	item.data.amount += amount
	if len(item.get_children()) == 0:
		var label = Label.new()
		label.theme = self.amount_label_theme
		label.text = str(item.data.amount)
		label.rect_position = Vector2(0, 37)
		label.rect_min_size = Vector2(58, 0)
		label.align = Label.ALIGN_RIGHT
		item.add_child(label)
		return
	item.get_child(0).text = str(item.data.amount)

func insert_item_at_first_available_spot(item):
	if item.data.stackable:
		for i in self.items:
			if i.data.item_name == item.data.item_name and i.data.amount + item.data.amount <= i.data.max_stack:
				self.increase_item_amount(i, item.data.amount)
				item.data.ui_sprite.queue_free()
				return true
		
	for y in range(grid_height):
		for x in range(grid_width):
			if !grid[x][y]:
				item.rect_global_position = rect_global_position + Vector2(x, y) * cell_size
				if insert_item(item):
					self.increase_item_amount(item, 0)
					return true
	return false
