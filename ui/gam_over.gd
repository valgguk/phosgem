extends Control
class_name GameOverScreen
@onready var game_over_sound = $GameOverSound


# Called when the node enters the scene tree for the first time.
func _ready()-> void:
	add_to_group("game_over_screen")


func play_game_over():
	game_over_sound.play(17.75)
	
	
