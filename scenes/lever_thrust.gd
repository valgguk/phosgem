extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
var _direction: int = 1
var _state: int = 0
var _player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if not _player_inside:
		return
	if Input.is_action_just_pressed("area_interact"):
		if _state == 1 or _state == -1:
			_direction = -(_state)
			_set_state.rpc(0)
			
		elif _state == 0:
				_set_state.rpc(_direction)
			
			
@rpc("any_peer","call_local","reliable")
func _set_state(new_state: int) -> void:
	_state = new_state
	get_tree().get_root().get_node("Main").input_thrust(_state)
	_animate()

func _animate() -> void:
	var tween = get_tree().create_tween()
	if _state == 1:
		tween.tween_property(sprite, "rotation_degrees", -20.0, 0.15)
	elif _state == -1:
		tween.tween_property(sprite, "rotation_degrees", 20.0, 0.15)
	else:
		tween.tween_property(sprite, "rotation_degrees", 0.0, 0.15)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		_player_inside = true

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		_player_inside = false
		
func area_interact() -> void:
	pass
