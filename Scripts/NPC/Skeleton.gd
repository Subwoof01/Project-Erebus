extends Enemy

var can_fire = true

func _ready():
	._ready()
	self.level = 1
	self.base_exp = 100

func attack():
	if !self.can_fire:
		return
	self.can_fire = false
	self.speed = 1
	self.animation_tree.set("parameters/Casting/blend_position", self.global_position.direction_to(self.player.global_position).normalized())
	self.animation_mode.travel("Casting")
	$TurnAxis.rotation = self.get_angle_to(self.player.global_position)
	var skill = load("res://Scenes/Skills/RangedSingleTargetSkill.tscn").instance()
	skill.skill_name = "Ice_Spear"
	skill.rotation = $Center.get_angle_to(self.player.global_position)
	skill.position = $TurnAxis/CastPoint.global_position
	skill.origin = "Enemy"
	self.get_parent().add_child(skill)
	yield(self.get_tree().create_timer(0.7), "timeout")
	self.can_fire = true
	self.speed = self.MAX_SPEED
