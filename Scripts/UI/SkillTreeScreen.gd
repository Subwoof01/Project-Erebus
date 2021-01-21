extends Control

onready var player = self.get_tree().get_root().get_node("Game/NavigationMap/YSort/Player")
onready var list_item = preload("res://Scenes/UI/SkillTreeListItem.tscn")
onready var skill_list = $UnknownSkills/VBoxContainer
onready var known_skill_list = $KnownSkillList/VBoxContainer
onready var known_skills_box = $KnownSkillList
onready var unknown_skills_box = $UnknownSkills
onready var selector = $Selector
onready var selected = $Selected
onready var unlock_button = $LearnSkill
onready var ability_essences = $AbilityEssencePanel/Amount
onready var unlock_skills_button = $UnlockSkills
onready var known_skills_button = $KnownSkills

onready var skill_tooltip = preload("res://Scenes/UI/SkillTooltip.tscn")
var current_skill_tooltip = null

var unlearned_skills = {}
var selected_skill = null
var unknown_items = []
var known_items = []

func _ready():
	for skill in DataImport.skill_data:
		if !player.learned_skills.has(skill):
			self.unlearned_skills[skill] = DataImport.skill_data[skill]
	
	for skill in self.unlearned_skills:
		var new_skill = self.list_item.instance()
		new_skill.skill_name = skill
		new_skill.skill = self.unlearned_skills[skill]
		self.skill_list.add_child(new_skill)
		new_skill.connect("mouse_entered", self, "_on_item_mouse_entered", [new_skill])
		new_skill.connect("mouse_exited", self, "_on_item_mouse_exited")
		new_skill.connect("gui_input", self, "_on_item_mouse_click", [new_skill])
		self.unknown_items.append(new_skill)

	for skill in self.player.learned_skills:
		var new_skill = self.list_item.instance()
		new_skill.skill_name = skill
		new_skill.skill = self.player.learned_skills[skill]
		self.known_skill_list.add_child(new_skill)
		new_skill.connect("mouse_entered", self, "_on_item_mouse_entered", [new_skill])
		new_skill.connect("mouse_exited", self, "_on_item_mouse_exited")
		self.known_items.append(new_skill)

	self.update_info()

func update_info():
	self.ability_essences.text = str(self.player.ability_essences)

	for skill in self.player.learned_skills:
		var exists = false
		for item in self.known_items:
			if item.skill_name == skill:
				exists = true
				break
		if exists:
			continue
		var new_skill = self.list_item.instance()
		new_skill.skill_name = skill
		new_skill.skill = self.player.learned_skills[skill]
		self.known_skill_list.add_child(new_skill)
		new_skill.connect("mouse_entered", self, "_on_item_mouse_entered", [new_skill])
		new_skill.connect("mouse_exited", self, "_on_item_mouse_exited")
		
	for skill in self.unlearned_skills:
		var learned = self.player.learned_skills.has(skill)
		var exists = false
		for item in self.unknown_items:
			if item.skill_name == skill:
				if learned:
					self.unknown_items.remove(self.unknown_items.find(item))
					item.queue_free()
					break
				exists = true
				break
		if exists:
			continue
		var new_skill = self.list_item.instance()
		new_skill.skill_name = skill
		new_skill.skill = self.unlearned_skills[skill]
		self.skill_list.add_child(new_skill)
		new_skill.connect("mouse_entered", self, "_on_item_mouse_entered", [new_skill])
		new_skill.connect("mouse_exited", self, "_on_item_mouse_exited")
		new_skill.connect("gui_input", self, "_on_item_mouse_click", [new_skill])


func _on_item_mouse_entered(skill):
	self.selector.visible = true
	self.selector.rect_global_position = skill.rect_global_position
	var tooltip = self.skill_tooltip.instance()
	tooltip.position_override = Vector2(
		skill.rect_global_position.x + skill.rect_size.x,
		skill.rect_global_position.y
	)
	var skill_data = skill.skill.duplicate()
	var regex = RegEx.new()
	regex.compile("\\$(?<name>([a-z]|[A-Z])*).(?<index>[0-9]+)")
	var result = regex.search_all(skill_data["SkillTooltip"])
	if skill_data["SkillDamage"][1] > 0:
		skill_data["SkillDamage"] = self.player.damage(skill_data["SkillTags"], false, skill_data["SkillDamage"])["minmax"]
		skill_data["SkillDamage"] = [round(skill_data["SkillDamage"][0]), round(skill_data["SkillDamage"][1])]
	for i in len(result):
		regex.compile("\\$" + result[i].get_string("name") + "." + result[i].get_string("index"))
		skill_data["SkillTooltip"] = regex.sub(skill_data["SkillTooltip"], "[color=#9a94ee]" + str(skill_data[result[i].get_string("name")][int(result[i].get_string("index"))]) + "[/color]")

	tooltip.description = skill_data["SkillTooltip"]
	tooltip.mana_cost = skill_data["SkillManaCost"]
	tooltip.use_time = skill_data["SkillCastTime"]
	tooltip.tags = skill_data["SkillTags"]
	regex.compile("_")
	var skill_name = skill.skill_name
	tooltip.ic = load("res://Sprites/UI/SkillIcons/" + skill_name + "_Icon.png")
	tooltip.skill_name = " " + regex.sub(skill_name, " ")
	self.get_parent().add_child(tooltip)
	self.current_skill_tooltip = tooltip

func _on_item_mouse_exited():
	self.selector.visible = false
	self.current_skill_tooltip.queue_free()
	self.current_skill_tooltip = null

func _on_item_mouse_click(event, skill):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		self.selected.visible = true
		self.selected.rect_global_position = skill.rect_global_position
		self.selected_skill = skill
		if self.player.ability_essences >= skill.skill["SkillUnlockCost"] and self.player.level >= skill.skill["SkillRequiredLevel"]:
			self.unlock_button.disabled = false
		else:
			self.unlock_button.disabled = true

func _on_KnownSkills_pressed():
	self.known_skills_button.disabled = true
	self.unlock_skills_button.disabled = false
	self.known_skills_box.visible = true
	self.unknown_skills_box.visible = false
	self.selected.visible = false
	self.selected_skill = null
	self.unlock_button.disabled = true

func _on_UnlockSkills_pressed():
	self.known_skills_button.disabled = false
	self.unlock_skills_button.disabled = true
	self.known_skills_box.visible = false
	self.unknown_skills_box.visible = true


func _on_LearnSkill_pressed():
	self.player.learned_skills[self.selected_skill.skill_name] = self.selected_skill.skill
	self.unlearned_skills.erase(self.selected_skill.skill_name)
	self.player.ability_essences -= self.selected_skill.skill["SkillUnlockCost"]
	for item in self.unknown_items:
		if self.player.learned_skills.has(item.skill_name):
			self.unknown_items.remove(self.unknown_items.find(item))
			item.queue_free()
			break
	self.unlock_button.disabled = true
	self.selected_skill = null
	self.selected.visible = false
	self.update_info()
