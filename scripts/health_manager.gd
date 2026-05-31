extends Node
class_name HealthManager

@export var MAX_HEALTH: int = 100
var ShipHealth
@export var UI_health: TextureProgressBar
signal game_over

# Called when the node enters the scene tree for the first time.
func _ready():
	UI_health.max_value = MAX_HEALTH
	ShipHealth= MAX_HEALTH
	
func _process(delta):
	UI_health.value = ShipHealth
	
	
func _update_health(amount: int) -> void:
	Debug.log("DAMAGE" + str(amount))
	ShipHealth = clampi(ShipHealth+ amount,0,MAX_HEALTH)
	#do sync shinenigans
	if ShipHealth<=0.5:
		game_over.emit()
	
func take_damage(amount:int= 1)-> void:
	_update_health(-amount)
	
func heal_ship(amount:int= 1)-> void:
	_update_health(amount)
	

	
