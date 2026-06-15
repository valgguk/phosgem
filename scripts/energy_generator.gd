extends Area2D
class_name EnergyGenerator
@onready var progress_bar = $ProgressBar
@onready var static_body = $StaticBody2D


var player_inside := false
var player_running := false
@export var energy: int
@export var energy_generation_per_second: int = 1
@export var energy_lost_per_second: int = 1
@export var MAX_ENERGY = 100
@export var energy_empty:bool = false
@export var min_energy_for_lights: int = 3
@export var walk_velocity = 490.0
signal trigger_ship_event
signal game_over
	
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	energy= MAX_ENERGY
	static_body.constant_linear_velocity.x= -walk_velocity

func _process(_delta: float) -> void:
	if energy<=0 and not energy_empty:
		energy_empty= true
		trigger_ship_event.emit()
		game_over.emit()
	if not player_inside:
		return
	
	#if Input.is_action_just_pressed("area_interact"):
		#player_running = player_inside
		

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		player_inside = false

func _get_main() -> Node:
	return get_tree().get_root().get_node("Main")


func change_energy(amount: int):
	energy = clampi(energy+amount,0,MAX_ENERGY)
	progress_bar.value =energy
	if energy>=min_energy_for_lights and energy_empty == true:
		energy_empty= false
		trigger_ship_event.emit()

	

func _on_timer_timeout():
	if not player_inside:

		change_energy(-energy_lost_per_second)
		return
	change_energy(energy_generation_per_second)
