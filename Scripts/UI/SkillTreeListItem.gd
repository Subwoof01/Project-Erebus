extends Control

onready var icon = $Panel/Icon
onready var s_name = $Panel/Name
onready var level = $Panel/Level
onready var cost = $Panel/Cost

var skill_name
var skill

func _ready():
	var regex = RegEx.new()
	regex.compile("_")
	self.icon.texture = load("res://Sprites/UI/SkillIcons/" + self.skill_name + "_Icon.png")
	self.s_name.text = regex.sub(self.skill_name, " ")
	self.level.text = str(self.skill["SkillRequiredLevel"])
	self.cost.text = str(self.skill["SkillUnlockCost"])
