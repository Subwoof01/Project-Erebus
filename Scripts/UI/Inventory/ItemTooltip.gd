extends Control

var item_type = ""
var mod_types = []
var game
var item = load("res://Scripts/Items/Item.gd").new()
var rarity_colours = {
	item.RARITY.Rare: "faff73",
	item.RARITY.Magic: "aaa8ff",
	item.RARITY.Normal: "ffffff"
}
var last_mod: String = ""

func _input(event):
	if Input.is_action_just_pressed("ui_alt"):
		self.show_mod_types()
	if Input.is_action_just_released("ui_alt"):
		self.hide_mod_types()
	self.set_pos()

func _ready():
	self.set_pos()

func setup(_item, game):
	self.game = game
	self.set_pos()
	self.set_item_name(_item.data.item_name, Color(self.rarity_colours[_item.data.rarity]))
	self.set_item_type(_item)

	if _item.data.type == "Equipment":
		$Tooltip/VBoxContainer/MainStat.visible = true
		$Tooltip/VBoxContainer/Requirements.visible = true
		$Tooltip/VBoxContainer/Divider.visible = true
		$Tooltip/VBoxContainer/Divider2.visible = true
		self.set_main_stat(_item.data)
		for mod in _item.data.mods:
			self.add_mod(mod, _item.data)
		self.set_requirements(_item.data)

	self.scale_tooltip()

func show_mod_types():
	for label in self.mod_types:
		label.visible = true
	self.scale_tooltip()

func hide_mod_types():
	for label in self.mod_types:
		label.visible = false
	self.scale_tooltip()

func set_pos():
	var margin = Vector2(10, 10)
	var cursor_pos = self.get_global_mouse_position()
	var new_pos = Vector2(cursor_pos.x - $Tooltip.rect_size.x, cursor_pos.y - $Tooltip.rect_size.y)
	if new_pos.x < margin.x:
		new_pos.x = margin.x
	if new_pos.y < margin.y:
		new_pos.y = margin.y
	self.rect_position = new_pos

func scale_tooltip():
	var margin = Vector2(50, 10)
	var width = 0
	var height = $Tooltip/VBoxContainer/Divider.rect_size.y + $Tooltip/VBoxContainer/Divider2.rect_size.y

	for child in $Tooltip/VBoxContainer.get_children():
		if child.name == "Divider" or child.name == "Divider2":
			continue

		var check_size = child.theme.default_font.get_string_size(child.text)
		child.rect_size.y = check_size.y
		if check_size.x > width:
			width = check_size.x
		if child.visible:
			height += check_size.y
		child.rect_min_size.y = check_size.y
		# if child.name == "MainStat":
		# 	print($Tooltip/VBoxContainer/MainStat)
		# 	print(child.theme.default_font.get_string_size(child.text))
	
	$Tooltip.rect_size = Vector2(width + margin.x, height + margin.y)

