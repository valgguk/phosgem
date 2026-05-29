extends Node2D
class_name AsteroidSpawner

@export var asteroid_scene: PackedScene
@export var spawn_interval_min: float = 6.0
@export var spawn_interval_max: float = 10.0
@export var speed_min: float = 30.0
@export var speed_max: float = 120.0
@export var size_min: float = 100.0
@export var size_max: float = 150.0
@export var spawn_radius: float = 1200.0
@export var despawn_radius: float = 1600.0

var _timer: float = 0.0
var _next_spawn: float = 3.0
var _asteroid_counter: int = 0
var _active_asteroids: Dictionary = {}
var _ship_ref: Node2D = null

func initialize(ship: Node2D) -> void:
	_ship_ref = ship
	_schedule_next()

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_timer += delta
	if _timer >= _next_spawn:
		_timer = 0.0
		_spawn_asteroid()
		_schedule_next()
	_cull_distant_asteroids()

func _schedule_next() -> void:
	_next_spawn = randf_range(spawn_interval_min, spawn_interval_max)

func _spawn_asteroid() -> void:
	if _active_asteroids.size()>=3:
		return

	if _ship_ref == null:
		return
	var ship_center: Vector2 = _ship_ref.global_position

	var angle: float = randf() * TAU
	var spawn_pos: Vector2 = ship_center + Vector2(cos(angle), sin(angle)) * spawn_radius

	var to_ship: Vector2 = (ship_center - spawn_pos).normalized()

	var deviation: float = randf_range(-0.85, 0.85)
	var vel_dir: Vector2 = to_ship.rotated(deviation)

	var speed: float = randf_range(speed_min, speed_max)
	var rot_spd: float = randf_range(-2.0, 2.0)
	var size: float = randf_range(size_min, size_max)
	var id: int = _asteroid_counter
	_asteroid_counter += 1

	spawn_asteroid_rpc.rpc(id, spawn_pos, vel_dir * speed, rot_spd, size)

@rpc("authority", "call_local", "reliable")
func spawn_asteroid_rpc(id: int, pos: Vector2, vel: Vector2,
	rot_spd: float, size: float) -> void:
	var asteroid: Asteroid = asteroid_scene.instantiate()
	add_child(asteroid)
	asteroid.setup(id, pos, vel, rot_spd, size)
	asteroid._ship_ref = _ship_ref  # ← línea nueva
	asteroid.asteroid_hit_ship.connect(_on_asteroid_hit_ship)
	_active_asteroids[id] = asteroid

func _cull_distant_asteroids() -> void:
	if _ship_ref == null:
		return
	var ship_center: Vector2 = _ship_ref.global_position
	var to_remove: Array = []
	for id in _active_asteroids:
		var ast: Asteroid = _active_asteroids[id]
		if not is_instance_valid(ast):
			to_remove.append(id)
			continue
		if ast.global_position.distance_to(ship_center) > despawn_radius:
			to_remove.append(id)
			ast.destroy()
	for id in to_remove:
		_active_asteroids.erase(id)

func _on_asteroid_hit_ship(asteroid: Asteroid) -> void:
	if not multiplayer.is_server():
		return
	var id = asteroid.asteroid_id
	if _active_asteroids.has(id):
		_active_asteroids.erase(id)
		asteroid.destroy()
	trigger_game_over.rpc()

#futura para torreta
func destroy_asteroid_by_id(id: int) -> void:
	if not multiplayer.is_server():
		return
	if _active_asteroids.has(id):
		var ast: Asteroid = _active_asteroids[id]
		_active_asteroids.erase(id)
		notify_asteroid_destroyed.rpc(id)
		ast.destroy()

@rpc("authority", "call_local", "reliable")
func notify_asteroid_destroyed(id: int) -> void:
	if _active_asteroids.has(id):
		var ast: Asteroid = _active_asteroids[id]
		_active_asteroids.erase(id)
		if is_instance_valid(ast):
			ast.destroy()

@rpc("authority", "call_local", "reliable")
func trigger_game_over() -> void:
	print("ASTEROIDE IMPACTO - buscando score_label")
	var score_label = get_tree().get_first_node_in_group("score_label")
	print("score_label encontrado: ", score_label)
	if score_label and score_label.has_method("take_damage"):
		print("llamando take_damage")
		score_label.take_damage(50)
