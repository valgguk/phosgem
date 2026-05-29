extends Area2D
class_name Asteroid

signal asteroid_hit_ship(asteroid: Asteroid)

@onready var sprite: ColorRect = $ColorRect
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var shader_material_ref: ShaderMaterial = $ColorRect.material

var velocity: Vector2 = Vector2.ZERO
var rotation_speed: float = 0.0
var asteroid_id: int = -1
var radius: float = 40.0
var _time: float = 0.0

func setup(id: int, pos: Vector2, vel: Vector2, rot_spd: float, size: float) -> void:
	asteroid_id = id
	global_position = pos
	velocity = vel
	rotation_speed = rot_spd
	radius = size
	_apply_size(size)

func _apply_size(size: float) -> void:
	var diameter = size * 2.0
	$ColorRect.size = Vector2(diameter, diameter)
	$ColorRect.position = Vector2(-size, -size)
	var circle = CircleShape2D.new()
	circle.radius = size*0.85
	collision.shape = circle
	shader_material_ref.set_shader_parameter("time_offset", float(asteroid_id) * 13.7)
	shader_material_ref.set_shader_parameter("roughness", randf_range(3.0, 6.0))

func _physics_process(delta: float) -> void:
	_time += delta
	position += velocity * delta
	rotation += rotation_speed * delta
	shader_material_ref.set_shader_parameter("time_offset",
		float(asteroid_id) * 13.7 + _time * 0.3)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		asteroid_hit_ship.emit(self)

func destroy() -> void:
	queue_free()
