extends CanvasLayer

signal sequence_finished
signal exit_requested

const StoryStore = preload("res://scripts/story_store.gd")
const FRAME_SIZE := Vector2(1280.0, 720.0)
const PANEL_TEXTURES: Array[Texture2D] = [
	preload("res://assets/story/post_boss/panel_01_warehouse.webp"),
	preload("res://assets/story/post_boss/panel_02_crate.webp"),
	preload("res://assets/story/post_boss/panel_03_blade.webp"),
	preload("res://assets/story/post_boss/panel_04_cat.webp")
]
const DEFAULT_SLIDES: Array[Dictionary] = [
	{
		"panel": 0,
		"chapter": "第二幕  //  货物",
		"caption": "旧电站地下仓库。\n委托目标就在那盏灯下。",
		"duration": 3.1,
		"start_scale": 1.02,
		"end_scale": 1.10,
		"start_offset": Vector2(-14.0, 0.0),
		"end_offset": Vector2(26.0, -4.0)
	},
	{
		"panel": 1,
		"chapter": "目标确认",
		"caption": "没有编号，没有警告。\n只有一只潮湿的木箱。",
		"duration": 2.8,
		"start_scale": 1.08,
		"end_scale": 1.02,
		"start_offset": Vector2(24.0, 0.0),
		"end_offset": Vector2(-10.0, 0.0)
	},
	{
		"panel": 2,
		"chapter": "执行委托",
		"caption": "影拔出刀。\n任务只剩最后一下。",
		"duration": 2.7,
		"start_scale": 1.01,
		"end_scale": 1.09,
		"start_offset": Vector2(-8.0, 4.0),
		"end_offset": Vector2(18.0, -8.0)
	},
	{
		"panel": 2,
		"chapter": "……",
		"caption": "——喵。",
		"duration": 1.55,
		"start_scale": 1.09,
		"end_scale": 1.12,
		"start_offset": Vector2(18.0, -8.0),
		"end_offset": Vector2(12.0, -10.0)
	},
	{
		"panel": 3,
		"chapter": "货物",
		"caption": "箱盖缓缓弹开。\n里面的东西正在发抖。",
		"duration": 3.6,
		"start_scale": 1.01,
		"end_scale": 1.10,
		"start_offset": Vector2(16.0, 0.0),
		"end_offset": Vector2(-22.0, -7.0)
	}
]
const SLIDE_PRESET_INDICES := {
	"warehouse": 0,
	"crate": 1,
	"blade": 2,
	"blade_hold": 3,
	"cat": 4
}

var overlay: Control
var black: ColorRect
var panel: TextureRect
var panel_shade: ColorRect
var chapter_rule: ColorRect
var chapter_label: Label
var caption_back: ColorRect
var caption_label: Label
var counter_label: Label
var skip_label: Label
var final_title: Label
var final_hint: Label
var playing := false
var complete := false
var advance_requested := false
var current_slide_index := -1
var presentation_scale := 1.0
var slides: Array[Dictionary] = []

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	slides = _load_story_slides()
	_build_ui()
	visible = false

func _load_story_slides() -> Array[Dictionary]:
	var configured: Array[Dictionary] = StoryStore.get_scene("post_boss_epilogue")
	var resolved: Array[Dictionary] = []
	for entry in configured:
		var target := String(entry.get("target", ""))
		if not SLIDE_PRESET_INDICES.has(target):
			continue
		var preset_index: int = int(SLIDE_PRESET_INDICES[target])
		var slide: Dictionary = DEFAULT_SLIDES[preset_index].duplicate(true)
		slide["chapter"] = String(entry.get("speaker", slide["chapter"]))
		slide["caption"] = String(entry.get("text", slide["caption"]))
		slide["duration"] = maxf(0.0, float(entry.get("duration", slide["duration"])))
		resolved.append(slide)
	if resolved.is_empty():
		return DEFAULT_SLIDES.duplicate(true)
	return resolved

