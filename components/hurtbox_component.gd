class_name HurtboxComponent
extends Area2D

@export var health_component: HealthComponent
@export var owner_body: CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(_on_area_entered)
	
	if owner_body == null:
		owner_body = get_parent() as CharacterBody2D
	
	
func _on_area_entered(area: Area2D) -> void:
	var hitbox: HitboxComponent = area as HitboxComponent
	if hitbox and health_component:
		health_component.take_damage(hitbox.damage)
		hitbox.damage_dealt.emit(owner_body) # <-- avisamos que hicimos daño
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
