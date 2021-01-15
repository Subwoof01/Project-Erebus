# extends Node
class_name Equipment

enum RARITY {
	Normal,
	Magic,
	Rare,
	Unique
}

var stat_modifier = load("res://Scripts/Stats/StatModifier.gd").new(1, 1)

var equipment_name: String
var level: int
var rarity
var type: String
var sub_type: String
var slot
var inventory_size: Array
var icon_path: String
var ui_sprite
var world_icon_path: String
var world_sprite
var stats: Dictionary = {}
var mods: Dictionary = {}
var enhancements: Dictionary = {}
var requirements: Dictionary = {}
var is_two_handed = false
var item_level_rating = 1
var max_rating = 1000
var max_level = 100
var scale = 5

var level_req
var strength
var dexterity
var intelligence

var prefix = {}
var suffix = {}
var affixes = {}
var implicit = {}

var rng

var normal_chance = 0.50
var magic_chance = 0.35
var rare_chance = 0.15

var affix_slots_open = 0
var suffix_slot_open = false
var prefix_slot_open = false

func _init():
	self.rng = RandomNumberGenerator.new()

func get_stat_scalar():
	return self.item_level_rating * self.level

func get_max_scalar():
	return self.max_rating * self.max_level

func create_mod(min_val, max_val, _type) -> StatModifier:
	var value: float = self.rng.randf_range(min_val, max_val)
	var mod_type = stat_modifier.STAT_MOD_TYPE.PercentAdd
	# print("mod_type ", _type, " value ", value)

	match _type:
		"Flat":
			mod_type = stat_modifier.STAT_MOD_TYPE.Flat
			var normalised = inverse_lerp(0, get_max_scalar(), self.get_stat_scalar())
			value *= max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 3))
		"Add":
			mod_type = stat_modifier.STAT_MOD_TYPE.PercentAdd
			var normalised = inverse_lerp(0, get_max_scalar(), self.get_stat_scalar())
			value *= max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * self.scale)
		"Mult":
			mod_type = stat_modifier.STAT_MOD_TYPE.PercentMult
			var normalised = inverse_lerp(0, get_max_scalar(), self.get_stat_scalar())
			value *= max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * self.scale)
	
	var mod: StatModifier = StatModifier.new(value, mod_type)
	return mod

func add_affix(affix_list, _type="affix", item=self):
	var random_affix = affix_list[rng.randi_range(0, len(affix_list) - 1)]
	# print("affix ", random_affix)
	if _type == "prefix":
		if !item.prefix_slot_open:
			return false
		item.equipment_name = random_affix["Name"] + " " + item.equipment_name
	elif _type == "suffix":
		if !item.suffix_slot_open:
			return false
		item.equipment_name = item.equipment_name + " " + random_affix["Name"]
	elif _type == "affix" and item.affix_slots_open == 0:
		return false
	
	var normalised = inverse_lerp(0, get_max_scalar(), self.get_stat_scalar())
	level_req *= max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 0.1))

	match random_affix["MainStat"]:
		"Strength":
			if self.strength == 0:
				self.strength = self.level * 0.3
			self.strength *= max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 0.1))
		"Dexterity":
			if self.dexterity == 0:
				self.dexterity = self.level * 0.3
			self.dexterity *= max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 0.1))
		"Intelligence":
			if self.intelligence == 0:
				self.intelligence = self.level * 0.3
			self.intelligence *= max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 0.1))
	match random_affix["SecondaryStat"]:
		"Strength":
			if self.strength == 0:
				self.strength = self.level * 0.3
			self.strength *= max(1, (Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 0.1)) * .5)
		"Dexterity":
			if self.strength == 0:
				self.strength = self.level * 0.3
			self.dexterity *= max(1, (Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 0.1)) * .5)
		"Intelligence":
			if self.strength == 0:
				self.strength = self.level * 0.3
			self.intelligence *= max(1, (Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 0.1)) * .5)

	for mod in random_affix["Mods"]:
		if !item.mods.has(mod.keys()[0]):
			item.mods[mod.keys()[0]] = []
		item.mods[mod.keys()[0]].append(item.create_mod(mod[mod.keys()[0]][1], mod[mod.keys()[0]][2], mod[mod.keys()[0]][0]))
		# print("added mod ", mod.keys()[0], " values: ", mod[mod.keys()[0]][1], " ", mod[mod.keys()[0]][2], " ", mod[mod.keys()[0]][0])
		if _type == "prefix":
			self.prefix[mod.keys()[0]] = []
			self.prefix[mod.keys()[0]].append(random_affix["Name"])
		elif _type == "suffix":
			self.suffix[mod.keys()[0]] = []
			self.suffix[mod.keys()[0]].append(random_affix["Name"])
		else:
			self.affixes[mod.keys()[0]] = []
			self.affixes[mod.keys()[0]].append(random_affix["Name"])
	
	return true


