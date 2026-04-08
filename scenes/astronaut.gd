extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var label: Label = $Label

var _data: Statics.PlayerData

const SPEED = 400.0
const JUMP_VELOCITY = -900.0
const Gravity_factor = 2 #Aumenta la gravedad en este factor (x2 etc)

var walking = false

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * Gravity_factor* delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		change_sprite_direction(direction)
		manage_animations(direction)
	else:
		
		velocity.x = move_toward(velocity.x, 0, SPEED)
		

	move_and_slide()
	
	if Input.is_action_just_pressed("test"):
		test()


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
	
# defecto : ("authority", "call_remote", "reliable")
@rpc("authority", "call_remote", "reliable")
func test() -> void:
	Debug.log("test %s" % _data.name)
