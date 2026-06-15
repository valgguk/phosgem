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
		_get_main().input_rotation.rpc_id(1,direction)
	elif Input.is_action_just_released("area_interact"):
		_get_main().input_rotation.rpc_id(1,0)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		player_inside = false
		_get_main().input_rotation.rpc_id(1,0)

func _get_main() -> Node:
	return get_tree().get_root().get_node("Main")
