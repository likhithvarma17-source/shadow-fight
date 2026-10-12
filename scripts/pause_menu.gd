extends CanvasLayer

signal pause_requested
signal resumed
signal restart_requested
signal tutorial_requested
signal title_requested
signal pause_changed(paused: bool)

var overlay: Control
var panel: ColorRect
var resume_button: Button
var restart_button: Button
var tutorial_button: Button
var title_button: Button
var language_button: Button

func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_menu()

func _build_menu() -> void:
	overlay = Control.new()
	overlay.name = "PauseOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.002, 0.008, 0.014, 0.70)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

	panel = ColorRect.new()
	panel.name = "PausePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-230, -300)
	panel.size = Vector2(460, 600)
	panel.color = Color(0.012, 0.035, 0.048, 0.95)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(panel)

	var top_rule := ColorRect.new()
	top_rule.position = Vector2(0, 0)
	top_rule.size = Vector2(460, 3)
	top_rule.color = Color("39e6ff")
	panel.add_child(top_rule)

	var content := VBoxContainer.new()
	content.position = Vector2(52, 34)
	content.size = Vector2(356, 532)
	content.add_theme_constant_override("separation", 13)
	panel.add_child(content)

	var eyebrow := _label("系统中断", 13, Color("69d9e9"))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(eyebrow)
	var title := _label("已暂停", 48, Color("eefcff"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var status := _label("时间已经冻结。计划仍然完整。", 14, Color("9bb0b7"))
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.custom_minimum_size.y = 44
	content.add_child(status)
	var separator := HSeparator.new()
	separator.add_theme_color_override("separator", Color(0.25, 0.8, 0.9, 0.28))
	content.add_child(separator)

	resume_button = _button("继续游戏", true)
	resume_button.name = "ResumeButton"
	resume_button.pressed.connect(resume_game)
	content.add_child(resume_button)
	restart_button = _button("重新开始本关")
	restart_button.name = "RestartButton"
	restart_button.pressed.connect(_restart)
	content.add_child(restart_button)
	tutorial_button = _button("重玩剧情序章")
	tutorial_button.name = "PauseTutorialButton"
	tutorial_button.pressed.connect(_replay_tutorial)
	content.add_child(tutorial_button)
	title_button = _button("返回标题画面")
	title_button.name = "PauseTitleButton"
	title_button.pressed.connect(_return_to_title)
	content.add_child(title_button)

	language_button = _button("中文 / English")
	language_button.name = "PauseLanguageButton"
	content.add_child(language_button)
	I18n.configure_toggle(language_button)

	var footer := _label("ESC  //  继续游戏", 11, Color("607983"))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(footer)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if overlay.visible:
		resume_game()
	else:
		pause_requested.emit()

func show_menu() -> void:
	if overlay.visible:
		return
	overlay.visible = true
	get_tree().paused = true
	resume_button.grab_focus()
	pause_changed.emit(true)

func resume_game() -> void:
	if not overlay.visible:
		return
	overlay.visible = false
	get_tree().paused = false
	pause_changed.emit(false)
	resumed.emit()

func _restart() -> void:
	_close_for_action()
	restart_requested.emit()

func _return_to_title() -> void:
	_close_for_action()
	title_requested.emit()

func _replay_tutorial() -> void:
	_close_for_action()
	tutorial_requested.emit()

func _close_for_action() -> void:
	overlay.visible = false
	get_tree().paused = false
	pause_changed.emit(false)

func is_open() -> bool:
	return is_instance_valid(overlay) and overlay.visible

func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false

func _button(text_value: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(356, 52)
	button.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("173943") if primary else Color("0c2029")
	normal.border_color = Color("47dbea") if primary else Color("315a65")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("52e7f4")
	hover.border_color = Color("8ff5ff")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("ffad66")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("d9f8fb"))
	button.add_theme_color_override("font_hover_color", Color("051217"))
	button.add_theme_color_override("font_focus_color", Color("051217"))
	button.add_theme_color_override("font_pressed_color", Color("071319"))
	return button

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.01, 0.02, 0.86))
	return label
