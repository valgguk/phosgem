class_name Planet
extends Area2D

signal planet_reached

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("planet")
	area_entered.connect(_on_area_entered)
	animated_sprite.play("default")

func _on_area_entered(area: Area2D) -> void:
	if area.name == "asteroidColision":
		planet_reached.emit()
