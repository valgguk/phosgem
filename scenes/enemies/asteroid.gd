extends Area2D
class_name Asteroid

signal asteroid_hit_ship(asteroid: Asteroid)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var shader_material_ref: ShaderMaterial = sprite.material
@onready var trail: CPUParticles2D = $CPUParticles2D


var velocity: Vector2 = Vector2.ZERO
var rotation_speed: float = 0.0
var asteroid_id: int = -1
var radius: float = 40.0
var _time: float = 0.0
var _hit: bool = false
var _ship_ref: Node2D = null

func setup(id: int, pos: Vector2, vel: Vector2, rot_spd: float, size: float) -> void:
	asteroid_id = id
	global_position = pos
	velocity = vel
	rotation_speed = rot_spd
	_apply_size(size)

func _apply_size(size: float) -> void:
	radius = size
	var diameter = size * 2.0
	sprite.scale = Vector2(diameter, diameter)/32.0
	sprite.position = Vector2(-size, -size)
	var circle = CircleShape2D.new()
	circle.radius = size * 0.85
	collision.shape = circle
	shader_material_ref.set_shader_parameter("time_offset", float(asteroid_id) * 13.7)
	shader_material_ref.set_shader_parameter("roughness", randf_range(3.0, 6.0))
	
	var scale_factor=size/80.0
	trail.scale=Vector2(scale_factor,scale_factor)
	trail.lifetime=size / 100.0
	trail.initial_velocity_min = 30.0 * scale_factor
	trail.initial_velocity_max = 80.0 * scale_factor
	trail.scale_amount_max= 0.2*scale_factor
	trail.scale_amount_min=0.8*scale_factor

func _physics_process(delta: float) -> void:
	_time += delta
	global_position += velocity * delta
	#rotation += rotation_speed * delta
	shader_material_ref.set_shader_parameter("time_offset",
		float(asteroid_id) * 13.7 + _time * 0.3)
	if velocity.length() > 1.0:
		trail.rotation = velocity.angle()
	_check_ship_collision()

func _check_ship_collision() -> void:
	if _hit or _ship_ref == null:
		return
	var dist = global_position.distance_to(_ship_ref.global_position)
	if dist < radius + 300.0:
		_hit = true
		asteroid_hit_ship.emit(self)

func destroy() -> void:
	trail.emitting = false
	await get_tree().create_timer(trail.lifetime).timeout
	queue_free()

func _ready() -> void:
	add_to_group("asteroids")
