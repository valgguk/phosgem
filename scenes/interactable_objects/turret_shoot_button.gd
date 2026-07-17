extends Area2D

@export var direction: int = 1
var player_inside := false
@export var turret_path: NodePath
@onready var label: Label = $Label
@export var turret_id: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.text = str(turret_id)
func _process(_delta: float) -> void:
	if not player_inside:
		return
	
	if Input.is_action_just_pressed("area_interact"):
		if multiplayer.is_server():
			_get_main().turret_shoot(turret_path)
		else:
			_get_main().turret_shoot.rpc_id(1, turret_path)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		player_inside = false

func _get_main() -> Node:
	return get_tree().get_root().get_node("Main")
