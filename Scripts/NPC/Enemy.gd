extends KinematicBody2D

enum STATE {
	Idle,
	Walking,
	Casting,
	Striking,
	Searching
}

const ACCELERATION = 45
const MAX_SPEED = 120
onready var animation_tree = $AnimationTree
onready var animation_mode = animation_tree.get("parameters/playback")
onready var animation_player = $AnimationPlayer
export var monster_name = ""
export var max_health = 100
export var level = 1
export var base_exp = 100
var shader_material
var current_health
var percentage_hp = 100
var is_dead = false
onready var health_bar: TextureProgress = get_node("HealthBar")
onready var bar_tween: Tween = get_node("HealthBar/Tween")
onready var outline_shader = preload("res://Resources/OutlineShader.tres")
onready var sprite = $Sprite
var location = self.global_position
var speed = 0
var state = STATE.Idle

var can_heal = true

func _process(delta):
	pass

		

func _ready():
	self.current_health = self.max_health
	self.shader_material = self.outline_shader.duplicate()
	self.sprite.material = self.shader_material
	pass

func on_hit(damage):
	self.current_health -= damage
	self.animation_mode.travel("Hit")
	self.update_health_bar()
	if (current_health <= 0):
		self.on_death()
		return

func on_heal(heal):
	self.current_health += heal
	if self.current_health > self.max_health:
		self.current_health = self.max_health
	self.update_health_bar()

func update_health_bar():
	if self.current_health < self.max_health:
		self.health_bar.show()
	self.percentage_hp = int((float(self.current_health) / self.max_health) * 100)
	self.bar_tween.interpolate_property(self.health_bar, 'value', self.health_bar.value, percentage_hp, 0.1, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	self.bar_tween.start()
	
func on_death():
	self.health_bar.hide()
	self.is_dead = true
