extends Node2D

@export var bullet_scene: PackedScene
@onready var boca: Marker2D = $Boca

var rotation_speed := 2.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func rotate_turret(dir: float):
	if not is_multiplayer_authority():
		return
		
	rotation += dir * rotation_speed * get_process_delta_time()
	sync_rotation.rpc(rotation)

@rpc("authority", "unreliable")
func sync_rotation(rot: float):
	rotation = rot


func shoot():
	if not is_multiplayer_authority():
		return
		
	var bullet = bullet_scene.instantiate()
	
	var bullets_node = get_node("/root/Main/Ship/Bullets")
	bullets_node.add_child(bullet)
	
	bullet.global_position = boca.global_position
	
	var dir = Vector2.RIGHT.rotated(global_rotation)
	bullet.setup(dir)
	
	bullet.set_multiplayer_authority(1)

	sync_shoot.rpc(boca.global_position, dir)


@rpc("authority", "call_remote", "reliable")
func sync_shoot(pos: Vector2, dir: Vector2):
	if is_multiplayer_authority():
		return
		
	var bullet = bullet_scene.instantiate()
	var bullets_node = get_node("/root/Main/Ship/Bullets")
	bullets_node.add_child(bullet)
	
	bullet.global_position = pos
	bullet.setup(dir)
