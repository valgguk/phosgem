extends CharacterBody2D

@onready var health_component: HealthComponent = $Pivote/HurtboxComponent/HealthComponent
@onready var pivote: Node2D = $Pivote
@onready var hitbox_component: HitboxComponent = $Pivote/HitboxComponent

@onready var ray_cast_2d: RayCast2D = $Pivote/RayCast2D

const SPEED = 200.0
const JUMP_VELOCITY = -900.0 
const Gravity_factor = 2 #1 is like a super jump

var move_direction := 1.0 # <- (-1)  (+1) ->
var hit_cooldown := false
var ignore_target: Node2D = null
var ship_velocity: Vector2 = Vector2.ZERO


# tipo : sigue a un player 
var target: Node2D = null

var already_hit := {}

func _ready() -> void:
	add_to_group("aliens_instances")
	add_to_group("affected_by_ship")
	health_component.health_changed.connect(_on_health_changed)
	hitbox_component.damage_dealt.connect(_on_damage_dealt)
	# sync_timer.timeout.connect(_on_sync_timeout)

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority(): # clientes no ejecutan physics_process
		
		var g = get_gravity()
		if g.length() == 0:
			g = Vector2.DOWN * 980
		var vertical_direction = g.normalized()
		
		var horizontal_direction = vertical_direction.rotated(-PI/2)
		var move_dir = _get_move_direction()
		
		#var horizontal_speed = velocity.dot(horizontal_direction) !!
		#horizontal_speed = move_dir * SPEED !!
		# var horizontal_velocity = horizontal_direction * horizontal_speed
		var horizontal_velocity = horizontal_direction * (move_dir * SPEED)
		
		var vertical_velocity = vertical_direction * velocity.dot(vertical_direction)
		
		if not is_on_floor():
			vertical_velocity += g * delta * Gravity_factor
		elif _should_jump():
			move_direction *= -1
			vertical_velocity = vertical_direction * JUMP_VELOCITY

		velocity  = horizontal_velocity + vertical_velocity
		up_direction = -vertical_direction
		
		# var angle = vertical_direction.angle() + PI/2
		# pivote.rotation = angle
		
		move_and_slide()
		var collision = get_last_slide_collision()
		if collision:
			var collider = collision.get_collider()
			if collider is CharacterBody2D:
				# evita que se empujen horizontalmente infinito
				velocity = velocity.slide(collision.get_normal())
		send_position.rpc(position)
		sync_direction.rpc(move_dir)
	# ESTO corre en TODOS (server + clientes)
	if move_direction != 0:
		pivote.scale.x = sign(move_direction)
	
	
func take_damage(damage: int) -> void:
	Debug.log("Mario damage: %d, player->alien" % damage)
	

func _on_health_changed(value: int) -> void:
	take_damage(value)
	
func _on_damage_dealt():
	if not is_multiplayer_authority():
		return
		
	if hit_cooldown:
		return
	hit_cooldown = true
	
	# soltar target actual
	ignore_target = target
	target = _find_closest_player(ignore_target)
	velocity *= -1
	
	# pequeño "cooldown" para no reengancharse
	await get_tree().create_timer(0.5).timeout
	hit_cooldown = false

	
func _get_move_direction() -> float:
	if _should_jump():
		return move_direction
		
	# CLAVE: no cambiar target durante cooldown
	if not hit_cooldown:
		target = _find_closest_player()
	
	if not target:
		return move_direction
	
	var vertical_direction = get_gravity().normalized()
	var horizontal_direction = vertical_direction.rotated(-PI/2)
	
	var to_target = target.global_position - global_position
	var dot = to_target.dot(horizontal_direction)
	
	if abs(dot) < 10:
		return move_direction  # ← mantiene dirección anterior
	
	if abs(dot) > 10:
		move_direction = sign(dot) # <-- actualiza dirección 
	return move_direction
	
func _find_closest_player(exclude: Node2D = null) -> Node2D:
	var players = get_tree().get_nodes_in_group("players_instances")
	# print("players encontrados:", players)
	var closest = null
	var min_dist = INF
	
	for p in players:
		if p == exclude:
			continue
		var dist = global_position.distance_to(p.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = p
	
	return closest
	
func _should_jump() -> bool:
	if not ray_cast_2d.is_colliding():
		return false
	
	var collider = ray_cast_2d.get_collider()
	
	# ignorar players
	# subir en el árbol hasta encontrar un nodo válido
	while collider:
		if collider.is_in_group("players_instances"):
			return false
		collider = collider.get_parent()
	
	return true
	

@rpc("authority", "call_remote", "unreliable_ordered")
func send_position(pos: Vector2):
	if is_multiplayer_authority():
		return
	position = position.lerp(pos, 0.2)
	
func _on_sync_timeout() -> void:
	if is_multiplayer_authority():
		send_position.rpc(position)

@rpc("authority", "call_remote", "unreliable")
func sync_direction(dir: float):
	move_direction = dir
	
