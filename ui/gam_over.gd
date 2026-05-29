extends Control
class_name GameOverScreen

@onready var game_over_sound = $GameOverSound

func _ready() -> void:
	add_to_group("game_over_screen")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_game_over() -> void:
	visible = true
	game_over_sound.play(17.75)
	await get_tree().create_timer(7.0, true).timeout
	get_tree().change_scene_to_file("res://lobby/waiting_screen.tscn") # ver después
	
