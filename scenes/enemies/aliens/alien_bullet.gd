extends HitboxComponent

@export var max_speed = 400
var already_hit := false
var health_manager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(_on_area_entered)
	health_manager = get_node("/root/Main/HealthManager")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	var velocity = transform.x * max_speed
	position += velocity * delta
	
func _on_area_entered(area: Area2D) -> void:
	if already_hit:
		return
	if not is_multiplayer_authority():
		return
	if area.is_in_group("bullet_area"):
		already_hit = true
		_hit_ship()
		
func _hit_ship():
	health_manager.take_damage(damage)
	destroy_bullet.rpc()
	
@rpc("authority", "call_local", "reliable")
func destroy_bullet():
	queue_free()
