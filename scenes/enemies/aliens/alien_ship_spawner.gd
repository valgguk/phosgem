extends Node2D
class_name AlienShipSpawner

@export var alien_scene: PackedScene
@export var wave_size_min := 1
@export var wave_size_max := 2

@export var time_between_waves_min := 30.0
@export var time_between_waves_max := 60.0

var _recent_spawns: Array[Vector2] = []
@export var min_spawn_distance := 120.0
@export var max_spawn_attempts := 10

@export var spawn_areas: Array[Area2D]

var _timer := 0.0
var _next_spawn := 5.0

func _ready() -> void:
	_schedule_next()

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return

	_timer += delta
	if _timer >= _next_spawn:
		_timer = 0.0
		_spawn_wave()
		_schedule_next()

func _schedule_next():
	_next_spawn = randf_range(time_between_waves_min, time_between_waves_max)

func _spawn_wave():
	var amount = randi_range(wave_size_min, wave_size_max)
	
	for i in amount:
		_spawn_alien()
		await get_tree().create_timer(0.3).timeout
		
func _spawn_alien():
	if spawn_areas.is_empty():
		return

	# elegir área random
	var area = spawn_areas.pick_random()
	var spawn_pos = _get_valid_spawn(area)
	
	spawn_alien_rpc.rpc(spawn_pos)

	
@rpc("authority", "call_local", "reliable")
func spawn_alien_rpc(pos: Vector2):
	var alien = alien_scene.instantiate()
	self.add_child(alien) # importante
	alien.global_position = pos

func get_random_point_in_area(area: Area2D) -> Vector2:
	var shape_node := area.find_child("CollisionShape2D", true, false) as CollisionShape2D
	
	if shape_node == null:
		push_warning("Area sin CollisionShape2D")
		return area.global_position
	
	var shape = shape_node.shape
	
	if shape is RectangleShape2D:
		var extents = shape.extents
		
		var local_point = Vector2(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y)
		)
		
		return shape_node.to_global(local_point)

	return shape_node.global_position
	
func _get_valid_spawn(area: Area2D) -> Vector2:
	for i in max_spawn_attempts:
		var pos = get_random_point_in_area(area)
		
		var valid = true
		
		for other in _recent_spawns:
			if pos.distance_to(other) < min_spawn_distance:
				valid = false
				break
		
		if valid:
			_recent_spawns.append(pos)
			
			# Limitar memoria (solo últimos 10)
			if _recent_spawns.size() > 10:
				_recent_spawns.pop_front()
				
			return pos
	
	# fallback si no encontró nada
	return get_random_point_in_area(area)
