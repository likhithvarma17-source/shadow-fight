extends Node2D

const BACKDROP: Texture2D = preload("res://assets/environment/interior_hideout.webp")
const CATWALK: Texture2D = preload("res://assets/environment/catwalk_platform.webp")
const MACHINE_A: Texture2D = preload("res://assets/environment/rooftop_machine_a.webp")
const MACHINE_B: Texture2D = preload("res://assets/environment/rooftop_machine_b.webp")
const EXIT_GATE: Texture2D = preload("res://assets/environment/exit_gate.webp")

const WORLD_RECT := Rect2(0.0, 0.0, 1280.0, 3475.0)
const BACKDROP_PANEL_SIZE := Vector2(1280.0, 2275.0)
const BACKDROP_TINT := Color(0.88, 0.94, 1.0, 1.0)

var camera_ref: Camera2D
var platforms: Array[Rect2] = []
var alerted_floors: Array[int] = []
var exit_open := false
var pulse_clock := 0.0

func _ready() -> void:
	z_index = -12
	z_as_relative = false
	queue_redraw()

func setup(camera: Camera2D) -> void:
	camera_ref = camera
	queue_redraw()

func set_platforms(rects: Array[Rect2]) -> void:
	platforms = rects.duplicate()
	queue_redraw()

func set_floor_alerted(floor_index: int) -> void:
	if floor_index not in alerted_floors:
		alerted_floors.append(floor_index)
		queue_redraw()

func set_exit_open(value: bool) -> void:
	exit_open = value
	queue_redraw()

func set_gate_open(value: bool) -> void:
	set_exit_open(value)

func get_visible_world_size() -> Vector2:
	if not is_instance_valid(camera_ref):
		return Vector2(1280.0, 720.0)
	return camera_ref.get_viewport_rect().size / camera_ref.zoom

func _process(delta: float) -> void:
	pulse_clock += delta
	if not alerted_floors.is_empty() or exit_open:
		queue_redraw()

func _draw() -> void:
	draw_texture_rect(BACKDROP, Rect2(0.0, 0.0, BACKDROP_PANEL_SIZE.x, BACKDROP_PANEL_SIZE.y), false, BACKDROP_TINT)
	draw_texture_rect(BACKDROP, Rect2(0.0, WORLD_RECT.size.y - BACKDROP_PANEL_SIZE.y, BACKDROP_PANEL_SIZE.x, BACKDROP_PANEL_SIZE.y), false, BACKDROP_TINT)
	for rect in platforms:
		draw_texture_rect(CATWALK, rect, false, Color(0.67, 0.74, 0.82, 0.96))
	_draw_rest_props()
	_draw_alert_lights()
	_draw_exit()

func _draw_rest_props() -> void:
	draw_texture_rect(MACHINE_A, Rect2(78.0, 3202.0, 158.0, 138.0), false, Color(0.52, 0.58, 0.65, 0.92))
	draw_texture_rect(MACHINE_B, Rect2(1018.0, 2502.0, 148.0, 126.0), false, Color(0.52, 0.58, 0.65, 0.92))
	draw_texture_rect(MACHINE_A, Rect2(88.0, 1802.0, 150.0, 124.0), false, Color(0.49, 0.55, 0.62, 0.92))
	draw_texture_rect(MACHINE_B, Rect2(1018.0, 1102.0, 148.0, 126.0), false, Color(0.49, 0.55, 0.62, 0.92))
	draw_texture_rect(MACHINE_A, Rect2(88.0, 402.0, 150.0, 124.0), false, Color(0.47, 0.53, 0.60, 0.92))

func _draw_alert_lights() -> void:
	var floor_lights := [
		Vector2(72.0, 3218.0),
		Vector2(1208.0, 2518.0),
		Vector2(72.0, 1818.0),
		Vector2(1208.0, 1118.0),
		Vector2(72.0, 418.0),
	]
	for index in range(floor_lights.size()):
		var position: Vector2 = floor_lights[index]
		var active := index in alerted_floors
		var glow := 0.52 + sin(pulse_clock * 10.0 + index) * 0.22 if active else 0.15
		draw_circle(position, 8.0, Color(1.0, 0.10, 0.08, glow))
		if active:
			draw_circle(position, 24.0, Color(1.0, 0.03, 0.02, glow * 0.13))

func _draw_exit() -> void:
	var exit_rect := Rect2(1084.0, 168.0, 118.0, 205.0)
	draw_texture_rect(EXIT_GATE, exit_rect, false, Color(0.95, 0.98, 1.0, 1.0) if exit_open else Color(0.42, 0.46, 0.53, 1.0))
	var light_color := Color("ffb25b") if exit_open else Color("682e2f")
	draw_circle(exit_rect.position + Vector2(19.0, 26.0), 4.0, light_color)
	if exit_open:
		var alpha := 0.55 + sin(pulse_clock * 6.0) * 0.22
		draw_line(exit_rect.position + Vector2(16.0, 38.0), exit_rect.position + Vector2(16.0, 188.0), Color(1.0, 0.55, 0.22, alpha), 2.0)
