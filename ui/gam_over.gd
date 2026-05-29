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
	get_tree().paused = true
	await get_tree().create_timer(3.0, true).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	
