extends Node2D

const ORIGINAL_SKYLINE: Texture2D = preload("res://assets/world/skyline_far.webp")
const BACKGROUND_MODULATE := Color(0.92, 0.95, 1.0, 1.0)
const BACKGROUND_WASH := Color(0.015, 0.035, 0.055, 0.34)
const PARALLAX_RATE := 0.0

var camera: Camera2D
var last_screen_offsets: Array[float] = [0.0]
var last_camera_center := Vector2(640.0, 360.0)
var last_source_rect := Rect2(Vector2.ZERO, Vector2(1600.0, 900.0))
var last_world_rect := Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))

func _ready() -> void:
	z_index = -100
	z_as_relative = false
	queue_redraw()

func setup(active_camera: Camera2D) -> void:
	camera = active_camera
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func get_rendered_camera_center() -> Vector2:
	if is_instance_valid(camera):
		var rendered_center := camera.get_screen_center_position()
		if rendered_center.length_squared() > 0.0:
			return rendered_center
		return camera.global_position
	var view_size := get_viewport_rect().size
	return Vector2(view_size.x * 0.5, view_size.y * 0.5)

func get_layer_screen_offset(_layer_index: int = 0, _camera_x: float = NAN) -> float:
	return 0.0

func get_layer_travel(_layer_index: int, _from_camera_x: float, _to_camera_x: float) -> float:
	return 0.0

func get_visible_world_size() -> Vector2:
	var screen_size := get_viewport_rect().size
	if not is_instance_valid(camera):
		return screen_size
	return Vector2(
		screen_size.x / maxf(camera.zoom.x, 0.001),
		screen_size.y / maxf(camera.zoom.y, 0.001)
	)

func get_cover_source_rect(target_size: Vector2) -> Rect2:
	var texture_size := ORIGINAL_SKYLINE.get_size()
	if target_size.x <= 0.0 or target_size.y <= 0.0:
		return Rect2(Vector2.ZERO, texture_size)
	var source_rect := Rect2(Vector2.ZERO, texture_size)
	var texture_aspect := texture_size.x / texture_size.y
	var target_aspect := target_size.x / target_size.y
	if texture_aspect > target_aspect:
		source_rect.size.x = texture_size.y * target_aspect
		source_rect.position.x = (texture_size.x - source_rect.size.x) * 0.5
	elif texture_aspect < target_aspect:
		source_rect.size.y = texture_size.x / target_aspect
		source_rect.position.y = (texture_size.y - source_rect.size.y) * 0.5
	return source_rect

func _draw() -> void:
	var screen_size := get_viewport_rect().size
	var visible_world_size := get_visible_world_size()
	last_camera_center = get_rendered_camera_center()
	last_screen_offsets[0] = 0.0
	last_world_rect = Rect2(last_camera_center - visible_world_size * 0.5, visible_world_size)
	last_source_rect = get_cover_source_rect(screen_size)
	draw_texture_rect_region(ORIGINAL_SKYLINE, last_world_rect, last_source_rect, BACKGROUND_MODULATE)
	draw_rect(last_world_rect, BACKGROUND_WASH, true)
