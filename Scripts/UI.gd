extends CanvasLayer

onready var ui = $UI
onready var action_bar_path = "UI/ActionBarManaOverlay/SkillSlots/"
onready var player = self.get_tree().get_root().get_node("Game/NavigationMap/YSort/Player")
onready var skill_tooltip = preload("res://Scenes/UI/SkillTooltip.tscn")

var loaded_skills

func _ready():
	load_shortcuts()

func load_shortcuts():
	loaded_skills = self.player.action_bar_skills
	for shortcut in loaded_skills.keys():
		var skill_icon = load("res://Sprites/UI/SkillIcons/" + loaded_skills[shortcut] + "_Icon.png")
		self.get_node(action_bar_path + shortcut + "/SkillIcon").set_normal_texture(skill_icon)
		for action in InputMap.get_action_list("ui_" + shortcut.to_lower()):
			if action is InputEventKey:
				self.get_node(action_bar_path + shortcut + "/Hotkey").text = OS.get_scancode_string(action.scancode)

func show_skill_tooltip(skill_name):
	if skill_name == "":
		return
	var tooltip = self.skill_tooltip.instance()
	var skill_data = DataImport.skill_data[skill_name].duplicate()
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
	tooltip.ic = load("res://Sprites/UI/SkillIcons/" + skill_name + "_Icon.png")
	tooltip.skill_name = " " + regex.sub(skill_name, " ")
	self.ui.add_child(tooltip)
	return tooltip
