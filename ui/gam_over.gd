extends Control
class_name GameOverScreen
@onready var game_over_sound = $GameOverSound


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func play_game_over():
	game_over_sound.play(17.75)
	
	
