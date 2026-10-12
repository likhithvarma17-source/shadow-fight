extends CanvasLayer

const TuningStore = preload("res://scripts/tuning_store.gd")

const TAB_DEFINITIONS := [
		{
			"id": "Player",
			"title": "角色",
		"sections": [
			{
					"title": "移动",
				"controls": [
						["run_speed", "奔跑速度", 180.0, 480.0, 5.0, "像素/秒"],
						["acceleration", "加速度", 700.0, 3200.0, 50.0, ""],
						["gravity", "重力", 800.0, 2300.0, 20.0, ""],
						["jump_force", "跳跃力度", 480.0, 1000.0, 10.0, ""],
						["jump_launch_multiplier", "起跳速度", 0.80, 1.60, 0.05, "倍"],
						["jump_rise_gravity_multiplier", "上升重力", 0.80, 2.20, 0.05, "倍"],
						["jump_fall_gravity_multiplier", "下落重力", 0.80, 2.20, 0.05, "倍"],
						["jump_animation_fps", "跳跃动画", 8.0, 36.0, 1.0, "帧/秒"]
				]
			},
			{
					"title": "专注",
				"controls": [
						["focus_drain", "专注消耗", 5.0, 55.0, 1.0, "/秒"],
						["focus_regen", "专注恢复", 3.0, 40.0, 1.0, "/秒"]
				]
			}
		]
	},
	{
		"id": "Combat",
			"title": "战斗",
		"sections": [
			{
					"title": "攻击动作",
				"controls": [
						["attack_cooldown", "攻击冷却", 0.12, 0.80, 0.01, "秒"],
						["slash_dash_distance", "斩击突进距离", 0.0, 420.0, 5.0, "像素"],
						["slash_dash_speed", "斩击突进速度", 500.0, 2200.0, 25.0, "像素/秒"]
				]
			},
			{
					"title": "攻击判定框",
				"controls": [
						["attack_hitbox_forward", "向前长度", 50.0, 220.0, 2.0, "像素"],
						["attack_hitbox_back", "向后长度", 0.0, 60.0, 1.0, "像素"],
						["attack_hitbox_height", "总高度", 30.0, 150.0, 2.0, "像素"]
				]
			},
			{
					"title": "角色受击框",
				"controls": [
						["player_hurtbox_width", "身体宽度", 20.0, 44.0, 1.0, "像素"],
						["player_hurtbox_height", "身体高度", 48.0, 100.0, 1.0, "像素"]
				]
			},
			{
					"title": "弹反反馈 // 全场景",
				"controls": [
						["melee_parry_slow_duration", "弹反慢放时长", 0.0, 2.0, 0.05, "秒"],
						["melee_parry_time_scale", "弹反时间倍率", 0.10, 1.0, 0.05, "倍"],
						["parry_zoom_amount", "中心缩放强度", 0.0, 0.25, 0.01, "倍"],
						["parry_zoom_duration", "中心缩放时长", 0.0, 0.80, 0.02, "秒"]
				]
			}
		]
	},
	{
		"id": "Enemies",
				"title": "敌人",
			"sections": [
				{
						"title": "通用敌人受击框",
					"controls": [
							["enemy_hurtbox_width", "身体宽度", 18.0, 50.0, 1.0, "像素"],
							["enemy_hurtbox_height", "身体高度", 50.0, 120.0, 1.0, "像素"]
					]
				},
				{
						"title": "持刀打手",
				"controls": [
						["blade_move_speed", "追击速度", 40.0, 240.0, 2.0, "像素/秒"],
						["blade_patrol_speed", "巡逻速度", 10.0, 120.0, 2.0, "像素/秒"],
						["blade_aggression", "攻击欲望", 0.35, 2.50, 0.05, "倍"],
						["blade_alert_range", "警戒范围", 220.0, 1100.0, 10.0, "像素"]
				]
			},
				{
						"title": "枪手",
					"controls": [
							["gunner_patrol_speed", "巡逻速度", 10.0, 120.0, 2.0, "像素/秒"],
							["gunner_aggression", "攻击欲望", 0.35, 2.50, 0.05, "倍"],
							["gunner_alert_range", "警戒范围", 300.0, 1500.0, 10.0, "像素"],
							["gunner_projectile_speed", "子弹速度", 240.0, 1000.0, 10.0, "像素/秒"]
					]
				},
					{
							"title": "守门人 // 首领难度",
						"controls": [
							["boss_max_health", "生命格数", 8.0, 40.0, 1.0, "格"],
							["boss_katana_damage", "斩击伤害", 1.0, 6.0, 1.0, "格"],
							["boss_melee_parry_damage", "弹刀伤害", 1.0, 8.0, 1.0, "格"],
						["boss_reflected_damage", "反弹子弹伤害", 1.0, 6.0, 1.0, "格"],
						["boss_action_interval", "招式间隔", 0.30, 1.20, 0.02, "秒"],
					["boss_dash_speed", "逼近速度", 500.0, 1600.0, 20.0, "像素/秒"],
					["boss_projectile_speed", "连射速度", 380.0, 1100.0, 10.0, "像素/秒"]
				]
				}
		]
	},
	{
		"id": "AudioVisual",
				"title": "视听",
			"sections": [
				{
						"title": "摄像机",
					"controls": [
							["camera_distance", "摄像机距离", 0.75, 1.60, 0.05, "倍"]
					]
				},
				{
						"title": "角色轮廓光",
				"controls": [
						["rim_width", "轮廓粗细", 0.5, 8.0, 0.1, "像素"],
						["rim_brightness", "轮廓亮度", 0.0, 1.5, 0.05, "倍"]
				]
			},
			{
					"title": "音频混合",
				"controls": [
						["bgm_volume_db", "背景音乐音量", -36.0, 3.0, 0.5, "分贝"],
						["sfx_volume_db", "音效音量偏移", -24.0, 6.0, 0.5, "分贝"],
						["rain_volume_db", "雨声音量", -40.0, 0.0, 0.5, "分贝"]
				]
			}
		]
	}
]

