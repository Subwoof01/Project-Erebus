
class_name CharacterStat

var base_value: float 
var last_base_value = -1.0
var stat_modifiers: Array
var is_dirty = true
var _value: float
var value setget , value_get

func _init(base_val):
	self.base_value = base_val
	self.stat_modifiers = []

func value_get():
	if self.is_dirty or self.base_value != self.last_base_value:
		self.last_base_value = self.base_value
		self.is_dirty = false
		self._value = calculate_final_value()
	return _value

func add_modifier(mod):
	# print(str(typeof(mod)))
	self.is_dirty = true
	self.stat_modifiers.append(mod)
	self.stat_modifiers.sort_custom(self, "compare_mod_order")

func compare_mod_order(a, b):
	if a.order < b.order:
		return true
	return false

func remove_modifier(mod):
	self.is_dirty = true
	self.stat_modifiers.remove(self.stat_modifiers.find(mod))

func remove_all_modifiers_from_source(source):
	var did_remove = false
	for i in range(self.stat_modifiers.size() - 1, -1, -1):
		if self.stat_modifiers[i].source == source:
			self.is_dirty = true
			did_remove = false
			self.stat_modifiers.remove(self.stat_modifiers.find(self.stat_modifiers[i]))
	return did_remove

func get_flat_bonus_value():
	var bonus = 0
	for i in len(self.stat_modifiers):
		if self.stat_modifiers[i].mod_type == StatModifier.STAT_MOD_TYPE.Flat:
			bonus += self.stat_modifiers[i].value
	return bonus

func get_percentual_bonus_value():
	var bonus = 0
	for i in len(self.stat_modifiers):
		if self.stat_modifiers[i].mod_type == StatModifier.STAT_MOD_TYPE.PercentAdd:
			bonus += self.stat_modifiers[i].value
		elif self.stat_modifiers[i].mod_type == StatModifier.STAT_MOD_TYPE.PercentMult:
			bonus += self.stat_modifiers[i].value
	return bonus

func calculate_final_value():
	var final_value = self.base_value
	var sumPercentAdd = 0

	for i in range(len(self.stat_modifiers)):
		# print(self.stat_modifiers[i])
		if self.stat_modifiers[i].mod_type == StatModifier.STAT_MOD_TYPE.Flat:
			final_value += self.stat_modifiers[i].value
		elif self.stat_modifiers[i].mod_type == StatModifier.STAT_MOD_TYPE.PercentAdd:
			sumPercentAdd += self.stat_modifiers[i].value

			if i + 1 >= len(self.stat_modifiers) or self.stat_modifiers[i + 1].mod_type != StatModifier.STAT_MOD_TYPE.PercentAdd:
				final_value *= 1 + sumPercentAdd
				sumPercentAdd = 0
		elif self.stat_modifiers[i].mod_type == StatModifier.STAT_MOD_TYPE.PercentMult:
			final_value *= 1 + self.stat_modifiers[i].value

	return float(stepify(final_value, 0.01))
