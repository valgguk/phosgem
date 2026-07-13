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
