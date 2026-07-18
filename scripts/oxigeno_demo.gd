extends Area2D

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var lever: Sprite2D = $lever
@onready var timer: Timer = $Timer

@export var OXIGEN_MAX: int = 120 * 3
@export var oxigen_per_pump: int = 20
@export var difficulty: int = 1

var _oxigen_level: int
var polarity = -1
var player_inside: bool = false

func _ready() -> void:
	progress_bar.max_value = OXIGEN_MAX
	_oxigen_level = OXIGEN_MAX
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _process(_delta: float) -> void:
	progress_bar.value = _oxigen_level

func area_interact() -> void:
	_oxigen_level = clamp(_oxigen_level + oxigen_per_pump, 0, OXIGEN_MAX)
	var tween = get_tree().create_tween()
	tween.tween_property(lever, "position:y", 7 * polarity, 0.1).as_relative()
	polarity *= -1

func _on_timer_timeout() -> void:
	_oxigen_level = clamp(_oxigen_level - difficulty * 2, 0, OXIGEN_MAX)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		player_inside = false
