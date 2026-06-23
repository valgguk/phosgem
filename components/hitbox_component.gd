class_name HitboxComponent
extends Area2D

signal damage_dealt(body: CharacterBody2D)
@export var owner_body: CharacterBody2D
@export var damage : int = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if owner_body == null:
		owner_body = get_parent() as CharacterBody2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
