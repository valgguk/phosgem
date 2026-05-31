extends Node
@export var LoseNodes: Array[Node] 
@export var GameOverLayer: GameOverScreen
@export var wait_time: float = 9
var _is_game_over = false


### ALL nodes with signal "game_over" can be put on LoseNodes for automatic conection
# THIS NODE IS FOR GLOBAL EVENTS LIKE DYING OR SHARED VARIABLES AND RESOURCES
#I WILL USE IT FOR A GAME OVER BY OXYGEN
### 
# SETS UP any LoseNode so it connects its lose signal with a game over, 
func _ready():
	for losenode in LoseNodes:
		if losenode.has_signal("game_over"):
			losenode.game_over.connect(_on_game_over.bind(losenode))
		else:
			Debug.log("Hay un nodo equivocado en las condiciones de DERROTA")
	pass # Replace with function body.




### custom details allowed on the function by detecting any contition on your node
func _on_game_over(LoseCondition: Node):
	if _is_game_over:
		return
	
	if LoseCondition is OxigenGenerator : #example
		#ZOOM into the oxigen tank
		Debug.log("Oxigen Ran OUT!")
	
	if LoseCondition is HealthManager: 
		Debug.log("Health ran OUT!")
	game_over()
	
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
