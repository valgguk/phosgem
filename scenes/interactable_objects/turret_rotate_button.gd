extends Area2D

@export var sprite_reversed: bool
@export var direction: int = 1
var player_inside := false
@export var turret_path: NodePath
@export var rotate_visual := true
@export var visual_speed := 5.0
var last_dir := 999
var visual_dir := 0

func _ready() -> void:
	if sprite_reversed: $Sprite2D.frame= 0
	set_multiplayer_authority(1)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_inside:
		var dir := 0
		
		if Input.is_action_pressed("area_interact"):
			dir = direction
		if dir != last_dir:
			last_dir = dir
			if multiplayer.is_server():
				_apply_input(dir)
			else:
				rpc_id(1, "_send_button_dir", dir)
			
			if multiplayer.is_server():
				_get_main().turret_rotate(turret_path, dir)
			else:
				_get_main().turret_rotate.rpc_id(1, turret_path, dir)
			
	# ANIMACIÓN LOCAL (TODOS)
	if rotate_visual and visual_dir != 0:
		rotation += visual_dir * visual_speed * _delta

# RPC → SERVER
@rpc("any_peer", "reliable")
func _send_button_dir(dir: int):
	if not is_multiplayer_authority():
		return
	_apply_input(dir)
	
# SERVER aplica y sincroniza
func _apply_input(dir: int):
	visual_dir = dir
	_sync_visual_dir.rpc(dir)


# TODOS reciben estado
@rpc("authority", "reliable")
func _sync_visual_dir(dir: int):
	if is_multiplayer_authority():
		return
	visual_dir = dir

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		player_inside = false
		if multiplayer.is_server():
			_apply_input(0)
			_get_main().turret_rotate(turret_path, 0)
		else:
			rpc_id(1, "_send_button_dir", 0)
			_get_main().turret_rotate.rpc_id(1, turret_path, 0)

func _get_main() -> Node:
	return get_tree().get_root().get_node("Main")
