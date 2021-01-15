extends CanvasLayer

onready var action_bar_path = "UI/ActionBarManaOverlay/Background/HBoxContainer/"


var loaded_skills

func _ready():
	loaded_skills = self.get_tree().get_root().get_node("Game/NavigationMap/YSort/Player").action_bar_skills
	load_shortcuts()

func load_shortcuts():
	for shortcut in loaded_skills.keys():
		var skill_icon = load("res://Sprites/UI/SkillIcons/" + loaded_skills[shortcut] + "_Icon.png")
		self.get_node(action_bar_path + shortcut + "/SkillIcon").set_normal_texture(skill_icon)

