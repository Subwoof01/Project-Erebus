extends RigidBody2D

export var skill_name = ""
var damage = {"damage": 50, "crit": false, "minmax": [50, 50]}
export var projectile_speed = 400
export var life_time = 3
export var skill_cast_time = 0.4
export var skill_projectile_acceleration = 0
export var skill_projectile_delay = 0
var damage_type = ["Lightning"]
var crit = false

var origin

var accelerate = false

func _ready():
	if self.origin == "Player":
		self.set_collision_mask_bit(1, false)
	elif self.origin == "Enemy":
		self.set_collision_mask_bit(16, false)
	var skill_data = DataImport.skill_data[skill_name]
	self.projectile_speed = skill_data.SkillProjectileSpeed
	self.skill_cast_time = skill_data.SkillCastTime
	self.skill_projectile_acceleration = skill_data.SkillProjectileAcceleration
	self.skill_projectile_delay = skill_data.SkillProjectileDelay
	$Sprite.animation = skill_name
	self.apply_impulse(Vector2(), Vector2(self.projectile_speed, 0).rotated(self.global_rotation))
	yield(self.get_tree().create_timer(self.skill_projectile_delay), "timeout")
	self.accelerate = true
	self.self_destruct()

func self_destruct():
	yield(self.get_tree().create_timer(life_time), "timeout")
	self.queue_free()

func _on_Spell_body_entered(body):
	$CollisionPolygon2D.set_deferred("disabled", true)
	if body.is_in_group("Player"):
		body.take_damage(self.damage.duplicate(), self.damage_type)
	self.hide()

func _process(delta):
	if accelerate:
		self.apply_impulse(Vector2(), Vector2(self.skill_projectile_acceleration, 0).rotated(self.global_rotation))
