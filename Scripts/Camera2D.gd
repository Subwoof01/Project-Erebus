extends Camera2D

onready var player = get_parent().get_node("NavigationMap/YSort/Player")

func _process(delta):
	position = player.global_position