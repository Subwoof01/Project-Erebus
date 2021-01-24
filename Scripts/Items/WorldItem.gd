extends Node2D

onready var sprite = $Sprite
onready var animation = $Sprite/AnimationPlayer
onready var name_label = $Control/ItemName
onready var tooltip_shape = $Control/ClickArea2/TooltipShape
onready var tooltip_bg = $Control/ItemName/Panel

var base_name_colour = "96000000"
var highlight_colour = "96ffa200"
var item_data
var item_ui
var info_set = false

func _process(delta):
	if ItemManager.alt_down:
		if self.item_data.amount > 1:
			self.name_label.text = self.item_data.item_name + " (" + str(self.item_data.amount) + ")"
		else:
			self.name_label.text = self.item_data.item_name
		self.name_label.rect_position.x = self.name_label.rect_size.x * 0.5 * -1
		self.name_label.visible = true
	else:
		self.name_label.visible = false

func show():
	self.sprite.material.set_shader_param("draw_outline", true)
	self.tooltip_bg.self_modulate = Color(self.highlight_colour)

func hide():
	self.sprite.material.set_shader_param("draw_outline", false)
	self.tooltip_bg.self_modulate = Color(self.base_name_colour)


func _on_ClickArea_mouse_entered():
	self.show()

func _on_ClickArea_mouse_exited():
	self.hide()
	
func _on_Panel_mouse_entered():
	self.show()
	
func _on_Panel_mouse_exited():
	self.hide()

func _on_ClickArea_input_event(viewport, event: InputEvent, shape_idx):
	if event.is_action_pressed("ui_left_mouse_button"):
		self.pick_up()

func _on_Panel_gui_input(event: InputEvent):
	if event.is_action_pressed("ui_left_mouse_button"):
		self.pick_up()
		
func pick_up():
	ItemManager.game.player.pickup(self)
