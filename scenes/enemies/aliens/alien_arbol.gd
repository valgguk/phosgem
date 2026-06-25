extends CharacterBody2D

@onready var health_component: HealthComponent = $Pivote/HurtboxComponent/HealthComponent
@onready var pivote: Node2D = $Pivote
@onready var hitbox_component: HitboxComponent = $Pivote/HitboxComponent
@onready var sync_timer: Timer = $SyncTimer
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var ray_cast_2d: RayCast2D = $Pivote/RayCast2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]

const SPEED = 200.0
const JUMP_VELOCITY = -900.0 
const GRAVITY_FACTOR = 2 #1 is like a super jump

var move_direction := 1.0 
var ship_velocity: Vector2 = Vector2.ZERO

# tipo : sigue a un player 
var target: Node2D = null
var already_hit := {}
var hit_cooldown := 1.0

#var players: Array = []
#var current_target_index := 0
enum State { CHASE, COOLDOWN }
var state: State = State.CHASE

var target_refresh_time := 0.4
var target_timer := 0.0
var target_switch_threshold := 40.0 # distancia mínima para cambiar target

var aggro_target: Node2D = null
var aggro_time := 2.0
var aggro_timer := 0.0

func _ready() -> void:
	add_to_group("aliens_instances")
	add_to_group("affected_by_ship")
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	hitbox_component.damage_dealt.connect(_on_damage_dealt)
	#sync_timer.timeout.connect(_on_sync_timeout)
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	_update_target()
	multiplayer.peer_connected.connect(_on_peer_changed)
	multiplayer.peer_disconnected.connect(_on_peer_changed)
	animation_tree.active = true
	playback.travel("idle")

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority(): # clientes no ejecutan physics_process
		
		var g = get_gravity()
		if g.length() == 0:
			g = Vector2.DOWN * 980
		var vertical_direction = g.normalized()
		var horizontal_direction = vertical_direction.rotated(-PI/2)
		
		aggro_timer -= delta
		if aggro_target and aggro_timer > 0:
			target = aggro_target
		else:
			_update_target()
		
		target_timer -= delta
		if target_timer <= 0:
			_update_target()
			target_timer = target_refresh_time
			
		match state:
			State.CHASE:
				_move_to_target()
			State.COOLDOWN:
				_move_away()
		
		var move_dir = move_direction
		
		#var horizontal_speed = velocity.dot(horizontal_direction) !!
		#horizontal_speed = move_dir * SPEED !!
		# var horizontal_velocity = horizontal_direction * horizontal_speed
		var horizontal_velocity = horizontal_direction * (move_dir * SPEED)
		
		var vertical_velocity = velocity.project(vertical_direction)
		
		if not is_on_floor():
			vertical_velocity += g * delta * GRAVITY_FACTOR
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
		if move_dir != move_direction:
			sync_direction.rpc(move_direction)
	# ESTO corre en TODOS (server + clientes)
	if move_direction != 0:
		pivote.scale.x = sign(move_direction)
	
	
func take_damage(damage: int) -> void:
	Debug.log("Mario hit %d" % damage)
	

func _on_health_changed(value: int) -> void:
	take_damage(value)
	
func _on_damage_dealt(body_target: CharacterBody2D):
	if not is_multiplayer_authority():
		return
	if not body_target:
		return
	if body_target == self:
		return	
		
	aggro_target = body_target
	aggro_timer = aggro_time
		
	#var id = body_target.get_multiplayer_authority()
	var id = body_target.get_instance_id()
	
	# aplicar stun desde server
	if id in already_hit:
		return
	
	already_hit[id] = true
	
	body_target.apply_stun.rpc()
	
	if state != State.CHASE:
		return
	state = State.COOLDOWN
	var g = get_gravity()
	if g.length() == 0:
		g = Vector2.DOWN * 980
	g = g.normalized()
	var horizontal = g.rotated(-PI/2)
	velocity = -velocity.project(horizontal)
	cooldown_timer.start()
	
