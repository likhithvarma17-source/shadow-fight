extends Node2D

const ACTIVE_DURATION := 0.62

var age := ACTIVE_DURATION
var intensity := 0.0
var bolt_points: PackedVector2Array = PackedVector2Array()
var branches: Array[PackedVector2Array] = []
var sparks: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	z_index = 28
	rng.seed = 90417
	_build_geometry()
	visible = false
	set_process(true)

func strike() -> void:
	age = 0.0
	intensity = 1.0
	visible = true
	queue_redraw()

func show_preview(progress: float = 0.16) -> void:
	age = clampf(progress, 0.0, 1.0) * ACTIVE_DURATION
	intensity = 1.0 - age / ACTIVE_DURATION
	visible = true
	queue_redraw()

func hide_effect() -> void:
	age = ACTIVE_DURATION
	intensity = 0.0
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	age += delta
	intensity = clampf(1.0 - age / ACTIVE_DURATION, 0.0, 1.0)
	if age >= ACTIVE_DURATION:
		visible = false
	queue_redraw()

func _build_geometry() -> void:
	bolt_points.clear()
	branches.clear()
	sparks.clear()
	var segments := 13
	for index in range(segments + 1):
		var phase := float(index) / float(segments)
		var x := rng.randf_range(-28.0, 28.0) * sin(phase * PI)
		bolt_points.append(Vector2(x, lerpf(-650.0, -10.0, phase)))
	for branch_index in range(6):
		var source_index := 2 + branch_index * 2
		var source := bolt_points[mini(source_index, bolt_points.size() - 2)]
		var direction := -1.0 if branch_index % 2 == 0 else 1.0
		var branch := PackedVector2Array([source])
		for step in range(1, 4):
			branch.append(source + Vector2(direction * step * rng.randf_range(20.0, 34.0), step * rng.randf_range(22.0, 38.0)))
		branches.append(branch)
	for _index in range(28):
		var angle := rng.randf_range(PI * 0.08, PI * 0.92)
		var distance := rng.randf_range(28.0, 150.0)
		sparks.append({"end": Vector2(cos(angle) * distance, -sin(angle) * distance * 0.5), "width": rng.randf_range(0.8, 2.1)})

func _draw() -> void:
	if intensity <= 0.0:
		return
	var flicker := clampf(intensity * (0.78 + sin(age * 137.0) * 0.22), 0.0, 1.0)
	for width in [16.0, 8.0, 3.0]:
		var color := Color(0.28, 0.82, 1.0, flicker * (0.10 if width > 10.0 else 0.36 if width > 4.0 else 0.98))
		draw_polyline(bolt_points, color, width, true)
	for branch in branches:
		draw_polyline(branch, Color(0.64, 0.94, 1.0, flicker * 0.62), 2.0, true)
	draw_circle(Vector2(0.0, -8.0), 34.0 + (1.0 - intensity) * 92.0, Color(0.72, 0.96, 1.0, flicker * 0.18), false, 4.0)
	draw_circle(Vector2(0.0, -8.0), 14.0 + (1.0 - intensity) * 44.0, Color(0.94, 1.0, 1.0, flicker * 0.46), false, 3.0)
	for spark in sparks:
		var endpoint: Vector2 = spark["end"] * (0.55 + (1.0 - intensity) * 0.65)
		draw_line(Vector2(0.0, -12.0), endpoint, Color(0.70, 0.95, 1.0, flicker * 0.55), float(spark["width"]), true)
