extends Node

var stat_data

func _ready():
	var stat_data_file = File.new()
	stat_data_file.open("res://Data/CharacterStatData.json", File.READ)
	var stat_data_json = JSON.parse(stat_data_file.get_as_text())
	stat_data_file.close()
	stat_data = stat_data_json.result