func _build_ui() -> void:
	overlay = Control.new()
	overlay.name = "PostBossCinematicOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	black = ColorRect.new()
	black.name = "CinematicBlack"
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.color = Color.BLACK
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(black)

	panel = TextureRect.new()
	panel.name = "ComicPanel"
	panel.position = Vector2.ZERO
	panel.size = FRAME_SIZE
	panel.pivot_offset = FRAME_SIZE * 0.5
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(panel)

	panel_shade = ColorRect.new()
	panel_shade.name = "PanelShade"
	panel_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_shade.color = Color(0.0, 0.0, 0.0, 0.08)
	panel_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(panel_shade)

	chapter_rule = ColorRect.new()
	chapter_rule.position = Vector2(42.0, 42.0)
	chapter_rule.size = Vector2(4.0, 52.0)
	chapter_rule.color = Color("48dff1")
	chapter_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(chapter_rule)

	chapter_label = _label("第二幕  //  货物", 15, Color("c7f6fb"))
	chapter_label.name = "ComicChapter"
	chapter_label.position = Vector2(62.0, 46.0)
	chapter_label.size = Vector2(520.0, 40.0)
	overlay.add_child(chapter_label)

	caption_back = ColorRect.new()
	caption_back.name = "ComicCaptionBack"
	caption_back.position = Vector2(42.0, 548.0)
	caption_back.size = Vector2(650.0, 126.0)
	caption_back.color = Color(0.015, 0.025, 0.035, 0.90)
	caption_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(caption_back)
	var caption_rule := ColorRect.new()
	caption_rule.position = Vector2.ZERO
	caption_rule.size = Vector2(5.0, 126.0)
	caption_rule.color = Color("48dff1")
	caption_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption_back.add_child(caption_rule)

	caption_label = _label("", 24, Color("f2f6f5"))
	caption_label.name = "ComicCaption"
	caption_label.position = Vector2(25.0, 17.0)
	caption_label.size = Vector2(600.0, 92.0)
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption_back.add_child(caption_label)

	counter_label = _label("01 / 05", 13, Color("91b7bc"))
	counter_label.name = "ComicCounter"
	counter_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	counter_label.position = Vector2(-178.0, -73.0)
	counter_label.size = Vector2(126.0, 30.0)
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	overlay.add_child(counter_label)

	skip_label = _label("按任意键  //  下一幕", 12, Color("6f8d92"))
	skip_label.name = "ComicAdvanceHint"
	skip_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_label.position = Vector2(-278.0, -44.0)
	skip_label.size = Vector2(226.0, 26.0)
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	overlay.add_child(skip_label)

	final_title = _label("未完待续……", 42, Color("e9f8f6"))
	final_title.name = "ToBeContinued"
	final_title.set_anchors_preset(Control.PRESET_CENTER)
	final_title.position = Vector2(-360.0, -52.0)
	final_title.size = Vector2(720.0, 72.0)
	final_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_title.visible = false
	overlay.add_child(final_title)

	final_hint = _label("按任意键返回标题画面", 13, Color("587276"))
	final_hint.name = "EpilogueExitHint"
	final_hint.set_anchors_preset(Control.PRESET_CENTER)
	final_hint.position = Vector2(-220.0, 42.0)
	final_hint.size = Vector2(440.0, 30.0)
	final_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_hint.visible = false
	overlay.add_child(final_hint)

func play_sequence() -> void:
	slides = _load_story_slides()
	visible = true
	playing = true
	complete = false
	advance_requested = false
	final_title.visible = false
	final_hint.visible = false
	panel.visible = true
	panel_shade.visible = true
	chapter_rule.visible = true
	chapter_label.visible = true
	caption_back.visible = true
	counter_label.visible = true
	skip_label.visible = true
	for index in range(slides.size()):
		await _present_slide(index)
	await _present_final()
	playing = false
	complete = true
	sequence_finished.emit()

