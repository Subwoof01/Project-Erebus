extends TextureRect

onready var font = preload("res://Resources/UI_Theme.tres")
onready var plus = preload("res://Sprites/UI/Main/PlusButton.png")
onready var plus_pressed = preload("res://Sprites/UI/Main/PlusButton_Pressed.png")
onready var minus = preload("res://Sprites/UI/Main/MinusButton.png")
onready var minus_pressed = preload("res://Sprites/UI/Main/MinusButton_Pressed.png")

onready var player = self.get_tree().get_root().get_node("Game/NavigationMap/YSort/Player")

onready var damage_names = $ScrollContainer/MarginContainer/VBoxContainer/Damage/DamageNames
onready var damage_values = $ScrollContainer/MarginContainer/VBoxContainer/Damage/DamageStatValues
onready var defense_names = $ScrollContainer/MarginContainer/VBoxContainer/Defense/DefenseNames
onready var defense_values = $ScrollContainer/MarginContainer/VBoxContainer/Defense/DefenseStatValues
onready var utility_names = $ScrollContainer/MarginContainer/VBoxContainer/Utility/UtilityNames
onready var utility_values = $ScrollContainer/MarginContainer/VBoxContainer/Utility/UtilityStatValues

onready var p_name = $PlayerName
onready var level = $Level
onready var experience = $ExperienceCurrent
onready var exp_next = $ExperienceNextLevel
onready var strength = $Strength
onready var dexterity = $Dexterity
onready var intelligence = $Intelligence
onready var armour = $Armour
onready var health = $Health
onready var mana = $Mana

onready var strength_button = $StrengthButton
onready var dexterity_button = $DexterityButton
onready var intelligence_button = $IntelligenceButton

onready var stat_points = $StatPointsBackground

var alt_pressed = false
var stats = {}

func _ready():
	var phys = Label.new()
	phys.text = "Physical Damage"
	phys.theme = self.font

	var phys_val = Label.new()
	phys_val.text = str(self.player.stats["PhysicalDamageMin"].value) + "-" + str(self.player.stats["PhysicalDamageMax"].value)
	phys_val.theme = self.font

	self.stats["WeaponDamage"] = phys_val
	print("Damage label ", phys_val)
	self.damage_names.add_child(phys)
	self.damage_values.add_child(phys_val)

	var text_width = 0
	var names = []
	for stat in self.player.stats:
		
		var value = Label.new()
		value.theme = self.font
		self.stats[stat] = value

		var label = Label.new()
		label.theme = self.font
		var type = ""
		match stat:
			"FireResistance":
				type = "Defense"
				label.text = "Fire Resistance"
			"FrostResistance":
				type = "Defense"
				label.text = "Frost Resistance"
			"LightningResistance":
				type = "Defense"
				label.text = "Lightning Resistance"
			"NatureResistance":
				type = "Defense"
				label.text = "Nature Resistance"
			"CriticalHitChance":
				type = "Damage"
				label.text = "Critical Hit Chance"
			"CriticalHitDamage":
				type = "Damage"
				label.text = "Critical Hit Damage"
			"PhysicalDamage":
				type = "Damage"
				label.text = "to Physical Damage"
			"SpellDamage":
				type = "Damage"
				label.text = "to Spell Damage"
			"FireDamage":
				type = "Damage"
				label.text = "to Fire Damage"
			"FrostDamage":
				type = "Damage"
				label.text = "to Frost Damage"
			"LightningDamage":
				type = "Damage"
				label.text = "to Lightning Damage"
			"NatureDamage":
				type = "Damage"
				label.text = "to Nature Damage"
			"PhysicalDamage":
				type = "Damage"
				label.text = "to Physical Damage"
			"Armour":
				type = "Defense"
				label.text = "Increased Armour"
			"BlockChance":
				type = "Defense"
				label.text = "Block Chance"
			"HealthRegen":
				type = "Defense"
				label.text = "Health Regenerated Per Second"
			"ManaRegen":
				type = "Defense"
				label.text = "Mana Regenerated Per Second"
			"MovementSpeed":
				type = "Utility"
				label.text = "Increased Movement Speed"

		match type:
			"Damage":
				self.damage_names.add_child(label)
				self.damage_values.add_child(value)
			"Defense":
				self.defense_names.add_child(label)
				self.defense_values.add_child(value)
			"Utility":
				self.utility_names.add_child(label)
				self.utility_values.add_child(value)
		names.append(label)
		var width = self.font.default_font.get_string_size(label.text)
		if width.x > text_width:
			text_width = width.x
	
	for n in names:
		n.rect_min_size.x = text_width
	self.update_stat_window()

func on_show():
	self.update_stat_window()

