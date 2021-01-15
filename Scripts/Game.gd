extends Node2D

onready var player = $NavigationMap/YSort/Player
onready var char_window = $CanvasLayer/UI/StatScreen
onready var inventory_window = $CanvasLayer/UI/InventoryScreen
onready var stat_window = $CanvasLayer/UI/StatScreen
onready var ui_health_bar = $CanvasLayer/UI/EnemyHealthBar
onready var ui_enemy_name = $CanvasLayer/UI/EnemyHealthBar/EnemyName

onready var skelly = preload("res://Scenes/NPC/Skeleton.tscn")

var alt_pressed = false
var current_mouse_over_target = null

func _ready():
	for i in range(10):
		ItemManager.spawn_item(player.global_position)

func _process(delta):
	if self.current_mouse_over_target != null:
		self.set_ui_health_bar_info()
	var screen_space = self.get_world_2d().direct_space_state
	var ray_cast = screen_space.intersect_point(self.get_global_mouse_position(), 1, [self.player], 2)
	for body in ray_cast:
		if body.collider.is_in_group("Enemies"):
			self.current_mouse_over_target = body.collider
			self.ui_health_bar.visible = true
			self.current_mouse_over_target.shader_material.set_shader_param("draw_outline", true)
	if len(ray_cast) == 0 and self.current_mouse_over_target != null:
		self.current_mouse_over_target.shader_material.set_shader_param("draw_outline", false)
		self.current_mouse_over_target = null
		self.ui_health_bar.visible = false

func _unhandled_input(event):
	self.player.handle_inputs()
	if Input.is_action_just_pressed("ui_char_window"):
		self.char_window.visible = !self.char_window.visible
		self.char_window.on_show()
	
	if Input.is_action_just_pressed("ui_inventory_window"):
		self.inventory_window.visible = !self.inventory_window.visible

	if Input.is_action_just_pressed("ui_skill8"):
		var dooter = skelly.instance()
		dooter.position = self.get_global_mouse_position()
		$NavigationMap/YSort.add_child(dooter)
	
	if Input.is_action_just_pressed("ui_alt"):
		self.alt_pressed = true
		ItemManager.alt_down = true
	if Input.is_action_just_released("ui_alt"):
		self.alt_pressed = false
		ItemManager.alt_down = false
		

func set_ui_health_bar_info():
	if self.current_mouse_over_target.current_health <= 0:
		self.ui_health_bar.visible = false
		self.current_mouse_over_target.shader_material.set_shader_param("draw_outline", false)
		pass
	self.ui_enemy_name.text = self.current_mouse_over_target.monster_name
	var percentage_hp = int((float(self.current_mouse_over_target.current_health) / self.current_mouse_over_target.max_health) * 100)
	self.ui_health_bar.get_node("Tween").interpolate_property(self.ui_health_bar, 'value', self.ui_health_bar.value, percentage_hp, 0.025, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	self.ui_health_bar.get_node("Tween").start()
