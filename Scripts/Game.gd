extends Node2D

onready var player = $NavigationMap/YSort/Player
onready var ui = $CanvasLayer/UI
onready var char_window = $CanvasLayer/UI/StatScreen
onready var inventory_window = $CanvasLayer/UI/InventoryScreen
onready var skill_screen = $CanvasLayer/UI/SkillTreeScreen
onready var stat_window = $CanvasLayer/UI/StatScreen
onready var ui_health_bar = $CanvasLayer/UI/EnemyHealthBar
onready var ui_enemy_name = $CanvasLayer/UI/EnemyHealthBar/EnemyName
onready var action_bar_skill_slots = $CanvasLayer/UI/ActionBarManaOverlay/Background/SkillSlots

var current_skill_tooltip = null

var alt_pressed = false
var current_mouse_over_target = null

var last_openened_menu = null

func _ready():
	var item = Equipment.new()
	item.create_item(2)
	item.create_randomised_equipment(1)
	ItemManager.spawn_item(player.global_position, 1, item)
	ItemManager.pickup(item)
	# for i in range(10):
	# 	ItemManager.spawn_item(player.global_position)

func _process(delta):
	if self.current_mouse_over_target != null:
		self.set_ui_health_bar_info()
	var screen_space = self.get_world_2d().direct_space_state
	var ray_cast = screen_space.intersect_point(self.get_global_mouse_position(), 1, [self.player], 16, false, true)
	for body in ray_cast:
		if body.collider.is_in_group("Enemies"):
			self.current_mouse_over_target = body.collider.get_parent()
			self.ui_health_bar.visible = true
			self.current_mouse_over_target.shader_material.set_shader_param("draw_outline", true)
	if len(ray_cast) == 0 and self.current_mouse_over_target != null:
		self.current_mouse_over_target.shader_material.set_shader_param("draw_outline", false)
		self.current_mouse_over_target = null
		self.ui_health_bar.visible = false

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_char_window"):
		self.char_window.visible = !self.char_window.visible
		if self.char_window.visible:
			self.last_openened_menu = self.char_window
		if self.skill_screen.visible:
			self.skill_screen.visible = false
		self.char_window.on_show()
	
	if Input.is_action_just_pressed("ui_inventory_window"):
		self.inventory_window.visible = !self.inventory_window.visible
		if self.inventory_window.visible:
			self.last_openened_menu = self.inventory_window

	if Input.is_action_just_pressed("ui_skill_screen"):
		self.skill_screen.visible = !self.skill_screen.visible
		if self.skill_screen.visible:
			self.last_openened_menu = self.skill_screen
		if self.char_window.visible:
			self.char_window.visible = false
		self.skill_screen.update_info()
	
	if Input.is_action_just_pressed("ui_cancel"):
		if self.last_openened_menu != null:
			self.last_openened_menu.visible = false
	
	if Input.is_action_just_pressed("ui_space"):
		self.skill_screen.visible = false
		self.inventory_window.visible = false
		self.skill_screen.visible = false

	if Input.is_action_just_pressed("ui_alt"):
		self.alt_pressed = true
		ItemManager.alt_down = true
	if Input.is_action_just_released("ui_alt"):
		self.alt_pressed = false
		ItemManager.alt_down = false
	self.player.handle_inputs()
		
func set_ui_health_bar_info():
	if self.current_mouse_over_target.current_health <= 0:
		self.ui_health_bar.visible = false
		self.current_mouse_over_target.shader_material.set_shader_param("draw_outline", false)
		pass
	self.ui_enemy_name.text = self.current_mouse_over_target.monster_name
	var percentage_hp = int((float(self.current_mouse_over_target.current_health) / self.current_mouse_over_target.max_health) * 100)
	self.ui_health_bar.get_node("Tween").interpolate_property(self.ui_health_bar, 'value', self.ui_health_bar.value, percentage_hp, 0.025, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	self.ui_health_bar.get_node("Tween").start()

func _on_Skill_mouse_entered(slot):
	self.current_skill_tooltip = self.ui.get_parent().show_skill_tooltip(self.player.action_bar_skills["Skill" + str(slot+1)])

func _on_Skill_mouse_exited():
	if self.current_skill_tooltip == null:
		return
	self.current_skill_tooltip.queue_free()
	self.current_skill_tooltip = null