var panel: PanelContainer
var value_labels: Dictionary = {}
var value_suffixes: Dictionary = {}
var export_status: Label
var last_export_path := ""
var tab_buttons: Array[Button] = []
var tab_pages: Array[Control] = []
var tab_scrolls: Array[ScrollContainer] = []
var active_tab := 0
var tab_group: ButtonGroup

func _ready() -> void:
	layer = 90
	_build_panel()
	panel.visible = false
	I18n.language_changed.connect(_refresh_localized_values)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_F1 or event.keycode == KEY_P):
		panel.visible = not panel.visible
		get_viewport().set_input_as_handled()

func _build_panel() -> void:
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-524, 18)
	panel.size = Vector2(500, 684)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.032, 0.046, 0.98)
	style.border_color = Color("247c8b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 7)
	margin.add_child(shell)

	var title := Label.new()
	title.text = "实时调参  //  F1 或 P"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("54e8f8"))
	shell.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "面板打开时显示判定框；鼠标滚轮只滚动页面。"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color("78939c"))
	shell.add_child(subtitle)

	tab_group = ButtonGroup.new()
	tab_group.allow_unpress = false
	var tab_bar := HBoxContainer.new()
	tab_bar.name = "TweakTabBar"
	tab_bar.add_theme_constant_override("separation", 4)
	shell.add_child(tab_bar)

	var page_host := VBoxContainer.new()
	page_host.name = "TweakPageHost"
	page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(page_host)

	for tab_index in range(TAB_DEFINITIONS.size()):
		var tab_data: Dictionary = TAB_DEFINITIONS[tab_index]
		var tab_button := _make_tab_button(String(tab_data["id"]), String(tab_data["title"]))
		tab_button.button_group = tab_group
		var captured_index := tab_index
		tab_button.pressed.connect(func(): select_tab(captured_index))
		tab_bar.add_child(tab_button)
		tab_buttons.append(tab_button)

		var scroll := ScrollContainer.new()
		scroll.name = "TweakScroll%s" % String(tab_data["id"])
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page_host.add_child(scroll)
		tab_pages.append(scroll)
		tab_scrolls.append(scroll)

		var content := VBoxContainer.new()
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_theme_constant_override("separation", 7)
		scroll.add_child(content)
		for section in tab_data["sections"]:
			_add_section(content, String(section["title"]), section["controls"])

	var footer_line := HSeparator.new()
	shell.add_child(footer_line)

	var footer_actions := HBoxContainer.new()
	footer_actions.add_theme_constant_override("separation", 8)
	shell.add_child(footer_actions)

	var export_button := Button.new()
	export_button.name = "ExportTweaksButton"
	export_button.text = "导出调参文件"
	export_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export_button.custom_minimum_size.y = 38
	var export_normal := StyleBoxFlat.new()
	export_normal.bg_color = Color("15343d")
	export_normal.border_color = Color("35d9eb")
	export_normal.set_border_width_all(1)
	export_normal.set_corner_radius_all(3)
	var export_hover := export_normal.duplicate() as StyleBoxFlat
	export_hover.bg_color = Color("35d9eb")
	export_button.add_theme_stylebox_override("normal", export_normal)
	export_button.add_theme_stylebox_override("hover", export_hover)
	export_button.add_theme_color_override("font_hover_color", Color("071319"))
	export_button.pressed.connect(_export_values)
	footer_actions.add_child(export_button)

	var reset_button := Button.new()
	reset_button.name = "ResetTweaksButton"
	reset_button.text = "恢复默认值"
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_button.custom_minimum_size.y = 38
	reset_button.pressed.connect(_reset_values)
	footer_actions.add_child(reset_button)

	export_status = Label.new()
	export_status.name = "ExportStatus"
	export_status.text = "导出的调参文件包含全部分页。"
	export_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	export_status.add_theme_font_size_override("font_size", 10)
	export_status.add_theme_color_override("font_color", Color("78939c"))
	shell.add_child(export_status)

	select_tab(0)

