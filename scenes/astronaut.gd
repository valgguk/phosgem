extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@export var color: int = 0
@onready var label: Label = $Label
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var input_synchronizer: InputSynchronizer = $InputSynchronizer
@onready var sync_timer: Timer = $SyncTimer


var _data: Statics.PlayerData

const SPEED = 400.0
const JUMP_VELOCITY = -900.0
const Gravity_factor = 2 #Aumenta la gravedad en este factor (x2 etc)

var walking = false

func _ready() -> void:
	sync_timer.timeout.connect(_on_sync_timeout)
	animated_sprite.frame= color


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * Gravity_factor* delta

	# Handle jump.
	if input_synchronizer.jump and is_on_floor():
		velocity.y = JUMP_VELOCITY
		input_synchronizer.jump = false

	# Get the input direction and handle the movement/deceleration.
	var direction = input_synchronizer.move_input
	if direction:
		velocity.x = direction * SPEED
		change_sprite_direction(direction)
		manage_animations(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		

	move_and_slide()
	
	# rpc manual de movimiento -> mejor multiplayer_synchronizer
	#send_position.rpc(global_position)
	
	if Input.is_action_just_pressed("test") and is_multiplayer_authority():
		test.rpc()


#for the direction of the sprite, probably a simpler way to do this exists
func change_sprite_direction(direction:int)-> void:
	if direction <0:
		animated_sprite.flip_h= true
	elif direction >0:
		animated_sprite.flip_h=false
	else: return


#for animation of the character
func manage_animations(direction):
	if direction and is_on_floor():
		walking_wobble(direction)
	else: return
	
#walking animation with tweens
func walking_wobble(direction):
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
	multiplayer_synchronizer.set_multiplayer_authority(data.id, false)
	input_synchronizer.set_multiplayer_authority(data.id, false)
	if is_multiplayer_authority():
		sync_timer.start()
		
	
# defecto : ("authority", "call_remote", "reliable")
@rpc("authority", "call_local", "reliable")
func test() -> void:
	Debug.log("test %s" % _data.name)

@rpc("authority", "call_remote", "unreliable_ordered")
func send_position(pos: Vector2) -> void:
	global_position = lerp(global_position, pos, 0.5)

func _on_sync_timeout() -> void:
	send_position.rpc(global_position)
	
	
