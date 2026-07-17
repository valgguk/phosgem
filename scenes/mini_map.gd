class_name Minimap
extends Node

@onready var control: Control = $RootControl/Control
@onready var ship_marker: ColorRect = $RootControl/Control/ship
@onready var planet_marker: ColorRect = $RootControl/Control/planet
@onready var asteroids_container: Control = $RootControl/Control/asteroids
@onready var expand_button: Button = $RootControl/expandButton
@onready var background: ColorRect = $RootControl/Control/ColorRect

const SCALE := 0.04
const UPDATE_INTERVAL := 0.1

var _ship_ref: Node2D = null
var _update_timer: float = 0.0
var _asteroid_markers: Dictionary = {}

func _ready() -> void:
	expand_button.pressed.connect(_toggle_expand)
	control.hide()
	await get_tree().process_frame
	_find_ship()

func _find_ship() -> void:
	if not is_inside_tree() or not get_tree():
		return
	var ships := get_tree().get_nodes_in_group("ship")
	if ships.size() > 0:
		_ship_ref = ships[0]
		Debug.log("Minimapa: nave encontrada " + str(_ship_ref.name))
	else:
		Debug.log("Minimapa: nave no encontrada")

func _process(delta: float) -> void:
	if not is_inside_tree() or not get_tree():
		return
	if not control.visible:
		return
	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		_sync_asteroid_markers()
		_update_positions()

func _sync_asteroid_markers() -> void:
	if not get_tree():
		return
	var active := get_tree().get_nodes_in_group("asteroids")
	var active_ids := {}
	for asteroid in active:
		if is_instance_valid(asteroid):
			active_ids[asteroid.asteroid_id] = asteroid
	for id in _asteroid_markers.keys():
		if not active_ids.has(id):
			if is_instance_valid(_asteroid_markers[id]):
				_asteroid_markers[id].queue_free()
			_asteroid_markers.erase(id)
	for id in active_ids:
		if not _asteroid_markers.has(id):
			var marker := ColorRect.new()
			marker.size = Vector2(8, 8)
			marker.color = Color(1.0, 0.4, 0.1)
			asteroids_container.add_child(marker)
			_asteroid_markers[id] = marker

func _update_positions() -> void:
	if not _ship_ref or not is_instance_valid(_ship_ref):
		_find_ship()
		return
	var center := control.size / 2.0

	# nave siempre al centro
	ship_marker.position = center - ship_marker.size / 2.0

	# planeta
	if not get_tree():
		return
	var planets := get_tree().get_nodes_in_group("planet")
	if planets.size() > 0 and is_instance_valid(planets[0]):
		planet_marker.show()
		var pmap := _world_to_map(planets[0].global_position, center)
		if Rect2(Vector2.ZERO, control.size).has_point(pmap):
			planet_marker.position = pmap - planet_marker.size / 2.0
		else:
			# planeta fuera del rango, mostrarlo en el borde
			var dir := (pmap - center).normalized()
			planet_marker.position = center + dir * (center.x * 0.85) - planet_marker.size / 2.0
	else:
		planet_marker.hide()

	# asteroides
	var active := get_tree().get_nodes_in_group("asteroids")
	for asteroid in active:
		if not is_instance_valid(asteroid):
			continue
		var id: int = asteroid.asteroid_id
		if not _asteroid_markers.has(id):
			continue
		var marker = _asteroid_markers[id]
		if not is_instance_valid(marker):
			continue
		var mpos := _world_to_map(asteroid.global_position, center)
		if Rect2(Vector2.ZERO, control.size).has_point(mpos):
			marker.show()
			marker.position = mpos - marker.size / 2.0
		else:
			marker.hide()

func _world_to_map(world_pos: Vector2, center: Vector2) -> Vector2:
	return center + (world_pos - _ship_ref.global_position) * SCALE

func _toggle_expand() -> void:
	control.visible = not control.visible
	expand_button.text = "−" if control.visible else "+"
