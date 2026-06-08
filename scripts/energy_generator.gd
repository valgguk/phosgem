extends Area2D


var player_inside := false
var player_running := false
@export var energy: int
@export var energy_generation_per_second: int
@export var energy_lost_per_second: int
@export var MAX_ENERGY = 100

	
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if not player_inside:
		return
		
	
	
	#if Input.is_action_just_pressed("area_interact"):
		#player_running = player_inside
		

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		player_inside = false

func _get_main() -> Node:
	return get_tree().get_root().get_node("Main")


func change_energy(amount: int):
	energy = clampi(energy+amount,0,MAX_ENERGY)
	

func _on_timer_timeout():
	if not player_inside:
		change_energy(-energy_lost_per_second)
		return
	change_energy(energy_generation_per_second)
