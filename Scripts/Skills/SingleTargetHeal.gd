extends Node2D

export var skill_name = ""
export var heal_amount = 1
var skill_cast_time = 0.4

func _ready():
	var skill_data = DataImport.skill_data[skill_name]
	self.heal_amount = skill_data.SkillHeal
	self.skill_cast_time = skill_data.SkillCastTime
	heal()

func heal():
	$AnimatedSprite.animation = skill_name
	$AnimatedSprite.play()
	self.get_parent().on_heal(self.heal_amount)


func _on_animation_finished():
	self.queue_free()
