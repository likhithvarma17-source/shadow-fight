extends Node2D

const GROUND_A: Texture2D = preload("res://assets/environment/roof_ground_tile.webp")
const GROUND_B: Texture2D = preload("res://assets/environment/roof_ground_tile_b.webp")
const CATWALK: Texture2D = preload("res://assets/environment/catwalk_platform.webp")
const MACHINE_A: Texture2D = preload("res://assets/environment/rooftop_machine_a.webp")
const MACHINE_B: Texture2D = preload("res://assets/environment/rooftop_machine_b.webp")
const EXIT_GATE: Texture2D = preload("res://assets/environment/exit_gate.webp")

const GROUND_TILE_WIDTH := 640.0
const MACHINE_RECTS: Array[Rect2] = [
	Rect2(300.0, 500.0, 190.0, 150.0),
	Rect2(1985.0, 510.0, 200.0, 140.0),
	Rect2(3175.0, 510.0, 195.0, 140.0),
	Rect2(4160.0, 510.0, 170.0, 140.0)
]
const GATE_RECT := Rect2(5006.0, 440.0, 120.0, 210.0)
const MATERIAL_TINT := Color(0.84, 0.89, 0.98, 1.0)
const STRUCTURE_TINT := Color(0.73, 0.80, 0.92, 1.0)

var platforms: Array[Rect2] = []
var gate_open := false
var last_ground_module_count := 0
var last_catwalk_count := 0
var last_machine_count := 0

func _ready() -> void:
	z_index = -8
	z_as_relative = false
	queue_redraw()

func _process(_delta: float) -> void:
	if gate_open:
		queue_redraw()

func setup(platform_rects: Array[Rect2]) -> void:
	platforms = platform_rects.duplicate()
	queue_redraw()

func set_gate_open(value: bool) -> void:
	if gate_open == value:
		return
	gate_open = value
	queue_redraw()

func get_expected_ground_module_count() -> int:
	if platforms.is_empty():
		return 0
	return int(ceil(platforms[0].size.x / GROUND_TILE_WIDTH))

func get_expected_catwalk_count() -> int:
	return maxi(0, platforms.size() - 1)

func _draw() -> void:
	last_ground_module_count = 0
	last_catwalk_count = 0
	last_machine_count = 0
	if platforms.is_empty():
		return
	_draw_ground(platforms[0])
	for index in range(1, platforms.size()):
		var rect := platforms[index]
		draw_texture_rect(CATWALK, rect, false, MATERIAL_TINT)
		last_catwalk_count += 1
	for index in range(MACHINE_RECTS.size()):
		var texture := MACHINE_A if index % 2 == 0 else MACHINE_B
		draw_texture_rect(texture, MACHINE_RECTS[index], false, STRUCTURE_TINT)
		last_machine_count += 1
	_draw_gate()

func _draw_ground(rect: Rect2) -> void:
	var cursor := rect.position.x
	var module_index := 0
	while cursor < rect.end.x - 0.1:
		var width := minf(GROUND_TILE_WIDTH, rect.end.x - cursor)
		var texture := GROUND_A if module_index % 2 == 0 else GROUND_B
		var source_width := texture.get_width() * width / GROUND_TILE_WIDTH
		draw_texture_rect_region(
			texture,
			Rect2(cursor, rect.position.y, width, rect.size.y),
			Rect2(0.0, 0.0, source_width, texture.get_height()),
			MATERIAL_TINT
		)
		cursor += width
		module_index += 1
		last_ground_module_count += 1

func _draw_gate() -> void:
	var gate_tint := Color(0.96, 0.98, 1.0, 1.0) if gate_open else Color(0.62, 0.66, 0.74, 1.0)
	draw_texture_rect(EXIT_GATE, GATE_RECT, false, gate_tint)
	var lens_color := Color("ffb15c") if gate_open else Color("70452f")
	draw_circle(Vector2(GATE_RECT.position.x + 22.0, GATE_RECT.position.y + 27.0), 3.8, lens_color)
	draw_circle(Vector2(GATE_RECT.end.x - 22.0, GATE_RECT.position.y + 27.0), 3.8, lens_color)
	if gate_open:
		var pulse := 0.50 + sin(Time.get_ticks_msec() * 0.006) * 0.18
		draw_line(
			Vector2(GATE_RECT.position.x + 18.0, GATE_RECT.end.y - 10.0),
			Vector2(GATE_RECT.position.x + 18.0, GATE_RECT.position.y + 36.0),
			Color(1.0, 0.58, 0.24, pulse),
			2.0
		)
		draw_line(
			Vector2(GATE_RECT.end.x - 18.0, GATE_RECT.end.y - 10.0),
			Vector2(GATE_RECT.end.x - 18.0, GATE_RECT.position.y + 36.0),
			Color(1.0, 0.58, 0.24, pulse),
			2.0
		)
