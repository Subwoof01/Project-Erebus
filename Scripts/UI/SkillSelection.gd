extends GridContainer

onready var game = self.get_tree().get_root().get_node("Game")
var selected_slot
var selectable_skills = {}
var current_tooltip = null

func _ready():
	pass # Replace with function body.

func _on_Skill_gui_input(event, skill_slot):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		self.selected_slot = skill_slot
		# print(self.game.player.learned_skills.keys())
		for skill in self.game.player.learned_skills:
			if self.selectable_skills.has(skill):
				continue
			var skill_icon = TextureRect.new()
			skill_icon.texture = load("res://Sprites/UI/SkillIcons/" + skill + "_Icon.png")
			skill_icon.connect("mouse_entered", self, "_on_Skill_mouse_entered", [skill])
			skill_icon.connect("mouse_exited", self, "_on_Skill_mouse_exited")
			skill_icon.connect("gui_input", self, "_on_Skill_click", [skill])
			skill_icon.expand = true
			skill_icon.rect_min_size = Vector2(50, 50)
			self.selectable_skills[skill] = self.game.player.learned_skills[skill]
			self.rect_size = Vector2(self.rect_size.x, 50)
			self.add_child(skill_icon)
		
		if len(self.selectable_skills) > 0:
			self.visible = !self.visible


func _on_Skill_mouse_entered(skill):
	self.current_tooltip = self.game.ui.get_parent().show_skill_tooltip(skill)

func _on_Skill_mouse_exited():
	if self.current_tooltip == null:
		return
	self.current_tooltip.queue_free()
	self.current_tooltip = null

func _on_Skill_click(event, skill):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if skill == "NONE":
			self.game.player.action_bar_skills["Skill" + str(self.selected_slot + 1)] = ""
		else:
			self.game.player.action_bar_skills["Skill" + str(self.selected_slot + 1)] = skill
		self.game.ui.get_parent().load_shortcuts()
		self.game.player.update_selected_skills()
		self.visible = false
		if self.current_tooltip == null:
			return
		self.current_tooltip.queue_free()
		self.current_tooltip = null
