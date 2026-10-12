extends CanvasLayer

var root: Control
var action_buttons: Dictionary = {}

func _ready() -> void:
	layer = 30
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_make_button("move_left", "◀", Control.PRESET_BOTTOM_LEFT, Vector2(26, -98), Vector2(70, 70))
	_make_button("move_right", "▶", Control.PRESET_BOTTOM_LEFT, Vector2(108, -98), Vector2(70, 70))
	_make_button("aim_down", "▼", Control.PRESET_BOTTOM_LEFT, Vector2(190, -98), Vector2(64, 64))
	_make_button("jump", "↑", Control.PRESET_BOTTOM_RIGHT, Vector2(-272, -98), Vector2(64, 64))
	_make_button("focus", "专注", Control.PRESET_BOTTOM_RIGHT, Vector2(-196, -98), Vector2(72, 64))
	_make_button("attack", "斩击", Control.PRESET_BOTTOM_RIGHT, Vector2(-112, -108), Vector2(86, 78))
	_make_button("pause_game", "暂停", Control.PRESET_TOP_RIGHT, Vector2(-72, 24), Vector2(46, 42))
	get_viewport().size_changed.connect(_update_visibility)
	_update_visibility()

func _make_button(action: String, text_value: String, preset: int, offset: Vector2, button_size: Vector2) -> void:
	var button := Button.new()
	button.text = text_value
	button.set_anchors_preset(preset)
	button.position = offset
	button.size = button_size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	var uses_word_label := action in ["focus", "attack", "pause_game"]
	button.add_theme_font_size_override("font_size", 14 if uses_word_label else 24)
	button.add_theme_color_override("font_color", Color("bfeef4"))
	button.add_theme_color_override("font_pressed_color", Color("061319"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.02, 0.08, 0.11, 0.58)
	normal.border_color = Color(0.25, 0.82, 0.9, 0.46)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.25, 0.9, 1.0, 0.84)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.button_down.connect(_dispatch_action.bind(action, true))
	button.button_up.connect(_dispatch_action.bind(action, false))
	button.tree_exiting.connect(_dispatch_action.bind(action, false))
	root.add_child(button)
	action_buttons[action] = button

func _dispatch_action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func _update_visibility() -> void:
	root.visible = get_viewport().get_visible_rect().size.x < 1000.0 or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
