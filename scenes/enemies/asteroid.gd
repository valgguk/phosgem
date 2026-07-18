extends Area2D
class_name Asteroid

signal asteroid_hit_ship(asteroid: Asteroid)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var shader_material_ref: ShaderMaterial = sprite.material
@onready var trail: CPUParticles2D = $Sprite2D/CPUParticles2D
@onready var detection_area_2d: Area2D = $DetectionArea
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var update_timer: Timer = $updateTimer


var speed: int = 50
var velocity: Vector2 = Vector2.ZERO
var rotation_speed: float = 0.0
var asteroid_id: int = -1
var radius: float = 40.0
var _time: float = 0.0
var _hit: bool = false
var _ship_ref: Node2D = null

var target_ship: Node2D 

func setup(id: int, pos: Vector2, vel: Vector2, rot_spd: float, size: float) -> void:
	asteroid_id = id
	global_position = pos
	global_rotation = vel.angle()
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
	shader_material_ref.set_shader_parameter("pixel_size", (size * 2.0) / 16.0)


func _physics_process(delta: float) -> void:
	_time += delta * 1000
	global_position += velocity * delta
	shader_material_ref.set_shader_parameter("time_offset", float(asteroid_id) * 13.7 + _time * 0.3)
	

	
@rpc("authority", "call_local", "reliable")
func destroy() -> void:
	$AudioStreamPlayer.play()
	trail.emitting = false
	get_tree().create_timer(trail.lifetime).timeout
	queue_free()
	
func _on_detection_area_entered(area: Area2D) -> void:
	if area.name=="asteroidColision": #de la nave
		asteroid_hit_ship.emit(self)
		
		

func _ready() -> void:
	add_to_group("asteroids")
	detection_area_2d.area_entered.connect(_on_detection_area_entered)
	detection_area_2d.area_exited.connect(_on_detection_area_entered)
	update_timer.timeout.connect(_update_target_position)
	
func _on_body_entered(body:Node)->void:
	var ship = body as Node2D
	if ship:
		target_ship = ship
		_update_target_position()
		update_timer.start()
		
		
		
func _on_body_exited(body:Node)->void:
	var ship = body as Node2D
	if ship and ship == target_ship:
		target_ship = null
		update_timer.stop()
		

func _update_target_position() -> void:
	if target_ship:
		navigation_agent_2d.target_position = target_ship.global_position
