extends HitboxComponent

@export var speed := 800.0
var direction: Vector2
var lifetime := 3.0

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
		
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
		
	position += direction * speed * delta
	sync_position.rpc(global_position)

@rpc("authority", "unreliable")
func sync_position(pos: Vector2):
	global_position = pos

func setup(dir: Vector2):
	direction = dir.normalized()
	rotation = direction.angle()
