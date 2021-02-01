extends Panel


func _input(event):
	if !self.get_tree().paused:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		self.get_tree().paused = false
		self.get_tree().reload_current_scene()