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
	# server : logica de daño
	var hitbox: HitboxComponent = area as HitboxComponent
	if not hitbox or not health_component:
		return
	var attacker = hitbox.owner_body
	if not attacker:
		return

	# ------
	if attacker.is_in_group("players_instances") and owner_body.is_in_group("aliens_instances"):
		if not owner_body.is_multiplayer_authority():
			return
			
		if attacker.jump_damage and not attacker.stomped:
			var g = attacker.get_gravity()
			if g.length() == 0:
				g = Vector2.DOWN * 980
			
			var vertical = g.normalized()
			var dir = owner_body.global_position - attacker.global_position
			var is_above = dir.dot(vertical) > 0
			
			if is_above:
				print("STOMP DETECTADO")
				health_component.take_damage(50)
				print("Alien HP:", health_component.health)
				attacker.apply_bounce.rpc(-vertical * 400) # REBOTE
				attacker.stomped = true
				attacker.jump_damage = false
				return
	# EVITA DAÑO EXTRA
	#if attacker.stomped:
		#return
	# ------
	if hitbox and health_component:
		health_component.take_damage(hitbox.damage)
		hitbox.damage_dealt.emit(owner_body) # <-- avisamos que hicimos daño
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
