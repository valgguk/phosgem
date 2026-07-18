extends HitboxComponent

var lifetime := 10.0
@export var max_speed = 400
var already_hit := false
var health_manager
var entering := false
var target: Node2D = null
var direction: Vector2
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
@export var alien_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(_on_area_entered)
	#health_manager = get_node("/root/Main/HealthManager")
	animation_tree.active = true
	playback.travel("idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
		
	if entering:
		return
	
	lifetime -= delta
	if lifetime <= 0:
		destroy_bullet.rpc()
		return
		
	#var velocity = -transform.x * max_speed
	#position += velocity * delta
	position += direction * max_speed * delta
	sync_position.rpc(global_position)
	
	
func _on_area_entered(area: Area2D) -> void:
	if already_hit:
		return
	if not is_multiplayer_authority():
		return
	if area.is_in_group("bullet_area"):
		already_hit = true
		_enter_to_ship()
		
#func _hit_ship():
	#health_manager.take_damage(damage)
	#destroy_bullet.rpc()
	
func _enter_to_ship():
	play_enter_animation.rpc()
	await get_tree().create_timer(1.5).timeout
	# SOLO SERVER decide spawn
	if is_multiplayer_authority():
		var spawn_pos = _get_spawn_point()
		spawn_alien_inside_ship.rpc(spawn_pos)
	destroy_bullet.rpc()
	
@rpc("authority", "call_local", "reliable")
func destroy_bullet():
	queue_free()

@rpc("authority", "call_local", "reliable")
func play_enter_animation():
	entering = true
	playback.travel("enter")
	
@rpc("authority", "unreliable")
func sync_position(pos: Vector2):
	global_position = pos
	
func setup(target_node: Node2D) -> void:
	target = target_node
	direction = (target.global_position - global_position).normalized()
	rotation = direction.angle()
	
func _get_spawn_point() -> Vector2:
	var spawn_container = get_node("/root/Main/Ship/AlienSpawnPoints")
	var points = spawn_container.get_children()
	if points.is_empty():
		return spawn_container.global_position
		
	var chosen = points.pick_random()
	return chosen.global_position
	
@rpc("authority", "call_local", "reliable")
func spawn_alien_inside_ship(pos: Vector2):
	if alien_scene == null:
		print("✕ ERROR: alien_scene es NULL")
		return
	var aliens_node = get_node("/root/Main/Ship/Aliens")
	# LIMITE DE ALIENS
	var current_aliens = aliens_node.get_child_count()
	if current_aliens >= 3:
		print("(=) LIMITE DE ALIENS ALCANZADO:", current_aliens)
		return
		
	var alien = alien_scene.instantiate()
	alien.set_multiplayer_authority(1)
	aliens_node.add_child(alien)
	alien.global_position = pos
	
	print("✓ ALIEN SPAWNEADO en:", pos)
