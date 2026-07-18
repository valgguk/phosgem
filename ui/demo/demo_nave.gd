extends Node2D

@onready var players: Node2D = $Ship/Players
@onready var ship: Node2D = $Ship
@onready var gravity_zone: Area2D = $Ship/GravityZone

func _ready() -> void:
	gravity_zone.gravity_direction = ship.global_transform.y

func _physics_process(_delta: float) -> void:
	gravity_zone.gravity_direction = ship.global_transform.y

func input_thrust(_direction: int) -> void:
	pass

func input_rotation(_direction: int) -> void:
	pass