func _present_slide(index: int) -> void:
	current_slide_index = index
	advance_requested = false
	var slide: Dictionary = slides[index]
	panel.texture = PANEL_TEXTURES[int(slide["panel"])]
	chapter_label.text = String(slide["chapter"])
	caption_label.text = String(slide["caption"])
	counter_label.text = "%02d / %02d" % [index + 1, slides.size()]
	panel.scale = Vector2.ONE * float(slide["start_scale"])
	panel.position = Vector2(slide["start_offset"])
	panel.modulate.a = 0.0
	chapter_label.modulate.a = 0.0
	caption_back.modulate.a = 0.0
	counter_label.modulate.a = 0.0
	skip_label.modulate.a = 0.0
	var fade_in := create_tween().set_parallel(true)
	fade_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(panel, "modulate:a", 1.0, 0.28 * presentation_scale)
	fade_in.tween_property(chapter_label, "modulate:a", 1.0, 0.34 * presentation_scale)
	fade_in.tween_property(caption_back, "modulate:a", 1.0, 0.34 * presentation_scale)
	fade_in.tween_property(counter_label, "modulate:a", 1.0, 0.34 * presentation_scale)
	fade_in.tween_property(skip_label, "modulate:a", 1.0, 0.34 * presentation_scale)
	await fade_in.finished

	var movement := create_tween().set_parallel(true)
	movement.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	movement.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var duration := float(slide["duration"]) * presentation_scale
	movement.tween_property(panel, "scale", Vector2.ONE * float(slide["end_scale"]), duration)
	movement.tween_property(panel, "position", Vector2(slide["end_offset"]), duration)
	var elapsed_time := 0.0
	while elapsed_time < duration and not advance_requested:
		elapsed_time += get_process_delta_time()
		await get_tree().process_frame
	if movement.is_running():
		movement.kill()

	var fade_out := create_tween().set_parallel(true)
	fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(panel, "modulate:a", 0.0, 0.24 * presentation_scale)
	fade_out.tween_property(chapter_label, "modulate:a", 0.0, 0.18 * presentation_scale)
	fade_out.tween_property(caption_back, "modulate:a", 0.0, 0.18 * presentation_scale)
	fade_out.tween_property(counter_label, "modulate:a", 0.0, 0.18 * presentation_scale)
	fade_out.tween_property(skip_label, "modulate:a", 0.0, 0.18 * presentation_scale)
	await fade_out.finished

func _present_final() -> void:
	current_slide_index = slides.size()
	panel.visible = false
	panel_shade.visible = false
	chapter_rule.visible = false
	chapter_label.visible = false
	caption_back.visible = false
	counter_label.visible = false
	skip_label.visible = false
	black.color = Color.BLACK
	final_title.visible = true
	final_title.modulate.a = 0.0
	final_hint.visible = true
	final_hint.modulate.a = 0.0
	var reveal := create_tween().set_parallel(true)
	reveal.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	reveal.tween_property(final_title, "modulate:a", 1.0, 0.75 * presentation_scale)
	reveal.tween_property(final_hint, "modulate:a", 1.0, 0.50 * presentation_scale).set_delay(0.65 * presentation_scale)
	await reveal.finished

func show_slide_preview(index: int) -> void:
	slides = _load_story_slides()
	visible = true
	playing = false
	complete = false
	current_slide_index = clampi(index, 0, slides.size() - 1)
	var slide: Dictionary = slides[current_slide_index]
	panel.visible = true
	panel.texture = PANEL_TEXTURES[int(slide["panel"])]
	panel.scale = Vector2.ONE * float(slide["end_scale"])
	panel.position = Vector2(slide["end_offset"])
	panel.modulate.a = 1.0
	panel_shade.visible = true
	chapter_rule.visible = true
	chapter_label.visible = true
	chapter_label.text = String(slide["chapter"])
	chapter_label.modulate.a = 1.0
	caption_back.visible = true
	caption_back.modulate.a = 1.0
	caption_label.text = String(slide["caption"])
	counter_label.visible = true
	counter_label.modulate.a = 1.0
	counter_label.text = "%02d / %02d" % [current_slide_index + 1, slides.size()]
	skip_label.visible = true
	skip_label.modulate.a = 1.0
	final_title.visible = false
	final_hint.visible = false

func show_final_preview() -> void:
	if slides.is_empty():
		slides = _load_story_slides()
	visible = true
	playing = false
	complete = true
	current_slide_index = slides.size()
	panel.visible = false
	panel_shade.visible = false
	chapter_rule.visible = false
	chapter_label.visible = false
	caption_back.visible = false
	counter_label.visible = false
	skip_label.visible = false
	final_title.visible = true
	final_title.modulate.a = 1.0
	final_hint.visible = true
	final_hint.modulate.a = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed():
		return
	if event is InputEventKey and event.echo:
		return
	if complete:
		exit_requested.emit()
	elif playing:
		advance_requested = true
	get_viewport().set_input_as_handled()

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
