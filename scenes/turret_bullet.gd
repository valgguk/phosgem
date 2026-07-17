extends HitboxComponent

@export var speed := 800.0
var direction: Vector2
var lifetime := 3.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
		
	lifetime -= delta
	if lifetime <= 0:
		destroy()
		return
		
	position += direction * speed * delta
	sync_position.rpc(global_position)

@rpc("authority", "unreliable")
func sync_position(pos: Vector2):
	global_position = pos

func setup(dir: Vector2):
	direction = dir.normalized()
	rotation = direction.angle()
	
func destroy():
	queue_free()
	destroy_rpc.rpc()

@rpc("authority", "call_remote", "reliable")
func destroy_rpc():
	if is_multiplayer_authority():
		return
	queue_free()