func create_randomised_equipment(level):
	self.rng.randomize()

	# ItemDb.ITEMS[str(rng.randi_range(1, len(ItemDb.ITEMS) - 1))]
	# ItemDb.ITEMS["1"]
	var base_item = ItemDb.ITEMS[str(rng.randi_range(1, len(ItemDb.ITEMS) - 1))]
	self.equipment_name = base_item["ItemName"]
	self.slot = base_item["slot"]
	self.inventory_size = [base_item["width"], base_item["height"]]
	self.type = base_item["ItemType"]
	self.sub_type = base_item["ItemSubType"]
	self.icon_path = "res://Sprites/Items/" + self.type + "/" + base_item["icon"] + ".png"
	self.world_icon_path = "res://Sprites/Items/" + self.type + "/" + base_item["icon"] + "_World.png"
	self.level = rng.randi_range(1, 100)
	self.level_req = self.level * 0.7
	self.strength = 0
	self.dexterity = 0
	self.intelligence = 0

	if base_item.has("ItemIsTwoHanded"):
		self.is_two_handed = base_item["ItemIsTwoHanded"]
	
	var rare = self.rng.randf()
	if rare <= self.rare_chance:
		self.rarity = RARITY.Rare
		self.prefix_slot_open = true
		self.suffix_slot_open = true
		self.affix_slots_open = 3
	elif rare > self.rare_chance and rare <= self.rare_chance + self.magic_chance:
		self.rarity = RARITY.Magic
		self.prefix_slot_open = true
		self.suffix_slot_open = true
	else:
		self.rarity = RARITY.Normal
	
	# if ItemModData.implicit_mods.has(base_item["Itemequipment_Name"]):
	# 	self.mods[base_item["Itemequipment_Name"]

	if self.type == "Weapon":
		self.item_level_rating = self.max_rating

		var normalised = inverse_lerp(0, get_max_scalar(), self.get_stat_scalar())
		var min_val = [
			base_item["ItemBaseDamage"][0] * max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 3)), 
			base_item["ItemBaseDamage"][1] * max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 3))
		]
		var max_val = [
			base_item["ItemBaseDamage"][2] * max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 3)), 
			base_item["ItemBaseDamage"][3] * max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 3))
		]

		var base_damage_min = rng.randi_range(min_val[0], min_val[1])
		var base_damage_max = rng.randi_range(max_val[0], max_val[1])
		var a = CharacterStat.new(base_damage_min)
		var b = CharacterStat.new(base_damage_max)
		self.stats["PhysicalDamageMin"] = a
		self.stats["PhysicalDamageMax"] = b

		if self.prefix_slot_open:
			if self.add_affix(ItemModData.prefix_weapon_mods, "prefix"):
				self.prefix_slot_open = false

		if self.suffix_slot_open:
			if self.add_affix(ItemModData.suffix_weapon_mods, "suffix"):
				self.suffix_slot_open = false
		
		for i in range(self.affix_slots_open):
			if self.add_affix(ItemModData.affix_weapon_mods):
				self.affix_slots_open -= 1

		if self.mods.has("EnhancedDamage"):
			for i in range(len(self.mods["EnhancedDamage"])):
				self.stats["PhysicalDamageMin"].add_modifier(self.mods["EnhancedDamage"][i])
				self.stats["PhysicalDamageMax"].add_modifier(self.mods["EnhancedDamage"][i])
		self.stats["PhysicalDamageMin"] = StatModifier.new(self.stats["PhysicalDamageMin"].value, StatModifier.STAT_MOD_TYPE.Flat)
		self.stats["PhysicalDamageMax"] = StatModifier.new(self.stats["PhysicalDamageMax"].value, StatModifier.STAT_MOD_TYPE.Flat)
	
	elif self.type == "Armour":
		self.item_level_rating = self.max_rating

		var normalised = inverse_lerp(0, get_max_scalar(), self.get_stat_scalar())
		var base_armour = rng.randi_range(
			base_item["ItemBaseArmour"][0] * max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 3)), 
			base_item["ItemBaseArmour"][1] * max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * (self.scale * 3))
			)
		var a = CharacterStat.new(base_armour)
		self.stats["Armour"] = a

		if self.prefix_slot_open:
			if self.add_affix(ItemModData.prefix_armour_mods, "prefix"):
				self.prefix_slot_open = false

		if self.suffix_slot_open:
			if self.add_affix(ItemModData.suffix_armour_mods, "suffix"):
				self.suffix_slot_open = false
		
		for i in range(self.affix_slots_open):
			if self.add_affix(ItemModData.affix_armour_mods):
				self.affix_slots_open -= 1
		
		if self.mods.has("EnhancedArmour"):
			for i in range(len(self.mods["EnhancedArmour"])):
				self.stats["Armour"].add_modifier(self.mods["EnhancedArmour"][i])
		self.stats["Armour"] = StatModifier.new(self.stats["Armour"].value, StatModifier.STAT_MOD_TYPE.Flat)

	elif self.type == "Jewelry":
		self.item_level_rating = self.max_rating * 0.4

		if self.prefix_slot_open:
			if self.add_affix(ItemModData.prefix_jewelry_mods, "prefix"):
				self.prefix_slot_open = false

		if self.suffix_slot_open:
			if self.add_affix(ItemModData.suffix_jewelry_mods, "suffix"):
				self.suffix_slot_open = false
		
		for i in range(self.affix_slots_open):
			if self.add_affix(ItemModData.affix_jewelry_mods):
				self.affix_slots_open -= 1

	elif self.type == "Shield":
		self.item_level_rating = self.max_rating * 0.5

		var normalised = inverse_lerp(0, get_max_scalar(), self.get_stat_scalar())
		var base_block = rng.randf_range(
			base_item["ItemBaseBlockChance"][0] * max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * self.scale), 
			base_item["ItemBaseBlockChance"][1] * max(1, Mathf.crossfade(Mathf.smooth_start2(normalised), Mathf.smooth_stop2(normalised), normalised) * self.scale)
			)
		var a = CharacterStat.new(base_block)
		self.stats["BlockChance"] = a

		if self.prefix_slot_open:
			if self.add_affix(ItemModData.prefix_shield_mods, "prefix"):
				self.prefix_slot_open = false

		if self.suffix_slot_open:
			if self.add_affix(ItemModData.suffix_shield_mods, "suffix"):
				self.suffix_slot_open = false
		
		for i in range(self.affix_slots_open):
			if self.add_affix(ItemModData.affix_shield_mods):
				self.affix_slots_open -= 1

		if self.mods.has("BlockChance"):
			for i in range(len(self.mods["BlockChance"])):
				self.stats["BlockChance"].add_modifier(self.mods["BlockChance"][i])
		self.stats["BlockChance"] = StatModifier.new(self.stats["BlockChance"].value, StatModifier.STAT_MOD_TYPE.Flat)

	if ItemModData.implicit_mods.has(base_item["ItemName"]):
		var implicit = ItemModData.implicit_mods[base_item["ItemName"]]
		for mod in implicit["Mods"]:
			if !self.mods.has(mod.keys()[0]):
				self.mods[mod.keys()[0]] = []
			self.mods[mod.keys()[0]].append(self.create_mod(mod[mod.keys()[0]][1], mod[mod.keys()[0]][2], mod[mod.keys()[0]][0]))
			self.implicit[mod.keys()[0]] = []
			self.implicit[mod.keys()[0]].append(self.create_mod(mod[mod.keys()[0]][1], mod[mod.keys()[0]][2], mod[mod.keys()[0]][0]))


	self.requirements["Level"] = ceil(level_req)
	if self.strength > 0:
		self.requirements["Strength"] = ceil(strength)
	if self.dexterity > 0:
		self.requirements["Dexterity"] = ceil(dexterity)
	if self.intelligence > 0:
		self.requirements["Intelligence"] = ceil(intelligence)
