extends Area2D

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var timer: Timer = $Timer

@export var MAX_ENERGY: int = 100
@export var energy_lost_per_second: int = 2
@export var energy_generation_per_second: int = 5
@export var walk_velocity: float = 490.0

var energy: int
var player_inside := false

func _ready() -> void:
	energy = MAX_ENERGY
	progress_bar.max_value = MAX_ENERGY
	progress_bar.value = energy

	static_body.constant_linear_velocity.x = -walk_velocity

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout() -> void:
	if player_inside:
		energy = clampi(energy + energy_generation_per_second, 0, MAX_ENERGY)
	else:
		energy = clampi(energy - energy_lost_per_second, 0, MAX_ENERGY)

	progress_bar.value = energy

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		player_inside = false
