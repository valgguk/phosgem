extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@export var default_color: int = 0
@onready var label: Label = $Label
# @onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var input_synchronizer: InputSynchronizer = $InputSynchronizer
@onready var sync_timer: Timer = $SyncTimer
@onready var interact_area = $InteractArea

var role: Statics.Role
var role_name: String 
var ship_velocity: Vector2 = Vector2.ZERO

@onready var health_component: HealthComponent = $HurtboxComponent/HealthComponent

var _data: Statics.PlayerData

const SPEED = 500.0
const JUMP_VELOCITY = -900.0 
const Gravity_factor=2 #1 is like a super jump

@export var walking = false
var stunned = false
var jump_damage = false
var stomped := false
var bounce_velocity := Vector2.ZERO
var bounce_timer := 0.0
var active_role_special: Statics.Role

func _ready() -> void:
	add_to_group("players_instances")
	add_to_group("affected_by_ship")
	#sync_timer.timeout.connect(_on_sync_timeout)
	animated_sprite.frame= default_color
	health_component.health_changed.connect(_on_health_changed)


func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	if bounce_timer > 0:
		bounce_timer -= delta
		velocity = bounce_velocity
		move_and_slide()
		return
	
	if stunned:
		return
	
	var g = get_gravity()
	if g.length() == 0:
		g = Vector2.DOWN * 980
	var vertical_direction = g.normalized()
	
	var horizontal_direction = vertical_direction.rotated(-PI/2)
	var move_input = input_synchronizer.move_input
	
	#var vertical_velocity = Vector2.ZERO
	var vertical_velocity = vertical_direction * velocity.dot(vertical_direction)
	
	var horizontal_speed = velocity.dot(horizontal_direction)
	if move_input:
		horizontal_speed = move_input * SPEED
	else:
		horizontal_speed = move_toward(horizontal_speed, 0, SPEED * delta * 5)
	#var horizontal_velocity = horizontal_direction * horizontal_speed
	var horizontal_velocity = horizontal_direction * horizontal_speed
	
	if not is_on_floor():
		vertical_velocity += g * delta * Gravity_factor
	elif input_synchronizer.jump:
		vertical_velocity = vertical_direction * JUMP_VELOCITY
		jump_damage = true
		stomped = false
		notify_jump.rpc()
		input_synchronizer.jump = false
		
	if input_synchronizer.special:
		#Debug.log("EFECTO ESPECIAL")
		special_move()
		input_synchronizer.special= false
	
	velocity = horizontal_velocity + vertical_velocity
	if move_input:
		change_sprite_direction(move_input)
		manage_animations(move_input)
	
	# cambiar si se rota demasiado, para que el player detecte bien lo que es suelo
	up_direction = -vertical_direction 
	move_and_slide()
	var collision = get_last_slide_collision()
	if collision:
		var collider = collision.get_collider()
		if collider is CharacterBody2D:
			# evita que se empujen horizontalmente infinito
			velocity = velocity.slide(collision.get_normal())
	# rpc manual de movimiento o multiplayer_synchronizer
	# con position tirita -> ver como mandar la position de los players
	send_position.rpc(position) 
	sync_vertical_velocity.rpc(velocity)
	if Input.is_action_just_pressed("test") and is_multiplayer_authority():
		test.rpc()
	if Input.is_action_just_pressed("area_interact"):
		_check_interact()
	if is_on_floor():
		jump_damage = false	
		
	
func _check_interact() -> void:
	for area in interact_area.get_overlapping_areas():
		if area is Area2D and area.has_method("area_interact"):
			area.area_interact()

#for the direction of the sprite, probably a simpler way to do this exists
func change_sprite_direction(direction:int)-> void:
	if direction <0:
		animated_sprite.flip_h= true
	elif direction >0:
		animated_sprite.flip_h=false
	else: return

func special_move():
	match active_role_special:
		0: Debug.log("no power")
		1: Debug.log("red power")
		2: Debug.log("blue power")


func manage_animations(direction):
	if direction:  #and is_on_floor():
		walking_wobble.rpc(direction)
	else: return
	
#walking animation with tweens
@rpc("authority", "call_local", "reliable")
func walking_wobble(direction):
	#Debug.log("testing2")
	if walking:
		return
	walking =true
	var tween = get_tree().create_tween()
	
	tween.tween_property(animated_sprite,"rotation",-direction*0.2,0.05)
	tween.tween_property(animated_sprite,"rotation",-direction*-0.2,0.1)
	tween.tween_property(animated_sprite,"rotation",0,0.05)
	await tween.finished 
	walking=false
	
	
func setup(data: Statics.PlayerData) -> void:
	_data = data
	name = str(data.id)
	label.text = data.name
	role= data.role
	define_role(role)
	
	set_multiplayer_authority(data.id, false)
	input_synchronizer.set_multiplayer_authority(data.id, false)
	if is_multiplayer_authority():
		sync_timer.start()
	
	
func define_role(Role: Statics.Role):
	role_name = Statics.get_role_name(role)
	animated_sprite.frame= clampi(role-1,0,Statics.Role.size())
	match Role:
		Statics.Role.NONE:
			active_role_special= Statics.Role.NONE
			return "None"
		Statics.Role.ROLE_A:
			active_role_special= Statics.Role.ROLE_A
			return "Redie"
		Statics.Role.ROLE_B:
			active_role_special= Statics.Role.ROLE_B
			return ""
			
			
	return "Unknown"

	
# defecto : ("authority", "call_remote", "reliable")
@rpc("authority", "call_local", "reliable")
func test() -> void:
	Debug.log("test %s" % _data.name)
	Debug.log("role: %s " % role_name)
	



@rpc("authority", "call_remote", "unreliable_ordered")
func send_position(pos: Vector2) -> void:
	if is_multiplayer_authority():
		return
	position = position.lerp(pos, 0.2)

func _on_sync_timeout() -> void:
	if is_multiplayer_authority():
		send_position.rpc(position)
	
	
#func take_damage(damage: int) -> void:
	#Debug.log("Stun: %d, , alien->player" % damage)
	

func _on_health_changed(value: int) -> void:
	Debug.log("Stun %d" % value)

@rpc("any_peer", "call_local", "reliable")
func apply_stun():
	if stunned:
		return
	
	stunned = true
	velocity = Vector2.ZERO
	
	# visual
	animated_sprite.modulate = Color(2,2,2)
	
	var tween = get_tree().create_tween()
	tween.set_loops()
	tween.tween_property(animated_sprite, "rotation", 0.3, 0.1)
	tween.tween_property(animated_sprite, "rotation", -0.3, 0.1)
	
	await get_tree().create_timer(3).timeout
	
	tween.kill()
	animated_sprite.rotation = 0
	animated_sprite.modulate = Color(1,1,1)
	stunned = false
	
@rpc("authority", "call_remote", "reliable")
func notify_jump():
	jump_damage = true
	
@rpc("authority", "call_remote", "unreliable")
func sync_vertical_velocity(v: Vector2):
	if bounce_timer > 0:
		return
	velocity = v
	
@rpc("any_peer", "call_local", "reliable")
func apply_bounce(v: Vector2):
	print("BOUNCE RECIBIDO:", v)
	bounce_velocity = v
	bounce_timer = 0.3  # duración del rebote 0.15
