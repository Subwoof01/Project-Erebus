extends Control


onready var description_box = $Background/VBoxContainer/MarginContainer/VBoxContainer/Description
onready var icon = $Background/VBoxContainer/HBoxContainer/Panel3/Icon
onready var name_box = $Background/VBoxContainer/HBoxContainer/Panel/Name
onready var cost = $Background/VBoxContainer/HBoxContainer/Panel2/Cost
onready var cast_time = $Background/VBoxContainer/HBoxContainer/Panel4/CastTime
onready var background = $Background
onready var top_bar = $Background/VBoxContainer/HBoxContainer
onready var description_margin = $Background/VBoxContainer/MarginContainer
onready var tags_box = $Background/VBoxContainer/MarginContainer/VBoxContainer/Tags
onready var divider = $Background/VBoxContainer/MarginContainer/VBoxContainer/Divider
onready var skill_icon = $Background/VBoxContainer/HBoxContainer/Panel3/Icon

var description = ""
var mana_cost = 0
var use_time = 0
var skill_name = ""
var tags = []
var ic = null
var position_override = null

func _ready():
	self.skill_icon.texture = ic
	self.description_box.bbcode_text = self.description
	self.cost.text = "Mana Cost \n" + str(self.mana_cost)
	self.cast_time.text = "Use Time \n" + str(self.use_time) + " sec"
	self.name_box.text = self.skill_name
	var text = "[center]"
	var i = 1
	for tag in self.tags:
		if i == len(self.tags):
			text += "[color=#9a94ee]" + tag + "[/color][/center]"
			break
		text += "[color=#9a94ee]" + tag + "[/color][color=#ffffff], [/color]"
		i += 1
	self.tags_box.bbcode_text = text
	self.scale_tooltip()
	self.set_pos()

func _input(event):
	self.set_pos()

func scale_tooltip():
	var height = self.description_box.get("custom_fonts/normal_font").get_string_size(self.description_box.text).x
	height /= background.rect_size.x
	height = 31 * ceil(height) + self.description_margin.get("custom_constants/margin_top") * 2 + self.tags_box.rect_size.y + self.divider.rect_size.y
	background.rect_size.y += height

func set_pos():
	var margin = Vector2(10, 10)
	var cursor_pos = self.get_global_mouse_position()
	var new_pos = Vector2(cursor_pos.x - self.background.rect_size.x, cursor_pos.y - self.background.rect_size.y) if self.position_override == null else self.position_override
	if new_pos.x < margin.x:
		new_pos.x = margin.x
	if new_pos.y < margin.y:
		new_pos.y = margin.y
	self.rect_position = new_pos
