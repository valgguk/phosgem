extends Area2D
class_name OxigenGenerator

@onready var timer: Timer = $Timer
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var lever: Sprite2D = $lever

@export var OXIGEN_MAX: int = 120*3
@export var difficulty: int= 1 #how fast oxygen gets consumed
@export var oxigen_per_pump = 2


var _Oxigen_level: int
var polarity = -1 # postion of the lever

signal game_over


#ALWAYS USE THIS FUNCTIONS TO CHANGE OXIGEN OR IT WILL DESYNC
func increaseOxigen(amount: int):
	_Oxigen_level = clamp(_Oxigen_level+amount, 0 ,OXIGEN_MAX)
	update_oxigen_sync.rpc(_Oxigen_level)
func decreaseOxigen(amount: int):
	increaseOxigen(-amount)

var player_inside:bool = false

func _ready() -> void:
	progress_bar.max_value = OXIGEN_MAX
	
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	timer.timeout.connect(_on_timer_timeout)
	_Oxigen_level = OXIGEN_MAX
	timer.start()


func _process(_delta: float) -> void:
	if _Oxigen_level <= 0:
		game_over.emit()
		return
		
	progress_bar.value = _Oxigen_level
	
	if not player_inside:
		return
	
	if Input.is_action_just_pressed("area_interact"):
		move_lever.rpc()
		increaseOxigen(oxigen_per_pump)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D and body.is_multiplayer_authority():
		player_inside = false
		
		
func _on_timer_timeout():
	if is_multiplayer_authority():
		decreaseOxigen(difficulty*2)

@rpc("any_peer","call_remote",)
func update_oxigen_sync(new_level):
	_Oxigen_level = new_level

@rpc("any_peer", "call_local", "reliable")
func move_lever():
	var tween = get_tree().create_tween()
	tween.tween_property(lever,"position:y",7* polarity,0.1).as_relative()
	polarity *= -1