func update_stat_window():

	if self.player.stat_points > 0:
		self.stat_points.show()
		self.stat_points.get_node("StatPoints").text = str(self.player.stat_points)
		self.strength_button.texture_normal = self.plus
		self.dexterity_button.texture_normal = self.plus
		self.intelligence_button.texture_normal = self.plus
		self.strength_button.texture_pressed = self.plus_pressed
		self.dexterity_button.texture_pressed = self.plus_pressed
		self.intelligence_button.texture_pressed = self.plus_pressed
		self.strength_button.disabled = false
		self.dexterity_button.disabled = false
		self.intelligence_button.disabled = false
	else:
		self.stat_points.hide()
		self.strength_button.disabled = true
		self.dexterity_button.disabled = true
		self.intelligence_button.disabled = true

	if self.alt_pressed:
		self.strength_button.texture_normal = self.minus
		self.dexterity_button.texture_normal = self.minus
		self.intelligence_button.texture_normal = self.minus
		self.strength_button.texture_pressed = self.minus_pressed
		self.dexterity_button.texture_pressed = self.minus_pressed
		self.intelligence_button.texture_pressed = self.minus_pressed
		self.strength_button.disabled = false
		self.dexterity_button.disabled = false
		self.intelligence_button.disabled = false
		if self.player.stats["Strength"].base_value <= 3:
			self.strength_button.disabled = true
		if self.player.stats["Dexterity"].base_value <= 3:
			self.dexterity_button.disabled = true
		if self.player.stats["Intelligence"].base_value <= 3:
			self.intelligence_button.disabled = true

	self.p_name.text = self.player.p_name
	self.level.text = "Level\n" + str(round(self.player.level))
	self.experience.text = "Experience\n" + str(self.player.total_exp + self.player.experience)
	self.exp_next.text = "Next level\n" + str(self.player.next_level_exp)
	self.strength.text = str(round(self.player.stats["Strength"].value))
	self.dexterity.text = str(round(self.player.stats["Dexterity"].value))
	self.intelligence.text = str(round(self.player.stats["Intelligence"].value))
	self.armour.text = str(round(self.player.stats["Armour"].value))
	self.health.text = str(round(self.player.stats["Health"].value))
	self.mana.text = str(round(self.player.stats["Mana"].value))
	
	for stat in self.stats:
		match stat:
			"WeaponDamage":
				var s = str(round(self.player.stats["PhysicalDamageMin"].value)) + "-" + str(round(self.player.stats["PhysicalDamageMax"].value))
				self.stats["WeaponDamage"].text = s
			"CriticalHitChance":
				self.stats[stat].text = str(stepify(self.player.stats[stat].value / 100, 0.1)) + "%"
			"BlockChance":
				self.stats[stat].text = str(self.player.stats[stat].value * 100) + "%"
			"FireResistance":
				self.stats[stat].text = str(self.player.stats[stat].value * 100) + "%"
			"FrostResistance":
				self.stats[stat].text = str(self.player.stats[stat].value * 100) + "%"
			"LightningResistance":
				self.stats[stat].text = str(self.player.stats[stat].value * 100) + "%"
			"NatureResistance":
				self.stats[stat].text = str(self.player.stats[stat].value * 100) + "%"
			"HealthRegen":
				self.stats[stat].text = str(self.player.stats[stat].value)
			"ManaRegen":
				self.stats[stat].text = str(self.player.stats[stat].value)
			_:
				self.stats[stat].text = "+" + str(round(self.player.stats[stat].get_percentual_bonus_value() * 100)) + "%"
	
	for stat in self.stats:
		self.stats[stat].rect_min_size.x = 100

func _input(event):
	if Input.is_action_just_pressed("ui_alt"):
		self.alt_pressed = true
		self.update_stat_window()
	if Input.is_action_just_released("ui_alt"):
		self.alt_pressed = false
		self.update_stat_window()

func _on_StrengthButton_pressed():
	if self.alt_pressed:
		if self.player.stats["Strength"].base_value > 3:
			self.player.stats["Strength"].base_value -= 1
			self.player.stat_points += 1
		else:
			self.strength_button.disabled = true
	else:
		self.player.stats["Strength"].base_value += 1
		self.player.stat_points -= 1
	self.update_stat_window()


func _on_DexterityButton_pressed():
	if self.alt_pressed:
		if self.player.stats["Dexterity"].base_value > 3:
			self.player.stats["Dexterity"].base_value -= 1
			self.player.stat_points += 1
		else:
			self.dexterity_button.disabled = true

	else:
		self.player.stats["Dexterity"].base_value += 1
		self.player.stat_points -= 1
	self.update_stat_window()


func _on_IntelligenceButton_pressed():
	if self.alt_pressed:
		if self.player.stats["Intelligence"].base_value > 3:
			self.player.stats["Intelligence"].base_value -= 1
			self.player.stat_points += 1
		else:
			self.intelligence_button.disabled = true
	else:
		self.player.stats["Intelligence"].base_value += 1
		self.player.stat_points -= 1
	self.update_stat_window()
