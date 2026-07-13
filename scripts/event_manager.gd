extends Node
@export var EventNodes: Array[Node] 
@export var GameOverLayer: GameOverScreen
@export var wait_time: float = 9
var _is_game_over = false
@onready var ship = $"../Ship"
@onready var ship_visuals = $"../Ship/Visuals"


### ALL nodes with signal "game_over" can be put on LoseNodes for automatic conection
# THIS NODE IS FOR GLOBAL EVENTS LIKE DYING OR SHARED VARIABLES AND RESOURCES
#I WILL USE IT FOR A GAME OVER BY OXYGEN, now it has something for general events with trigger_ship_event
### 
# SETS UP any Node so it connects its lose signal with a game over, or trigger_ship_event with a function in here
func _ready():
	for node in EventNodes:
		if node.has_signal("game_over"):
			node.game_over.connect(_on_game_over.bind(node))
		if node.has_signal("trigger_ship_event"):
			node.trigger_ship_event.connect(on_ship_event.bind(node)) 
		elif not (node.has_signal("trigger_ship_event") or node.has_signal("game_over")):
			Debug.log("Hay un nodo equivocado en las condiciones de DERROTA o EVENTO")
	pass # Replace with function body.




### custom details allowed on the function by detecting any contition on your node
func _on_game_over(LoseCondition: Node):
	if _is_game_over:
		return
	
	if LoseCondition is OxigenGenerator : #example
		#ZOOM into the oxigen tank
		Debug.log("Oxigen Ran OUT!")
	
	if LoseCondition is HealthManager: 
		Debug.log("The Ship Got damaged to much!")
		
		
	if LoseCondition is EnergyGenerator:
		var tween = get_tree().create_tween()
		tween.tween_property(ship_visuals,"modulate",Color(0.104, 0.104, 0.104, 1.0),1)
		return
		

	game_over.rpc()

func on_ship_event(EventNode:Node):
	if EventNode is EnergyGenerator:

		var tween = get_tree().create_tween()
		if EventNode.energy_empty:
			tween.tween_property(ship_visuals,"modulate",Color(0.104, 0.104, 0.104, 1.0),1)
			return
		else:
			tween.tween_property(ship_visuals,"modulate",Color(1.0, 1.0, 1.0, 1.0),1)
			



@rpc("authority","call_local","reliable")
func game_over():
	if _is_game_over:
		return
	_is_game_over = true
	var tween = get_tree().create_tween()
	GameOverLayer.modulate.a = 0
	GameOverLayer.visible= true
	
		
	tween.tween_property(GameOverLayer,"modulate:a",1,1)
	GameOverLayer.play_game_over()
	await get_tree().create_timer(wait_time).timeout
	get_tree().change_scene_to_file("res://lobby/waiting_screen.tscn")
