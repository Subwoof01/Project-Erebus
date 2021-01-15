extends KinematicBody2D

enum STATE {
	Idle,
	Walking,
	Casting,
	Striking
}

const ACCELERATION = 25
export var MAX_SPEED = 165

onready var animation_tree = $AnimationTree
onready var animation_mode = animation_tree.get("parameters/playback")
onready var animation_player = $AnimationPlayer

var p_name = "Player_Name"
var level = 1
var total_exp = 0
var experience = 0
var next_level_exp = 1500
var stat_points = 0

var stats = {}
var current_health
var current_mana

var movement_margin = 2

var action_queue = []

var state = STATE.Idle

var speed = 0
var can_cast = true
var can_strike = true
var rate_of_fire = 0.3
var location = Vector2()
var location_angle = 0

var lmb_pressed = false
var shift_down = false

var current_target = null

var action_bar_skills = {"Skill1": "Ice_Spear", "Skill2": "Earthquake", "Skill3": "Ice_Nova", "Skill4": "Healing_Word"}
var selected_skills = []

var things_in_interact_range = []

onready var game = get_node("/root/Game")
onready var camera = $Camera2D
onready var nav_map = get_parent()
onready var animation = $Body
onready var head_animation = $Head

onready var health_orb = game.get_node("CanvasLayer/UI/HealthOrb/Health")
onready var health_tween = game.get_node("CanvasLayer/UI/HealthOrb/Health/Tween")
onready var mana_orb = game.get_node("CanvasLayer/UI/ActionBarManaOverlay/Mana")
onready var mana_tween = game.get_node("CanvasLayer/UI/ActionBarManaOverlay/Mana/Tween")
onready var exp_bar = game.get_node("CanvasLayer/UI/Experience/Bar")
onready var stat_screen = game.get_node("CanvasLayer/UI/StatScreen")

onready var rng = RandomNumberGenerator.new()

var skills = []

func _ready():
	for stat in StatData.stat_data:
		self.stats[stat] = CharacterStat.new(StatData.stat_data[stat]["StatBaseValue"])

	self.current_health = self.stats["Health"].value
	self.current_mana = self.stats["Mana"].value
	for skill in self.action_bar_skills:
		self.selected_skills.append(self.action_bar_skills[skill])

func _process(delta):
	if len(self.action_queue) > 0:
		self.lmb_pressed = false
		self.location = self.action_queue[2].global_position
		self.state = self.STATE.Walking
	if self.lmb_pressed:
		if self.can_strike:
			var space_state = self.get_world_2d().direct_space_state
			var check = space_state.intersect_point(self.get_global_mouse_position(), 2, [self], 2, true)
			# print(check)
			for body in check:
				# print("Checking body: ", body)
				if body.collider.is_in_group("Enemies"):
					if body.collider.get_node("Collision") in self.things_in_interact_range:
						self.melee_strike(body.collider)
						break;
					self.queue_action("strike", body.collider, body.collider)
		if self.shift_down:
			self.melee_strike()
		else:
			if self.state != STATE.Casting and self.state != self.STATE.Striking:
				self.animation_tree.set("parameters/Idle/blend_position", self.global_position.direction_to(self.get_global_mouse_position()).normalized())
				self.lmb_pressed = true
				self.state = STATE.Walking
				self.location = self.get_global_mouse_position()

func _physics_process(delta):
	if self.state == STATE.Walking:
		if self.speed < MAX_SPEED:
			self.speed += ACCELERATION
		
		self.animation_tree.set("parameters/Walking/blend_position", self.global_position.direction_to(self.location).normalized())
		self.animation_tree.set("parameters/Idle/blend_position", self.global_position.direction_to(self.location).normalized())
		var direction = (self.location - self.position).normalized()
		self.animation_mode.travel("Walking")
		# if self.lmb_pressed:
		# 	self.set_animation(true)
		# else:
		# 	self.set_animation(false, self.location_angle)

		if self.global_position.distance_to(self.location) > self.movement_margin:
			self.move_and_slide(direction * self.speed)
			return

		self.state = STATE.Idle
		self.animation_mode.travel("Idle")
			# self.set_animation(false, self.location_angle)

