extends Area2D

@export var direction: int = 1
var player_inside := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if not player_inside:
		return
	if Input.is_action_just_pressed("area_interact"):
		area_interact()

func area_interact() -> void:
	pass

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		player_inside = false
