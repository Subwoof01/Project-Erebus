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
var level = 3
var total_exp = 0
var experience = 0
var next_level_exp = 1500
var stat_points = 100
var ability_essences = 3

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

var action_bar_skills = {"Skill1": "", "Skill2": "", "Skill3": "", "Skill4": ""}
var selected_skills = []
var learned_skills = {}

var things_in_interact_range = []

onready var game = get_node("/root/Game")
onready var nav_map = get_parent()
onready var animation = $Body
onready var head_animation = $Head

onready var health_orb = game.get_node("CanvasLayer/UI/HealthOrb/Health")
onready var health_tween = game.get_node("CanvasLayer/UI/HealthOrb/Health/Tween")
onready var health_text = game.get_node("CanvasLayer/UI/HealthOrb/HealthLabel")
onready var mana_orb = game.get_node("CanvasLayer/UI/ActionBarManaOverlay/Mana")
onready var mana_tween = game.get_node("CanvasLayer/UI/ActionBarManaOverlay/Mana/Tween")
onready var mana_text = game.get_node("CanvasLayer/UI/ActionBarManaOverlay/ManaLabel")
onready var exp_bar = game.get_node("CanvasLayer/UI/Experience/Bar")
onready var stat_screen = game.get_node("CanvasLayer/UI/StatScreen")

onready var rng = RandomNumberGenerator.new()

var skills = []
var time_since_last_tick = 0

func _ready():
	for stat in StatData.stat_data:
		self.stats[stat] = CharacterStat.new(StatData.stat_data[stat]["StatBaseValue"])
	
	
	var str_base = floor(self.stats["Strength"].value / 5)
	var health_bonus = floor(self.stats["Strength"].value / 2)
	var phys_bonus = str_base * 0.01
	var health_mod = StatModifier.new(health_bonus, StatModifier.STAT_MOD_TYPE.Flat, int(StatModifier.STAT_MOD_TYPE.Flat), "Strength")
	var phys_mod = StatModifier.new(phys_bonus, StatModifier.STAT_MOD_TYPE.PercentMult, int(StatModifier.STAT_MOD_TYPE.PercentMult), "Strength")
	self.stats["Health"].add_modifier(health_mod)
	self.stats["PhysicalDamage"].add_modifier(phys_mod)

	var dex_base = floor(self.stats["Dexterity"].value / 5)
	var armour_bonus = self.stats["Dexterity"].value * 2
	var chc_bonus = dex_base * 0.1
	var armour_mod = StatModifier.new(armour_bonus, StatModifier.STAT_MOD_TYPE.Flat, int(StatModifier.STAT_MOD_TYPE.Flat), "Dexterity")
	var chc_mod = StatModifier.new(chc_bonus, StatModifier.STAT_MOD_TYPE.PercentAdd, int(StatModifier.STAT_MOD_TYPE.PercentAdd), "Dexterity")
	self.stats["Armour"].add_modifier(armour_mod)
	self.stats["CriticalHitChance"].add_modifier(chc_mod)

	var int_base = floor(self.stats["Intelligence"].value / 5)
	var mana_bonus = floor(self.stats["Intelligence"].value / 2)
	var spell_bonus = int_base * 0.01
	var mana_mod = StatModifier.new(mana_bonus, StatModifier.STAT_MOD_TYPE.Flat, int(StatModifier.STAT_MOD_TYPE.Flat), "Intelligence")
	var spell_mod = StatModifier.new(spell_bonus, StatModifier.STAT_MOD_TYPE.PercentMult, int(StatModifier.STAT_MOD_TYPE.PercentMult), "Intelligence")
	self.stats["Mana"].add_modifier(mana_mod)
	self.stats["SpellDamage"].add_modifier(spell_mod)

	self.current_health = self.stats["Health"].value
	self.current_mana = self.stats["Mana"].value
	self.update_selected_skills()

	self.update_health_orb()
	self.update_mana_orb()

func update_selected_skills():
	self.selected_skills.clear()
	for skill in self.action_bar_skills:
		self.selected_skills.append(self.action_bar_skills[skill])

func _process(delta):
	self.time_since_last_tick += delta
	if self.time_since_last_tick >= 1:
		self.time_since_last_tick = 0
		self.per_second_effects_tick()
	
	if len(self.action_queue) > 0:
		self.lmb_pressed = false
		self.location = self.action_queue[2].global_position
		self.state = self.STATE.Walking
		return
	if self.lmb_pressed:
		if self.can_strike:
			var space_state = self.get_world_2d().direct_space_state
			var check = space_state.intersect_point(self.get_global_mouse_position(), 2, [self], 16)
			for body in check:
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
	self.things_in_interact_range.append(body)

func _on_InteractRange_body_exited(body):
	self.things_in_interact_range.remove(self.things_in_interact_range.find(body))

func queue_action(action, object, interact_checker):
	self.action_queue.append(action)
	self.action_queue.append(object)
	self.action_queue.append(interact_checker)

func restore_mana(amount):
	self.current_mana += amount
	if self.current_mana > self.stats["Mana"].value:
		self.current_mana = self.stats["Mana"].value
	self.update_mana_orb()

func per_second_effects_tick():
	self.on_heal(self.stats["HealthRegen"].value)
	self.restore_mana(self.stats["ManaRegen"].value)

