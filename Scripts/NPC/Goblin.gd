extends Enemy

var can_attack = true

func _ready():
	print("-- GOBLIN --")
	print(self.collision_layer)
	print(self.collision_mask)
	._ready()
	self.level = 1
	self.base_exp = 100

func attack():
	if !self.can_attack:
		return
	
	self.can_attack = false
	self.speed = 1
	self.animation_tree.set("parameters/Melee/blend_position", self.global_position.direction_to(self.player.global_position).normalized())
	self.animation_tree.set("parameters/Idle/blend_position", self.global_position.direction_to(self.player.global_position).normalized())
	$TurnAxis.rotation = self.get_angle_to(self.player.global_position)
	$TurnAxis/MeleeCheck.global_position = self.player.global_position
	self.animation_mode.travel("Melee")
	yield(self.get_tree().create_timer(0.7), "timeout")
	self.can_attack = true
	self.speed = self.MAX_SPEED

func _on_MeleeCheck_body_entered(body):
	if body == self.player:
		body.take_damage(20)