func find_mod_text(text, list):
	var label
	var value = 0
	var i = 0
	for l in list.mods[text]:
		value += list.mods[text][i].value
		# print("tooltip mod ", text, " ", list.mods[text][i].value)
		i += 1

	match text:
		"EnhancedDamage":
			label = str(round(value * 100)) + "% Enhanced Damage"
		"EnhancedArmour":
			label = str(round(value * 100)) + "% Enhanced Armour"
		"IncreasedArmour":
			label = str(round(value * 100)) + "% Increased Armour"
		"FlatArmour":
			label = "+" + str(round(value)) + " To Armour"
		"Accuracy":
			label = "+" + str(round(value)) + " To Accuracy Rating"
		"DodgeChance":
			label = str(round(value * 100)) + "% Increased Dodge Chance"
		"BlockChance":
			label = str(round(value * 100)) + "% Enhanced Block Chance"
		"FrostDamage":
			label = str(round(value * 100)) + "% Increased Frost Damage"
		"FireDamage":
			label = str(round(value * 100)) + "% Increased Fire Damage"
		"NatureDamage":
			label = str(round(value * 100)) + "% Increased Nature Damage"
		"LightningDamage":
			label = str(round(value * 100)) + "% Increased Lightning Damage"
		"PhysicalDamage":
			label = str(round(value * 100)) + "% Increased Physical Damage"
		"LightningResistance":
			label = str(round(value * 100)) + "% Increased Lightning Resistance"
		"FrostResistance":
			label = str(round(value * 100)) + "% Increased Frost Resistance"
		"FireResistance":
			label = str(round(value * 100)) + "% Increased Fire Resistance"
		"NatureResistance":
			label = str(round(value * 100)) + "% Increased Nature Resistance"
		"CriticalHitChance":
			label = str(round(value * 100)) + "% Increased Critical Strike Chance"
		"CriticalHitDamage":
			label = str(round(value * 100)) + "% Increased Critical Strike Damage"
		"FlatHealth":
			label = "+" + str(round(value)) + " to Maximum Health"
		"IncreasedHealth":
			label = str(round(value * 100)) + "% Increased Maximum Health"
		"HealthRegen":
			label = "Regenerate " + str(round(value)) + " Health Per Second"
		"FlatMana":
			label = "+" + str(round(value)) + " to Maximum Mana"
		"IncreasedMana":
			label = str(round(value * 100)) + "% Increased Maximum Mana"
		"ManaRegen":
			label = "Regenerate " + str(round(value)) + " Mana Per Second"
		"MovementSpeed":
			label = str(round(value * 100)) + "% Increased Movement Speed"
		"Strength":
			label = "+" + str(round(value)) + " To Strength"
		"Dexterity":
			label = "+" + str(round(value)) + " To Dexterity"
		"Intelligence":
			label = "+" + str(round(value)) + " To Intelligence"
		_:
			label = str(round(value)) + " " + text

	return label

func add_mod(mod, list):
	self.game = game
	var label = Label.new()
	label.theme = load("res://Resources/UI_Font_30.tres")
	label.self_modulate = Color("9a94ee")
	label.align = label.ALIGN_CENTER

	if list.implicit.has(mod):
		var label2 = RichTextLabel.new()
		label2.theme = load("res://Resources/UI_Font_22.tres")
		label2.self_modulate = Color("b9b9b9")
		label2.fit_content_height = true
		label2.bbcode_enabled = true
		label2.bbcode_text = "[center]Implicit Modifier[/center]"
		if !game.alt_pressed:
			label2.visible = false
		self.mod_types.append(label2)
		$Tooltip/VBoxContainer.add_child_below_node($Tooltip/VBoxContainer/Divider, label2)
		$Tooltip/VBoxContainer/Implicit.text = self.find_mod_text(mod, list)
		$Tooltip/VBoxContainer/Implicit.visible = true
		return
		
	if list.prefix.has(mod) and list.prefix[mod][0] != self.last_mod:
		var label2 = RichTextLabel.new()
		label2.theme = load("res://Resources/UI_Font_22.tres")
		label2.self_modulate = Color("b9b9b9")
		label2.fit_content_height = true
		label2.bbcode_enabled = true
		label2.bbcode_text = '[center]Prefix Modifier "' + list.prefix[mod][0] + '"[/center] '
		if !game.alt_pressed:
			label2.visible = false
		self.mod_types.append(label2)
		$Tooltip/VBoxContainer.add_child(label2)
		self.last_mod = list.prefix[mod][0]

	if list.suffix.has(mod) and list.suffix[mod][0] != self.last_mod:
		var label2 = RichTextLabel.new()
		label2.theme = load("res://Resources/UI_Font_22.tres")
		label2.self_modulate = Color("b9b9b9")
		label2.fit_content_height = true
		label2.bbcode_enabled = true
		label2.bbcode_text = '[center]Suffix Modifier "' + list.suffix[mod][0] + '"[/center] '
		if !game.alt_pressed:
			label2.visible = false
		self.mod_types.append(label2)
		$Tooltip/VBoxContainer.add_child(label2)
		self.last_mod = list.suffix[mod][0]

	if list.affixes.has(mod) and list.affixes[mod][0] != self.last_mod:
		var label2 = RichTextLabel.new()
		label2.theme = load("res://Resources/UI_Font_22.tres")
		label2.self_modulate = Color("b9b9b9")
		label2.fit_content_height = true
		label2.bbcode_enabled = true
		label2.bbcode_text = '[center]Affix Modifier "' + list.affixes[mod][0] + '"[/center] '
		if !game.alt_pressed:
			label2.visible = false
		self.mod_types.append(label2)
		$Tooltip/VBoxContainer.add_child(label2)
		self.last_mod = list.affixes[mod][0]

	label.text = self.find_mod_text(mod, list)

	$Tooltip/VBoxContainer.add_child(label)