func handle_inputs():
	if Input.is_action_just_released("ui_left_mouse_button"):
		self.lmb_pressed = false
	if Input.is_action_just_pressed("ui_left_mouse_button"):
		self.action_queue = []
		self.lmb_pressed = true
	if Input.is_action_just_released("ui_shift"):
		self.shift_down = false
	if Input.is_action_just_pressed("ui_shift"):
		self.shift_down = true
	if Input.is_action_pressed("ui_skill1") and can_cast:
		self.use_skill(0)
	if Input.is_action_pressed("ui_skill2") and can_cast:
		self.use_skill(1)
	if Input.is_action_pressed("ui_skill3") and can_cast:
		self.use_skill(2)
	if Input.is_action_pressed("ui_skill4") and can_cast:
		self.use_skill(3)

func _on_InteractRange_area_entered(area):
	print("area added ", area)
	if len(self.action_queue) > 0:
		if area == self.action_queue[2]:
			self.execute_queued_action()
	self.things_in_interact_range.append(area)

func _on_InteractRange_area_exited(area):
	self.things_in_interact_range.remove(self.things_in_interact_range.find(area))

func _on_InteractRange_body_entered(body):
	if len(self.action_queue) > 0:
		if body == self.action_queue[2]:
			self.execute_queued_action()
	print("body added ", body)
	self.things_in_interact_range.append(body)

func _on_InteractRange_body_exited(body):
	self.things_in_interact_range.remove(self.things_in_interact_range.find(body))

func queue_action(action, object, interact_checker):
	self.action_queue.append(action)
	self.action_queue.append(object)
	self.action_queue.append(interact_checker)

func execute_queued_action():
	match self.action_queue[0]:
		"pickup":
			ItemManager.pickup(self.action_queue[1])
			self.action_queue = []
		"strike":
			self.melee_strike(self.action_queue[1])
			self.action_queue = []

func damage(type):
	# Add more damage logic here. Crit chance, other dmg types etc.
	var damage
	match type:
		"Physical":
			self.rng.randomize()
			damage = self.rng.randf_range(self.stats["PhysicalDamageMin"].value, self.stats["PhysicalDamageMax"].value)
		_:
			damage = 0
	return damage


func take_damage(damage):
	self.current_health -= damage;
	self.update_health_orb()

func lose_mana(cost):
	self.current_mana -= cost;
	self.update_mana_orb()

func on_heal(heal):
	self.current_health += heal
	if self.current_health > self.stats["Health"].value:
		self.current_health = self.stats["Health"].value

