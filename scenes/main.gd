extends Node2D

@export var player_scene: PackedScene
@onready var players: Node2D = $Players
@onready var spawn_points: Node2D = $SpawnPoints

# Called when the node enters the scene tree for the first time.
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
	pass
