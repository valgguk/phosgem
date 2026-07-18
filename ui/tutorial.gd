class_name TutorialScreen
extends Control

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %Description
@onready var counter_label: Label = %Counter
@onready var next_button: Button = %NextButton
@onready var back_button: Button = %BackButton
@onready var sub_viewport: SubViewport = %SubViewport

const SLIDES := [
	{
		"title": "¡Bienvenido a Crashtronauts!",
		"description": "Tu tripulación está varada en el espacio. Deben cooperar para llevar la nave hasta el planeta y escapar.",
		"demo": ""
	},
	{
		"title": "Movimiento",
		"description": "Usa [A] / [Flecha Izquierda] para moverte a la izquierda y [D] / [Flecha Derecha] para moverte a la derecha.",
		"demo": ""
	},
	{
		"title": "Salto",
		"description": "Presiona [Espacio] para saltar.",
		"demo": ""
	},
	{
		"title": "Interactuar",
		"description": "Presiona [E] o [Click Izquierdo] para interactuar con objetos y paneles de la nave.",
		"demo": ""
	},
	{
		"title": "La nave",
		"description": "Esta es tu nave. Dentro encontrarás los controles para moverla por el espacio.",
		"demo": "res://ui/demo/demo_nave.tscn"
	},
	{
		"title": "Oxígeno",
		"description": "El generador de oxígeno mantiene viva a la tripulación. Si el oxígeno se acaba, todos mueren.",
		"demo": "res://ui/demo/demo_oxigeno.tscn"
	},
	{
		"title": "Energía",
		"description": "El generador de energía alimenta los sistemas de la nave. Sin energía los controles dejan de funcionar.",
		"demo": "res://ui/demo/demo_energia.tscn"
	},
	{ "title": "Aliens",
		"description": "¡No hay paz en el universo! Destruye las naves alienígenas antes de que envíen tripulación.

Si un alien entra a la nave, te aturde. ¡Sáltale encima para eliminarlo!",
		"demo": ""
		
	},
	{ "title": "Torretas",
		"description": "Torretas: usa clic derecho o [E] en los botones.
• Botón cercano: rota la torreta
• Botón rojo: dispara",
		"demo": ""
		
	},
	{
		"title": "Menú de pausa",
		"description": "Presiona [Escape] para pausar. Puedes reanudar, volver al menú o salir.",
		"demo": ""
	},
	{
		"title": "Asteroides",
		"description": "Los asteroides dañan la nave. Coopera con tu equipo para esquivarlos, puedes verlos llegar desde el minimapa con un impactante color rojo.",
		"demo": ""
	},
	{
		"title": "El Planeta",
		"description": "El objetivo es llegar al planeta. Usa el minimapa (el marcador verde indica su dirección).",
		"demo": ""
	},
]

var _current := 0
var _current_demo: Node = null

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_show_slide(_current)

func _show_slide(index: int) -> void:
	title_label.text = SLIDES[index]["title"]
	description_label.text = SLIDES[index]["description"]
	counter_label.text = "%d / %d" % [index + 1, SLIDES.size()]
	back_button.disabled = index == 0
	next_button.text = "Siguiente" if index < SLIDES.size() - 1 else "Ir al menú"
	next_button.grab_focus()
	_load_demo(SLIDES[index]["demo"])

func _load_demo(path: String) -> void:
	if _current_demo and is_instance_valid(_current_demo):
		_current_demo.queue_free()
		_current_demo = null

	if path == "":
		sub_viewport.get_parent().hide()
		return

	sub_viewport.get_parent().show()
	var scene := load(path) as PackedScene
	if scene:
		_current_demo = scene.instantiate()
		sub_viewport.add_child(_current_demo)

func _on_next_pressed() -> void:
	if _current < SLIDES.size() - 1:
		_current += 1
		_show_slide(_current)
	else:
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_back_pressed() -> void:
	if _current > 0:
		_current -= 1
		_show_slide(_current)
