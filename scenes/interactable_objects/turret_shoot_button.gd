extends Area2D

@export var direction: int = 1
var player_inside := false
@export var turret_path: NodePath
@onready var label: Label = $Label
@export var turret_id: int = 0
var last_state: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.text = str(turret_id)
func _process(_delta: float) -> void:
	if not player_inside:
		return
	var shooting := Input.is_action_pressed("area_interact")
	if shooting != last_state:
		last_state = shooting
		if multiplayer.is_server():
			_get_main().turret_set_shooting(turret_path, shooting)
		else:
			_get_main().turret_set_shooting.rpc_id(1, turret_path, shooting)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		player_inside = false
		if multiplayer.is_server():
			_get_main().turret_set_shooting(turret_path, false)
		else:
			_get_main().turret_set_shooting.rpc_id(1, turret_path, false)

func _get_main() -> Node:
	return get_tree().get_root().get_node("Main")
