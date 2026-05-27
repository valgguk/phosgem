extends Node

@export var oxigen_generator: OxigenGenerator


#THIS NODE IS FOR GLOBAL EVENTS LIKE DYING OR SHARED VARIABLES AND RESOURCES
#I WILL USE IT FOR A GAME OVER OVER OXYGEN FOR NOW

# Called when the node enters the scene tree for the first time.
func _ready():
	oxigen_generator.oxigen_empty.connect(_on_oxigen_empty)
	pass # Replace with function body.



func _on_oxigen_empty():
	get_tree().change_scene_to_file("res://autoloads/lobby.tscn")
