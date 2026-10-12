extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var smoke_i18n = root.get_node("I18n")
	smoke_i18n.set_language("zh_CN", false)
	var tuning = load("res://scripts/tuning_store.gd")
	tuning.reset()
	assert(tuning.CONFIG_VERSION == 16)
	assert(is_equal_approx(tuning.get_value("boss_max_health"), 25.0))
	assert(is_equal_approx(tuning.get_value("boss_katana_damage"), 1.0))
	assert(is_equal_approx(tuning.get_value("boss_melee_parry_damage"), 2.0))
	assert(is_equal_approx(tuning.get_value("boss_reflected_damage"), 2.0))
	assert(is_equal_approx(tuning.get_value("boss_action_interval"), 0.58))
	assert(is_equal_approx(tuning.get_value("boss_dash_speed"), 980.0))
	assert(is_equal_approx(tuning.get_value("boss_projectile_speed"), 690.0))
	assert(is_equal_approx(tuning.get_value("melee_parry_slow_duration"), 0.3))
	assert(is_equal_approx(tuning.get_value("melee_parry_time_scale"), 0.5))
	assert(is_equal_approx(tuning.get_value("parry_zoom_amount"), 0.02))
	assert(is_equal_approx(tuning.get_value("parry_zoom_duration"), 0.28))

	var title_scene := load("res://scenes/title_screen.tscn") as PackedScene
	assert(title_scene != null)
	var title := title_scene.instantiate()
	root.add_child(title)
	await process_frame
	var boss_test_button := title.find_child("BossTestButton", true, false) as Button
	assert(is_instance_valid(boss_test_button))
	assert(boss_test_button.text == "首领测试  //  守门人")
	assert(boss_test_button.pressed.get_connections().size() == 1)
	assert(title.BOSS_SCENE == "res://scenes/boss_battle.tscn")
	title.queue_free()
	await process_frame

	var boss_scene := load("res://scenes/boss_battle.tscn") as PackedScene
	assert(boss_scene != null)
	var battle := boss_scene.instantiate()
	battle.intro_transition_scale = 0.0
	root.add_child(battle)
	assert(battle.state == battle.BattleState.INTRO)
	assert(not battle.boss_intro_active and not battle.boss_intro_finished)
	assert(not battle.player.control_enabled and battle.player.force_idle_visual)
	assert(not battle.player.is_physics_processing() and not battle.boss.is_physics_processing())
	assert(is_equal_approx(battle.player.get_hurtbox_rect_world().end.y, battle.FLOOR_Y))
	assert(is_equal_approx(battle.boss.get_hurtbox_rect_world().end.y, battle.FLOOR_Y))
	assert(not battle.hud_layer.visible and not battle.touch_input.visible)
	assert(battle.tv_transition.is_closed)
	assert(battle.BOSS_BGM_STREAM.resource_path == "res://assets/audio/warden_boss_theme.ogg")
	assert(battle.BOSS_BGM_STREAM.get_length() >= 44.9 and battle.BOSS_BGM_STREAM.get_length() <= 45.1)
	assert(not battle.bgm_player.playing)
	battle._open_pause_menu()
	assert(not paused and not battle.pause_menu.is_open())
	battle.tv_transition.set_aspect_ratio(battle.CINEMATIC_ASPECT)
	var cinematic_bar_height: float = battle.tv_transition.get_bar_height_for_aspect(2.35)
	assert(is_equal_approx(cinematic_bar_height, (720.0 - 1280.0 / 2.35) * 0.5))
	assert(is_equal_approx(battle.tv_transition.top_bar.size.y, cinematic_bar_height))
	assert(is_equal_approx(battle.tv_transition.bottom_bar.position.y, 720.0 - cinematic_bar_height))
	var boss_arrival: Array[Dictionary] = battle.StoryStore.get_scene("boss_arrival")
	assert(not boss_arrival.is_empty())
	battle._show_boss_story_bubble(battle.boss, boss_arrival[0])
	assert(is_instance_valid(battle.active_story_bubble))
	assert(battle.active_story_bubble.get_parent() == battle.boss)
	assert(String(boss_arrival[0]["text"]) in battle.active_story_bubble.text)
	assert(battle.active_story_bubble.position.y + battle.active_story_bubble.size.y <= -190.0)
	battle.story_typewriter.begin_line(battle.active_story_bubble, battle.active_story_hint, battle.active_story_bubble.text, 32.0)
	assert(not battle.active_story_hint.visible)
	battle.story_typewriter.reveal_immediately()
	assert(battle.active_story_hint.visible and battle.active_story_hint.text == "J  //  继续")
	assert(battle.story_typewriter.TYPE_TICK.resource_path == "res://assets/audio/dialogue_type_tick.ogg")
	battle._clear_boss_story_bubble()
	battle.tv_transition.set_closed(true)
	for _i in range(12):
		await physics_frame
	assert(battle.state == battle.BattleState.PLAYING)
	assert(not battle.boss_intro_active and battle.boss_intro_finished)
	assert(battle.hud_layer.visible and battle.touch_input.visible)
	assert(is_zero_approx(battle.tv_transition.top_bar.size.y))
	assert(battle.player.control_enabled and battle.player.is_physics_processing() and battle.boss.is_physics_processing())
	assert(battle.bgm_player.playing)
	assert(battle.bgm_player.stream is AudioStreamOggVorbis and battle.bgm_player.stream.loop)
	assert(is_instance_valid(battle.player) and battle.player.alive)
	assert(is_instance_valid(battle.boss) and battle.boss.alive)
	assert(battle.enemies == [battle.boss])
	assert(battle.boss.max_health == 25 and battle.boss.health == 25)
	assert(battle.boss.get_hurtbox_size().is_equal_approx(Vector2(48.0, 118.0)))
	assert(battle.boss_health_label.text == "守门人  //  25 / 25")
	assert(is_instance_valid(battle.boss_fill) and is_equal_approx(battle.boss_fill.size.x, 496.0))
	assert(battle.camera.zoom.is_equal_approx(Vector2.ONE / 1.45))
	assert(battle.world_art.name == "OriginalFixedSkyline")
	assert(battle.arena_art.name == "BossRooftopArena")
	assert(battle.platforms.size() == 3)
	assert(not battle.crt_filter.is_filter_enabled())
	assert(battle.pause_menu.overlay.find_child("PauseTutorialButton", true, false) is Button)
	assert(battle.pause_menu.restart_button.text == "重新挑战首领")
	for boss_slider_name in ["boss_max_health", "boss_katana_damage", "boss_melee_parry_damage", "boss_reflected_damage", "boss_action_interval", "boss_dash_speed", "boss_projectile_speed", "melee_parry_slow_duration", "melee_parry_time_scale", "parry_zoom_amount", "parry_zoom_duration"]:
		var boss_slider := battle.tuning_panel.panel.find_child(boss_slider_name, true, false) as HSlider
		assert(is_instance_valid(boss_slider) and not boss_slider.scrollable)
	assert(is_instance_valid(battle.hitbox_debug_overlay) and not battle.hitbox_debug_overlay.visible)
	battle.tuning_panel.panel.visible = true
	battle.hitbox_debug_overlay._process(0.0)
	assert(battle.hitbox_debug_overlay.visible)
	battle.tuning_panel.panel.visible = false
	battle.hitbox_debug_overlay._process(0.0)
	assert(not battle.hitbox_debug_overlay.visible)
	tuning.set_value("boss_max_health", 20.0)
	battle.boss._process(0.0)
	assert(battle.boss.max_health == 20 and battle.boss.health == 20)
	assert(battle.boss_health_label.text == "守门人  //  20 / 20")
	tuning.set_value("boss_max_health", 16.0)
	battle.boss._process(0.0)
	assert(battle.boss.max_health == 16 and battle.boss.health == 16)

	assert(battle.player.control_enabled)
	battle.boss.set_physics_process(false)
	battle.player.set_physics_process(false)
	battle.player.global_position = Vector2(700.0, 600.0)
	battle.boss.global_position = battle.player.global_position + Vector2(64.0, 0.0)
	battle.boss.state = battle.boss.BossState.RECOVER
	battle.boss.state_clock = 1.0
	battle.boss.damage_invulnerability = 0.0
	var slash_origin: Vector2 = battle.player.global_position + Vector2(0.0, -34.0)
	tuning.set_value("boss_katana_damage", 3.0)
	battle._on_player_slash(slash_origin, 1.0, Vector2.RIGHT, true)
	assert(battle.boss.health == 13)
	assert(battle.boss.alive and battle.state == battle.BattleState.PLAYING)
	assert(battle.boss.last_damage_source == "KATANA")
	assert(battle.boss_damage_events == 1)
	assert(battle.boss_fill.size.x < 496.0)
	tuning.set_value("boss_katana_damage", 1.0)
	battle.boss_hit_during_player_attack = false
	battle.boss.damage_invulnerability = 0.0
	battle._on_player_slash(slash_origin, 1.0, Vector2.RIGHT, true)
	assert(battle.boss.health == 12 and battle.boss.alive)

	tuning.set_value("boss_melee_parry_damage", 4.0)
	battle.boss_hit_during_player_attack = false
	battle.boss.damage_invulnerability = 0.0
	battle.boss.state = battle.boss.BossState.MELEE_DASH
	battle.boss.state_clock = 0.25
	assert(battle.boss.can_parry_melee())
	battle._on_player_slash(slash_origin, 1.0, Vector2.RIGHT, true)
	assert(battle.boss.health == 8)
	assert(battle.boss.state == battle.boss.BossState.STAGGER)
	assert(battle.boss.melee_parry_count == 1 and battle.melee_parry_events == 1)
	assert(battle.parry_sparks.size() == 34)
	assert(battle.last_sfx_stream == battle.PARRY_STREAM)
	assert(is_equal_approx(battle.parry_slow_remaining, 0.3))
	assert(is_equal_approx(battle.parry_zoom_remaining, 0.28))
	assert(battle.camera.zoom.x > 1.0 / tuning.get_value("camera_distance"))
	assert(battle.camera.position.is_equal_approx(Vector2(battle.ARENA_WIDTH * 0.5, 360.0)))
	assert(absf(battle.last_sfx_pitch_scale - 0.5) <= 0.02)
	assert(is_equal_approx(battle.player.external_time_scale, 0.5))
	battle.player.attack_time = 0.30
	battle.player._physics_process(0.10)
	assert(is_equal_approx(battle.player.simulation_scale, 0.5))
	assert(is_equal_approx(battle.player.attack_time, 0.25))
	battle._process(0.25)
	assert(is_equal_approx(battle.parry_slow_remaining, 0.05))
	assert(battle.parry_zoom_remaining > 0.0)
	assert(is_equal_approx(battle.player.simulation_scale, 0.5))
	assert(is_equal_approx(battle.boss.simulation_scale, 0.5))
	assert(is_equal_approx(battle.blood_effects.simulation_scale, 0.5))
	assert(is_equal_approx(battle.projectile_explosions.simulation_scale, 0.5))
	assert(is_equal_approx(battle.bgm_player.pitch_scale, 0.5))
	assert(is_equal_approx(battle.rain_audio_player.pitch_scale, 0.5))
	battle._process(0.80)
	assert(is_zero_approx(battle.parry_slow_remaining))
	assert(is_zero_approx(battle.parry_zoom_remaining))
	assert(is_equal_approx(battle.camera.zoom.x, 1.0 / tuning.get_value("camera_distance")))
	assert(is_equal_approx(battle.player.simulation_scale, 1.0))
	assert(is_equal_approx(battle.boss.simulation_scale, 1.0))
	assert(is_equal_approx(battle.bgm_player.pitch_scale, 1.0))
	battle.boss.damage_invulnerability = 0.0
	battle.boss_hit_during_player_attack = false
	battle.boss.global_position = battle.player.global_position + Vector2(64.0, 0.0)
	battle.boss.facing = -1.0
	battle.boss.state = battle.boss.BossState.MELEE_DASH
	battle.boss.state_clock = 0.08
	battle.boss.strike_committed = false
	battle.player.attack_direction = Vector2.RIGHT
	battle.player.attack_time = 0.16
	assert(battle.player.is_attack_hitbox_active())
	battle.boss._commit_melee_strike()
	assert(battle.player.alive)
	assert(battle.boss.health == 4)
	assert(battle.boss.state == battle.boss.BossState.STAGGER)
	assert(battle.boss.melee_parry_count == 2 and battle.melee_parry_events == 2)
	tuning.set_value("boss_melee_parry_damage", 2.0)
	battle.player.attack_time = 0.0
	battle._process(1.05)
	assert(is_zero_approx(battle.parry_slow_remaining))

	battle.boss.global_position = Vector2(1500.0, 600.0)
	battle.player.global_position = Vector2(700.0, 600.0)
	battle.boss.current_melee_is_teleport = false
	battle.boss.state = battle.boss.BossState.MELEE_WINDUP
	battle.boss.state_clock = 0.0
	battle.boss._physics_process(0.01)
	assert(battle.boss.state == battle.boss.BossState.MELEE_DASH)
	assert(battle.boss.state_clock > 0.75 and battle.boss.state_clock < 0.90)
	assert(battle.boss.dash_attack_count == 1)

	battle.boss.attack_index = 0
	battle.boss.melee_variant = 0
	battle.boss._begin_next_attack()
	assert(battle.boss.state == battle.boss.BossState.MELEE_WINDUP)
	assert(not battle.boss.current_melee_is_teleport)
	battle.boss._begin_next_attack()
	assert(battle.boss.state == battle.boss.BossState.RANGED_WINDUP)
	battle.boss._begin_next_attack()
	assert(battle.boss.state == battle.boss.BossState.MELEE_WINDUP)
	assert(battle.boss.current_melee_is_teleport)
	battle.boss.player.facing = 1.0
	battle.boss.teleport_committed = false
	battle.boss.state_clock = 0.17
	battle.boss._physics_process(0.01)
	assert(battle.boss.state == battle.boss.BossState.TELEPORT_IN)
	assert(battle.boss.teleport_attack_count == 1)
	assert(battle.boss.global_position.x < battle.player.global_position.x)

	battle.boss.global_position = Vector2(1150.0, 600.0)
	battle.boss.health = 6
	battle.boss.state = battle.boss.BossState.RANGED_WINDUP
	battle.boss.state_clock = 0.0
	var before_volley: int = battle.projectiles.size()
	battle.boss._physics_process(0.01)
	assert(battle.boss.state == battle.boss.BossState.RANGED_BURST)
	assert(battle.boss.ranged_shots_remaining == 4)
	battle.boss._physics_process(0.01)
	assert(battle.projectiles.size() == before_volley + 1)
	var volley_shot = battle.projectiles.back()
	assert(volley_shot.source_shooter == battle.boss)
	assert(is_equal_approx(volley_shot.velocity.length(), tuning.get_value("boss_projectile_speed")))
	volley_shot.queue_free()
	battle.projectiles.erase(volley_shot)
	await process_frame

	battle.boss.health = 8
	battle._on_boss_health_changed(8, battle.boss.max_health)
	battle.boss.global_position = Vector2(1100.0, 600.0)
	battle.boss.damage_invulnerability = 0.0
	tuning.set_value("boss_reflected_damage", 3.0)
	var reflected_shot = load("res://scripts/projectile.gd").new()
	reflected_shot.position = battle.player.global_position + Vector2(52.0, -34.0)
	reflected_shot.setup(Vector2.LEFT, battle.player, battle.enemies, battle.boss, battle.projectiles)
	reflected_shot.velocity = Vector2.LEFT * tuning.get_value("boss_projectile_speed")
	reflected_shot.hit_enemy.connect(battle._on_projectile_hit_enemy)
	reflected_shot.expired.connect(battle._on_projectile_expired.bind(reflected_shot))
	battle.add_child(reflected_shot)
	battle.projectiles.append(reflected_shot)
	battle._on_player_slash(battle.player.global_position + Vector2(0.0, -34.0), 1.0, Vector2.RIGHT, true)
	assert(reflected_shot.reflected)
	assert(is_equal_approx(battle.parry_slow_remaining, tuning.get_value("melee_parry_slow_duration")))
	assert(is_equal_approx(battle.parry_zoom_remaining, tuning.get_value("parry_zoom_duration")))
	assert(is_equal_approx(battle._current_gameplay_time_scale(), tuning.get_value("melee_parry_time_scale")))
	assert(battle.camera.zoom.x > 1.0 / tuning.get_value("camera_distance"))
	assert(battle.camera.position.is_equal_approx(Vector2(battle.ARENA_WIDTH * 0.5, 360.0)))
	assert(is_equal_approx(reflected_shot.velocity.length(), tuning.get_value("boss_projectile_speed") * 3.0))
	reflected_shot.global_position = Vector2(930.0, 541.0)
	reflected_shot._process(0.16)
	assert(not reflected_shot.alive)
	assert(battle.boss.health == 5)
	assert(battle.reflected_damage_events == 1)
	assert(battle.boss.last_damage_source == "REFLECTED ROUND")
	assert(not battle.projectiles.has(reflected_shot))
	tuning.set_value("boss_reflected_damage", 2.0)
	await process_frame

	Input.action_press("focus")
	battle.player.set_physics_process(true)
	battle.player._physics_process(0.05)
	battle._process(0.05)
	assert(battle.player.is_focusing)
	assert(is_equal_approx(battle.boss.simulation_scale, tuning.FOCUS_TIME_SCALE))
	assert(is_equal_approx(battle.projectile_explosions.simulation_scale, tuning.FOCUS_TIME_SCALE))
	Input.action_release("focus")
	battle.player.set_physics_process(false)

	battle._open_pause_menu()
	assert(paused and battle.pause_menu.is_open())
	assert(battle.bgm_player.stream_paused and battle.rain_audio_player.stream_paused)
	battle.pause_menu.resume_game()
	assert(not paused and not battle.pause_menu.is_open())

	battle.post_boss_transition_scale = 0.0
	battle.post_boss_presentation_scale = 0.01
	battle.boss.damage_invulnerability = 0.0
	battle.boss.health = 1
	battle.last_sfx_stream = null
	battle._on_projectile_hit_enemy(battle.boss)
	assert(not battle.boss.alive)
	assert(battle.state == battle.BattleState.POST_BOSS)
	assert(battle.last_sfx_stream == battle.HIT_STREAM)
	assert(is_equal_approx(battle.FINISHER_SLOW_DURATION, 1.0))
	assert(is_equal_approx(battle.FINISHER_TIME_SCALE, 0.5))
	assert(is_equal_approx(battle.finisher_slow_remaining, 1.0))
	assert(is_equal_approx(battle._current_gameplay_time_scale(), 0.5))
	assert(is_equal_approx(battle.player.external_time_scale, 0.5))
	assert(is_equal_approx(battle.boss.simulation_scale, 0.5))
	assert(is_equal_approx(battle.blood_effects.simulation_scale, 0.5))
	assert(is_equal_approx(battle.rain_audio_player.pitch_scale, 0.5))
	battle._process(0.40)
	assert(is_equal_approx(battle.finisher_slow_remaining, 0.60))
	assert(is_equal_approx(battle.boss.death_time, 0.0))
	assert(is_equal_approx(battle.rain_audio_player.pitch_scale, 0.5))
	battle.boss._physics_process(0.40)
	assert(is_equal_approx(battle.boss.death_time, 0.20))
	battle._process(0.60)
	assert(is_zero_approx(battle.finisher_slow_remaining))
	assert(is_equal_approx(battle._current_gameplay_time_scale(), 1.0))
	assert(is_equal_approx(battle.player.external_time_scale, 1.0))
	assert(is_equal_approx(battle.boss.simulation_scale, 1.0))
	assert(not battle.bgm_player.playing)
	assert(not battle.end_overlay.visible)
	assert(not battle.hud_layer.visible and not battle.touch_input.visible)
	assert(battle.player.force_idle_visual and not battle.player.control_enabled)
	var boss_passed: Array[Dictionary] = battle.StoryStore.get_scene("boss_passed")
	assert(not boss_passed.is_empty())
	battle._show_boss_story_bubble(battle.boss, boss_passed[0])
	assert(String(boss_passed[0]["text"]) in battle.active_story_bubble.text)
	battle._clear_boss_story_bubble()
	for texture in battle.post_boss_cinematic.PANEL_TEXTURES:
		assert(is_instance_valid(texture))
		assert(texture.get_size().is_equal_approx(Vector2(1280.0, 720.0)))
	var epilogue_config: Array[Dictionary] = battle.StoryStore.get_scene("post_boss_epilogue")
	assert(battle.post_boss_cinematic.slides.size() == epilogue_config.size())
	assert(battle.post_boss_cinematic.slides[0]["chapter"] == epilogue_config[0]["speaker"])
	assert(battle.post_boss_cinematic.slides[0]["caption"] == epilogue_config[0]["text"])
	assert(is_equal_approx(float(battle.post_boss_cinematic.slides[0]["duration"]), float(epilogue_config[0]["duration"])))
	var completion_deadline := Time.get_ticks_msec() + 5000
	while battle.state != battle.BattleState.COMPLETE and Time.get_ticks_msec() < completion_deadline:
		await process_frame
	assert(battle.state == battle.BattleState.COMPLETE)
	assert(battle.post_boss_sequence_finished)
	assert(battle.post_boss_cinematic.visible and battle.post_boss_cinematic.complete)
	assert(battle.post_boss_cinematic.final_title.visible)
	assert(battle.post_boss_cinematic.final_title.text == "未完待续……")
	assert(battle.post_boss_cinematic.final_hint.text == "按任意键返回标题画面")
	assert(not battle.end_overlay.visible)

	battle._restart_battle()
	await process_frame
	assert(battle.state == battle.BattleState.PLAYING)
	assert(battle.bgm_player.playing and battle.bgm_player.stream is AudioStreamOggVorbis)
	assert(not battle.post_boss_cinematic.visible and not battle.post_boss_sequence_finished)
	assert(is_instance_valid(battle.boss) and battle.boss.alive and battle.boss.health == battle.boss.max_health)
	battle.player.set_physics_process(false)
	battle.boss.set_physics_process(false)
	battle.rewind_sequence.reset_history()
	var boss_rewind_start: Vector2 = battle.boss.global_position
	battle._on_boss_fire(Vector2(1180.0, 520.0), Vector2.LEFT, battle.boss)
	var rewind_shot: Node = battle.projectiles.back()
	rewind_shot.set_process(false)
	battle.player.global_position = Vector2(520.0, 600.0)
	battle._capture_rewind_frame(0.0)
	for rewind_step in range(1, 9):
		battle.player.global_position.x = 520.0 + rewind_step * 28.0
		battle.boss.global_position.x = 1420.0 - rewind_step * 18.0
		battle.boss.health = maxi(2, battle.boss.max_health - rewind_step)
		rewind_shot.global_position.x = 1180.0 - rewind_step * 32.0
		battle._capture_rewind_frame(battle.rewind_sequence.SAMPLE_INTERVAL)
	var death_x: float = battle.player.global_position.x
	var boss_death_x: float = battle.boss.global_position.x
	var projectile_death_x: float = rewind_shot.global_position.x
	battle.player.die()
	await process_frame
	assert(battle.state == battle.BattleState.DEAD)
	assert(battle.last_sfx_stream == battle.HIT_STREAM)
	assert(battle.rewind_sequence.is_waiting_for_input() and not battle.rewind_sequence.playing)
	assert(battle.rewind_sequence.death_group.visible)
	assert(battle.rewind_sequence.death_title.text == "已死亡")
	assert(battle.bgm_player.stream_paused and battle.rain_audio_player.stream_paused)
	battle._process(0.8)
	assert(is_equal_approx(battle.player.global_position.x, death_x))
	assert(is_equal_approx(battle.boss.global_position.x, boss_death_x))
	Input.action_press("restart")
	battle._process(0.0)
	Input.action_release("restart")
	assert(battle.rewind_sequence.playing and not battle.rewind_sequence.armed)
	assert(is_equal_approx(battle.rewind_sequence.playback_duration, 2.0))
	assert(is_instance_valid(battle.rewind_sequence.noise_player.stream))
	battle.rewind_sequence._process(battle.rewind_sequence.playback_duration * 0.70)
	assert(battle.player.global_position.x < death_x)
	assert(battle.boss.global_position.x > boss_death_x)
	assert(rewind_shot.global_position.x > projectile_death_x)
	battle.rewind_sequence._process(battle.rewind_sequence.playback_duration)
	assert(battle.state == battle.BattleState.DEAD)
	assert(battle.rewind_sequence.is_splicing_reset() and battle.rewind_sequence.overlay.visible)
	assert(is_equal_approx(battle.player.global_position.x, 520.0))
	assert(battle.boss.global_position.is_equal_approx(boss_rewind_start))
	assert(battle.boss.health == battle.boss.max_health)
	assert(is_equal_approx(rewind_shot.global_position.x, 1180.0))
	battle.rewind_sequence._process(battle.rewind_sequence.RESET_COVER_SECONDS + 0.01)
	assert(battle.state == battle.BattleState.PLAYING)
	assert(battle.player.alive and battle.boss.alive)
	assert(battle.bgm_player.playing and not battle.bgm_player.stream_paused)
	assert(battle.rewind_sequence.is_splicing_reset() and battle.rewind_sequence.wash.color.a > 0.99)
	battle.rewind_sequence._process(battle.rewind_sequence.RESET_HOLD_SECONDS + 0.01)
	await process_frame
	assert(not battle.rewind_sequence.playing and not battle.rewind_sequence.overlay.visible)

	print("[BOSS_SMOKE_PASS] fixed 1s/0.5x finisher slowdown, no victory chime, shared parry scale, ending, rewind, and rematch verified")
	var audio_children: Array[AudioStreamPlayer] = []
	for child in battle.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
			audio_children.append(child)
	await create_timer(0.12).timeout
	for audio in audio_children:
		if is_instance_valid(audio):
			audio.free()
	battle.free()
	battle = null
	boss_scene = null
	title_scene = null
	tuning = null
	quit(0)
