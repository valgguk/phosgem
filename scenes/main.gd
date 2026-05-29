extends Node2D


@export var player_scene: PackedScene
@onready var players: Node2D = $Ship/Players

@onready var ship: Node2D = $Ship
@onready var spawn_points: Node2D = $Ship/SpawnPoints
@onready var camera: Camera2D=$Camera2D
@onready var space_background: Sprite2D = $Parallax2D2/spaceBackground
@onready var label = $Ship/CanvasLayer/Label
@onready var asteroid_spawner: AsteroidSpawner= $AsteroidSpawner

@export var camera_max_zoom: float=1.5
@export var camera_min_zoom: float=0.3
@export var camera_zoom_factor: float=7000.0
@onready var gravity_zone: Area2D = $Ship/GravityZone
@onready var lever_thrust = $Ship/LeverThrust



const rotation_vel=1.5
const acceleration: float=50.0
const max_vel:float=300.0

var target_rotation := 0.0
var rotating:=0
var is_rotating:=false

var ship_velocity: Vector2 = Vector2.ZERO
var ship_thrust: int = 0 


# Called when the node enters the scene tree for the first time.
func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		if is_rotating: 
			target_rotation += rotating * rotation_vel * delta
		ship.rotation = lerp_angle(ship.rotation, target_rotation, 0.2) #solo cambia en el server
		
	gravity_zone.gravity_direction = ship.global_transform.y
	var forward: Vector2 = Vector2(cos(ship.rotation), sin(ship.rotation))

	if ship_thrust != 0:
		ship_velocity += forward * ship_thrust * acceleration * delta
		ship_velocity = ship_velocity.limit_length(max_vel)
	else:
		ship_velocity = ship_velocity.move_toward(Vector2.ZERO, acceleration * delta)

	ship.position += ship_velocity * delta
	_apply_ship_motion_to_players(delta)
	_update_camera()
	space_background.global_position = camera.global_position
	
	if multiplayer.is_server():
		sync_ship.rpc(ship.position, ship.rotation)
	
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
	players.add_to_group("players_container")
	for i in Game.players.size():
		var player_data = Game.players[i]
		var player_inst = player_scene.instantiate()
		player_inst.color = i
		players.add_child(player_inst, true)
		var spawn_point = spawn_points.get_child(i)
		player_inst.global_position = spawn_point.global_position
		player_inst.setup(player_data)
	if multiplayer.is_server():
		asteroid_spawner.initialize(ship)




# mandarle rotacion al server 
# se llama cuando se aprieta el boton
# unreliable garantiza inputs continuos	
@rpc("any_peer", "call_local", "reliable")
func input_rotation(direction: int)->void:
	rotating=direction
	is_rotating=direction!=0
	
	
@rpc("any_peer", "call_local", "unreliable")
func input_thrust(direction: int) -> void:
	ship_thrust = direction
	
func _apply_ship_motion_to_players(delta: float) -> void:
	for player in players.get_children():
		if player.has_method("apply_ship_motion"):
			player.apply_ship_motion(ship_velocity, delta)

@rpc("authority", "call_remote", "unreliable")
func sync_ship(pos: Vector2, rot: float):
	ship.position = ship.position.lerp(pos, 0.2)
	ship.rotation = lerp_angle(ship.rotation, rot, 0.2)
