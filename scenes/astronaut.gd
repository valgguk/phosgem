extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@export var color: int = 0
@onready var label: Label = $Label
# @onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var input_synchronizer: InputSynchronizer = $InputSynchronizer
@onready var sync_timer: Timer = $SyncTimer
@onready var interact_area = $InteractArea
var ship_velocity: Vector2 = Vector2.ZERO

@onready var health_component: HealthComponent = $HurtboxComponent/HealthComponent

var _data: Statics.PlayerData

const SPEED = 400.0
const JUMP_VELOCITY = -900.0 
const Gravity_factor=2 #1 is like a super jump

@export var walking = false

@export var stunned = false
var jump_damage = false

func _ready() -> void:
	add_to_group("players_instances")
	add_to_group("affected_by_ship")
	sync_timer.timeout.connect(_on_sync_timeout)
	animated_sprite.frame= color
	health_component.health_changed.connect(_on_health_changed)


func _physics_process(delta):
	if not is_multiplayer_authority():
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
		horizontal_speed = move_toward(horizontal_speed, 0, SPEED)
	#var horizontal_velocity = horizontal_direction * horizontal_speed
	var horizontal_velocity = horizontal_direction * horizontal_speed
	
	if not is_on_floor():
		vertical_velocity += g * delta * Gravity_factor
	elif input_synchronizer.jump:
		vertical_velocity = vertical_direction * JUMP_VELOCITY
		jump_damage = true
		input_synchronizer.jump = false
	
	velocity = horizontal_velocity + vertical_velocity + ship_velocity
	print("ship_velocity astronaut: ", ship_velocity)
	print("velocity final astronaut: ", velocity)
	if move_input:
		change_sprite_direction(move_input)
		manage_animations(move_input)
	
	# cambiar si se rota demasiado, para que el player detecte bien lo que es suelo
	up_direction = -vertical_direction 
	move_and_slide()
	# rpc manual de movimiento o multiplayer_synchronizer
	# con position tirita -> ver como mandar la position de los players
	send_position.rpc(position) 
	if Input.is_action_just_pressed("test") and is_multiplayer_authority():
		test.rpc()
	if Input.is_action_just_pressed("area_interact"):
		_check_interact()
		
	
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
	set_multiplayer_authority(data.id, false)
	input_synchronizer.set_multiplayer_authority(data.id, false)
	if is_multiplayer_authority():
		sync_timer.start()
		
	
# defecto : ("authority", "call_remote", "reliable")
@rpc("authority", "call_local", "reliable")
func test() -> void:
	Debug.log("test %s" % _data.name)

@rpc("authority", "call_remote", "unreliable_ordered")
func send_position(pos: Vector2) -> void:
	if is_multiplayer_authority() :
		return
	position = lerp(position, pos, 0.2)

func _on_sync_timeout() -> void:
	if is_multiplayer_authority():
		send_position.rpc(position)
	
func apply_ship_motion(vel: Vector2, delta: float) -> void:
	ship_velocity = vel
	
	
func take_damage(damage: int) -> void:
	Debug.log("Stun: %d, , alien->player" % damage)
	

func _on_health_changed(value: int) -> void:
	take_damage(value)
	
# verificar !!!
#func _on_hitbox_body_entered(body): #el hitbox_player (foot) tocan al alien
	#if not is_multiplayer_authority(): #el cliente no
		#return
	#
	#if body.is_in_group("aliens_instances"):
		#if jump_damage: # cambiar esto -> detecta que PLAYER esta saltando
			#body.die()
			#jump_damage = false
			
@rpc("authority")
func apply_stun():
	stunned = true
