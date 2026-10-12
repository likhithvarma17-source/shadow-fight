extends CanvasLayer

signal sequence_finished

const FRAME_SIZE := Vector2(1280.0, 720.0)
const TYPE_SPEED := 34.0
const BRIEFING_BACKGROUND: Texture2D = preload("res://assets/story/briefing_flip_phone.webp")
const DialogueTypewriter = preload("res://scripts/dialogue_typewriter.gd")

var overlay: Control
var background: TextureRect
var text_column: Control
var speaker_label: Label
var message_label: Label
var progress_label: Label
var hint_label: Label
var typewriter: Node

var typing: bool:
	get:
		return is_instance_valid(typewriter) and typewriter.typing
	set(value):
		if not value and is_instance_valid(typewriter):
			typewriter.reveal_immediately()

func _ready() -> void:
	layer = 78
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	typewriter = DialogueTypewriter.new()
	typewriter.name = "BriefingTypewriter"
	add_child(typewriter)
	visible = false

func present_line(entry: Dictionary, index: int = 0, total: int = 1) -> void:
	_prepare_line(entry, index, total)
	typewriter.begin_line(message_label, hint_label, message_label.text, TYPE_SPEED)

func _prepare_line(entry: Dictionary, index: int, total: int) -> void:
	speaker_label.text = String(entry.get("speaker", "加密委托"))
	message_label.text = String(entry.get("text", ""))
	progress_label.text = "%02d / %02d" % [index + 1, total]

func play_sequence(entries: Array[Dictionary]) -> void:
	visible = true
	for index in range(entries.size()):
		_prepare_line(entries[index], index, entries.size())
		await typewriter.play_line(message_label, hint_label, message_label.text, TYPE_SPEED)
	sequence_finished.emit()

func request_advance() -> void:
	if is_instance_valid(typewriter):
		typewriter.request_advance()

func _build_ui() -> void:
	overlay = Control.new()
	overlay.name = "PhoneBriefingOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	background = TextureRect.new()
	background.name = "BriefingPhoneBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = BRIEFING_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(background)

	var cinematic_wash := ColorRect.new()
	cinematic_wash.name = "CinematicWash"
	cinematic_wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cinematic_wash.color = Color(0.0, 0.012, 0.022, 0.22)
	cinematic_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(cinematic_wash)

	var left_fade := TextureRect.new()
	left_fade.name = "BriefingTextFade"
	left_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_fade.texture = _make_left_fade_texture()
	left_fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(left_fade)

	text_column = Control.new()
	text_column.name = "BriefingTextColumn"
	text_column.position = Vector2(76.0, 48.0)
	text_column.size = Vector2(620.0, 570.0)
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(text_column)

	var accent := ColorRect.new()
	accent.position = Vector2.ZERO
	accent.size = Vector2(3.0, 520.0)
	accent.color = Color("66d9d2")
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_child(accent)

	var eyebrow := _label("加密频道  //  凌晨 02:13", 13, Color("7aa29f"))
	eyebrow.position = Vector2(24.0, 0.0)
	eyebrow.size = Vector2(570.0, 28.0)
	text_column.add_child(eyebrow)

	var title := _label("收到委托", 32, Color("e5f4ef"))
	title.position = Vector2(24.0, 36.0)
	title.size = Vector2(570.0, 52.0)
	text_column.add_child(title)

	var rule := ColorRect.new()
	rule.position = Vector2(24.0, 102.0)
	rule.size = Vector2(560.0, 1.0)
	rule.color = Color(0.40, 0.73, 0.70, 0.52)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_child(rule)

	speaker_label = _label("加密委托", 14, Color("ef9e6e"))
	speaker_label.name = "BriefingSpeaker"
	speaker_label.position = Vector2(24.0, 142.0)
	speaker_label.size = Vector2(560.0, 30.0)
	text_column.add_child(speaker_label)

	message_label = _label("", 28, Color("f4faf6"))
	message_label.name = "BriefingMessage"
	message_label.position = Vector2(24.0, 184.0)
	message_label.size = Vector2(560.0, 220.0)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_constant_override("line_spacing", 10)
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text_column.add_child(message_label)

	progress_label = _label("01 / 06", 12, Color("79aaa5"))
	progress_label.name = "BriefingProgress"
	progress_label.position = Vector2(24.0, 454.0)
	progress_label.size = Vector2(560.0, 24.0)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_column.add_child(progress_label)

	hint_label = _label("J  //  继续", 12, Color("8fd6cf"))
	hint_label.name = "BriefingAdvanceHint"
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_label.position = Vector2(-320.0, -54.0)
	hint_label.size = Vector2(260.0, 24.0)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.visible = false
	overlay.add_child(hint_label)

	var input_catcher := ColorRect.new()
	input_catcher.name = "BriefingInputCatcher"
	input_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	input_catcher.color = Color.TRANSPARENT
	input_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(input_catcher)

func _make_left_fade_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.42, 0.66, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.0, 0.008, 0.014, 0.78),
		Color(0.0, 0.008, 0.014, 0.62),
		Color(0.0, 0.008, 0.014, 0.18),
		Color.TRANSPARENT,
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = int(FRAME_SIZE.x)
	texture.height = int(FRAME_SIZE.y)
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.01, 0.01, 0.95))
	return label
