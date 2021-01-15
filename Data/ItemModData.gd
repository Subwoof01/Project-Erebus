extends Node

var item_mod_data
var weapon_mods = {}
var armour_mods = {}
var jewelry_mods = {}
var shield_mods = {}
var implicit_mods = {}

var prefix_weapon_mods = {}
var suffix_weapon_mods = {}
var affix_weapon_mods = {}

var prefix_armour_mods = {}
var suffix_armour_mods = {}
var affix_armour_mods = {}

var prefix_jewelry_mods = {}
var suffix_jewelry_mods = {}
var affix_jewelry_mods = {}

var prefix_shield_mods = {}
var suffix_shield_mods = {}
var affix_shield_mods = {}

func _ready():
	var item_mod_data_file = File.new()
	item_mod_data_file.open("res://Data/ItemModData.json", File.READ)
	var item_mod_data_json = JSON.parse(item_mod_data_file.get_as_text())
	item_mod_data_file.close()
	self.item_mod_data = item_mod_data_json.result
	# print(len(self.item_mod_data["Mod"]))

	var weapon_id = 0
	var pwid = 0
	var swid = 0
	var awid = 0
	var armour_id = 0
	var paid = 0
	var said = 0
	var aaid = 0
	var jewelry_id = 0
	var pjid = 0
	var sjid = 0
	var ajid = 0
	var shield_id = 0
	var psid = 0
	var ssid = 0
	var asid = 0

	for i in range(len(self.item_mod_data["Mod"])):
		if self.item_mod_data["Mod"][i].has("Slot"):
			match self.item_mod_data["Mod"][i]["Slot"]:
				"Weapon":
					self.weapon_mods[weapon_id] = self.item_mod_data["Mod"][i]
					weapon_id += 1
					if self.item_mod_data["Mod"][i]["Type"] == "Prefix":
						self.prefix_weapon_mods[pwid] = self.item_mod_data["Mod"][i]
						pwid += 1
					elif self.item_mod_data["Mod"][i]["Type"] == "Suffix":
						self.suffix_weapon_mods[swid] = self.item_mod_data["Mod"][i]
						swid += 1
					elif self.item_mod_data["Mod"][i]["Type"] == "Affix":
						self.affix_weapon_mods[awid] = self.item_mod_data["Mod"][i]
						awid += 1
				"Armour":
					self.armour_mods[armour_id] = self.item_mod_data["Mod"][i]
					armour_id += 1
					if self.item_mod_data["Mod"][i]["Type"] == "Prefix":
						self.prefix_armour_mods[paid] = self.item_mod_data["Mod"][i]
						paid += 1
					elif self.item_mod_data["Mod"][i]["Type"] == "Suffix":
						self.suffix_armour_mods[said] = self.item_mod_data["Mod"][i]
						said += 1
					elif self.item_mod_data["Mod"][i]["Type"] == "Affix":
						self.affix_armour_mods[aaid] = self.item_mod_data["Mod"][i]
						aaid += 1
				"Jewelry":
					self.jewelry_mods[jewelry_id] = self.item_mod_data["Mod"][i]
					jewelry_id += 1
					if self.item_mod_data["Mod"][i]["Type"] == "Prefix":
						self.prefix_jewelry_mods[pjid] = self.item_mod_data["Mod"][i]
						pjid += 1
					elif self.item_mod_data["Mod"][i]["Type"] == "Suffix":
						self.suffix_jewelry_mods[sjid] = self.item_mod_data["Mod"][i]
						sjid += 1
					elif self.item_mod_data["Mod"][i]["Type"] == "Affix":
						self.affix_jewelry_mods[ajid] = self.item_mod_data["Mod"][i]
						ajid += 1
				"Shield":
					self.shield_mods[shield_id] = self.item_mod_data["Mod"][i]
					shield_id += 1
					if self.item_mod_data["Mod"][i]["Type"] == "Prefix":
						self.prefix_shield_mods[psid] = self.item_mod_data["Mod"][i]
						psid += 1
					elif self.item_mod_data["Mod"][i]["Type"] == "Suffix":
						self.suffix_shield_mods[ssid] = self.item_mod_data["Mod"][i]
						ssid += 1
					elif self.item_mod_data["Mod"][i]["Type"] == "Affix":
						self.affix_shield_mods[asid] = self.item_mod_data["Mod"][i]
						asid += 1
		elif self.item_mod_data["Mod"][i].has("ImplicitBaseItem"):
			self.implicit_mods[self.item_mod_data["Mod"][i]["ImplicitBaseItem"]] = self.item_mod_data["Mod"][i]
