extends "Enemy.gd"

onready var player = self.get_parent().get_node("Player")
var is_player_in_range
var is_player_in_sight
var is_player_in_strike_range
var is_player_seen

func _ready():
	self.level = 1
	self.base_exp = 100
	pass # Replace with function body.

func _process(delta):
	if is_player_in_sight:
		self.location = player.global_position

func on_death():
	.on_death()
	$CollisionShape2D.set_deferred("disabled", true)
	$Collision/CollisionPolygon2D.set_deferred("disabled", true)
	self.animation_mode.travel("Death")
	self.player.gain_exp(self.base_exp, self.level)

func _physics_process(delta):
	self.sight_check()

func _on_Sight_body_entered(body):
	if body == self.player:
		self.is_player_in_range = true
		# print("player in range: ", self.is_player_in_range)

func _on_Sight_body_exited(body):
	if body == self.player:
		self.is_player_in_range = false
		# print("player in range: ", self.is_player_in_range)
		if self.is_player_seen:
			self.state = self.STATE.Searching

func _on_StrikeRange_body_entered(body):
	if body == self.player:
		self.is_player_in_strike_range = true

func _on_StrikeRange_body_exited(body):
	if body == self.player:
		self.is_player_in_strike_range = false

func sight_check():
	if is_player_in_range:
		var space_state = self.get_world_2d().direct_space_state
		var check = space_state.intersect_ray(self.position, self.player.position, [self, $Collision], 1)
		if check:
			if check.collider.name == "Player":
				self.is_player_in_sight = true
				self.is_player_seen = true
				# print("player in sight: ", self.is_player_in_sight)
			else:
				self.is_player_in_sight = false
				if self.is_player_seen:
					self.state = self.STATE.Searching
				else:
					self.state = self.STATE.Idle
				# print("player in sight: ", self.is_player_in_sight)