func set_requirements(item):
	var s = "[center]Requires Level [color=#ffffff]" + str(item.requirements["Level"]) + "[/color]"
	if item.requirements.has("Strength"):
		s += "[color=#b9b9b9], [/color][color=#ffffff]" + str(item.requirements["Strength"]) + "[/color] [color=#b9b9b9]Str[/color]"
	if item.requirements.has("Dexterity"):
		s += "[color=#b9b9b9], [/color][color=#ffffff]" + str(item.requirements["Dexterity"]) + "[/color] [color=#b9b9b9]Dex[/color]"
	if item.requirements.has("Intelligence"):
		s += "[color=#b9b9b9], [/color][color=#ffffff]" + str(item.requirements["Intelligence"]) + "[/color] [color=#b9b9b9]Int[/color]"
	s += "[/center]"
	$Tooltip/VBoxContainer/Requirements.parse_bbcode(s)

func set_item_name(name_, colour):
	$Tooltip/VBoxContainer/Name.text = name_
	$Tooltip/VBoxContainer/Name.self_modulate = colour
	$Tooltip/NamePanel.self_modulate = colour

func set_item_type(item):
	self.mod_types.append($Tooltip/VBoxContainer/ItemLevel)
	if !game.alt_pressed:
		$Tooltip/VBoxContainer/ItemLevel.visible = false
	$Tooltip/VBoxContainer/ItemLevel.text = "Item Level: " + str(item.data.level)
	if item.data.type == "Equipment":
		if item.data.equipment_type == "Weapon":
			$Tooltip/VBoxContainer/Type.text = "Two Handed " if item.data.is_two_handed else "One Handed " + item.data.sub_type
		else:
			$Tooltip/VBoxContainer/Type.text = item.data.sub_type
		self.item_type = item.data.equipment_type
	else:
		$Tooltip/VBoxContainer/Type.text = item.data.type

func set_main_stat(item, type_=self.item_type):
	if item.type == "Equipment":
		match item.equipment_type:
			"Weapon":
				var s = "[center]Physical Damage: " + ("[color=#9a94ee]" if item.mods.has("EnhancedDamage") else "[color=#ffffff]") + str(round(item.stats["PhysicalDamageMin"].value)) + "-" + str(round(item.stats["PhysicalDamageMax"].value)) + "[/color][/center]"
				$Tooltip/VBoxContainer/MainStat.parse_bbcode(s)
			"Armour":
				var s = "[center]Armour: " + ("[color=#9a94ee]" if item.mods.has("EnhancedArmour") else "[color=#ffffff]") + str(round(item.stats["Armour"].value)) + "[/color][/center]"
				$Tooltip/VBoxContainer/MainStat.parse_bbcode(s)
			"Shield":
				var s = "[center]Block Chance: " + ("[color=#9a94ee]" if item.mods.has("BlockChance") else "[color=#ffffff]") + str(round(item.stats["BlockChance"].value * 100)) + "%[/color][/center]"
				$Tooltip/VBoxContainer/MainStat.parse_bbcode(s)
			_:
				var main_stat = $Tooltip/VBoxContainer/MainStat
				$Tooltip/VBoxContainer.remove_child(main_stat)
				main_stat.free()
