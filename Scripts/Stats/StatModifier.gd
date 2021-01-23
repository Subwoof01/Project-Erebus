class_name StatModifier

enum STAT_MOD_TYPE {
	Flat = 100,
	PercentAdd = 200,
	PercentMult = 300
}

var value: float
var mod_type
var order
var source

# this is some documentation
func _init(val, _type, _order=null, source=null):
	self.value = val
	self.mod_type = _type
	if order == null:
		self.order = int(_type)
	else:
		self.order = _order
	self.source = source
