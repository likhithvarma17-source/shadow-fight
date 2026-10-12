extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	const FUSION_PIXEL_FONT := "res://assets/template/fonts/manuscc0_regular.tres"
	var smoke_i18n = root.get_node("I18n")
	smoke_i18n.set_language("zh_CN", false)
	assert(ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items")
	assert(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep")
	assert(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 1280)
	assert(int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 720)
	assert(ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color") == Color.BLACK)
	assert(ProjectSettings.get_setting("application/config/name") == "Shadow")
	var fusion_font := load(FUSION_PIXEL_FONT) as Font
	assert(is_instance_valid(fusion_font) and fusion_font.has_char("赤".unicode_at(0)))
	var frames = load("res://scripts/animation_frames.gd")
	assert(frames.HERO_RUN.size() >= 8 and frames.HERO_RUN.size() <= 16)
	assert(frames.HERO_JUMP.size() == 12)
	assert(frames.HERO_ATTACK.size() >= 6 and frames.HERO_ATTACK.size() <= 16)
	assert(frames.HERO_DEATH.size() >= 8 and frames.HERO_DEATH.size() <= 16)
	assert(frames.BLADE_RUN.size() >= 8 and frames.BLADE_RUN.size() <= 16)
	assert(frames.GUNNER_WALK.size() >= 8 and frames.GUNNER_WALK.size() <= 16)
	var save_store = load("res://scripts/save_store.gd")
	assert(save_store.VERSION == 2)
	save_store.set_tutorial_complete(false)
	assert(not save_store.has_completed_tutorial())
	var title_scene := load("res://scenes/title_screen.tscn") as PackedScene
	assert(title_scene != null)
	var title := title_scene.instantiate()
	root.add_child(title)
	await process_frame
	assert(title.get_node_or_null("TitleContent") != null)
	assert((title.find_child("GameTitle", true, false) as Label).text == "SHADOW")
	assert((title.get_node("TitleContent") as Control).get_child_count() == 5)
	assert(title.find_child("BestRunLabel", true, false) == null)
	assert(title.find_children("*", "HSeparator", true, false).is_empty())
	assert(title.find_child("StartPrompt", true, false) is Label)
	assert((title.find_child("StartPrompt", true, false) as Label).text == "按任意键  //  开始剧情")
	assert((title.find_child("StartPrompt", true, false) as Label).get_theme_font("font") == fusion_font)
	assert(title.find_child("TitleControls", true, false) is Label)
	assert("暂停  ESC" in (title.find_child("TitleControls", true, false) as Label).text)
	var title_buttons := title.find_children("*", "Button", true, false)
	assert(title_buttons.size() == 3)
	assert(title.find_child("LanguageButton", true, false) is Button)
	assert(title.find_child("StoryPrologueButton", true, false) is Button)
	assert((title.find_child("StoryPrologueButton", true, false) as Button).text == "剧情序章  //  从任务简报开始")
	assert((title.find_child("StoryPrologueButton", true, false) as Button).pressed.get_connections().size() == 1)
	assert((title.find_child("StoryPrologueButton", true, false) as Button).get_theme_font("font") == fusion_font)
	assert(title.find_child("BossTestButton", true, false) is Button)
	assert((title.find_child("BossTestButton", true, false) as Button).text == "首领测试  //  守门人")
	assert((title.find_child("BossTestButton", true, false) as Button).pressed.get_connections().size() == 1)
	assert(title.BOSS_SCENE == "res://scenes/boss_battle.tscn")
	assert(title.get_start_scene_path() == "res://scenes/tutorial.tscn")
	save_store.mark_tutorial_complete()
	assert(save_store.has_completed_tutorial())
	assert(title.get_start_scene_path() == "res://scenes/game.tscn")
	assert(title.get_start_prompt_text() == "按任意键  //  继续第一关")
	save_store.set_tutorial_complete(false)
	assert(title.find_child("CrtPixelFilter", true, false) == null)
	title.queue_free()
	await process_frame

	var tuning = load("res://scripts/tuning_store.gd")
	var legacy_tuning := ConfigFile.new()
	legacy_tuning.set_value("meta", "version", 15)
	legacy_tuning.set_value("tuning", "boss_max_health", 13.0)
	legacy_tuning.set_value("tuning", "boss_action_interval", 0.71)
	legacy_tuning.set_value("tuning", "boss_reflected_damage", 1.0)
	legacy_tuning.set_value("tuning", "attack_cooldown", 0.34)
	legacy_tuning.set_value("tuning", "player_hurtbox_height", 89.0)
	legacy_tuning.set_value("tuning", "melee_parry_slow_duration", 0.85)
	legacy_tuning.set_value("tuning", "melee_parry_time_scale", 0.45)
	legacy_tuning.set_value("tuning", "parry_zoom_amount", 0.08)
	legacy_tuning.set_value("tuning", "parry_zoom_duration", 0.30)
	assert(legacy_tuning.save(tuning.CONFIG_PATH) == OK)
	tuning._values = {}
	tuning._loaded = false
	assert(is_equal_approx(tuning.get_value("boss_max_health"), 13.0))
	assert(is_equal_approx(tuning.get_value("boss_action_interval"), 0.71))
	assert(is_equal_approx(tuning.get_value("boss_katana_damage"), 1.0))
	assert(is_equal_approx(tuning.get_value("boss_melee_parry_damage"), 2.0))
	assert(is_equal_approx(tuning.get_value("boss_reflected_damage"), 1.0))
	assert(is_equal_approx(tuning.get_value("attack_cooldown"), 0.34))
	assert(is_equal_approx(tuning.get_value("player_hurtbox_height"), 89.0))
	assert(is_equal_approx(tuning.get_value("melee_parry_slow_duration"), 0.85))
	assert(is_equal_approx(tuning.get_value("melee_parry_time_scale"), 0.45))
	assert(is_equal_approx(tuning.get_value("parry_zoom_amount"), 0.08))
	assert(is_equal_approx(tuning.get_value("parry_zoom_duration"), 0.30))
	tuning.reset()
	var promoted_defaults := {
		"acceleration": 2550.0,
		"attack_cooldown": 0.35,
		"attack_hitbox_back": 50.0,
		"attack_hitbox_forward": 60.0,
		"attack_hitbox_height": 102.0,
		"bgm_volume_db": -1.0,
		"blade_aggression": 1.3,
		"blade_alert_range": 780.0,
		"blade_move_speed": 186.0,
		"blade_patrol_speed": 58.0,
		"camera_distance": 1.45,
		"enemy_hurtbox_height": 97.0,
		"enemy_hurtbox_width": 30.0,
		"focus_drain": 25.0,
		"focus_regen": 14.0,
		"gravity": 1480.0,
		"gunner_aggression": 1.5,
		"gunner_alert_range": 1050.0,
		"gunner_patrol_speed": 42.0,
		"gunner_projectile_speed": 610.0,
		"boss_max_health": 25.0,
		"boss_katana_damage": 1.0,
		"boss_melee_parry_damage": 2.0,
		"boss_reflected_damage": 2.0,
		"boss_action_interval": 0.58,
		"boss_dash_speed": 980.0,
		"boss_projectile_speed": 690.0,
		"melee_parry_slow_duration": 0.3,
		"melee_parry_time_scale": 0.5,
		"parry_zoom_amount": 0.02,
		"parry_zoom_duration": 0.28,
		"jump_animation_fps": 18.0,
		"jump_fall_gravity_multiplier": 1.45,
		"jump_force": 800.0,
		"jump_launch_multiplier": 1.35,
		"jump_rise_gravity_multiplier": 1.65,
		"player_hurtbox_height": 97.0,
		"player_hurtbox_width": 31.0,
		"rain_volume_db": -15.5,
		"rim_brightness": 0.35,
		"rim_width": 1.3,
		"run_speed": 470.0,
		"sfx_volume_db": 0.0,
		"slash_dash_distance": 240.0,
		"slash_dash_speed": 1200.0
	}
	assert(tuning.CONFIG_VERSION == 16)
	assert(tuning.DEFAULTS == promoted_defaults)
	var game_scene := load("res://scenes/game.tscn") as PackedScene
	assert(game_scene != null)
	var game := game_scene.instantiate()
	root.add_child(game)
	for _i in range(8):
		await physics_frame
	assert(is_instance_valid(game.player))
	assert(game.entrance_transition_active)
	assert(not game.player.control_enabled)
	var shutter_locked_x: float = game.player.global_position.x
	Input.action_press("move_right")
	await physics_frame
	Input.action_release("move_right")
	assert(is_equal_approx(game.player.global_position.x, shutter_locked_x))
	game.entrance_transition_duration = 0.0
	await game._open_entrance_transition()
	assert(not game.entrance_transition_active and game.player.control_enabled)
	assert(game.get_viewport_rect().size.is_equal_approx(Vector2(1280.0, 720.0)))
	assert(is_instance_valid(game.crt_filter) and not game.crt_filter.is_filter_enabled())
	assert(is_instance_valid(game.projectile_explosions))
	assert(game.projectile_explosions.z_index == 10)
	assert(is_instance_valid(game.pause_menu) and not game.pause_menu.is_open())
	assert(game.pause_menu.process_mode == Node.PROCESS_MODE_ALWAYS)
	assert(game.pause_menu.layer == 70)
	assert(game.pause_menu.overlay.find_child("ResumeButton", true, false) is Button)
	assert(game.pause_menu.overlay.find_child("RestartButton", true, false) is Button)
	assert(game.pause_menu.overlay.find_child("PauseTutorialButton", true, false) is Button)
	assert((game.pause_menu.overlay.find_child("PauseTutorialButton", true, false) as Button).text == "重玩剧情序章")
	assert(game.pause_menu.overlay.find_child("PauseTitleButton", true, false) is Button)
	assert(game.pause_menu.tutorial_requested.get_connections().size() == 1)
	assert(InputMap.has_action("pause_game"))
	var pause_has_escape := false
	for pause_event in InputMap.action_get_events("pause_game"):
		if pause_event is InputEventKey and pause_event.physical_keycode == KEY_ESCAPE:
			pause_has_escape = true
	assert(pause_has_escape)
	var touch_controls: Node = null
	for child in game.get_children():
		if child.get_script() == load("res://scripts/touch_input.gd"):
			touch_controls = child
			break
	assert(is_instance_valid(touch_controls) and touch_controls.action_buttons.has("pause_game"))
	assert((touch_controls.action_buttons["aim_down"] as Button).text == "▼")
	assert((touch_controls.action_buttons["focus"] as Button).text == "专注")
	assert((touch_controls.action_buttons["attack"] as Button).text == "斩击")
	assert((touch_controls.action_buttons["pause_game"] as Button).text == "暂停")
	game._open_pause_menu()
	assert(paused and game.pause_menu.is_open())
	assert(game.bgm_player.stream_paused and game.rain_audio_player.stream_paused)
	game.pause_menu.resume_game()
	assert(not paused and not game.pause_menu.is_open())
	assert(not game.bgm_player.stream_paused and not game.rain_audio_player.stream_paused)
	assert(not game.crt_filter.overlay.visible)
	assert(game.crt_filter.layer == 10)
	assert(game.crt_filter.overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(game.crt_filter.overlay.material is ShaderMaterial)
	var crt_virtual_resolution: Vector2 = game.crt_filter.get_parameter("virtual_resolution")
	assert(crt_virtual_resolution.is_equal_approx(Vector2(800.0, 450.0)))
	assert(is_equal_approx(float(game.crt_filter.get_parameter("curvature")), 0.012))
	assert(is_equal_approx(float(game.crt_filter.get_parameter("scanline_strength")), 0.085))
	assert(is_equal_approx(float(game.crt_filter.get_parameter("brightness")), 1.08))
	var controls_canvas := game.controls_panel.get_parent() as CanvasLayer
	assert(is_instance_valid(controls_canvas) and controls_canvas.layer == 20)
	assert(game.crt_filter.layer < controls_canvas.layer and game.crt_filter.layer < game.tuning_panel.layer)
	assert(is_instance_valid(game.world_art) and game.world_art.name == "OriginalFixedSkyline")
	assert(game.world_art.ORIGINAL_SKYLINE.get_size().is_equal_approx(Vector2(1600.0, 900.0)))
	assert(is_equal_approx(game.world_art.PARALLAX_RATE, 0.0))
	assert(game.world_art.BACKGROUND_MODULATE.r > 0.9)
	assert(game.world_art.z_index == -100)
	assert(game.camera.zoom.is_equal_approx(Vector2.ONE / 1.45))
	assert(game.get_camera_visible_world_size().is_equal_approx(game.get_viewport_rect().size * 1.45))
	assert(game.world_art.get_visible_world_size().is_equal_approx(game.get_camera_visible_world_size()))
	assert((game.world_art.last_world_rect.size * game.camera.zoom).is_equal_approx(game.get_viewport_rect().size))
	assert(is_equal_approx(game.world_art.get_layer_travel(0, 640.0, 4640.0), 0.0))
	assert(is_equal_approx(game.world_art.get_layer_screen_offset(0, 640.0), 0.0))
	assert(is_equal_approx(game.world_art.get_layer_screen_offset(0, 4640.0), 0.0))
	assert(game.world_art.last_camera_center.is_equal_approx(game.world_art.get_rendered_camera_center()))
	assert(is_instance_valid(game.environment_art) and game.environment_art.name == "TexturedRooftopEnvironment")
	assert(game.environment_art.z_index == -8)
	assert(game.environment_art.platforms == game.platforms and game.platforms.size() == 10)
	assert(game.environment_art.get_expected_ground_module_count() == 9)
	assert(game.environment_art.get_expected_catwalk_count() == 9)
	assert(game.environment_art.MACHINE_RECTS.size() == 4)
	assert(game.environment_art.GROUND_A.resource_path == "res://assets/environment/roof_ground_tile.webp")
	assert(game.environment_art.GROUND_B.resource_path == "res://assets/environment/roof_ground_tile_b.webp")
	assert(game.environment_art.CATWALK.resource_path == "res://assets/environment/catwalk_platform.webp")
	assert(game.environment_art.MACHINE_A.resource_path == "res://assets/environment/rooftop_machine_a.webp")
	assert(game.environment_art.MACHINE_B.resource_path == "res://assets/environment/rooftop_machine_b.webp")
	assert(game.environment_art.EXIT_GATE.resource_path == "res://assets/environment/exit_gate.webp")
	assert(game.environment_art.GROUND_A.get_size().is_equal_approx(Vector2(640.0, 90.0)))
	assert(game.environment_art.CATWALK.get_size().is_equal_approx(Vector2(320.0, 30.0)))
	assert(not game.environment_art.gate_open)
	game.set_process(false)
	game.camera.position_smoothing_enabled = false
	game.camera.position = Vector2(2000.0, 360.0)
	game.camera.force_update_scroll()
	await process_frame
	var camera_center_before: Vector2 = game.world_art.get_rendered_camera_center()
	var rendered_offset_before: float = game.world_art.get_layer_screen_offset(0, camera_center_before.x)
	assert(absf(camera_center_before.x - 2000.0) < 1.0)
	game.camera.position = Vector2(2030.0, 360.0)
	game.camera.force_update_scroll()
	await process_frame
	var camera_center_after: Vector2 = game.world_art.get_rendered_camera_center()
	var rendered_offset_after: float = game.world_art.get_layer_screen_offset(0, camera_center_after.x)
	assert(absf(camera_center_after.x - 2030.0) < 1.0)
	assert(is_equal_approx(rendered_offset_before, rendered_offset_after))
	assert(game.world_art.last_screen_offsets == [0.0])
	game.camera.position = Vector2(640.0, 360.0)
	game.camera.force_update_scroll()
	await process_frame
	game.set_process(true)
	assert(game.ZONE_NEON.size() == 4 and game.ZONE_NEON[0] != game.ZONE_NEON[1] and game.ZONE_NEON[1] != game.ZONE_NEON[2])
	assert(is_equal_approx(game.player.IDLE_SPRITE_SCALE, game.player.SPRITE_SCALE / game.player.IDLE_SCALE_RATIO))
	assert(is_equal_approx(game.player.IDLE_SCALE_RATIO, 1.18))
	assert(is_equal_approx(game.player.RUN_SPRITE_SCALE, game.player.IDLE_SPRITE_SCALE))
	assert(is_instance_valid(game.player.rim_light) and game.player.rim_light.name == "CharacterRimLight")
	assert(game.player.rim_light.texture != null and game.player.rim_light.material is ShaderMaterial)
	assert(game.player.rim_light.z_index == 1)
	assert(is_equal_approx(float(game.player.rim_light.get_parameter("outline_width")), 1.3))
	assert(is_equal_approx(float(game.player.rim_light.get_parameter("rim_brightness")), 0.35))
	assert(is_equal_approx(float(game.player.rim_light.get_parameter("inner_strength")), 0.68))
	var player_key_color: Color = game.player.rim_light.get_parameter("key_color")
	var player_bounce_color: Color = game.player.rim_light.get_parameter("bounce_color")
	assert(player_key_color.g > player_key_color.r and player_key_color.b > player_key_color.r)
	assert(player_bounce_color.r > player_bounce_color.g and player_bounce_color.b > player_bounce_color.g)
	for lit_enemy in game.enemies:
		assert(is_instance_valid(lit_enemy.rim_light))
		assert(lit_enemy.rim_light.texture != null and lit_enemy.rim_light.material is ShaderMaterial)
	assert(not game.player.FOCUS_RING_ENABLED)
	assert(game._living_enemy_count() == game.TOTAL_ENEMIES)
	assert(FileAccess.file_exists(game.StoryStore.STORY_PATH))
	assert(game.StoryStore.get_scene("opening_briefing").size() == 6)
	assert(game.StoryStore.get_barks("blade").size() == 6)
	assert(game.StoryStore.get_barks("gunner").size() == 6)
	assert(is_instance_valid(game.entrance_transition))
	assert(game.entrance_transition.layer > game.pause_menu.layer)
	for story_enemy in game.enemies:
		assert(story_enemy.has_meta("story_bark"))
	game._clear_all_enemy_barks()
	game.enemy_bark_roll_override = 0.0
	var bark_probe_enemy = game.enemies[0]
	bark_probe_enemy.remove_meta("story_bark_shown")
	var bark_probe_player_position: Vector2 = game.player.global_position
	game.player.global_position = bark_probe_enemy.global_position + Vector2(-120.0, 0.0)
	game._update_enemy_barks(0.01)
	assert(game.enemy_bark_bubbles.has(bark_probe_enemy))
	var bark_probe_label := bark_probe_enemy.find_child("StoryBark", false, false) as Label
	assert(is_instance_valid(bark_probe_label) and not bark_probe_label.text.is_empty())
	assert(bark_probe_label.position.y + bark_probe_label.size.y <= -160.0)
	assert(is_equal_approx(float(game.enemy_bark_bubbles[bark_probe_enemy]["remaining"]), 2.99))
	game._update_enemy_barks(3.1)
	assert(not game.enemy_bark_bubbles.has(bark_probe_enemy))
	var silent_probe_enemy = game.enemies[1]
	silent_probe_enemy.remove_meta("story_bark_shown")
	game.enemy_bark_roll_override = 1.0
	game.player.global_position = silent_probe_enemy.global_position + Vector2(-120.0, 0.0)
	game._update_enemy_barks(0.01)
	assert(silent_probe_enemy.has_meta("story_bark_shown"))
	assert(float(silent_probe_enemy.get_meta("story_bark_roll")) >= game.ENEMY_BARK_CHANCE)
	assert(not game.enemy_bark_bubbles.has(silent_probe_enemy))
	game.enemy_bark_roll_override = -1.0
	game.player.global_position = bark_probe_player_position
	assert(is_instance_valid(game.bgm_player) and game.bgm_player.playing)
	assert(game.bgm_player.stream is AudioStreamOggVorbis and game.bgm_player.stream.loop)
	assert(game.BGM_STREAM.get_length() >= 57.0 and game.BGM_STREAM.get_length() <= 58.0)
	assert(is_equal_approx(game.bgm_player.volume_db, tuning.get_value("bgm_volume_db")))
	assert(is_instance_valid(game.rain_audio_player) and game.rain_audio_player.playing)
	assert(game.SLASH_STREAM.get_length() >= 0.99)
	assert(game.PARRY_STREAM.get_length() >= 0.99)
	assert(game.ENEMY_HIT_STREAM.get_length() >= 0.99)
	assert(game.THUNDER_STREAMS.size() == 3)
	assert(is_instance_valid(game.lightning_overlay))
	game._trigger_thunder()
	assert(game.lightning_flash == 1.0)
	assert(game.thunder_timer >= 8.0 and game.thunder_timer <= 19.0)
	assert(game.thunder_sound_delay >= 0.12 and game.thunder_sound_delay <= 0.72)
	assert(game.pending_thunder_stream != null)
	game._update_storm(1.0)
	assert(game.shake_strength >= 2.2)
	game._update_screen_effects(0.016)
	assert(game.lightning_overlay.color.a > 0.0)
	var jump_keys: Array[int] = []
	for event in InputMap.action_get_events("jump"):
		if event is InputEventKey:
			jump_keys.append(event.physical_keycode)
	assert(KEY_K in jump_keys)
	assert(KEY_L not in jump_keys and KEY_SPACE not in jump_keys and KEY_W not in jump_keys and KEY_UP not in jump_keys)
	var focus_keys: Array[int] = []
	for event in InputMap.action_get_events("focus"):
		if event is InputEventKey:
			focus_keys.append(event.physical_keycode)
	assert(KEY_L in focus_keys and KEY_SHIFT in focus_keys)
	assert(KEY_K not in focus_keys)
	assert(is_instance_valid(game.controls_panel) and game.controls_panel.visible)
	assert(is_instance_valid(game.controls_label) and game.controls_label.visible)
	assert("下穿平台" in game.controls_label.text)
	assert("调参" in game.controls_label.text)
	assert(is_instance_valid(game.tuning_panel))
	assert(is_instance_valid(game.tuning_panel.panel) and not game.tuning_panel.panel.visible)
	assert(game.tuning_panel.TAB_DEFINITIONS.size() == 4)
	assert(game.tuning_panel.tab_buttons.size() == 4 and game.tuning_panel.tab_pages.size() == 4)
	assert(game.tuning_panel.active_tab == 0 and game.tuning_panel.tab_pages[0].visible)
	for tab_index in range(4):
		game.tuning_panel.select_tab(tab_index)
		assert(game.tuning_panel.active_tab == tab_index)
		assert(game.tuning_panel.tab_buttons[tab_index].button_pressed)
		for page_index in range(4):
			assert(game.tuning_panel.tab_pages[page_index].visible == (page_index == tab_index))
	assert(not game._should_draw_hitbox_preview())
	assert(is_instance_valid(game.hitbox_debug_overlay) and game.hitbox_debug_overlay.z_index == 50)
	for slider_name in ["jump_launch_multiplier", "jump_rise_gravity_multiplier", "jump_fall_gravity_multiplier", "jump_animation_fps", "attack_hitbox_forward", "attack_hitbox_back", "attack_hitbox_height", "player_hurtbox_width", "player_hurtbox_height", "melee_parry_slow_duration", "melee_parry_time_scale", "parry_zoom_amount", "parry_zoom_duration", "enemy_hurtbox_width", "enemy_hurtbox_height", "blade_move_speed", "blade_aggression", "gunner_aggression", "gunner_projectile_speed", "boss_max_health", "boss_katana_damage", "boss_melee_parry_damage", "boss_reflected_damage", "boss_action_interval", "boss_dash_speed", "boss_projectile_speed", "camera_distance", "rim_width", "rim_brightness", "bgm_volume_db", "sfx_volume_db", "rain_volume_db"]:
		var tweak_slider := game.tuning_panel.panel.find_child(slider_name, true, false) as HSlider
		assert(is_instance_valid(tweak_slider) and not tweak_slider.scrollable)
	assert(game.tuning_panel.panel.find_child("ExportTweaksButton", true, false) is Button)
	assert(game.tuning_panel.panel.find_child("TweakTabPlayer", true, false) is Button)
	assert(game.tuning_panel.panel.find_child("TweakTabCombat", true, false) is Button)
	assert(game.tuning_panel.panel.find_child("TweakTabEnemies", true, false) is Button)
	assert(game.tuning_panel.panel.find_child("TweakTabAudioVisual", true, false) is Button)
	var formatter_i18n = root.get_node("I18n")
	var original_formatter_locale: String = formatter_i18n.locale
	formatter_i18n.set_language("zh_CN", false)
	assert(game.tuning_panel._format_value(-15.5, "分贝") == "-15.5 分贝")
	formatter_i18n.set_language("en", false)
	assert(game.tuning_panel._format_value(-15.5, "分贝") == "-15.5 dB")
	formatter_i18n.set_language(original_formatter_locale, false)
	game.tuning_panel.select_tab(1)
	game.tuning_panel.panel.visible = true
	assert(game._should_draw_hitbox_preview())
	game.hitbox_debug_overlay._process(0.0)
	assert(game.hitbox_debug_overlay.visible)
	assert(not game.hitbox_debug_overlay._should_draw_attack_hitbox())
	var hitbox_forward_slider := game.tuning_panel.panel.find_child("attack_hitbox_forward", true, false) as HSlider
	var player_hurtbox_width_slider := game.tuning_panel.panel.find_child("player_hurtbox_width", true, false) as HSlider
	var player_hurtbox_height_slider := game.tuning_panel.panel.find_child("player_hurtbox_height", true, false) as HSlider
	var enemy_hurtbox_width_slider := game.tuning_panel.panel.find_child("enemy_hurtbox_width", true, false) as HSlider
	var enemy_hurtbox_height_slider := game.tuning_panel.panel.find_child("enemy_hurtbox_height", true, false) as HSlider
	hitbox_forward_slider.value = 100.0
	player_hurtbox_width_slider.value = 40.0
	player_hurtbox_height_slider.value = 80.0
	enemy_hurtbox_width_slider.value = 42.0
	enemy_hurtbox_height_slider.value = 88.0
	var rim_width_slider := game.tuning_panel.panel.find_child("rim_width", true, false) as HSlider
	var rim_brightness_slider := game.tuning_panel.panel.find_child("rim_brightness", true, false) as HSlider
	var camera_distance_slider := game.tuning_panel.panel.find_child("camera_distance", true, false) as HSlider
	rim_width_slider.value = 6.0
	rim_brightness_slider.value = 0.35
	camera_distance_slider.value = 1.5
	game._apply_camera_distance()
	assert(game.camera.zoom.is_equal_approx(Vector2(2.0 / 3.0, 2.0 / 3.0)))
	assert(game.get_camera_visible_world_size().is_equal_approx(game.get_viewport_rect().size * 1.5))
	game.player.global_position.x = 150.0
	game._update_camera()
	assert(is_equal_approx(game.camera.position.x, game.get_camera_visible_world_size().x * 0.5))
	game.player._apply_hurtbox_tuning()
	for tuned_enemy in game.enemies:
		tuned_enemy._apply_hurtbox_tuning()
	game.player._sync_rim_light()
	game.enemies[0]._sync_rim_light()
	assert(is_equal_approx(tuning.get_value("attack_hitbox_forward"), 100.0))
	var preview_rect: Rect2 = game._attack_hitbox_rect()
	assert(is_equal_approx(preview_rect.position.x, -50.0) and is_equal_approx(preview_rect.end.x, 100.0))
	assert(is_equal_approx(preview_rect.size.y, 102.0))
	assert(game.player.get_hurtbox_size().is_equal_approx(Vector2(40.0, 80.0)))
	assert(game.player.get_hurtbox_rect_world().size.is_equal_approx(Vector2(40.0, 80.0)))
	var tuned_player_shape := game.player.hurtbox_collision.shape as CapsuleShape2D
	assert(is_equal_approx(tuned_player_shape.radius, 20.0) and is_equal_approx(tuned_player_shape.height, 80.0))
	for tuned_enemy in game.enemies:
		assert(tuned_enemy.get_hurtbox_size().is_equal_approx(Vector2(42.0, 88.0)))
		assert(tuned_enemy.get_hurtbox_rect_world().size.is_equal_approx(Vector2(42.0, 88.0)))
		var tuned_enemy_shape := tuned_enemy.hurtbox_collision.shape as CapsuleShape2D
		assert(is_equal_approx(tuned_enemy_shape.radius, 21.0) and is_equal_approx(tuned_enemy_shape.height, 88.0))
		assert(tuned_enemy.hurtbox_collision.position.is_equal_approx(Vector2(0.0, -43.0)))
	var hurtbox_probe_enemy = game.enemies[0]
	var hurtbox_probe_origin: Vector2 = game.player.global_position + Vector2(0.0, -34.0)
	hurtbox_probe_enemy.global_position = hurtbox_probe_origin + Vector2(112.0, 43.0)
	assert(game._attack_hitbox_overlaps_rect(hurtbox_probe_enemy.get_hurtbox_rect_world(), hurtbox_probe_origin, Vector2.RIGHT))
	var hurtbox_probe_center: Vector2 = hurtbox_probe_enemy.get_hurtbox_center_world()
	assert(hurtbox_probe_enemy.hurtbox_overlaps_circle(hurtbox_probe_center + Vector2(20.0, 0.0), 0.0))
	enemy_hurtbox_width_slider.value = 20.0
	hurtbox_probe_enemy._apply_hurtbox_tuning()
	assert(not game._attack_hitbox_overlaps_rect(hurtbox_probe_enemy.get_hurtbox_rect_world(), hurtbox_probe_origin, Vector2.RIGHT))
	assert(not hurtbox_probe_enemy.hurtbox_overlaps_circle(hurtbox_probe_center + Vector2(20.0, 0.0), 0.0))
	enemy_hurtbox_width_slider.value = 42.0
	hurtbox_probe_enemy._apply_hurtbox_tuning()
	assert(is_equal_approx(float(game.player.rim_light.get_parameter("outline_width")), 6.0))
	assert(is_equal_approx(float(game.player.rim_light.get_parameter("rim_brightness")), 0.35))
	assert(is_equal_approx(float(game.enemies[0].rim_light.get_parameter("outline_width")), 6.0))
	var export_path: String = game.tuning_panel._export_values()
	assert(not export_path.is_empty() and FileAccess.file_exists(export_path))
	assert(export_path.ends_with("ying-tweaks-v16.json"))
	var exported_tweaks: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(export_path))
	assert(exported_tweaks["format"] == "ying-tweaks")
	assert(exported_tweaks["project"] == "Shadow")
	assert(int(exported_tweaks["config_version"]) == tuning.CONFIG_VERSION)
	assert(is_equal_approx(float(exported_tweaks["values"]["attack_hitbox_forward"]), 100.0))
	assert(is_equal_approx(float(exported_tweaks["values"]["player_hurtbox_width"]), 40.0))
	assert(is_equal_approx(float(exported_tweaks["values"]["player_hurtbox_height"]), 80.0))
	assert(is_equal_approx(float(exported_tweaks["values"]["enemy_hurtbox_width"]), 42.0))
	assert(is_equal_approx(float(exported_tweaks["values"]["enemy_hurtbox_height"]), 88.0))
	assert(is_equal_approx(float(exported_tweaks["values"]["jump_animation_fps"]), 18.0))
	assert(is_equal_approx(float(exported_tweaks["values"]["rim_width"]), 6.0))
	assert(is_equal_approx(float(exported_tweaks["values"]["rim_brightness"]), 0.35))
	assert(is_equal_approx(float(exported_tweaks["values"]["camera_distance"]), 1.5))
	assert(is_equal_approx(float(exported_tweaks["values"]["parry_zoom_amount"]), 0.02))
	assert(is_equal_approx(float(exported_tweaks["values"]["parry_zoom_duration"]), 0.28))
	assert(exported_tweaks["values"].size() == tuning.DEFAULTS.size())
	assert("已保存" in game.tuning_panel.export_status.text)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(export_path))
	game.tuning_panel._reset_values()
	assert(tuning.CONFIG_VERSION == 16)
	assert(is_equal_approx(tuning.get_value("boss_max_health"), 25.0))
	assert(is_equal_approx(tuning.get_value("boss_katana_damage"), 1.0))
	assert(is_equal_approx(tuning.get_value("boss_melee_parry_damage"), 2.0))
	assert(is_equal_approx(tuning.get_value("boss_reflected_damage"), 2.0))
	assert(is_equal_approx(tuning.get_value("melee_parry_slow_duration"), 0.3))
	assert(is_equal_approx(tuning.get_value("melee_parry_time_scale"), 0.5))
	assert(is_equal_approx(tuning.get_value("parry_zoom_amount"), 0.02))
	assert(is_equal_approx(tuning.get_value("parry_zoom_duration"), 0.28))
	assert(is_equal_approx(camera_distance_slider.value, 1.45))
	assert(is_equal_approx(hitbox_forward_slider.value, 60.0))
	assert(is_equal_approx(rim_width_slider.value, 1.3))
	assert(is_equal_approx(rim_brightness_slider.value, 0.35))
	assert(is_equal_approx(enemy_hurtbox_width_slider.value, 30.0))
	assert(is_equal_approx(enemy_hurtbox_height_slider.value, 97.0))
	game.player._apply_hurtbox_tuning()
	assert(game.player.get_hurtbox_size().is_equal_approx(Vector2(31.0, 97.0)))
	for reset_enemy in game.enemies:
		reset_enemy._apply_hurtbox_tuning()
		assert(reset_enemy.get_hurtbox_size().is_equal_approx(Vector2(30.0, 97.0)))
	assert(is_equal_approx(tuning.get_value("run_speed"), 470.0))
	assert(is_equal_approx(tuning.get_value("acceleration"), 2550.0))
	assert(is_equal_approx(tuning.get_value("blade_move_speed"), 186.0))
	assert(is_equal_approx(tuning.get_value("blade_patrol_speed"), 58.0))
	assert(is_equal_approx(tuning.get_value("blade_aggression"), 1.3))
	assert(is_equal_approx(tuning.get_value("blade_alert_range"), 780.0))
	assert(is_equal_approx(tuning.get_value("gunner_aggression"), 1.5))
	assert(is_equal_approx(tuning.get_value("gunner_alert_range"), 1050.0))
	assert(is_equal_approx(tuning.get_value("gunner_projectile_speed"), 610.0))
	game._apply_camera_distance()
	assert(game.camera.zoom.is_equal_approx(Vector2.ONE / 1.45))
	game.tuning_panel.panel.visible = false
	assert(not game._should_draw_hitbox_preview())
	game.hitbox_debug_overlay._process(0.0)
	assert(not game.hitbox_debug_overlay.visible)
	var up_keys: Array[int] = []
	var down_keys: Array[int] = []
	for event in InputMap.action_get_events("aim_up"):
		if event is InputEventKey:
			up_keys.append(event.physical_keycode)
	for event in InputMap.action_get_events("aim_down"):
		if event is InputEventKey:
			down_keys.append(event.physical_keycode)
	assert(KEY_W in up_keys and KEY_UP in up_keys)
	assert(KEY_S in down_keys and KEY_DOWN in down_keys)
	var jump_force: float = tuning.get_value("jump_force")
	var gravity: float = tuning.get_value("gravity")
	var jump_launch_speed: float = game.player.get_jump_launch_speed()
	var rise_gravity: float = gravity * tuning.get_value("jump_rise_gravity_multiplier")
	assert(jump_force >= 790.0 and jump_launch_speed >= 1070.0)
	assert(jump_launch_speed / rise_gravity < 0.46)
	assert((jump_launch_speed * jump_launch_speed) / (2.0 * rise_gravity) > 230.0)
	assert(is_equal_approx(tuning.get_value("jump_animation_fps"), 18.0))
	var one_way_count := 0
	for child in game.get_children():
		if child is StaticBody2D:
			for shape_node in child.get_children():
				if shape_node is CollisionShape2D and shape_node.one_way_collision:
					one_way_count += 1
	assert(one_way_count == game.platforms.size())
	assert(is_equal_approx(tuning.get_value("attack_hitbox_forward"), 60.0))
	assert(is_equal_approx(tuning.get_value("attack_hitbox_back"), 50.0))
	assert(is_equal_approx(tuning.get_value("attack_hitbox_height"), 102.0))
	assert(game._point_inside_attack_hitbox(Vector2(59.0, 50.0), Vector2.ZERO, Vector2.RIGHT))
	assert(not game._point_inside_attack_hitbox(Vector2(61.0, 0.0), Vector2.ZERO, Vector2.RIGHT))
	assert(not game._point_inside_attack_hitbox(Vector2(0.0, 52.0), Vector2.ZERO, Vector2.RIGHT))
	tuning.set_value("attack_hitbox_height", 40.0)
	assert(not game._point_inside_attack_hitbox(Vector2(120.0, 30.0), Vector2.ZERO, Vector2.RIGHT))
	tuning.set_value("attack_hitbox_forward", 100.0)
	assert(not game._point_inside_attack_hitbox(Vector2(120.0, 0.0), Vector2.ZERO, Vector2.RIGHT))
	tuning.set_value("attack_hitbox_height", 102.0)
	tuning.set_value("attack_hitbox_forward", 60.0)
	var stationary_edge_enemy = game.enemies[0]
	stationary_edge_enemy.set_physics_process(false)
	var stationary_origin: Vector2 = game.player.global_position + Vector2(0.0, -34.0)
	stationary_edge_enemy.global_position = Vector2(stationary_origin.x + 75.0, game.player.global_position.y)
	assert(not game._point_inside_attack_hitbox(stationary_edge_enemy.global_position, stationary_origin, Vector2.RIGHT))
	assert(game._attack_hitbox_overlaps_rect(stationary_edge_enemy.get_hurtbox_rect_world(), stationary_origin, Vector2.RIGHT))
	game.player.attack_cooldown = 0.0
	game.tuning_panel.panel.visible = true
	assert(game.player.begin_slash(Vector2.ZERO))
	assert(game.player.get_attack_frame_index() == 0)
	assert(game.player.STANDING_HIT_START_FRAME == 2 and game.player.STANDING_HIT_END_FRAME == 8)
	var theoretical_startup: float = game.player.ATTACK_DURATION * float(game.player.STANDING_HIT_START_FRAME) / float(frames.HERO_ATTACK.size())
	assert(theoretical_startup <= 0.0551)
	assert(not game.player.is_attack_hitbox_active())
	assert(not game.hitbox_debug_overlay._should_draw_attack_hitbox())
	assert(stationary_edge_enemy.alive)
	var observed_active_frames: Dictionary = {}
	var physics_steps_to_first_hit := -1
	for _i in range(24):
		await physics_frame
		var attack_frame: int = game.player.get_attack_frame_index()
		if game.player.is_attack_hitbox_active():
			if physics_steps_to_first_hit < 0:
				physics_steps_to_first_hit = _i + 1
			observed_active_frames[attack_frame] = true
			assert(game.hitbox_debug_overlay._should_draw_attack_hitbox())
	assert(physics_steps_to_first_hit > 0 and physics_steps_to_first_hit <= 5)
	for expected_frame in range(game.player.STANDING_HIT_START_FRAME, game.player.STANDING_HIT_END_FRAME + 1):
		assert(observed_active_frames.has(expected_frame))
	assert(not stationary_edge_enemy.alive)
	assert(not game.player.is_attack_hitbox_active())
	assert(not game.hitbox_debug_overlay._should_draw_attack_hitbox())
	game.tuning_panel.panel.visible = false
	game._restart_room()
	await process_frame
	var overhead_enemy = game.enemies[0]
	var overhead_enemy_position: Vector2 = overhead_enemy.global_position
	overhead_enemy.global_position = game.player.global_position + Vector2(30.0, -125.0)
	game._on_player_slash(game.player.global_position + Vector2(0.0, -34.0), 1.0, Vector2.RIGHT)
	assert(overhead_enemy.alive)
	overhead_enemy.global_position = overhead_enemy_position
	tuning.set_value("bgm_volume_db", -18.0)
	tuning.set_value("rain_volume_db", -12.0)
	game._update_audio_tuning()
	assert(is_equal_approx(game.bgm_player.volume_db, -18.0))
	assert(is_equal_approx(game.rain_audio_player.volume_db, -12.0))
	tuning.set_value("bgm_volume_db", -1.0)
	tuning.set_value("rain_volume_db", -15.5)
	tuning.set_value("sfx_volume_db", -7.0)
	game._update_audio_tuning()
	game._play_sfx(game.SLASH_STREAM, -2.5)
	assert(is_equal_approx(game.last_sfx_volume_db, -9.5))
	tuning.set_value("sfx_volume_db", 0.0)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	var tuned_blade = game.enemies[0]
	var tuned_blade_position: Vector2 = tuned_blade.global_position
	tuned_blade.global_position = game.player.global_position - Vector2(300.0, 0.0)
	tuned_blade.velocity = Vector2.ZERO
	tuned_blade.facing = 1.0
	tuned_blade.windup = 0.0
	tuned_blade.action_clock = 1.0
	tuning.set_value("blade_move_speed", 200.0)
	tuned_blade._update_blade(1.0, Vector2(300.0, 0.0))
	assert(is_equal_approx(tuned_blade.velocity.x, 200.0))
	tuning.set_value("blade_move_speed", 186.0)
	tuned_blade.global_position = tuned_blade_position
	tuned_blade.velocity = Vector2.ZERO
	var tuned_gunner = game.enemies[1]
	tuning.set_value("gunner_aggression", 2.0)
	tuned_gunner.action_clock = 0.0
	tuned_gunner.windup = 0.0
	tuned_gunner._update_gunner(0.01, Vector2(-320.0, 0.0))
	assert(is_equal_approx(tuned_gunner.action_clock, 0.675))
	tuning.set_value("gunner_aggression", 1.5)
	tuned_gunner.action_clock = 0.0
	tuned_gunner.windup = 0.0
	var gunner_count := 0
	var late_gunner_shot = null
	for enemy in game.enemies:
		if enemy.kind != "gunner":
			continue
		gunner_count += 1
		var projectile_count: int = game.projectiles.size()
		enemy.action_clock = 0.0
		enemy.windup = 0.0
		enemy._update_gunner(0.01, Vector2(-320.0, 0.0))
		enemy._update_gunner(0.31, Vector2(-320.0, 0.0))
		assert(game.projectiles.size() == projectile_count + 1)
		var emitted_shot = game.projectiles.back()
		assert(emitted_shot.source_shooter == enemy)
		assert(emitted_shot.projectiles == game.projectiles)
		assert(is_equal_approx(emitted_shot.velocity.length(), tuning.get_value("gunner_projectile_speed")))
		if enemy.global_position.x > 4000.0:
			late_gunner_shot = emitted_shot
	assert(gunner_count == 6)
	assert(late_gunner_shot != null and late_gunner_shot.global_position.x > 4000.0)
	late_gunner_shot._process(0.05)
	assert(late_gunner_shot.alive)
	var dead_gunner_probe = load("res://scripts/enemy.gd").new()
	dead_gunner_probe.kind = "gunner"
	dead_gunner_probe.player = game.player
	dead_gunner_probe.position = Vector2(1800.0, 600.0)
	game.add_child(dead_gunner_probe)
	dead_gunner_probe.set_physics_process(false)
	dead_gunner_probe.fire_projectile.connect(game._on_enemy_fire)
	dead_gunner_probe.windup = 0.20
	dead_gunner_probe.action_clock = 0.0
	dead_gunner_probe.action_committed = false
	dead_gunner_probe.kill()
	var projectile_count_before_dead_gunner: int = game.projectiles.size()
	dead_gunner_probe._physics_process(0.40)
	assert(not dead_gunner_probe.alive and is_zero_approx(dead_gunner_probe.windup))
	assert(is_equal_approx(dead_gunner_probe.death_time, 0.40))
	assert(game.projectiles.size() == projectile_count_before_dead_gunner)
	game._on_enemy_fire(dead_gunner_probe.global_position, Vector2.LEFT, dead_gunner_probe)
	assert(game.projectiles.size() == projectile_count_before_dead_gunner)
	dead_gunner_probe.free()
	for emitted_shot in game.projectiles:
		if is_instance_valid(emitted_shot):
			emitted_shot.queue_free()
	game.projectiles.clear()
	await process_frame
	game.player.global_position = Vector2(2000.0, 600.0)
	game.camera.position = Vector2(2120.0, 360.0)
	var shot = load("res://scripts/projectile.gd").new()
	var incoming := Vector2(480.0, 135.0)
	shot.velocity = incoming
	shot.position = game.player.global_position + Vector2(32.0, -34.0)
	game.add_child(shot)
	game.projectiles.append(shot)
	game._on_player_slash(game.player.global_position + Vector2(0.0, -34.0), 1.0)
	assert(shot.reflected)
	assert(shot.velocity.normalized().dot(-incoming.normalized()) > 0.999)
	assert(is_equal_approx(shot.velocity.length(), incoming.length() * 3.0))
	assert(game.parry_sparks.size() == 32)
	assert(game.shake_strength >= 6.2)
	assert(is_equal_approx(game.parry_slow_remaining, tuning.get_value("melee_parry_slow_duration")))
	assert(is_equal_approx(game.parry_zoom_remaining, tuning.get_value("parry_zoom_duration")))
	assert(is_equal_approx(game._current_gameplay_time_scale(), tuning.get_value("melee_parry_time_scale")))
	assert(is_equal_approx(game.player.simulation_scale, tuning.get_value("melee_parry_time_scale")))
	assert(absf(game.last_sfx_pitch_scale - tuning.get_value("melee_parry_time_scale")) <= 0.02)
	var base_camera_zoom: float = 1.0 / tuning.get_value("camera_distance")
	assert(game.camera.zoom.x > base_camera_zoom)
	var base_camera_position := Vector2(game.player.global_position.x + 120.0, 360.0)
	game._update_camera()
	assert(game.camera.position.is_equal_approx(base_camera_position))
	game._tick_parry_feedback(tuning.get_value("parry_zoom_duration"))
	game._apply_camera_distance()
	assert(is_zero_approx(game.parry_zoom_remaining))
	assert(is_equal_approx(game.camera.zoom.x, base_camera_zoom))
	assert(game.parry_slow_remaining > 0.0)
	assert(is_equal_approx(game.player.external_time_scale, tuning.get_value("melee_parry_time_scale")))
	Input.action_press("move_right")
	game.player.velocity = Vector2(tuning.get_value("run_speed"), 0.0)
	game.player.attack_time = 0.30
	var parry_move_start: Vector2 = game.player.global_position
	game.player._physics_process(0.1)
	var parry_move_distance: float = game.player.global_position.distance_to(parry_move_start)
	assert(is_equal_approx(game.player.simulation_scale, tuning.get_value("melee_parry_time_scale")))
	assert(is_equal_approx(game.player.attack_time, 0.30 - 0.1 * tuning.get_value("melee_parry_time_scale")))
	game._reset_parry_feedback()
	assert(is_equal_approx(game.player.external_time_scale, 1.0))
	game.player.global_position = parry_move_start
	game.player.velocity = Vector2(tuning.get_value("run_speed"), 0.0)
	game.player.attack_time = 0.0
	game.player._physics_process(0.1)
	var normal_move_distance_after_parry: float = game.player.global_position.distance_to(parry_move_start)
	assert(parry_move_distance < normal_move_distance_after_parry * 0.60)
	Input.action_release("move_right")
	var dash_scale_probe = load("res://scripts/player.gd").new()
	dash_scale_probe.position = Vector2(2500.0, 300.0)
	game.add_child(dash_scale_probe)
	dash_scale_probe.set_physics_process(false)
	dash_scale_probe.slash.connect(func(_origin: Vector2, _facing: float, _direction: Vector2, primary: bool):
		if not primary:
			dash_scale_probe.set_external_time_scale(tuning.get_value("melee_parry_time_scale"))
	)
	assert(dash_scale_probe.begin_slash(Vector2.RIGHT))
	assert(is_equal_approx(dash_scale_probe.external_time_scale, 1.0))
	dash_scale_probe._physics_process(0.1)
	assert(is_equal_approx(dash_scale_probe.external_time_scale, 0.5))
	assert(is_equal_approx(dash_scale_probe.dash_distance_remaining, tuning.get_value("slash_dash_distance") - tuning.get_value("slash_dash_speed") * 0.1 * 0.5))
	dash_scale_probe.free()
	game.projectiles.erase(shot)
	shot.free()
	var interception_pool: Array = []
	var interceptor = load("res://scripts/projectile.gd").new()
	interceptor.position = Vector2(1000.0, 530.0)
	interceptor.setup(Vector2.RIGHT, game.player, [], null, interception_pool)
	interceptor.intercepted_projectile.connect(game._on_projectile_intercepted)
	game.add_child(interceptor)
	interception_pool.append(interceptor)
	var hostile_shot_near = load("res://scripts/projectile.gd").new()
	hostile_shot_near.position = Vector2(930.0, 530.0)
	hostile_shot_near.setup(Vector2.LEFT, game.player, [], null, interception_pool)
	game.add_child(hostile_shot_near)
	interception_pool.append(hostile_shot_near)
	var hostile_shot_far = load("res://scripts/projectile.gd").new()
	hostile_shot_far.position = Vector2(820.0, 530.0)
	hostile_shot_far.setup(Vector2.LEFT, game.player, [], null, interception_pool)
	game.add_child(hostile_shot_far)
	interception_pool.append(hostile_shot_far)
	game.shake_strength = 0.0
	interceptor.reflect(1.0)
	interceptor._process(0.16)
	assert(interceptor.alive and not interceptor.is_queued_for_deletion())
	assert(interceptor.global_position.is_equal_approx(interceptor.last_sweep_to))
	assert(interceptor.intercepted_projectile_count == 2)
	assert(interceptor.last_interception_positions.size() == 2)
	assert(interceptor.last_interception_positions[0].x > interceptor.last_interception_positions[1].x)
	assert(not hostile_shot_near.alive and hostile_shot_near.is_queued_for_deletion())
	assert(not hostile_shot_far.alive and hostile_shot_far.is_queued_for_deletion())
	assert(game.projectile_explosions.total_bursts == 2)
	assert(game.projectile_explosions.particles.size() == game.projectile_explosions.PARTICLE_COUNT * 2)
	assert(game.projectile_explosions.rings.size() == 2)
	for explosion_particle in game.projectile_explosions.particles:
		var spark_color: Color = explosion_particle["color"]
		assert(spark_color.r > spark_color.g and spark_color.r >= spark_color.b)
	assert(game.last_sfx_stream == game.PARRY_STREAM)
	assert(is_equal_approx(game.last_sfx_volume_db, -2.0))
	assert(game.shake_strength >= 2.8)
	var explosion_life_before: float = game.projectile_explosions.particles[0]["life"]
	game.projectile_explosions.simulation_scale = tuning.FOCUS_TIME_SCALE
	game.projectile_explosions._process(0.1)
	assert(is_equal_approx(explosion_life_before - float(game.projectile_explosions.particles[0]["life"]), 0.1 * tuning.FOCUS_TIME_SCALE))
	game.projectile_explosions.simulation_scale = 1.0
	game.projectile_explosions._process(0.6)
	assert(game.projectile_explosions.particles.is_empty() and game.projectile_explosions.rings.is_empty())
	interceptor.free()
	interception_pool.clear()
	await process_frame
	var near_path_enemy = game.enemies[1]
	var far_path_enemy = game.enemies[0]
	near_path_enemy.set_physics_process(false)
	far_path_enemy.set_physics_process(false)
	near_path_enemy.global_position = Vector2(800.0, 510.0)
	far_path_enemy.global_position = Vector2(610.0, 462.5)
	var path_shot = load("res://scripts/projectile.gd").new()
	path_shot.position = Vector2(1000.0, 530.0)
	# Deliberately list the farther shooter first: collision must follow path order,
	# and the nearer arbitrary hostile must take the hit instead of the shooter.
	path_shot.setup(Vector2(1.0, 0.25), game.player, [far_path_enemy, near_path_enemy], far_path_enemy)
	path_shot.hit_enemy.connect(game._on_projectile_hit_enemy)
	path_shot.expired.connect(game._on_projectile_expired.bind(path_shot))
	game.add_child(path_shot)
	game.projectiles.append(path_shot)
	var path_speed_before_reflect: float = path_shot.velocity.length()
	path_shot.reflect(1.0)
	assert(is_equal_approx(path_shot.velocity.length(), path_speed_before_reflect * 3.0))
	path_shot._process(0.35)
	assert(path_shot.last_sweep_from.is_equal_approx(Vector2(1000.0, 530.0)))
	assert(path_shot.last_sweep_to.x < far_path_enemy.get_hurtbox_center_world().x)
	assert(path_shot.last_hit_enemy == near_path_enemy)
	assert(path_shot.last_hit_fraction > 0.0 and path_shot.last_hit_fraction < 1.0)
	assert(not near_path_enemy.alive and far_path_enemy.alive)
	assert(not path_shot.alive and path_shot.is_queued_for_deletion())
	assert(not game.projectiles.has(path_shot))
	await process_frame
	var rain_drop: Dictionary = game.rain_drops[0]
	var rain_start := Vector2(1400.0, 120.0)
	rain_drop["position"] = rain_start
	game._update_rain(0.01, 1.0)
	var normal_rain_distance: float = Vector2(rain_drop["position"]).distance_to(rain_start)
	rain_drop["position"] = rain_start
	game._update_rain(0.01, 0.34)
	var slow_rain_distance: float = Vector2(rain_drop["position"]).distance_to(rain_start)
	assert(slow_rain_distance < normal_rain_distance * 0.5)
	var start_x: float = game.player.global_position.x
	Input.action_press("move_right")
	for _i in range(12):
		await physics_frame
	Input.action_release("move_right")
	assert(game.player.global_position.x > start_x)
	game.player.global_position = Vector2(210.0, 600.0)
	game.player.velocity = Vector2.ZERO
	game.player.attack_cooldown = 0.0
	for _i in range(3):
		await physics_frame
	var neutral_slash_start: Vector2 = game.player.global_position
	assert(game.player.begin_slash(Vector2.ZERO))
	assert(game.player.dash_time == 0.0 and game.player.dash_distance_remaining == 0.0)
	for _i in range(12):
		await physics_frame
	assert(absf(game.player.global_position.x - neutral_slash_start.x) < 2.0)
	game.player.attack_time = 0.0
	game.player.attack_cooldown = 0.0
	var sweep_enemy = game.enemies[0]
	sweep_enemy.global_position = game.player.global_position + Vector2(220.0, 0.0)
	var living_before_sweep: int = game._living_enemy_count()
	assert(game.player.begin_slash(Vector2.RIGHT))
	for _i in range(30):
		await physics_frame
		if game.player.dash_time <= 0.0:
			break
	assert(not sweep_enemy.alive)
	assert(game._living_enemy_count() == living_before_sweep - 1)
	game._restart_room()
	await process_frame
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	sweep_enemy = null
	game.player.global_position = Vector2(210.0, 600.0)
	game.player.velocity = Vector2.ZERO
	game.player.attack_cooldown = 0.0
	for _i in range(3):
		await physics_frame
	var dash_start: Vector2 = game.player.global_position
	var diagonal := Vector2(1.0, -1.0).normalized()
	assert(game.player.begin_slash(diagonal))
	for _i in range(30):
		await physics_frame
		if game.player.dash_time <= 0.0:
			break
	var dash_displacement: Vector2 = game.player.global_position - dash_start
	assert(dash_displacement.length() >= 232.0)
	assert(dash_displacement.x > 150.0 and dash_displacement.y < -150.0)
	assert(game.player.attack_direction.dot(diagonal) > 0.999)
	game.player.attack_time = 0.0
	game.player.attack_cooldown = 0.0
	game.player.global_position = Vector2(340.0, 600.0)
	game.player.velocity = Vector2.ZERO
	for _i in range(3):
		await physics_frame
	var focus_before: float = game.player.focus_energy
	game.player.set_physics_process(false)
	game.player.set_external_time_scale(0.5)
	Input.action_press("move_right")
	Input.action_press("focus")
	game.player._physics_process(0.1)
	assert(game.player.is_focusing)
	assert(is_equal_approx(game.player.simulation_scale, tuning.FOCUS_TIME_SCALE))
	game.player.attack_time = 0.0
	game.player.velocity = Vector2(tuning.get_value("run_speed"), 0.0)
	var focused_move_start: Vector2 = game.player.global_position
	var focused_animation_start: float = game.player.animation_clock
	game.player._physics_process(0.1)
	var focused_move_distance: float = game.player.global_position.distance_to(focused_move_start)
	assert(is_equal_approx(game.player.animation_clock - focused_animation_start, 0.1 * tuning.FOCUS_TIME_SCALE))
	game.player.attack_time = game.player.ATTACK_DURATION
	var focused_attack_before: float = game.player.attack_time
	game.player._physics_process(0.1)
	assert(is_equal_approx(focused_attack_before - game.player.attack_time, 0.1 * tuning.FOCUS_TIME_SCALE))
	game._play_sfx(game.PARRY_STREAM, 0.0, 0.0)
	assert(is_equal_approx(game.last_sfx_pitch_scale, tuning.FOCUS_TIME_SCALE))
	var active_focus_voice := AudioStreamPlayer.new()
	active_focus_voice.set_meta("base_pitch", 1.0)
	game.add_child(active_focus_voice)
	game.sfx_voices.append(active_focus_voice)
	game._update_audio_tuning()
	assert(is_equal_approx(active_focus_voice.pitch_scale, tuning.FOCUS_TIME_SCALE))
	game._update_screen_effects(1.0)
	assert(is_equal_approx(game.rain_audio_player.pitch_scale, 0.72))
	assert(is_equal_approx(game.bgm_player.pitch_scale, 0.72))
	Input.action_release("focus")
	game.player.attack_time = 0.0
	game.player.velocity = Vector2(tuning.get_value("run_speed"), 0.0)
	var parry_only_move_start: Vector2 = game.player.global_position
	game.player._physics_process(0.1)
	var parry_only_move_distance: float = game.player.global_position.distance_to(parry_only_move_start)
	assert(is_equal_approx(game.player.simulation_scale, 0.5))
	game.player.set_external_time_scale(1.0)
	game.player.velocity = Vector2(tuning.get_value("run_speed"), 0.0)
	var normal_move_start: Vector2 = game.player.global_position
	game.player._physics_process(0.1)
	var normal_move_distance: float = game.player.global_position.distance_to(normal_move_start)
	assert(is_equal_approx(game.player.simulation_scale, 1.0))
	assert(focused_move_distance < normal_move_distance * 0.45)
	assert(parry_only_move_distance < normal_move_distance * 0.60)
	game._update_audio_tuning()
	assert(is_equal_approx(active_focus_voice.pitch_scale, 1.0))
	game.sfx_voices.erase(active_focus_voice)
	active_focus_voice.free()
	Input.action_release("move_right")
	game.player.set_physics_process(true)
	await physics_frame
	assert(game.player.focus_energy < focus_before)
	game._update_screen_effects(0.5)
	assert(game.rain_audio_player.pitch_scale > 0.99 and game.bgm_player.pitch_scale > 0.99)
	game.player.global_position = Vector2(1170.0, 640.0)
	for _i in range(6):
		await physics_frame
	game.player.velocity.y = -jump_launch_speed
	var minimum_jump_y: float = game.player.global_position.y
	for _i in range(105):
		await physics_frame
		minimum_jump_y = minf(minimum_jump_y, game.player.global_position.y)
	assert(minimum_jump_y < 450.0)
	assert(absf(game.player.global_position.y - 470.0) < 8.0)
	game.player.global_position = Vector2(150.0, 600.0)
	var first_enemy = game.enemies[0]
	first_enemy.global_position = game.player.global_position + Vector2(42, -42)
	game.enemy_bark_roll_override = 0.0
	game._show_enemy_bark(first_enemy)
	assert(game.enemy_bark_bubbles.has(first_enemy))
	assert(game.blood_effects.particles.is_empty())
	game._on_player_slash(game.player.global_position + Vector2(0, -34), 1.0, Vector2(1.0, -1.0).normalized())
	assert(not game.enemy_bark_bubbles.has(first_enemy))
	assert(game.blood_effects.particles.size() == game.blood_effects.PARTICLE_COUNT)
	var blood_start: Vector2 = game.blood_effects.particles[0]["position"]
	game.blood_effects._process(0.04)
	assert(Vector2(game.blood_effects.particles[0]["position"]).distance_to(blood_start) > 1.0)
	await process_frame
	assert(game._living_enemy_count() == game.TOTAL_ENEMIES - 1)
	game.rewind_sequence.reset_history()
	assert(is_equal_approx(game.rewind_sequence.calculate_playback_duration(40.0), 2.0))
	assert(is_equal_approx(game.rewind_sequence.calculate_playback_duration(120.0), 3.5))
	assert(is_equal_approx(game.rewind_sequence.calculate_playback_duration(200.0), 5.0))
	var synthetic_history: Array[Dictionary] = []
	for synthetic_index in range(game.rewind_sequence.MAX_HISTORY_FRAMES + 2):
		synthetic_history.append({"timeline_time": float(synthetic_index), "player": {}, "actors": [], "projectiles": []})
	game.rewind_sequence.history = synthetic_history
	game.rewind_sequence._compact_history_if_needed()
	assert(game.rewind_sequence.history.size() <= game.rewind_sequence.MAX_HISTORY_FRAMES)
	assert(is_equal_approx(float(game.rewind_sequence.history.front()["timeline_time"]), 0.0))
	assert(is_equal_approx(float(game.rewind_sequence.history.back()["timeline_time"]), float(game.rewind_sequence.MAX_HISTORY_FRAMES + 1)))
	assert(is_equal_approx(game.rewind_sequence.current_sample_interval, game.rewind_sequence.SAMPLE_INTERVAL * 2.0))
	game.rewind_sequence.reset_history()
	game.player.global_position = Vector2(210.0, 600.0)
	var archived_enemy: Node
	for rewind_enemy in game.enemies:
		if is_instance_valid(rewind_enemy) and rewind_enemy.alive:
			archived_enemy = rewind_enemy
			break
	assert(is_instance_valid(archived_enemy))
	var archived_enemy_start: Vector2 = archived_enemy.global_position
	game.elapsed = 12.0
	var initial_rewind_kills: int = game.kills
	game._on_enemy_fire(Vector2(680.0, 560.0), Vector2.LEFT, archived_enemy)
	var archived_shot: Node = game.projectiles.back()
	archived_shot.set_process(false)
	var archived_shot_start: Vector2 = archived_shot.global_position
	game._capture_rewind_frame(0.0)
	archived_enemy.kill()
	archived_enemy._physics_process(archived_enemy.DEATH_DURATION + 0.01)
	archived_shot._expire()
	assert(not archived_enemy.visible and not archived_enemy.is_queued_for_deletion())
	assert(not archived_shot.visible and not archived_shot.is_queued_for_deletion())
	for rewind_step in range(1, 481):
		game.player.global_position.x = 210.0 + rewind_step * 8.0
		game.elapsed = 12.0 + rewind_step * game.rewind_sequence.SAMPLE_INTERVAL
		game._capture_rewind_frame(game.rewind_sequence.SAMPLE_INTERVAL)
	var rewind_death_x: float = game.player.global_position.x
	game.player.die()
	await process_frame
	assert(game.state == game.RunState.DEAD)
	assert(game.last_sfx_stream == game.ENEMY_HIT_STREAM)
	assert(game.rewind_sequence.armed and not game.rewind_sequence.playing and game.rewind_sequence.overlay.visible)
	assert(game.rewind_sequence.death_group.visible and not game.rewind_sequence.rewind_group.visible)
	assert(game.rewind_sequence.death_title.text == "已死亡")
	assert(game.rewind_sequence.death_rewind_prompt.text == "R  //  倒放")
	assert(game.rewind_sequence.death_exit_prompt.text == "ESC  //  返回标题画面")
	assert(game.rewind_sequence.rewind_label.text == "<<  倒放")
	assert(game.rewind_sequence.history.size() >= 480)
	assert(absf(game.rewind_sequence.playback_source_duration - 40.0) < 0.1)
	assert(is_equal_approx(game.rewind_sequence.playback_duration, 2.0))
	assert(game.rewind_sequence.REVERSE_BGM_STREAM.get_length() > 57.0)
	assert(game.rewind_sequence.REWIND_NOISE_STREAM.get_length() >= 2.19)
	assert(game.bgm_player.stream_paused and game.rain_audio_player.stream_paused)
	assert(not game.player.is_processing() and not game.player.is_physics_processing())
	game._process(0.75)
	assert(game.rewind_sequence.armed and not game.rewind_sequence.playing)
	assert(is_equal_approx(game.player.global_position.x, rewind_death_x))
	Input.action_press("restart")
	game._process(0.0)
	Input.action_release("restart")
	assert(game.rewind_sequence.playing and not game.rewind_sequence.armed)
	assert(not game.rewind_sequence.death_group.visible and game.rewind_sequence.rewind_group.visible)
	game.rewind_sequence._process(game.rewind_sequence.playback_duration * 0.72)
	assert(game.player.global_position.x < rewind_death_x)
	game.rewind_sequence._process(game.rewind_sequence.playback_duration)
	assert(game.state == game.RunState.DEAD)
	assert(game.rewind_sequence.is_splicing_reset() and game.rewind_sequence.overlay.visible)
	assert(is_equal_approx(game.player.global_position.x, 210.0))
	assert(is_equal_approx(game.elapsed, 12.0) and game.kills == initial_rewind_kills)
	assert(archived_enemy.alive and archived_enemy.visible and archived_enemy.global_position.is_equal_approx(archived_enemy_start))
	assert(archived_shot.alive and archived_shot.visible and archived_shot.global_position.is_equal_approx(archived_shot_start))
	assert(game.rewind_sequence.rewind_label.text == "<<  倒放")
	game.rewind_sequence._process(game.rewind_sequence.RESET_COVER_SECONDS + 0.01)
	assert(game.rewind_sequence.is_splicing_reset() and game.rewind_sequence.overlay.visible)
	assert(game.rewind_sequence.wash.color.a > 0.99)
	assert(game.state == game.RunState.PLAYING)
	game.rewind_sequence._process(game.rewind_sequence.RESET_HOLD_SECONDS + 0.01)
	await process_frame
	assert(not game.rewind_sequence.playing and not game.rewind_sequence.overlay.visible)
	assert(game._living_enemy_count() == game.TOTAL_ENEMIES)
	assert(game.player.alive)
	game.auto_death_title_scene_change = false
	game.rewind_sequence.reset_history()
	game._capture_rewind_frame(0.0)
	game.player.die()
	await process_frame
	assert(game.rewind_sequence.is_waiting_for_input())
	Input.action_press("pause_game")
	game._process(0.0)
	Input.action_release("pause_game")
	assert(game.death_title_requested and not game.rewind_sequence.overlay.visible)
	game._restart_room()
	await process_frame
	assert(not game.death_title_requested and not game.bgm_player.stream_paused)
	for enemy in game.enemies:
		if is_instance_valid(enemy) and enemy.alive:
			enemy.kill()
	await process_frame
	assert(game.gate_open)
	assert(game.environment_art.gate_open)
	game.auto_boss_scene_change = false
	game.player.global_position.x = game.EXIT_TRIGGER_X + 5.0
	await process_frame
	assert(game.state == game.RunState.COMPLETE)
	assert(game.BOSS_SCENE == "res://scenes/boss_battle.tscn")
	assert(game.NEXT_SCENE == "res://scenes/interior_level.tscn")
	assert(game.boss_transition_requested)
	var pre_boss_menu_layers := 0
	for direct_child in game.get_children():
		if direct_child is CanvasLayer and direct_child.layer == 40:
			pre_boss_menu_layers += 1
	assert(pre_boss_menu_layers == 0)
	game._restart_room()
	await process_frame
	assert(game.state == game.RunState.PLAYING)
	assert(not game.boss_transition_requested)
	assert(game._living_enemy_count() == game.TOTAL_ENEMIES)
	assert(not game.gate_open and not game.environment_art.gate_open)
	print("[SMOKE_PASS] v16 supplied defaults, dead-gunner fire cancellation, shared time scale, routing, rewind, and combat verified")
	var audio_children: Array[AudioStreamPlayer] = []
	for child in game.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
			audio_children.append(child)
	await create_timer(0.12).timeout
	for audio_child in audio_children:
		if is_instance_valid(audio_child):
			audio_child.free()
	game.free()
	shot = null
	late_gunner_shot = null
	first_enemy = null
	overhead_enemy = null
	stationary_edge_enemy = null
	tuned_blade = null
	tuned_gunner = null
	game = null
	frames = null
	tuning = null
	game_scene = null
	title_scene = null
	quit(0)
