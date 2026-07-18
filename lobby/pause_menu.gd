class_name PauseMenu
extends CanvasLayer

@onready var resume_button: Button = $Panel/VBoxContainer/Resume
@onready var menu_button: Button = $Panel/VBoxContainer/Menu
@onready var quit_button: Button = $Panel/VBoxContainer/Quit

var _paused: bool = false
var _local_player: Node = null

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	hide()

func _get_local_player() -> Node:
	if not is_inside_tree() or not get_tree():
		return null
	for player: Node in get_tree().get_nodes_in_group("players_instances"):
		if is_instance_valid(player) and player.is_multiplayer_authority():
			return player
	return null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		_set_paused(not _paused)

func _set_paused(value: bool) -> void:
	_paused = value
	visible = _paused
	if _paused:
		resume_button.grab_focus()
		# buscar jugador justo cuando se pausa
		_local_player = _get_local_player()
	if _local_player and is_instance_valid(_local_player):
		_local_player.set_process_input(not _paused)
		_local_player.set_physics_process(not _paused)
	if multiplayer and multiplayer.multiplayer_peer and is_inside_tree():
		_notify_paused.rpc(multiplayer.get_unique_id(), _paused)

func _on_resume_pressed() -> void:
	_set_paused(false)

func _on_menu_pressed() -> void:
	_paused = false
	if multiplayer and multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_quit_pressed() -> void:
	if multiplayer and multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	get_tree().quit()

@rpc("any_peer", "call_local", "reliable")
func _notify_paused(player_id: int, is_paused: bool) -> void:
	if not is_inside_tree() or not get_tree():
		return
	if player_id == multiplayer.get_unique_id():
		return
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("set_player_paused_indicator"):
		hud.set_player_paused_indicator(player_id, is_paused)
