extends CharacterBody2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
@onready var health_component: HealthComponent = $HurtboxComponent/HealthComponent

@export var bullet_scene : PackedScene
@onready var bullet_spawn: Marker2D = $BulletSpawn

@export var shoot_interval := 60.0 # 60 segundos / 120.0 para 2 min
@export var min_interval := 60.0
@export var max_interval := 120.0
@onready var shoot_timer: Timer = $ShootTimer

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _ready() -> void:
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	animation_tree.active = true
	playback.travel("idle")
	
	if is_multiplayer_authority():
		shoot_timer.wait_time = randf_range(5, 10)
		shoot_timer.start()
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)

func _physics_process(delta: float) -> void:
	pass

func _on_shoot_timer_timeout():
	fire.rpc()
	
	
func take_damage(damage: int) -> void:
	Debug.log("Torreta hit %d" % damage)
	

func _on_health_changed(value: int) -> void:
	take_damage(value)

func _on_died():
	if not is_multiplayer_authority():
		return
	die.rpc()
	
@rpc("authority", "call_local", "reliable")
func die():
	print("Alien-Ship destruída")
	playback.travel("die")
	await get_tree().create_timer(0.4).timeout
	call_deferred("queue_free")

@rpc("authority", "call_local", "reliable")
func fire() -> void:
	var bullet_inst = bullet_scene.instantiate()
	get_parent().add_child(bullet_inst) # mejor que add_child local
	bullet_inst.global_position = bullet_spawn.global_position
	#bullet_inst.global_rotation = Vector2.LEFT.angle()
	if has_node("/root/Main/Ship/BulletColision2"):
		var ship_area = get_node("/root/Main/Ship/BulletColision2")
		bullet_inst.target = ship_area
		bullet_inst.setup(ship_area)
	bullet_inst.set_multiplayer_authority(get_multiplayer_authority())
