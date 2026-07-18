extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var label: Label = $Label
@onready var interact_area = $InteractArea  # ← agregar esto

const SPEED = 500.0
const JUMP_VELOCITY = -900.0
const Gravity_factor = 2

var walking = false

func _ready() -> void:
	label.text = "Demo"
	animated_sprite.frame = 0

func _physics_process(delta: float) -> void:
	var g = get_gravity()
	if g.length() == 0:
		g = Vector2.DOWN * 980
	var vertical_direction = g.normalized()
	var horizontal_direction = vertical_direction.rotated(-PI/2)
	var vertical_velocity = vertical_direction * velocity.dot(vertical_direction)
	var horizontal_speed = velocity.dot(horizontal_direction)

	var move_input := 0
	if Input.is_action_pressed("move_right"):
		move_input = 1
	elif Input.is_action_pressed("move_left"):
		move_input = -1

	if move_input:
		horizontal_speed = move_input * SPEED
		change_sprite_direction(move_input)
	else:
		horizontal_speed = move_toward(horizontal_speed, 0, SPEED * delta * 5)

	if not is_on_floor():
		vertical_velocity += g * delta * Gravity_factor
	elif Input.is_action_just_pressed("jump"):
		vertical_velocity = vertical_direction * JUMP_VELOCITY

	velocity = horizontal_direction * horizontal_speed + vertical_velocity
	up_direction = -vertical_direction
	move_and_slide()

	if Input.is_action_just_pressed("area_interact"):
		_check_interact()

func change_sprite_direction(direction: int) -> void:
	if direction < 0:
		animated_sprite.flip_h = true
	elif direction > 0:
		animated_sprite.flip_h = false

func _check_interact() -> void:
	for area in interact_area.get_overlapping_areas():
		if area.has_method("area_interact"):
			area.area_interact()
	for body in interact_area.get_overlapping_bodies():
		if body.has_method("area_interact"):
			body.area_interact()