func pickup(item):
	self.animation_tree.set("parameters/Idle/blend_position", self.global_position.direction_to(self.get_global_mouse_position()).normalized())
	var click_area = item.get_node("ClickArea")
	self.animation_mode.travel("Idle")
	if click_area in self.things_in_interact_range:
		self.speed = 0
		self.MAX_SPEED = 0
		ItemManager.pickup(item.item_data)
		yield(self.get_tree().create_timer(0.1), "timeout")
		self.animation_mode.travel("Idle")
		self.MAX_SPEED = 180
		self.state = STATE.Idle
	else:
		self.queue_action("pickup", item.item_data, click_area)

func execute_queued_action():
	match self.action_queue[0]:
		"pickup":
			ItemManager.pickup(self.action_queue[1])
			self.action_queue = []
		"strike":
			self.melee_strike(self.action_queue[1])
			self.action_queue = []

func get_crit_chance():
	var crit_chance = self.stats["CriticalHitChance"].value / 10000
	return crit_chance

func damage(type, can_crit=true, b=[0,0]):
	var base = b.duplicate()
	# Add more damage logic here. Crit chance, other dmg types etc.
	var is_crit = false
	if can_crit:
		self.rng.randomize()
		var crit_chance = self.rng.randf()
		if crit_chance <= self.get_crit_chance():
			is_crit = true
	
	self.rng.randomize()
	var damage
	for t in type:
		var d_type = t + "Damage"
		base[0] *= self.stats[d_type].value
		base[1] *= self.stats[d_type].value
	damage = self.rng.randf_range(base[0], base[1])

	if is_crit:
		damage *= self.stats["CriticalHitDamage"].value
	return {"damage": damage, "crit": is_crit, "minmax": [base[0], base[1]]}


func take_damage(damage):
	self.current_health -= damage;
	if self.current_health <= 0:
		self.current_health = 0
	self.update_health_orb()

func lose_mana(cost):
	self.current_mana -= cost
	# This should never be reached, but just in case.
	if self.current_mana <= 0:
		self.current_mana = self.stats["Mana"].value
	self.update_mana_orb()

func on_heal(heal):
	self.current_health += heal
	if self.current_health > self.stats["Health"].value:
		self.current_health = self.stats["Health"].value
	self.update_health_orb()

func update_health_orb():
	self.health_text.text = str(self.current_health) + "/" + str(self.stats["Health"].value)
	var percentage_hp = int((float(self.current_health) / self.stats["Health"].value) * 100)
	health_tween.interpolate_property(health_orb, 'value', health_orb.value, percentage_hp, 0.1, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	health_tween.start()

func update_mana_orb():
	self.mana_text.text = str(self.current_mana) + "/" + str(self.stats["Mana"].value)
	var percentage_mp = int((float(self.current_mana) / self.stats["Mana"].value) * 100)
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
	self.ability_essences += 1

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
	body.get_parent().on_hit(self.damage(["Physical"], true, [self.stats["PhysicalDamageMin"].value, self.stats["PhysicalDamageMax"].value]))

func use_skill(pressed_slot):
	if selected_skills[pressed_slot] == "":
		return
	
	var mana_cost = DataImport.skill_data[selected_skills[pressed_slot]].SkillManaCost
	if mana_cost > self.current_mana:
		return
	
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
			skill_instance.origin = "Player"
			var damage = self.damage(DataImport.skill_data[selected_skills[pressed_slot]].SkillTags, true, DataImport.skill_data[selected_skills[pressed_slot]].SkillDamage)
			skill_instance.damage = damage["damage"]
			skill_instance.damage_type = DataImport.skill_data[selected_skills[pressed_slot]].SkillTags
			skill_instance.crit = damage["crit"]
			self.get_parent().add_child(skill_instance)
		"RangedAoESkill":
			skill = load("res://Scenes/Skills/RangedAoESkill.tscn")
			skill_instance = skill.instance()
			skill_instance.skill_name = selected_skills[pressed_slot]
			skill_instance.position = self.get_global_mouse_position()
			skill_instance.origin = "Player"
			var damage = self.damage(DataImport.skill_data[selected_skills[pressed_slot]].SkillTags, true, DataImport.skill_data[selected_skills[pressed_slot]].SkillDamage)
			skill_instance.damage = damage["damage"]
			skill_instance.damage_type = DataImport.skill_data[selected_skills[pressed_slot]].SkillTags
			skill_instance.crit = damage["crit"]
			self.get_parent().add_child(skill_instance)
		"ExpandingAoESkill":
			skill = load("res://Scenes/Skills/ExpandingAoESkill.tscn")
			skill_instance = skill.instance()
			skill_instance.skill_name = selected_skills[pressed_slot]
			skill_instance.position = self.global_position
			skill_instance.origin = "Player"
			var damage = self.damage(DataImport.skill_data[selected_skills[pressed_slot]].SkillTags, true, DataImport.skill_data[selected_skills[pressed_slot]].SkillDamage)
			skill_instance.damage = damage["damage"]
			skill_instance.damage_type = DataImport.skill_data[selected_skills[pressed_slot]].SkillTags
			skill_instance.crit = damage["crit"]
			self.get_parent().add_child(skill_instance)
		"SingleTargetHeal":
			skill = load("res://Scenes/Skills/SingleTargetHeal.tscn")
			skill_instance = skill.instance()
			skill_instance.skill_name = selected_skills[pressed_slot]
			self.add_child(skill_instance)

	# print($TurnAxis.get_angle_to(get_global_mouse_position()))
	self.animation_mode.travel("Casting")
	self.lose_mana(mana_cost)
	yield(self.get_tree().create_timer(skill_instance.skill_cast_time), "timeout")
	self.can_cast = true
	self.MAX_SPEED = 180
	self.state = STATE.Idle
