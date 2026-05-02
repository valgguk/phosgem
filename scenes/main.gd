extends Node2D

@export var player_scene: PackedScene
@onready var players: Node2D = $Level/Players
@onready var level: Node2D=$Level
@onready var spawn_points: Node2D = $Level/SpawnPoints
@onready var camera: Camera2D=$Camera2D
@onready var space_background: Sprite2D = $spaceBackground

@export var camera_max_zoom: float=1.5
@export var camera_min_zoom: float=0.3
@export var camera_zoom_factor: float=7000.0


const rotation_vel=1.5
const acceleration: float=50.0
const max_vel:float=300.0

var rotating:=0
var is_rotating:=false

var ship_velocity: Vector2 = Vector2.ZERO
var ship_thrust: int = 0 


# Called when the node enters the scene tree for the first time.
func _physics_process(delta: float) -> void:
	_update_camera()
	
func _update_camera() -> void:
	var children = players.get_children()
	var center: Vector2 = Vector2.ZERO
	for player in children:
		center += player.global_position
	center/=children.size()
	camera.global_position=center
	var max_dist: float = 0.0
	for player in children:
		max_dist = max(max_dist, center.distance_squared_to(player.global_position))

	var zoom: float=clamp(1.0 / max(max_dist, 1.0) * camera_zoom_factor, camera_min_zoom, camera_max_zoom)
	camera.zoom = Vector2(zoom, zoom)
	
	
func _ready() -> void:
	for i in Game.players.size():
		var player_data = Game.players[i]
		var player_inst = player_scene.instantiate()
		players.add_child(player_inst, true)
		var spawn_point = spawn_points.get_child(i)
		player_inst.global_position = spawn_point.global_position
		player_inst.setup(player_data)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_rotating:
		level.rotation+=rotating*rotation_vel*delta
		
	var forward: Vector2 = Vector2(cos(level.rotation), sin(level.rotation))

	# Aplicar empuje o frenar
	if ship_thrust != 0:
		ship_velocity += forward * ship_thrust *acceleration* delta
		ship_velocity = ship_velocity.limit_length(max_vel)
	else:
		ship_velocity = ship_velocity.move_toward(Vector2.ZERO,acceleration* delta)
	level.position += ship_velocity * delta
	space_background.global_position = camera.global_position
		
@rpc("any_peer", "call_local", "reliable")
func input_rotation(direction: int)->void:
	rotating=direction
	is_rotating=direction!=0
	
	
@rpc("any_peer", "call_local", "reliable")
func input_thrust(direction: int) -> void:
	ship_thrust = direction
