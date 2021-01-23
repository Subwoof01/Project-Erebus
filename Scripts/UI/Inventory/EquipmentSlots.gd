extends Panel

onready var slots = self.get_children()
var stat_screen = null
var player = null
var items = {}
var off_hand_disabled = false

func _ready():
	self.player = self.get_tree().get_root().get_node("Game").player
	for slot in self.slots:
		self.items[slot.name] = null

func on_equip(item):
	if self.player == null:
		self.player = self.get_tree().get_root().get_node("Game").player
	if self.stat_screen == null:
		self.stat_screen = self.get_tree().get_root().get_node("Game").stat_window

	var current_health_percentage = (float(self.player.current_health) / self.player.stats["Health"].value) * 100
	var current_mana_percentage = (float(self.player.current_health) / self.player.stats["Mana"].value) * 100

	for stat in item.stats:
		if self.player.stats.has(stat):
			self.player.stats[stat].add_modifier(item.stats[stat])
			print("Added stat: ", self.player.stats[stat].value)
		else:
			print("Modifier could not be added to player stat! Stat not found: " + stat)

	for mod in item.mods:
		if self.player.stats.has(mod):
			for i in range(len(item.mods[mod])):
				match mod:
					"PhysicalDamage":
						self.player.stats["PhysicalDamageMin"].add_modifier(item.mods[mod][i])
						self.player.stats["PhysicalDamageMax"].add_modifier(item.mods[mod][i])
				self.player.stats[mod].add_modifier(item.mods[mod][i])
				print("added mod ", mod)
		elif mod == "IncreasedArmour" or mod == "FlatArmour":
			for i in range(len(item.mods[mod])):
				self.player.stats["Armour"].add_modifier(item.mods[mod][i])
				print("added mod ", mod)
		elif mod == "IncreasedHealth" or mod == "FlatHealth":
			for i in range(len(item.mods[mod])):
				self.player.stats["Health"].add_modifier(item.mods[mod][i])
				print("added mod ", mod)
		elif mod == "IncreasedMana" or mod == "FlatMana":
			for i in range(len(item.mods[mod])):
				self.player.stats["Mana"].add_modifier(item.mods[mod][i])
				print("added mod ", mod)
		else:
			print("Modifier could not be added to player stat! Stat not found: " + mod)

	self.player.current_health = self.player.stats["Health"].value / 100 * current_health_percentage
	self.player.current_mana = self.player.stats["Mana"].value / 100 * current_mana_percentage
	self.stat_screen.update_stat_window()
	self.player.update_health_orb()
	self.player.update_mana_orb()

func on_unequip(item):
	if self.player == null:
		self.player = self.get_tree().get_root().get_node("Game").player
	if self.stat_screen == null:
		self.stat_screen = self.get_tree().get_root().get_node("Game").stat_window


	var current_health_percentage = (float(self.player.current_health) / self.player.stats["Health"].value) * 100
	var current_mana_percentage = (float(self.player.current_health) / self.player.stats["Mana"].value) * 100

	for stat in item.stats:
		if self.player.stats.has(stat):
			self.player.stats[stat].remove_modifier(item.stats[stat])
		else:
			print("Modifier could not be removed from player stat! Stat not found: " + stat)
	for mod in item.mods:
		if self.player.stats.has(mod):
			for i in range(len(item.mods[mod])):
				match mod:
					"PhysicalDamage":
						self.player.stats["PhysicalDamageMin"].remove_modifier(item.mods[mod][i])
						self.player.stats["PhysicalDamageMax"].remove_modifier(item.mods[mod][i])
				print("removed mod ", mod)
				self.player.stats[mod].remove_modifier(item.mods[mod][i])
		elif mod == "IncreasedArmour" or mod == "FlatArmour":
			for i in range(len(item.mods[mod])):
				print("removed mod ", mod)
				self.player.stats["Armour"].remove_modifier(item.mods[mod][i])
		elif mod == "IncreasedHealth" or mod == "FlatHealth":
			for i in range(len(item.mods[mod])):
				print("removed mod ", mod)
				self.player.stats["Health"].remove_modifier(item.mods[mod][i])
		elif mod == "IncreasedMana" or mod == "FlatMana":
			for i in range(len(item.mods[mod])):
				print("removed mod ", mod)
				self.player.stats["Mana"].remove_modifier(item.mods[mod][i])
		else:
			print("Modifier could not be removed from player stat! Stat not found: " + mod)
	
	self.player.current_health = self.player.stats["Health"].value / 100 * current_health_percentage
	self.player.current_mana = self.player.stats["Mana"].value / 100 * current_mana_percentage

	self.stat_screen.update_stat_window()
	self.player.update_health_orb()
	self.player.update_mana_orb()

