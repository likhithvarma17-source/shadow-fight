extends CanvasLayer

signal opened
signal closed

const FRAME_SIZE := Vector2(1280.0, 720.0)

var top_bar: ColorRect
var bottom_bar: ColorRect
var seam: ColorRect
var is_closed := false
var animation_serial := 0

func _ready() -> void:
	layer = 96
	process_mode = Node.PROCESS_MODE_ALWAYS
	top_bar = ColorRect.new()
	top_bar.name = "TVShutterTop"
	top_bar.color = Color.BLACK
	top_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(top_bar)
	bottom_bar = ColorRect.new()
	bottom_bar.name = "TVShutterBottom"
	bottom_bar.color = Color.BLACK
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bottom_bar)
	seam = ColorRect.new()
	seam.name = "TVShutterSeam"
	seam.color = Color(0.72, 0.9, 0.92, 0.0)
	seam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(seam)
	set_closed(false)

func set_closed(closed_state: bool) -> void:
	is_closed = closed_state
	if not is_instance_valid(top_bar):
		return
	var half_height := FRAME_SIZE.y * 0.5 if closed_state else 0.0
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(FRAME_SIZE.x, half_height)
	bottom_bar.position = Vector2(0.0, FRAME_SIZE.y - half_height)
	bottom_bar.size = Vector2(FRAME_SIZE.x, half_height)
	seam.position = Vector2(0.0, FRAME_SIZE.y * 0.5 - 1.0)
	seam.size = Vector2(FRAME_SIZE.x, 2.0)
	seam.color.a = 0.0

func get_bar_height_for_aspect(aspect_ratio: float) -> float:
	var safe_aspect := maxf(aspect_ratio, FRAME_SIZE.x / FRAME_SIZE.y)
	var content_height := FRAME_SIZE.x / safe_aspect
	return maxf(0.0, (FRAME_SIZE.y - content_height) * 0.5)

func set_aspect_ratio(aspect_ratio: float) -> void:
	animation_serial += 1
	is_closed = false
	_apply_bar_height(get_bar_height_for_aspect(aspect_ratio))
	seam.color.a = 0.0

func open_to_aspect(aspect_ratio: float, duration: float = 0.52) -> void:
	animation_serial += 1
	var serial := animation_serial
	is_closed = false
	var target_height := get_bar_height_for_aspect(aspect_ratio)
	var tween := create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(top_bar, "size:y", target_height, duration)
	tween.tween_property(bottom_bar, "position:y", FRAME_SIZE.y - target_height, duration)
	tween.tween_property(bottom_bar, "size:y", target_height, duration)
	seam.color.a = 0.65
	tween.tween_property(seam, "color:a", 0.0, duration * 0.72)
	await tween.finished
	if serial == animation_serial:
		opened.emit()

func _apply_bar_height(bar_height: float) -> void:
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(FRAME_SIZE.x, bar_height)
	bottom_bar.position = Vector2(0.0, FRAME_SIZE.y - bar_height)
	bottom_bar.size = Vector2(FRAME_SIZE.x, bar_height)
	seam.position = Vector2(0.0, FRAME_SIZE.y * 0.5 - 1.0)
	seam.size = Vector2(FRAME_SIZE.x, 2.0)

func open_screen(duration: float = 0.52) -> void:
	animation_serial += 1
	var serial := animation_serial
	is_closed = false
	var tween := create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(top_bar, "size:y", 0.0, duration)
	tween.tween_property(bottom_bar, "position:y", FRAME_SIZE.y, duration)
	tween.tween_property(bottom_bar, "size:y", 0.0, duration)
	seam.color.a = 0.65
	tween.tween_property(seam, "color:a", 0.0, duration * 0.72)
	await tween.finished
	if serial == animation_serial:
		opened.emit()

func close_screen(duration: float = 0.48) -> void:
	animation_serial += 1
	var serial := animation_serial
	is_closed = true
	var half_height := FRAME_SIZE.y * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(top_bar, "size:y", half_height, duration)
	tween.tween_property(bottom_bar, "position:y", half_height, duration)
	tween.tween_property(bottom_bar, "size:y", half_height, duration)
	seam.color.a = 0.0
	tween.tween_property(seam, "color:a", 0.72, duration * 0.82)
	await tween.finished
	if serial == animation_serial:
		seam.color.a = 0.0
		closed.emit()
