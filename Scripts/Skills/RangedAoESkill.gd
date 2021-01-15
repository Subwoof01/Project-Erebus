extends Area2D

export var skill_name = ""
export var damage = 80
export var animation = "Earthquake"
export var damage_delay_time = 0.3
export var remove_delay_time = 0.5
export var skill_cast_time = 0.4

var origin

func _ready():
	if self.origin == "Player":
		self.set_collision_mask_bit(1, false)
	elif self.origin == "Enemy":
		self.set_collision_mask_bit(2, false)
		self.set_collision_mask_bit(4, false)
	var skill_data = DataImport.skill_data[skill_name]
	self.damage = skill_data.SkillDamage
	self.animation = skill_name
	self.damage_delay_time = skill_data.SkillDamageDelayTime
	self.remove_delay_time = skill_data.SkillRemoveDelayTime
	self.skill_cast_time = skill_data.SkillCastTime
	$CollisionShape2D.shape.radius = skill_data.SkillRadius
	aoe_attack()

func aoe_attack():
	$AnimatedSprite.animation = self.animation
	$AnimatedSprite.play()
	yield(self.get_tree().create_timer(self.damage_delay_time), "timeout")
	var targets = self.get_overlapping_bodies()
	for target in targets:
		if target.get_parent().is_in_group("Enemies"):
			target.get_parent().on_hit(self.damage)
		elif target.is_in_group("Player"):
			target.take_damage(self.damage)
	yield(self.get_tree().create_timer(self.remove_delay_time), "timeout")
	self.queue_free()


func _on_animation_finished():
	self.hide()