func disable_off_hand():
	$OffHand.self_modulate = Color8(0, 0, 0, 165)
	self.off_hand_disabled = true

func enable_off_hand():
	$OffHand.self_modulate = Color8(255, 255, 255, 66)
	self.off_hand_disabled = false

func insert_item_assigned_slot(item):
	var slot

	if typeof(item.data.slot) == TYPE_ARRAY:
		if item.data.is_two_handed:
			if self.items["MainHand"] != null:
				return false
			if self.items["OffHand"] != null:
				return false
			self.items["MainHand"] = item
			item.rect_global_position = $MainHand.rect_global_position
			item.rect_min_size = $MainHand.rect_size
			item.rect_size = $MainHand.rect_size
			self.disable_off_hand()
			self.on_equip(item.data)
			return true
		
		if self.items["MainHand"] != null:
			if self.items["OffHand"] != null:
				return false
			if self.off_hand_disabled:
				return false
			self.items["OffHand"] = item
			item.rect_global_position = $OffHand.rect_global_position
			item.rect_min_size = $OffHand.rect_size
			item.rect_size = $OffHand.rect_size
			self.on_equip(item.data)
			return true
		
		self.items["MainHand"] = item
		item.rect_global_position = $MainHand.rect_global_position
		item.rect_min_size = $MainHand.rect_size
		item.rect_size = $MainHand.rect_size
		self.on_equip(item.data)
		return true

		
	slot = self.get_node(item.data.slot)
	if off_hand_disabled and item.data.slot == "OffHand":
		return false
	if self.items[item.data.slot] != null:
		return false

	self.items[item.data.slot] = item
	self.on_equip(item.data)
	item.rect_global_position = slot.rect_global_position
	item.rect_min_size = slot.rect_size
	item.rect_size = slot.rect_size
	return true
	
func insert_item(item):
	var item_pos = item.rect_global_position + item.rect_size * 0.5
	var slot = self.get_slot_under_pos(item_pos)
	if slot == null:
		return false

	var item_slot = item.data.slot
	print(item_slot)
	var slot_found = false
	var found_slot = item_slot

	if typeof(item_slot) == TYPE_ARRAY:
		for s in item_slot:
			if s == slot.name:
				if off_hand_disabled:
					if s == "OffHand":
						return false
				slot_found = true
				found_slot = s
				break
		if !slot_found:
			return false
	else:
		if item_slot != slot.name:
			return false
		if items[item_slot] != null:
			return false
		if off_hand_disabled:
			if item_slot == "OffHand":
				return false
	
	if item.data.is_two_handed:
		if items["OffHand"] != null:
			return false
		self.disable_off_hand()
		if found_slot == "OffHand":
			items["MainHand"] = item
			slot = $MainHand
		items[found_slot] = item
	else:
		items[found_slot] = item
	item.rect_global_position = slot.rect_global_position
	# print(slot.rect_size)
	item.rect_min_size = slot.rect_size
	item.rect_size = slot.rect_size
	self.on_equip(item.data)

	return true

func grab_item(pos):
	var item = self.get_item_under_pos(pos)
	var slot = self.get_slot_under_pos(pos)
	if item == null:
		return null
	
	var item_slot = item.data.slot
	var found_slot = item_slot

	if typeof(item_slot) == TYPE_ARRAY:
		for s in item_slot:
			if s == slot.name:
				found_slot = s
				break

	if item.data.is_two_handed:
		self.enable_off_hand()

	items[found_slot] = null
	self.on_unequip(item.data)
	return item

func get_slot_under_pos(pos):
	return get_thing_under_pos(slots, pos)

func get_item_under_pos(pos):
	return get_thing_under_pos(self.items.values(), pos)

func get_thing_under_pos(arr, pos):
	for thing in arr:
		if thing != null and thing.get_global_rect().has_point(pos):
			return thing
	return null
