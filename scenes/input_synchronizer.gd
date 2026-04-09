class_name InputSynchronizer
extends MultiplayerSynchronizer

@export var move_input: float
var jump

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	move_input = Input.get_axis("move_left", "move_right")
	if Input.is_action_just_pressed("jump"):
		set_jump.rpc(true)
		
		
@rpc("reliable", "call_local")
func set_jump(value: bool) -> void:
	jump = value