func _make_tab_button(tab_id: String, label_text: String) -> Button:
	var button := Button.new()
	button.name = "TweakTab%s" % tab_id
	button.text = label_text
	button.toggle_mode = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 36
	button.add_theme_font_size_override("font_size", 10)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.02, 0.07, 0.09, 0.74)
	normal.border_color = Color(0.18, 0.36, 0.40, 0.72)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.04, 0.13, 0.16, 0.92)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.07, 0.23, 0.27, 0.98)
	pressed.border_color = Color("54e8f8")
	pressed.set_border_width(SIDE_BOTTOM, 3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("78939c"))
	button.add_theme_color_override("font_hover_color", Color("c6f7fb"))
	button.add_theme_color_override("font_pressed_color", Color("ffffff"))
	return button

func select_tab(tab_index: int) -> void:
	active_tab = clampi(tab_index, 0, tab_pages.size() - 1)
	for index in range(tab_pages.size()):
		tab_pages[index].visible = index == active_tab
		tab_buttons[index].button_pressed = index == active_tab

func get_active_scroll() -> ScrollContainer:
	return tab_scrolls[active_tab]

func _add_section(parent: VBoxContainer, title_text: String, controls: Array) -> void:
	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", Color("ffae63"))
	heading.add_theme_constant_override("outline_size", 3)
	heading.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	heading.custom_minimum_size.y = 27
	heading.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	parent.add_child(heading)
	for data in controls:
		_add_control(parent, String(data[0]), String(data[1]), float(data[2]), float(data[3]), float(data[4]), String(data[5]))

func _add_control(parent: VBoxContainer, key: String, display_name: String, minimum: float, maximum: float, step: float, suffix: String) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = display_name
	label.custom_minimum_size.x = 240
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("a8bbc2"))
	row.add_child(label)
	var value_label := Label.new()
	value_label.text = _format_value(TuningStore.get_value(key), suffix)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 11)
	value_label.add_theme_color_override("font_color", Color("ffcf8b"))
	row.add_child(value_label)
	parent.add_child(row)
	value_labels[key] = value_label
	value_suffixes[key] = suffix

	var slider := HSlider.new()
	slider.name = key
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = TuningStore.get_value(key)
	slider.scrollable = false
	slider.custom_minimum_size.y = 18
	slider.value_changed.connect(func(value: float):
		TuningStore.set_value(key, value)
		value_label.text = _format_value(value, suffix)
	)
	parent.add_child(slider)

func _reset_values() -> void:
	TuningStore.reset()
	for tab_data in TAB_DEFINITIONS:
		for section in tab_data["sections"]:
			for data in section["controls"]:
				var key := String(data[0])
				var slider := panel.find_child(key, true, false) as HSlider
				if slider:
					slider.value = TuningStore.get_value(key)
					value_labels[key].text = _format_value(slider.value, String(value_suffixes[key]))
	export_status.text = "四个分页均已恢复默认值。"

func _export_values() -> String:
	var file_name := "ying-tweaks-v%d.json" % TuningStore.CONFIG_VERSION
	var json_text := TuningStore.export_json()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(json_text.to_utf8_buffer(), file_name, "application/json")
		last_export_path = "download://%s" % file_name
		export_status.text = "调参文件已下载。"
	else:
		last_export_path = "user://%s" % file_name
		var file := FileAccess.open(last_export_path, FileAccess.WRITE)
		if file == null:
			last_export_path = ""
			export_status.text = "导出失败  //  请重试"
			return last_export_path
		file.store_string(json_text)
		file.close()
		export_status.text = "调参文件已保存。"
	return last_export_path

func _format_value(value: float, suffix: String) -> String:
	var rounded := roundf(value)
	var number := "%.2f" % value if absf(value) < 10.0 else ("%d" % int(rounded) if is_equal_approx(value, rounded) else "%.1f" % value)
	return number if suffix.is_empty() else "%s %s" % [number, tr(suffix)]

func _refresh_localized_values(_locale: String) -> void:
	for key in value_labels:
		value_labels[key].text = _format_value(TuningStore.get_value(key), String(value_suffixes[key]))
