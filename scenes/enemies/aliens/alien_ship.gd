extends CharacterBody2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
@onready var health_component: HealthComponent = $HurtboxComponent/HealthComponent

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _ready() -> void:
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	animation_tree.active = true
	playback.travel("idle")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	
func take_damage(damage: int) -> void:
	Debug.log("Torreta hit %d" % damage)
	

func _on_health_changed(value: int) -> void:
	take_damage(value)

func _on_died():
	if not is_multiplayer_authority():
		return
	die.rpc()
	
@rpc("authority", "call_local", "reliable")
func die():
	print("Alien-Ship destruída")
	playback.travel("die")
	await get_tree().create_timer(0.4).timeout
	call_deferred("queue_free")
