extends Node2D

@export var bullet_scene: PackedScene
@onready var boca: Marker2D = $Boca
var rotate_dir := 0.0
var rotation_speed := 5.0
@onready var label: Label = $Label
@export var turret_id: int = 0
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = str(turret_id)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta):
	if not is_multiplayer_authority():
		return
		
	if rotate_dir != 0:
		rotation += rotate_dir * rotation_speed * delta
		sync_rotation.rpc(rotation)

func rotate_turret(dir: float):
	if not is_multiplayer_authority():
		return
	rotate_dir = dir

@rpc("authority", "unreliable")
func sync_rotation(rot: float):
	rotation = rot


func shoot():
	if not is_multiplayer_authority():
		return
	_play_fire_animation()
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
	_play_fire_animation()
	var bullet = bullet_scene.instantiate()
	var bullets_node = get_node("/root/Main/Ship/Bullets")
	bullets_node.add_child(bullet)
	bullet.global_position = pos
	bullet.setup(dir)
	
func _play_fire_animation():
	playback.travel("fire")
