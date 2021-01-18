extends Position2D

onready var label = $Label
onready var tween = $Tween
var amount = 0

var velocity = Vector2(0, 0)
var move_amount = 80
var max_size = Vector2(1, 1)
var is_crit = false

func _ready():
	self.label.text = (str(round(amount)))
	if self.is_crit:
		max_size = Vector2(1.5, 1.5)
		label.set("custom_colors/font_color", Color("fcfb01"))

	randomize()
	var side_movement = randi() % (self.move_amount + 1) - (self.move_amount * 0.5)
	self.velocity = Vector2(side_movement, 80)
	self.tween.interpolate_property(self, "scale", self.scale, max_size, 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	self.tween.interpolate_property(self, "scale", max_size, Vector2(0.1, 0.1), 0.7, Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.3)
	self.tween.start()

func _on_Tween_tween_all_completed():
	self.queue_free()

func _process(delta):
	self.position -= velocity * delta