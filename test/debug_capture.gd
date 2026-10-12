extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	I18n.set_language("zh_CN", false)
	await get_tree().process_frame
	var capture_dir := OS.get_environment("GAME_CAPTURE_DIR")
	if capture_dir.is_empty():
		capture_dir = "/tmp/zero-hour-captures"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var title_scene := load("res://scenes/title_screen.tscn") as PackedScene
	var title := title_scene.instantiate()
	add_child(title)
	await _settle(60)
	assert(title.find_child("CrtPixelFilter", true, false) == null)
	assert(title.find_child("StartPrompt", true, false) is Label)
	assert(title.find_children("*", "Button", true, false).size() == 3)
	assert((title.get_node("TitleContent") as Control).get_child_count() == 5)
	assert(title.find_child("BestRunLabel", true, false) == null)
	assert(title.find_child("StoryPrologueButton", true, false) is Button)
	assert((title.find_child("StoryPrologueButton", true, false) as Button).text == "剧情序章  //  从任务简报开始")
	assert(title.find_child("BossTestButton", true, false) is Button)
	_save_view(capture_dir.path_join("title.png"))
	title.queue_free()
	await get_tree().process_frame
	var tuning = load("res://scripts/tuning_store.gd")
	tuning.reset()
	var boss_scene := load("res://scenes/boss_battle.tscn") as PackedScene
	var boss_battle := boss_scene.instantiate()
	boss_battle.skip_story_intro = true
	add_child(boss_battle)
	await _settle(12)
	boss_battle.camera.position_smoothing_enabled = false
	boss_battle.camera.position = Vector2(boss_battle.ARENA_WIDTH * 0.5, 360.0)
	boss_battle.player.global_position = Vector2(700.0, boss_battle.STORY_GROUND_Y)
	boss_battle.boss.global_position = Vector2(1050.0, boss_battle.STORY_GROUND_Y)
	boss_battle.state = boss_battle.BattleState.INTRO
	boss_battle.player.set_forced_idle_visual(true)
	boss_battle.player.set_physics_process(false)
	boss_battle.player.set_control_enabled(false)
	boss_battle.boss.set_physics_process(false)
	boss_battle._set_combat_hud_visible(false)
	boss_battle._stop_boss_music()
	assert(not boss_battle.bgm_player.playing)
	boss_battle.tv_transition.set_aspect_ratio(boss_battle.CINEMATIC_ASPECT)
	var boss_story: Array[Dictionary] = boss_battle.StoryStore.get_scene("boss_arrival")
	assert(not boss_story.is_empty())
	boss_battle._show_boss_story_bubble(boss_battle.boss, boss_story[0])
	boss_battle.story_typewriter.begin_line(boss_battle.active_story_bubble, boss_battle.active_story_hint, boss_battle.active_story_bubble.text, 32.0)
	boss_battle.story_typewriter.reveal_immediately()
	await _settle(2)
	assert(is_equal_approx(boss_battle.tv_transition.top_bar.size.y, (720.0 - 1280.0 / 2.35) * 0.5))
	assert(String(boss_story[0]["text"]) in boss_battle.active_story_bubble.text)
	assert(boss_battle.active_story_bubble.position.y + boss_battle.active_story_bubble.size.y <= -190.0)
	_save_view(capture_dir.path_join("boss_story_intro.png"))
	boss_battle._clear_boss_story_bubble()
	boss_battle.tv_transition.set_aspect_ratio(16.0 / 9.0)
	boss_battle._begin_boss_combat()
	assert(boss_battle.bgm_player.playing)
	assert(boss_battle.BOSS_BGM_STREAM.resource_path == "res://assets/audio/warden_boss_theme.ogg")
	assert(boss_battle.bgm_player.stream is AudioStreamOggVorbis and boss_battle.bgm_player.stream.loop)
	boss_battle.player.set_physics_process(false)
	boss_battle.player.set_control_enabled(false)
	boss_battle.boss.set_physics_process(false)
	boss_battle.boss.state = boss_battle.boss.BossState.MELEE_WINDUP
	boss_battle.boss.current_melee_is_teleport = false
	boss_battle.boss.state_clock = 0.20
	boss_battle._on_boss_attack_announced("高速逼近 // 斩击格挡", Color("ff4b42"))
	boss_battle.boss.queue_redraw()
	await _settle(2)
	assert(boss_battle.boss.health == 25)
	assert(boss_battle.boss_health_label.text == "守门人  //  25 / 25")
	_save_view(capture_dir.path_join("boss_melee_telegraph.png"))
	boss_battle.boss.current_melee_is_teleport = true
	boss_battle.boss.state_clock = 0.16
	boss_battle._on_boss_attack_announced("相位突袭 // 斩击格挡", Color("ff4b42"))
	boss_battle.boss.queue_redraw()
	await _settle(2)
	_save_view(capture_dir.path_join("boss_teleport_telegraph.png"))
	boss_battle.player.global_position = Vector2(700.0, boss_battle.STORY_GROUND_Y)
	boss_battle.boss.global_position = boss_battle.player.global_position + Vector2(64.0, 0.0)
	boss_battle.boss.state = boss_battle.boss.BossState.MELEE_DASH
	boss_battle.boss.state_clock = 0.25
	boss_battle.boss.damage_invulnerability = 0.0
	boss_battle.boss_hit_during_player_attack = false
	boss_battle.set_process(false)
	boss_battle._on_player_slash(boss_battle.player.global_position + Vector2(0.0, -34.0), 1.0, Vector2.RIGHT, true)
	await _settle(2)
	assert(boss_battle.parry_slow_remaining > 0.29)
	assert(boss_battle.parry_zoom_remaining > 0.2)
	assert(is_equal_approx(boss_battle.player.simulation_scale, tuning.get_value("melee_parry_time_scale")))
	assert(boss_battle.camera.zoom.x > 1.0 / tuning.get_value("camera_distance"))
	assert(boss_battle.parry_sparks.size() > 0)
	_save_view(capture_dir.path_join("boss_blade_parry_slowdown.png"))
	boss_battle._reset_parry_feedback()
	boss_battle._apply_camera_distance()
	boss_battle.player.set_external_time_scale(1.0)
	boss_battle.boss.simulation_scale = 1.0
	boss_battle.set_process(true)
	boss_battle.boss.health = 12
	boss_battle._on_boss_health_changed(12, 25)
	boss_battle.boss.state = boss_battle.boss.BossState.RANGED_WINDUP
	boss_battle.boss.state_clock = 0.28
	boss_battle._on_boss_attack_announced("弹道连射 // 弹反", Color("ffb04f"))
	boss_battle.boss.queue_redraw()
	await _settle(2)
	assert(is_equal_approx(boss_battle.boss_fill.size.x, 238.08))
	_save_view(capture_dir.path_join("boss_ranged_half_health.png"))
	boss_battle._stop_boss_music()
	assert(not boss_battle.bgm_player.playing)
	boss_battle.state = boss_battle.BattleState.POST_BOSS
	boss_battle.boss.alive = false
	boss_battle.boss.health = 0
	boss_battle.boss.state = boss_battle.boss.BossState.DEAD
	boss_battle.boss.death_time = 0.22
	boss_battle.boss.queue_redraw()
	boss_battle.player.set_forced_idle_visual(true)
	boss_battle.player.set_control_enabled(false)
	boss_battle._set_combat_hud_visible(false)
	boss_battle.set_process(false)
	boss_battle._start_finisher_slowdown()
	boss_battle.blood_effects.spawn_spray(boss_battle.boss.global_position + Vector2(0.0, -58.0), Vector2.LEFT)
	assert(is_equal_approx(boss_battle.finisher_slow_remaining, 1.0))
	assert(is_equal_approx(boss_battle.boss.simulation_scale, 0.5))
	await _settle(2)
	assert(is_equal_approx(boss_battle.finisher_slow_remaining, 1.0))
	assert(not boss_battle.hud_layer.visible and boss_battle.boss.health == 0)
	_save_view(capture_dir.path_join("boss_finisher_slowdown.png"))
	boss_battle._reset_finisher_slowdown()
	boss_battle.set_process(true)
	boss_battle.boss.death_time = boss_battle.boss.DEATH_DURATION
	boss_battle.tv_transition.set_aspect_ratio(boss_battle.CINEMATIC_ASPECT)
	var boss_passed_story: Array[Dictionary] = boss_battle.StoryStore.get_scene("boss_passed")
	assert(not boss_passed_story.is_empty())
	boss_battle._show_boss_story_bubble(boss_battle.boss, boss_passed_story[0])
	boss_battle.story_typewriter.begin_line(boss_battle.active_story_bubble, boss_battle.active_story_hint, boss_battle.active_story_bubble.text, 32.0)
	boss_battle.story_typewriter.reveal_immediately()
	await _settle(2)
	assert(String(boss_passed_story[0]["text"]) in boss_battle.active_story_bubble.text)
	_save_view(capture_dir.path_join("boss_final_words.png"))
	boss_battle._clear_boss_story_bubble()
	boss_battle.tv_transition.set_aspect_ratio(16.0 / 9.0)
	boss_battle.post_boss_cinematic.show_slide_preview(0)
	await _settle(2)
	_save_view(capture_dir.path_join("post_boss_warehouse.png"))
	boss_battle.post_boss_cinematic.show_slide_preview(2)
	await _settle(2)
	_save_view(capture_dir.path_join("post_boss_blade.png"))
	boss_battle.post_boss_cinematic.show_slide_preview(4)
	await _settle(2)
	_save_view(capture_dir.path_join("post_boss_cat.png"))
	boss_battle.post_boss_cinematic.show_final_preview()
	await _settle(2)
	assert(boss_battle.post_boss_cinematic.final_title.text == "未完待续……")
	_save_view(capture_dir.path_join("post_boss_to_be_continued.png"))
	for boss_audio in boss_battle.get_children():
		if boss_audio is AudioStreamPlayer:
			boss_audio.stop()
			boss_audio.stream = null
	await get_tree().create_timer(0.12).timeout
	boss_battle.free()
	boss_battle = null
	boss_scene = null
	await get_tree().process_frame
	var game_scene := load("res://scenes/game.tscn") as PackedScene
	var game := game_scene.instantiate()
	add_child(game)
	await _settle(12)
	game.entrance_transition_duration = 0.0
	await game._open_entrance_transition()
	game._open_pause_menu()
	assert(get_tree().paused and game.pause_menu.is_open())
	assert(game.pause_menu.overlay.find_child("PauseTutorialButton", true, false) is Button)
	await _settle(2)
	_save_view(capture_dir.path_join("gameplay_pause_menu.png"))
	game.pause_menu.resume_game()
	assert(not get_tree().paused and not game.pause_menu.is_open())
	game._clear_all_enemy_barks()
	var bark_capture_enemy = game.enemies[0]
	var bark_capture_enemy_position: Vector2 = bark_capture_enemy.global_position
	bark_capture_enemy.remove_meta("story_bark_shown")
	bark_capture_enemy.global_position = game.player.global_position + Vector2(245.0, 0.0)
	bark_capture_enemy.set_physics_process(false)
	game.enemy_bark_roll_override = 0.0
	game._update_enemy_barks(0.01)
	assert(game.enemy_bark_bubbles.has(bark_capture_enemy))
	await _settle(2)
	_save_view(capture_dir.path_join("gameplay_enemy_bark.png"))
	game._clear_all_enemy_barks()
	game.enemy_bark_roll_override = -1.0
	bark_capture_enemy.global_position = bark_capture_enemy_position
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	game.camera.position_smoothing_enabled = false
	game.player.global_position = Vector2(1030, 420)
	game.camera.position = Vector2(1080, 360)
	game.player.focus_energy = 78.0
	game.player.set_physics_process(false)
	game.player.velocity = Vector2.ZERO
	game.player.attack_time = 0.0
	game.player.queue_redraw()
	await _settle(2)
	assert(not game.crt_filter.is_filter_enabled())
	assert(not game.crt_filter.overlay.visible)
	assert(game.crt_filter.layer < (game.controls_panel.get_parent() as CanvasLayer).layer)
	assert(game.world_art.last_camera_center.is_equal_approx(game.world_art.get_rendered_camera_center()))
	assert(game.camera.zoom.is_equal_approx(Vector2.ONE / 1.45))
	assert((game.world_art.last_world_rect.size * game.camera.zoom).is_equal_approx(game.get_viewport_rect().size))
	_save_view(capture_dir.path_join("gameplay_no_crt.png"))
	_save_view(capture_dir.path_join("gameplay_camera_distance_1_45.png"))
	_save_view(capture_dir.path_join("gameplay_idle_scale.png"))
	_save_view(capture_dir.path_join("gameplay_rain_normal.png"))
	_save_view(capture_dir.path_join("gameplay_original_skyline_start.png"))
	_save_view(capture_dir.path_join("gameplay_textured_rooftop_start.png"))
	game.player.global_position = Vector2(1030, 600)
	game.player.velocity = Vector2(220.0, 0.0)
	game.player._sync_rim_light()
	game.player.queue_redraw()
	game.enemies[1].global_position = Vector2(1135, 600)
	game.enemies[1].velocity = Vector2.ZERO
	game.enemies[1]._sync_rim_light()
	game.enemies[1].queue_redraw()
	game.camera.position = Vector2(1080, 470)
	game.camera.force_update_scroll()
	tuning.set_value("camera_distance", 0.75)
	game._apply_camera_distance()
	await _settle(2)
	assert(game.camera.zoom.is_equal_approx(Vector2(1.0 / 0.75, 1.0 / 0.75)))
	assert(is_equal_approx(float(game.player._resolve_visual_state()["scale"]), game.player.IDLE_SPRITE_SCALE))
	assert(is_instance_valid(game.player.rim_light) and is_instance_valid(game.enemies[1].rim_light))
	_save_view(capture_dir.path_join("gameplay_run_character_lighting.png"))
	tuning.set_value("camera_distance", 1.45)
	game._apply_camera_distance()
	game.camera.position = Vector2(1080, 360)
	game.camera.force_update_scroll()
	game.player.global_position = Vector2(1030, 420)
	game.player.velocity = Vector2.ZERO
	game.player.attack_time = 0.16
	game.player.queue_redraw()
	await _settle(2)
	_save_view(capture_dir.path_join("gameplay_attack_scale.png"))
	var start_offsets: Array[float] = game.world_art.last_screen_offsets.duplicate()
	var start_source_rect: Rect2 = game.world_art.last_source_rect
	tuning.set_value("camera_distance", 1.60)
	game._apply_camera_distance()
	await _settle(2)
	assert(game.camera.zoom.is_equal_approx(Vector2(0.625, 0.625)))
	assert(game.world_art.last_source_rect.is_equal_approx(start_source_rect))
	assert((game.world_art.last_world_rect.size * game.camera.zoom).is_equal_approx(game.get_viewport_rect().size))
	_save_view(capture_dir.path_join("gameplay_camera_distance_1_60.png"))
	tuning.set_value("camera_distance", 1.45)
	game._apply_camera_distance()
	game.camera.position = Vector2(2600, 360)
	game.player.global_position = Vector2(2550, 430)
	await _settle(2)
	assert(game.world_art.last_screen_offsets == start_offsets and start_offsets == [0.0])
	assert(game.world_art.last_source_rect.is_equal_approx(start_source_rect))
	_save_view(capture_dir.path_join("gameplay_original_skyline_mid.png"))
	_save_view(capture_dir.path_join("gameplay_textured_rooftop_mid.png"))
	game.camera.position = Vector2(1080, 360)
	game.player.global_position = Vector2(1030, 420)
	game.player.attack_time = 0.0
	game.player.queue_redraw()
	game.player.set_physics_process(true)
	game._trigger_thunder()
	game._update_storm(0.8)
	game._update_screen_effects(0.016)
	await _settle(1)
	_save_view(capture_dir.path_join("gameplay_lightning.png"))
	game.lightning_flash = 0.0
	game.lightning_echo_timer = -1.0
	game._update_screen_effects(0.016)
	await _settle(1)
	Input.action_press("focus")
	await _settle(4)
	assert(not game.player.FOCUS_RING_ENABLED)
	_save_view(capture_dir.path_join("gameplay_focus.png"))
	Input.action_release("focus")
	game.player.velocity.y = -game.player.get_jump_launch_speed()
	game.player.jump_animation_clock = 0.0
	await _settle(8)
	assert(game.player.jump_animation_clock > 0.08)
	_save_view(capture_dir.path_join("gameplay_jump_fast.png"))
	game.player.global_position = Vector2(1030, 420)
	game.player.velocity = Vector2.ZERO
	game.player.attack_time = 0.16
	game.enemies[1].windup = 0.24
	await _settle(2)
	_save_view(capture_dir.path_join("gameplay_slash.png"))
	var interception_pool: Array = []
	var capture_interceptor = load("res://scripts/projectile.gd").new()
	capture_interceptor.position = Vector2(1240.0, 348.0)
	capture_interceptor.setup(Vector2.RIGHT, game.player, [], null, interception_pool)
	capture_interceptor.intercepted_projectile.connect(game._on_projectile_intercepted)
	capture_interceptor.z_index = 6
	game.add_child(capture_interceptor)
	capture_interceptor.set_process(false)
	interception_pool.append(capture_interceptor)
	var capture_hostile_shot = load("res://scripts/projectile.gd").new()
	capture_hostile_shot.position = Vector2(1160.0, 348.0)
	capture_hostile_shot.setup(Vector2.LEFT, game.player, [], null, interception_pool)
	capture_hostile_shot.z_index = 6
	game.add_child(capture_hostile_shot)
	capture_hostile_shot.set_process(false)
	interception_pool.append(capture_hostile_shot)
	capture_interceptor.reflect(1.0)
	capture_interceptor._process(0.07)
	assert(capture_interceptor.alive and capture_interceptor.intercepted_projectile_count == 1)
	assert(not capture_hostile_shot.alive)
	assert(game.projectile_explosions.total_bursts == 1 and game.projectile_explosions.particles.size() > 0)
	await _settle(2)
	_save_view(capture_dir.path_join("gameplay_projectile_interception.png"))
	capture_interceptor.free()
	interception_pool.clear()
	game.projectile_explosions.clear_effects()
	var debug_shot = load("res://scripts/projectile.gd").new()
	debug_shot.position = game.player.global_position + Vector2(180.0, -72.0)
	debug_shot.velocity = Vector2(-560.0, 0.0)
	debug_shot.set_process(false)
	game.add_child(debug_shot)
	game.projectiles.append(debug_shot)
	var tweak_panel = game.tuning_panel.panel
	assert(game.tuning_panel.tab_pages.size() == 4)
	game.tuning_panel.select_tab(1)
	var tweak_scroll = game.tuning_panel.get_active_scroll()
	assert(is_instance_valid(tweak_panel) and is_instance_valid(tweak_scroll))
	assert(not game._should_draw_hitbox_preview())
	game.player.set_physics_process(false)
	game.player.attack_time = game.player.ATTACK_DURATION * (1.0 - 2.25 / 12.0)
	game.player.attack_direction = Vector2.RIGHT
	game.player.queue_redraw()
	tweak_panel.visible = true
	assert(game._should_draw_hitbox_preview())
	await _settle(2)
	assert(game.hitbox_debug_overlay.visible)
	assert(game.player.get_attack_frame_index() == game.player.STANDING_HIT_START_FRAME)
	assert(game.hitbox_debug_overlay._should_draw_attack_hitbox())
	_save_view(capture_dir.path_join("gameplay_tweaks_player_hitbox.png"))
	game.player.attack_time = 0.0
	game.player.queue_redraw()
	await _settle(2)
	assert(not game.hitbox_debug_overlay._should_draw_attack_hitbox())
	_save_view(capture_dir.path_join("gameplay_tweaks_attack_inactive.png"))
	game.player.attack_time = 0.16
	game.player.attack_direction = Vector2.RIGHT
	game.player.queue_redraw()
	tweak_scroll.scroll_vertical = 320
	await _settle(2)
	assert(game.hitbox_debug_overlay._should_draw_attack_hitbox())
	_save_view(capture_dir.path_join("gameplay_tweaks_collision_controls.png"))
	for parry_control_name in ["melee_parry_slow_duration", "melee_parry_time_scale", "parry_zoom_amount", "parry_zoom_duration"]:
		assert(tweak_panel.find_child(parry_control_name, true, false) is HSlider)
	tweak_scroll.scroll_vertical = 5000
	await _settle(2)
	_save_view(capture_dir.path_join("gameplay_tweaks_parry_feedback.png"))
	game.player.attack_time = 0.0
	game.tuning_panel.select_tab(2)
	tweak_scroll = game.tuning_panel.get_active_scroll()
	var enemy_hurtbox_width_slider := tweak_panel.find_child("enemy_hurtbox_width", true, false) as HSlider
	var enemy_hurtbox_height_slider := tweak_panel.find_child("enemy_hurtbox_height", true, false) as HSlider
	assert(is_instance_valid(enemy_hurtbox_width_slider) and is_instance_valid(enemy_hurtbox_height_slider))
	enemy_hurtbox_width_slider.value = 44.0
	enemy_hurtbox_height_slider.value = 112.0
	for enemy in game.enemies:
		enemy._apply_hurtbox_tuning()
	await _settle(2)
	assert(game.enemies[0].get_hurtbox_size().is_equal_approx(Vector2(44.0, 112.0)))
	_save_view(capture_dir.path_join("gameplay_tweaks_enemies.png"))
	_save_view(capture_dir.path_join("gameplay_tweaks_enemy_hurtbox.png"))
	for warden_control_name in ["boss_max_health", "boss_katana_damage", "boss_melee_parry_damage", "boss_reflected_damage", "boss_action_interval", "boss_dash_speed", "boss_projectile_speed"]:
		assert(tweak_panel.find_child(warden_control_name, true, false) is HSlider)
	tweak_scroll.scroll_vertical = 5000
	await _settle(2)
	_save_view(capture_dir.path_join("gameplay_tweaks_warden_difficulty.png"))
	enemy_hurtbox_width_slider.value = 30.0
	enemy_hurtbox_height_slider.value = 97.0
	for enemy in game.enemies:
		enemy._apply_hurtbox_tuning()
	game.tuning_panel.select_tab(3)
	tweak_scroll = game.tuning_panel.get_active_scroll()
	assert(tweak_panel.find_child("rim_width", true, false) is HSlider)
	assert(tweak_panel.find_child("rim_brightness", true, false) is HSlider)
	await _settle(2)
	_save_view(capture_dir.path_join("gameplay_tweaks_audio_visual.png"))
	tweak_panel.visible = false
	assert(not game._should_draw_hitbox_preview())
	game.player.set_physics_process(true)
	tweak_scroll.scroll_vertical = 0
	game.projectiles.erase(debug_shot)
	debug_shot.free()
	debug_shot = null
	var parry_shot = load("res://scripts/projectile.gd").new()
	parry_shot.position = game.player.global_position + Vector2(52.0, -34.0)
	parry_shot.velocity = Vector2(-560.0, 35.0)
	game.add_child(parry_shot)
	game.projectiles.append(parry_shot)
	game._on_player_slash(game.player.global_position + Vector2(0, -34), 1.0, Vector2.RIGHT)
	assert(game.parry_sparks.size() == 32)
	assert(game.parry_slow_remaining > 0.29 and game.parry_zoom_remaining > 0.2)
	assert(game.camera.zoom.x > 1.0 / tuning.get_value("camera_distance"))
	await _settle(1)
	_save_view(capture_dir.path_join("gameplay_parry.png"))
	_save_view(capture_dir.path_join("gameplay_parry_slow_zoom.png"))
	game._reset_parry_feedback()
	game._apply_camera_distance()
	game.projectiles.erase(parry_shot)
	parry_shot.free()
	game.player.global_position = Vector2(1480.0, 600.0)
	game.player.velocity = Vector2.ZERO
	game.player.attack_time = 0.0
	game.player.attack_cooldown = 0.0
	var dash_start: Vector2 = game.player.global_position
	assert(game.player.begin_slash(Vector2(1.0, -1.0)))
	await _settle(6)
	assert(game.player.global_position.x > dash_start.x + 70.0)
	assert(game.player.global_position.y < dash_start.y - 70.0)
	_save_view(capture_dir.path_join("gameplay_diagonal_dash.png"))
	game.player.global_position = Vector2(3600, 405)
	game.camera.position = Vector2(3650, 360)
	await _settle(3)
	_save_view(capture_dir.path_join("gameplay_long_level.png"))
	_save_view(capture_dir.path_join("gameplay_textured_rooftop_late.png"))
	game.player.global_position = Vector2(4930.0, 600.0)
	game.environment_art.set_gate_open(true)
	await _settle(3)
	assert(game.environment_art.gate_open)
	_save_view(capture_dir.path_join("gameplay_textured_exit_gate.png"))
	game.environment_art.set_gate_open(false)
	game.player.global_position = Vector2(3600.0, 405.0)
	await _settle(2)
	game.enemies[6].kill()
	assert(game.blood_effects.particles.size() == game.blood_effects.PARTICLE_COUNT)
	await _settle(4)
	_save_view(capture_dir.path_join("gameplay_blood_spray.png"))
	for remaining_enemy in game.enemies:
		if is_instance_valid(remaining_enemy):
			remaining_enemy.queue_free()
	game.enemies.clear()
	game.blood_effects.clear_particles()
	game.gate_open = true
	game.environment_art.set_gate_open(true)
	game.objective_label.text = "出口已开启  //  前往橙色闸门"
	game._update_hud()
	await _settle(1)
	assert(game._living_enemy_count() == 0)
	game.auto_boss_scene_change = false
	game._complete_run()
	await _settle(2)
	assert(game.boss_transition_requested)
	for direct_child in game.get_children():
		assert(not (direct_child is CanvasLayer and direct_child.layer == 40))
	game._restart_room()
	await _settle(2)
	game.entrance_transition.set_closed(false)
	game.entrance_transition_active = false
	game.state = game.RunState.PLAYING
	game.player.set_control_enabled(true)
	game.rewind_sequence.reset_history()
	for rewind_step in range(481):
		game.player.global_position = Vector2(460.0 + rewind_step * 6.0, 600.0)
		game._capture_rewind_frame(game.rewind_sequence.SAMPLE_INTERVAL)
	game.player.die()
	assert(game.rewind_sequence.is_waiting_for_input() and game.rewind_sequence.overlay.visible)
	assert(game.rewind_sequence.death_title.text == "已死亡")
	await _settle(2)
	_save_view(capture_dir.path_join("gameplay_death_choice.png"))
	game.rewind_sequence.set_process(false)
	assert(game.rewind_sequence.start_rewind())
	game.rewind_sequence._process(game.rewind_sequence.playback_duration * 0.46)
	assert(game.rewind_sequence.rewind_label.text == "<<  倒放")
	assert(absf(game.rewind_sequence.playback_source_duration - 40.0) < 0.2)
	await _settle(2)
	_save_view(capture_dir.path_join("gameplay_rewind.png"))
	game.rewind_sequence._process(game.rewind_sequence.playback_duration)
	assert(game.rewind_sequence.is_splicing_reset())
	game.rewind_sequence._update_reset_cover(0.72)
	await _settle(2)
	_save_view(capture_dir.path_join("gameplay_rewind_reset_splice.png"))
	game.rewind_sequence.cancel(true)
	game.rewind_sequence.set_process(true)
	print("[DEBUG_CAPTURE_PASS] 1s/0.5x boss finisher, parry zoom, rewind, boss story, comic ending, and combat captured")
	var audio_children: Array[AudioStreamPlayer] = []
	for child in game.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
			audio_children.append(child)
	await get_tree().create_timer(0.35).timeout
	for audio_child in audio_children:
		if is_instance_valid(audio_child):
			audio_child.free()
	audio_children.clear()
	await get_tree().create_timer(0.20).timeout
	tweak_panel = null
	tweak_scroll = null
	parry_shot = null
	game.free()
	game = null
	game_scene = null
	title_scene = null
	await get_tree().create_timer(0.20).timeout
	get_tree().quit(0)

func _settle(frames: int) -> void:
	for _i in range(frames):
		await get_tree().process_frame

func _save_view(path: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	assert(error == OK)
