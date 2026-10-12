extends Node2D

const GROUND_A: Texture2D = preload("res://assets/environment/roof_ground_tile.webp")
const GROUND_B: Texture2D = preload("res://assets/environment/roof_ground_tile_b.webp")
const CATWALK: Texture2D = preload("res://assets/environment/catwalk_platform.webp")
const MACHINE_A: Texture2D = preload("res://assets/environment/rooftop_machine_a.webp")
const MACHINE_B: Texture2D = preload("res://assets/environment/rooftop_machine_b.webp")
const EXIT_GATE: Texture2D = preload("res://assets/environment/exit_gate.webp")

const TILE_WIDTH := 640.0
const MATERIAL_TINT := Color(0.76, 0.80, 0.90, 1.0)
const BOSS_TINT := Color(0.82, 0.55, 0.58, 1.0)

var platforms: Array[Rect2] = []
var arena_width := 1856.0

func _ready() -> void:
	z_index = -8
	z_as_relative = false
	queue_redraw()

func setup(platform_rects: Array[Rect2], width: float) -> void:
	platforms = platform_rects.duplicate()
	arena_width = width
	queue_redraw()

func _draw() -> void:
	if platforms.is_empty():
		return
	_draw_ground(platforms[0])
	for index in range(1, platforms.size()):
		draw_texture_rect(CATWALK, platforms[index], false, MATERIAL_TINT)
	var left_machine := Rect2(86.0, 500.0, 190.0, 150.0)
	var right_machine := Rect2(arena_width - 276.0, 500.0, 190.0, 150.0)
	draw_texture_rect(MACHINE_A, left_machine, false, BOSS_TINT)
	draw_texture_rect(MACHINE_B, right_machine, false, BOSS_TINT)
	_draw_gate(Rect2(16.0, 440.0, 120.0, 210.0), false)
	_draw_gate(Rect2(arena_width - 136.0, 440.0, 120.0, 210.0), true)
	var pulse := 0.34 + sin(Time.get_ticks_msec() * 0.005) * 0.12
	draw_line(Vector2(150.0, 635.0), Vector2(arena_width - 150.0, 635.0), Color(1.0, 0.10, 0.12, pulse), 2.0)
	for x in range(260, int(arena_width - 220.0), 260):
		draw_line(Vector2(float(x), 646.0), Vector2(float(x) + 92.0, 646.0), Color(1.0, 0.48, 0.22, 0.34), 3.0)

func _draw_ground(rect: Rect2) -> void:
	var cursor := rect.position.x
	var tile_index := 0
	while cursor < rect.end.x - 0.1:
		var width := minf(TILE_WIDTH, rect.end.x - cursor)
		var texture := GROUND_A if tile_index % 2 == 0 else GROUND_B
		var source_width := texture.get_width() * width / TILE_WIDTH
		draw_texture_rect_region(texture, Rect2(cursor, rect.position.y, width, rect.size.y), Rect2(0.0, 0.0, source_width, texture.get_height()), MATERIAL_TINT)
		cursor += width
		tile_index += 1

func _draw_gate(rect: Rect2, flip: bool) -> void:
	var source := Rect2(0.0, 0.0, EXIT_GATE.get_width(), EXIT_GATE.get_height())
	if flip:
		source.position.x = source.size.x
		source.size.x *= -1.0
	draw_texture_rect_region(EXIT_GATE, rect, source, Color(0.72, 0.50, 0.54, 1.0))
	var lens_x := rect.position.x + (22.0 if not flip else rect.size.x - 22.0)
	draw_circle(Vector2(lens_x, rect.position.y + 27.0), 4.2, Color("ff3945"))
