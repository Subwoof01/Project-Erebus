extends Area2D


export var skill_name = ""
export var damage = 80
export var radius = 200
export var skill_cast_time = 0.4
export var expansion_time = 0.45
var damaged_targets = []

var circle_shape = preload("res://Resources/CircleShape.res")

func _ready():
	var skill_data = DataImport.skill_data[skill_name]
	self.damage = skill_data.SkillDamage
	self.radius = skill_data.SkillRadius
	self.skill_cast_time = skill_data.SkillCastTime
	self.expansion_time = skill_data.SkillExpansionTime
	aoe_attack()

func aoe_attack():
	$AnimatedSprite.animation = self.skill_name
	$AnimatedSprite.play()
	var radius_step = self.radius / (self.expansion_time / 0.05)
	while $CollisionShape2D.shape.radius <= self.radius:
		var shape = circle_shape.duplicate()
		shape.radius = $CollisionShape2D.get_shape().radius + radius_step
		$CollisionShape2D.shape = shape
		var targets = self.get_overlapping_bodies()
		for target in targets:
			if damaged_targets.has(target):
				continue
			else:
				if target.is_in_group("Enemies"):
					target.on_hit(self.damage)
					damaged_targets.append(target)
		yield(self.get_tree().create_timer(0.05), "timeout")
		continue
	self.queue_free()
