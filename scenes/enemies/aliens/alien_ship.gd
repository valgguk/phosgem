extends CharacterBody2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
@onready var health_component: HealthComponent = $HurtboxComponent/HealthComponent

@export var bullet_scene : PackedScene
@onready var bullet_spawn: Marker2D = $BulletSpawn
#@export var munition_max = 5
#var munition_now = munition_max

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _ready() -> void:
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	animation_tree.active = true
	playback.travel("idle")

func _physics_process(delta: float) -> void:
	#if munition_now == 0:
		##recarga
		#munition_now = munition_max
		#await get_tree().create_timer(5).timeout
		#return
		#
	#while munition_now > 0:
		#fire()
		#await get_tree().create_timer(3).timeout
		#munition_now -= 1
	pass
	
	
	
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
	
func fire() -> void:
	var bullet_inst = bullet_scene.instantiate()
	add_child(bullet_inst)
	bullet_inst.global_position = bullet_spawn.global_position
	bullet_inst.global_rotation = Vector2.LEFT.angle()