# usar nuevamente
func _find_closest_player(exclude: Node2D = null) -> Node2D:
	var players = get_tree().get_nodes_in_group("players_instances")
	# print("players encontrados:", players)
	var closest: Node2D = null
	var min_dist := INF
	
	for p in players:
		if p == exclude:
			continue
		if not is_instance_valid(p):
			continue
		var dist = global_position.distance_to(p.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = p
	
	return closest
	
func _should_jump() -> bool:
	if not target:
		return false
		
	# dirección al target
	var to_target = target.global_position - global_position
	var g = get_gravity()
	if g.length() == 0:
		g = Vector2.DOWN * 980
	g = g.normalized()
	var horizontal = g.rotated(-PI/2)
	var vertical = g
	
	var horizontal_dist = to_target.dot(horizontal)
	var vertical_dist = to_target.dot(vertical)
	
	# 1. obstáculo enfrente
	var obstacle_ahead = ray_cast_2d.is_colliding()
	
	# 2. target está arriba
	var target_above = vertical_dist < -40
	
	# 3. target está lejos horizontalmente
	var far = abs(horizontal_dist) > 30
	
	# salto inteligente
	return obstacle_ahead or (target_above and far)
	

@rpc("authority", "call_remote", "unreliable_ordered")
func send_position(pos: Vector2):
	if is_multiplayer_authority():
		return
	position = position.lerp(pos, 0.2)
	
func _on_sync_timeout() -> void:
	if is_multiplayer_authority():
		send_position.rpc(position)
		
func _on_cooldown_timeout():
	already_hit.clear()
	state = State.CHASE

@rpc("authority", "call_remote", "unreliable_ordered")
func sync_direction(dir: float):
	move_direction = dir
	
#func _next_target():
	#if players.size() == 0:
		#target = null
		#return
		#
	#already_hit.clear()
	#
	#current_target_index = (current_target_index + 1) % players.size()
	#target = players[current_target_index]
	#sync_target.rpc(current_target_index)
	
func _move_to_target():
	if not target:
		return
		
	if not is_instance_valid(target):
		target = null
		return
	
	var dir = target.global_position - global_position
	
	var horizontal = get_gravity().normalized().rotated(-PI/2)
	var d = dir.dot(horizontal)
	
	var deadzone := 10
	if abs(d) > deadzone:
		move_direction = sign(d)
	#if abs(dir.x) < 10:
		#return # no cambies dirección
	
func _move_away():
	if not target:
		return
	
	var dir = global_position - target.global_position
	var horizontal = get_gravity().normalized().rotated(-PI/2)
	var d = dir.dot(horizontal)
	if abs(d) > 5:
		move_direction = sign(d)
	
#@rpc("authority", "call_remote", "reliable")
#func sync_target(index: int):
	#current_target_index = index
	#
	#if players.size() > index:
		#target = players[index]
		
#func _update_players():
	#await get_tree().process_frame
	#players = get_tree().get_nodes_in_group("players_instances")
	#players.sort_custom(func(a,b): return a.get_multiplayer_authority() < b.get_multiplayer_authority())
	#if players.size() > 0:
		#target = players[0]
		
func _on_peer_changed(_id):
	_update_target()
	#_update_players()
	
func _update_target():
	var new_target = _find_closest_player()

	if not new_target:
		target = null
		return
	
	if not target:
		target = new_target
		return
	
	var current_dist = global_position.distance_to(target.global_position)
	var new_dist = global_position.distance_to(new_target.global_position)
	
	# solo cambia si realmente es mejor
	if new_dist + target_switch_threshold < current_dist:
		target = new_target
		
func _on_died():
	if not is_multiplayer_authority():
		return
	die.rpc()
	
@rpc("authority", "call_local", "reliable")
func die():
	print("Alien murió")
	playback.travel("die")
	await get_tree().create_timer(1).timeout
	call_deferred("queue_free")