func update_health_orb():
	var percentage_hp = int((float(self.current_health) / self.stats["Health"]) * 100)
	health_tween.interpolate_property(health_orb, 'value', health_orb.value, percentage_hp, 0.1, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	health_tween.start()

func update_mana_orb():
	var percentage_mp = int((float(self.current_mana) / self.stats["Mana"]) * 100)
	mana_tween.interpolate_property(mana_orb, 'value', mana_orb.value, percentage_mp, 0.1, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	mana_tween.start()
		
func gain_exp(experience, level):
	var final_exp = experience * (1 - abs(level - self.level) / 10)
	self.experience += final_exp
	if self.total_exp + self.experience >= self.next_level_exp:
		self.level_up()
	self.update_exp_bar()
	self.stat_screen.update_stat_window()

func update_exp_bar():
	var percentage_exp = int((float(self.experience) / (self.next_level_exp - self.total_exp)) * 100)
	self.exp_bar.value = percentage_exp

func level_up():
	self.level += 1
	self.total_exp = self.experience
	self.experience = 0
	self.next_level_exp *= 1.5
	self.stat_points += 5

func mouse_position():
	var m_pos = self.game.get_global_mouse_position()
	return m_pos

func melee_strike(target=null):
	if !self.can_strike:
		return

	self.state = STATE.Striking
	self.can_strike = false
	if target == null:
		self.animation_tree.set("parameters/Melee/blend_position", self.global_position.direction_to(self.get_global_mouse_position()).normalized())
		self.animation_tree.set("parameters/Idle/blend_position", self.global_position.direction_to(self.get_global_mouse_position()).normalized())
		var angle = $MeleeTurnAxis.get_angle_to(self.get_global_mouse_position())
		$MeleeTurnAxis.rotate(angle)
		$MeleeTurnAxis/MeleeArea.global_position = self.global_position
		$MeleeTurnAxis/MeleeArea.position.x = $InteractRange/CollisionShape2D.shape.radius - $MeleeTurnAxis/MeleeArea/CollisionShape2D.shape.radius * 0.5
		$MeleeTurnAxis/MeleeArea.position.x = max(abs(($MeleeTurnAxis/MeleeArea.global_position - self.global_position).y * 0.6), abs(($MeleeTurnAxis/MeleeArea.global_position - self.global_position).x))
	else:
		self.animation_tree.set("parameters/Melee/blend_position", self.global_position.direction_to(target.global_position).normalized())
		self.animation_tree.set("parameters/Idle/blend_position", self.global_position.direction_to(target.global_position).normalized())
		$MeleeTurnAxis/MeleeArea.global_position = target.global_position
	MAX_SPEED = 0
	self.speed = 0
	self.animation_mode.travel("Melee")
	yield(self.get_tree().create_timer(self.rate_of_fire), "timeout")
	self.can_strike = true
	self.state = STATE.Idle
	self.MAX_SPEED = 180

func _on_MeleeArea_body_entered(body):
	body.on_hit(self.damage("Physical"))

func use_skill(pressed_slot):
	self.animation_tree.set("parameters/Idle/blend_position", self.global_position.direction_to(self.get_global_mouse_position()).normalized())
	self.animation_tree.set("parameters/Casting/blend_position", self.global_position.direction_to(self.get_global_mouse_position()).normalized())
	self.state = STATE.Casting
	self.can_cast = false
	MAX_SPEED = 0
	self.speed = 0

	var angle = $TurnAxis.get_angle_to(self.get_global_mouse_position())
	$TurnAxis.rotate(angle)

	var skill
	var skill_instance

	match DataImport.skill_data[selected_skills[pressed_slot]].SkillType:
		"RangedSingleTargetSkill":
			skill = load("res://Scenes/Skills/RangedSingleTargetSkill.tscn")
			skill_instance = skill.instance()
			skill_instance.skill_name = selected_skills[pressed_slot]
			skill_instance.rotation = $Center.get_angle_to(get_global_mouse_position())
			skill_instance.position = $TurnAxis/CastPoint.global_position
			self.get_parent().add_child(skill_instance)
		"RangedAoESkill":
			skill = load("res://Scenes/Skills/RangedAoESkill.tscn")
			skill_instance = skill.instance()
			skill_instance.skill_name = selected_skills[pressed_slot]
			skill_instance.position = self.get_global_mouse_position()
			self.get_parent().add_child(skill_instance)
		"ExpandingAoESkill":
			skill = load("res://Scenes/Skills/ExpandingAoESkill.tscn")
			skill_instance = skill.instance()
			skill_instance.skill_name = selected_skills[pressed_slot]
			skill_instance.position = self.global_position
			self.get_parent().add_child(skill_instance)
		"SingleTargetHeal":
			skill = load("res://Scenes/Skills/SingleTargetHeal.tscn")
			skill_instance = skill.instance()
			skill_instance.skill_name = selected_skills[pressed_slot]
			self.add_child(skill_instance)

	# print($TurnAxis.get_angle_to(get_global_mouse_position()))
	self.animation_mode.travel("Casting")
	yield(self.get_tree().create_timer(skill_instance.skill_cast_time), "timeout")
	self.can_cast = true
	self.MAX_SPEED = 180
	self.state = STATE.Idle
