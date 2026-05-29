extends Label
var score = 0

func _ready():
	add_to_group("score_label")

func _on_timer_timeout():
	score += 10
	text = "SCORE: " + str(score)

func take_damage(amount: int) -> void:
	score -= amount
	if score < 0:
		score = 0
	text = "SCORE: " + str(score)
	if score == 0:
		_trigger_game_over()

func _trigger_game_over() -> void:
	var game_over = get_tree().get_first_node_in_group("game_over_screen")
	if game_over and game_over.has_method("play_game_over"):
		game_over.play_game_over()
