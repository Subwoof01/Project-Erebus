extends KinematicBody2D
class_name Enemy

enum STATE {
	Idle,
	Wandering,
	Casting,
	Attacking,
	Searching,
	Dead
}

const ACCELERATION = 45
const MAX_SPEED = 120


onready var floating_text = preload("res://Scenes/UI/FloatingText.tscn")
onready var animation_tree = $AnimationTree
onready var animation_mode = animation_tree.get("parameters/playback")
onready var animation_player = $AnimationPlayer
onready var health_bar: TextureProgress = get_node("HealthBar")
onready var bar_tween: Tween = get_node("HealthBar/Tween")
onready var outline_shader = preload("res://Resources/OutlineShader.tres")
onready var sprite = $Sprite
onready var player = self.get_parent().get_node("Player")
onready var nav_map: Navigation2D = self.get_parent().get_parent()
onready var sight_range = $Sight
onready var attack_range = $AttackRange

export var monster_name = ""
export var max_health = 100
export var level = 1
export var base_exp = 100

var shader_material
var current_health
var percentage_hp = 100
var speed = 120
var state = STATE.Idle

var is_player_in_range = false
var is_player_in_sight = false
var is_player_in_strike_range = false
var is_player_seen = false
onready var destination = self.global_position

var can_heal = true

var time_passed_since_idle = 0
var time_between_wanders = 3

func _ready():
	self.current_health = self.max_health
	self.shader_material = self.outline_shader.duplicate()
	self.sprite.material = self.shader_material

func _process(delta):
	if self.state == STATE.Dead:
		return
	match self.state:
		STATE.Idle:
			self.animation_tree.set("parameters/Idle/blend_position", self.global_position.direction_to(self.destination).normalized())
			self.animation_mode.travel("Idle")
			self.time_passed_since_idle += delta
			if self.time_passed_since_idle >= self.time_between_wanders:
				self.time_passed_since_idle = 0
				self.destination = self.nav_map.get_closest_point(Mathf.randv_circle(self.sight_range.get_child(0).shape.radius * 0.5, self.sight_range.get_child(0).shape.radius))
				self.state = STATE.Wandering
		STATE.Wandering:
			self.animation_mode.travel("Walking")
			self.wander(delta)
		STATE.Attacking:			
			self.animation_tree.set("parameters/Idle/blend_position", self.global_position.direction_to(self.player.global_position).normalized())
			self.attack()
		STATE.Searching:
			self.animation_mode.travel("Walking")
			self.search(delta)
		
func _physics_process(delta):
	self.sight_check()

func sight_check():
	if self.is_player_in_range:
		var space_state = self.get_world_2d().direct_space_state
		var check = space_state.intersect_ray(self.position, self.player.position, [self, $Collision], 2)
		if check:
			if check.collider.name == "Player":
				self.is_player_in_sight = true
				self.is_player_seen = true
				self.destination = self.nav_map.get_closest_point(self.player.global_position)
				if self.is_player_in_strike_range:
					self.state = STATE.Attacking
			else:
				self.is_player_in_sight = false
				if self.is_player_seen:
					self.state = STATE.Searching
				else:
					self.state = STATE.Idle

func _on_Sight_body_entered(body):
	if self.state == STATE.Dead:
		return
	if body == self.player:
		self.is_player_in_range = true

func _on_Sight_body_exited(body):
	if self.state == STATE.Dead:
		return
	if body == self.player:
		self.is_player_in_range = false
		if self.is_player_seen:
			self.state = STATE.Searching

func _on_StrikeRange_body_entered(body):
	if self.state == STATE.Dead:
		return
	if body == self.player:
		self.is_player_in_strike_range = true

func _on_StrikeRange_body_exited(body):
	if self.state == STATE.Dead:
		return
	if body == self.player:
		self.is_player_in_strike_range = false

func wander(delta):
	var path = self.move(delta)
	if path.size() == 0:
		self.state = STATE.Idle

func move(delta) -> PoolVector2Array:
	var path_to_destination = self.nav_map.get_simple_path(self.global_position, self.destination)
	var starting_point = self.global_position
	var move_distance = self.speed * delta
	
	for point in range(path_to_destination.size()):
		var distance_to_next_point = starting_point.distance_to(path_to_destination[0])
		self.animation_tree.set("parameters/Walking/blend_position", self.global_position.direction_to(path_to_destination[0]).normalized())
		if move_distance <= distance_to_next_point:
			var move_direction = self.get_angle_to(starting_point.linear_interpolate(path_to_destination[0], move_distance / distance_to_next_point))
			var motion = Vector2(speed, 0).rotated(move_direction)
			self.move_and_slide(motion)
			break
		move_distance -= distance_to_next_point
		starting_point = path_to_destination[0]
		path_to_destination.remove(0)

	return path_to_destination

func search(delta):
	var path = self.move(delta)
	if path.size() == 0:
		self.is_player_seen = false
		self.state = STATE.Idle

func attack():
	pass

func on_death():
	self.health_bar.hide()
	self.state = STATE.Dead
	self.is_player_in_sight = false
	self.is_player_in_strike_range = false
	self.is_player_seen = false
	self.is_player_in_range = false
	self.sight_range.get_child(0).disabled = true
	self.attack_range.get_child(0).disabled = true
	$CollisionShape2D.set_deferred("disabled", true)
	$Collision/CollisionPolygon2D.set_deferred("disabled", true)
	self.animation_mode.travel("Death")
	self.player.gain_exp(self.base_exp, self.level)

func on_hit(damage):
	self.current_health -= damage
	self.animation_mode.travel("Hit")
	self.update_health_bar()
	var text = self.floating_text.instance()
	text.amount = damage
	self.add_child(text)
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

