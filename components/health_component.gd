class_name HealthComponent
extends Node

signal died
signal health_changed(value: int)
var dead := false

@export var health: int = 50:
	set(value):
		health = clamp(value, 0, max_health)
		health_changed.emit(health)
		if health == 0 and not dead:
			dead = true
			died.emit()
			
@export var max_health: int = 50

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func take_damage(damage: int) -> void:
	if dead:
		return
	health -= damage
