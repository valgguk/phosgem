extends CharacterBody2D

@onready var health_component: HealthComponent = $HealthComponent

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _ready() -> void:
	health_component.health_changed.connect(_on_health_changed)

func _physics_process(delta: float) -> void:
	pass
	
	
func take_damage(damage: int) -> void:
	Debug.log("damage: %d" % damage)
	

func _on_health_changed(value: int) -> void:
	Debug.log(value)
