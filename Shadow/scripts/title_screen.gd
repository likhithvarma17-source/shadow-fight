extends Control

const TITLE_ART: Texture2D = preload("res://assets/world/title_splash.webp")
const SaveStore = preload("res://scripts/save_store.gd")
const TUTORIAL_SCENE := "res://scenes/tutorial.tscn"
const GAME_SCENE := "res://scenes/game.tscn"
const BOSS_SCENE := "res://scenes/boss_battle.tscn"

var start_prompt: Label
var replay_tutorial_button: Button
var boss_test_button: Button
var language_button: Button
var fade_layer: ColorRect
var is_starting := false

func _ready() -> void:
	_build_title()
	get_viewport().size_changed.connect(_apply_responsive_scale)
	_apply_responsive_scale()
	fade_layer.modulate.a = 1.0
	create_tween().tween_property(fade_layer, "modulate:a", 0.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _build_title() -> void:
	var bg := TextureRect.new()
	bg.name = "TitleArt"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture = TITLE_ART
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var wash := ColorRect.new()
	wash.name = "TitleWash"
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.005, 0.012, 0.025, 0.22)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var accent := ColorRect.new()
	accent.name = "AccentRule"
	accent.position = Vector2(72, 132)
	accent.size = Vector2(3, 390)
	accent.color = Color("33e6ff")
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent)
	var glow_tween := create_tween().set_loops()
	glow_tween.tween_property(accent, "modulate:a", 0.35, 1.15)
	glow_tween.tween_property(accent, "modulate:a", 1.0, 1.15)

	var content := VBoxContainer.new()
	content.name = "TitleContent"
	content.position = Vector2(105, 142)
	content.size = Vector2(560, 430)
	content.add_theme_constant_override("separation", 18)
	add_child(content)

	var title := _label("SHADOW", 58, Color("edfaff"))
	title.name = "GameTitle"
	title.add_theme_color_override("font_shadow_color", Color("164858"))
	title.add_theme_constant_override("shadow_offset_x", 5)
	title.add_theme_constant_override("shadow_offset_y", 5)
	content.add_child(title)

	var controls := _label("移动  A D / 方向键     跳跃  K     下穿平台  S / ↓ + K\n方向 + 斩击  J / X / 点击     专注  L / Shift\n重演  R     暂停  ESC     实时调参  F1 / P", 14, Color("a9bbc2"))
	controls.name = "TitleControls"
	controls.add_theme_constant_override("line_spacing", 7)
	content.add_child(controls)

	start_prompt = _label(get_start_prompt_text(), 18, Color("7ff4ff"))
	start_prompt.name = "StartPrompt"
	start_prompt.custom_minimum_size = Vector2(360, 42)
	start_prompt.add_theme_constant_override("outline_size", 5)
	start_prompt.add_theme_color_override("font_outline_color", Color(0.0, 0.03, 0.05, 0.88))
	content.add_child(start_prompt)
	var prompt_tween := create_tween().set_loops()
	prompt_tween.tween_property(start_prompt, "modulate:a", 0.38, 0.72).set_trans(Tween.TRANS_SINE)
	prompt_tween.tween_property(start_prompt, "modulate:a", 1.0, 0.72).set_trans(Tween.TRANS_SINE)

	replay_tutorial_button = _button("剧情序章  //  从任务简报开始")
	replay_tutorial_button.name = "StoryPrologueButton"
	replay_tutorial_button.pressed.connect(_start_tutorial)
	content.add_child(replay_tutorial_button)

	boss_test_button = _button("首领测试  //  守门人")
	boss_test_button.name = "BossTestButton"
	boss_test_button.pressed.connect(_start_boss_test)
	_apply_boss_button_style(boss_test_button)
	content.add_child(boss_test_button)

	language_button = _button("中文 / English")
	language_button.name = "LanguageButton"
	language_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	language_button.position = Vector2(-282, 24)
	language_button.custom_minimum_size = Vector2(250, 42)
	add_child(language_button)
	I18n.configure_toggle(language_button)

	fade_layer = ColorRect.new()
	fade_layer.name = "TitleFade"
	fade_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_layer.color = Color("02070d")
	fade_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_layer)

func _unhandled_input(event: InputEvent) -> void:
	if is_starting:
		return
	if event is InputEventKey and event.keycode == KEY_TAB:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_start_game()
	elif event is InputEventMouseButton and event.pressed:
		_start_game()
	elif event is InputEventJoypadButton and event.pressed:
		_start_game()
	elif event is InputEventScreenTouch and event.pressed:
		_start_game()

func get_start_scene_path() -> String:
	return GAME_SCENE if SaveStore.has_completed_tutorial() else TUTORIAL_SCENE

func get_start_prompt_text() -> String:
	return "按任意键  //  继续第一关" if SaveStore.has_completed_tutorial() else "按任意键  //  开始剧情"

func _start_game() -> void:
	if is_starting:
		return
	_transition_to_scene(get_start_scene_path(), "正在进入任务……")

func _start_tutorial() -> void:
	if is_starting:
		return
	_transition_to_scene(TUTORIAL_SCENE, "正在打开剧情序章……")

func _start_boss_test() -> void:
	if is_starting:
		return
	_transition_to_scene(BOSS_SCENE, "正在进入首领测试……")

func _transition_to_scene(scene_path: String, prompt_text: String) -> void:
	is_starting = true
	start_prompt.text = prompt_text
	replay_tutorial_button.disabled = true
	boss_test_button.disabled = true
	language_button.disabled = true
	var tween := create_tween()
	tween.tween_property(fade_layer, "modulate:a", 1.0, 0.28)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))

func _apply_responsive_scale() -> void:
	var size := get_viewport_rect().size
	var scale_factor: float = clamp(size.y / 720.0, 0.72, 1.1)
	var content := get_node_or_null("TitleContent") as Control
	var accent := get_node_or_null("AccentRule") as Control
	if content:
		content.scale = Vector2.ONE * scale_factor
		content.position = Vector2(maxf(42.0, size.x * 0.075), maxf(44.0, size.y * 0.11))
	if accent:
		accent.position = Vector2(maxf(24.0, size.x * 0.05), maxf(44.0, size.y * 0.11))
		accent.size.y = minf(390.0 * scale_factor, size.y - accent.position.y - 56.0)

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.015, 0.025, 0.82))
	return label

func _button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(220, 38)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_size_override("font_size", 12)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.01, 0.055, 0.075, 0.76)
	normal.border_color = Color(0.25, 0.78, 0.85, 0.55)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("4ce9f4")
	hover.border_color = Color("94f8ff")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color("b9dfe4"))
	button.add_theme_color_override("font_hover_color", Color("06151a"))
	button.add_theme_color_override("font_focus_color", Color("06151a"))
	return button

func _apply_boss_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.018, 0.026, 0.82)
	normal.border_color = Color(0.86, 0.18, 0.24, 0.72)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("e13b49")
	hover.border_color = Color("ff8a85")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color("ffaaa3"))
	button.add_theme_color_override("font_hover_color", Color("180609"))
	button.add_theme_color_override("font_focus_color", Color("180609"))
