extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var smoke_i18n = root.get_node("I18n")
	smoke_i18n.set_language("zh_CN", false)
	var save_store = load("res://scripts/save_store.gd")
	save_store.set_tutorial_complete(false)
	var tuning = load("res://scripts/tuning_store.gd")
	tuning.reset()
	assert(tuning.CONFIG_VERSION == 16)
	var tutorial_scene := load("res://scenes/tutorial.tscn") as PackedScene
	assert(tutorial_scene != null)
	var tutorial = tutorial_scene.instantiate()
	tutorial.skip_story_intro = true
	tutorial.auto_scene_change = false
	root.add_child(tutorial)
	for _index in range(8):
		await physics_frame
	Input.action_release("attack")
	Input.action_release("focus")
	Input.action_release("move_right")
	assert(tutorial.process_mode == Node.PROCESS_MODE_ALWAYS)
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.BLADE_APPROACH)
	assert(is_instance_valid(tutorial.player) and not tutorial.player.control_enabled)
	assert(tutorial.player.force_idle_visual)
	assert(tutorial.player._resolve_visual_state()["texture"] == load("res://scripts/animation_frames.gd").HERO_IDLE[0])
	assert(tutorial.enemies.size() == 2)
	assert(is_instance_valid(tutorial.blade_enemy) and tutorial.blade_enemy.kind == "blade")
	assert(is_instance_valid(tutorial.gunner_enemy) and tutorial.gunner_enemy.kind == "gunner")
	for opening_actor in [tutorial.player, tutorial.blade_enemy, tutorial.gunner_enemy]:
		assert(absf(opening_actor.get_hurtbox_rect_world().end.y - tutorial.FLOOR_Y) <= 1.5)
	assert(not tutorial.gunner_enemy.is_physics_processing())
	var blade: Node = tutorial.blade_enemy

	Input.action_press("attack")
	tutorial.blade_enemy.global_position = tutorial.player.global_position + Vector2(100.0, 0.0)
	tutorial._update_tutorial_phase(0.016)
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.BLADE_EXECUTE)
	assert(tutorial.tutorial_paused and not paused)
	assert(tutorial.instruction_label.text == "按 J 斩击")
	assert(not tutorial.player.is_physics_processing() and not tutorial.blade_enemy.is_physics_processing())
	assert(not tutorial.instruction_input_armed)
	tutorial._process(0.20)
	assert(not tutorial.instruction_input_armed)
	Input.action_release("attack")
	tutorial._process(0.016)
	assert(tutorial.instruction_input_armed)
	tutorial._accept_attack_instruction()
	assert(tutorial.player.control_enabled and tutorial.player.attack_time > 0.0)
	assert(not tutorial.player.force_idle_visual)
	blade.kill()
	assert(tutorial.blood_effects.particles.size() == tutorial.blood_effects.PARTICLE_COUNT)
	await process_frame
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.GUNNER_DIALOGUE)
	assert(tutorial.story_sequence_active)
	assert(is_instance_valid(tutorial.active_story_bubble))
	assert("来人啊" in tutorial.active_story_bubble.text)
	tutorial.story_typewriter.reveal_immediately()
	assert(tutorial.active_story_hint.visible and tutorial.active_story_hint.text == "J  //  继续")
	await process_frame
	tutorial.story_typewriter.request_advance()
	for _index in range(4):
		await process_frame
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.GUNNER_FIRE)
	assert(tutorial.enemies.size() == 1)
	assert(tutorial.gunner_enemy.alive and tutorial.gunner_enemy.is_physics_processing())
	assert(tutorial.blood_effects.particles.is_empty())

	var gunner: Node = tutorial.gunner_enemy
	tutorial._on_enemy_fire(gunner.global_position + Vector2(-28.0, -42.0), Vector2.LEFT, gunner)
	assert(tutorial.projectiles.size() == 1)
	var parry_shot: Node = tutorial.projectiles[0]
	parry_shot.global_position = tutorial.player.global_position + Vector2(108.0, -44.0)
	tutorial._update_tutorial_phase(0.016)
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.PARRY_EXECUTE)
	assert(tutorial.tutorial_paused and not paused)
	assert(tutorial.instruction_label.text == "按 J 弹反子弹")
	assert(parry_shot.global_position.is_equal_approx(tutorial.player.global_position + Vector2(96.0, -44.0)))
	assert(not parry_shot.is_processing())
	tutorial._process(0.016)
	assert(tutorial.instruction_input_armed)
	tutorial._accept_attack_instruction()
	parry_shot.global_position = tutorial.player.global_position + Vector2(66.0, -44.0)
	tutorial._on_player_slash(tutorial.player.global_position + Vector2(0.0, -34.0), 1.0, Vector2.RIGHT, true)
	assert(parry_shot.reflected)
	assert(is_equal_approx(tutorial.parry_slow_remaining, tuning.get_value("melee_parry_slow_duration")))
	assert(is_equal_approx(tutorial.parry_zoom_remaining, tuning.get_value("parry_zoom_duration")))
	assert(is_equal_approx(tutorial._current_gameplay_time_scale(), tuning.get_value("melee_parry_time_scale")))
	assert(is_equal_approx(tutorial.player.external_time_scale, tuning.get_value("melee_parry_time_scale")))
	assert(tutorial.camera.zoom.x > 1.0)
	tutorial._process(0.0)
	assert(tutorial.camera.position.is_equal_approx(Vector2(640.0, 360.0)))
	gunner.kill()
	parry_shot._expire()
	await process_frame
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.REINFORCEMENT_ENTRY)
	assert(tutorial.finale_gunners.size() == 4)
	for index in range(tutorial.finale_gunners.size()):
		var entering_gunner: Node = tutorial.finale_gunners[index]
		assert(entering_gunner.global_position.x <= tutorial.REINFORCEMENT_ENTRY_POSITIONS[index].x)
		assert(entering_gunner.global_position.x > tutorial.REINFORCEMENT_POSITIONS[index].x)
		assert(absf(entering_gunner.get_hurtbox_rect_world().end.y - tutorial.FLOOR_Y) <= 1.5)
		assert(entering_gunner.velocity.x < 0.0)
		assert(entering_gunner._resolve_visual_state()["texture"] in load("res://scripts/animation_frames.gd").GUNNER_WALK)
	tutorial._update_tutorial_phase(2.0)
	tutorial._update_tutorial_phase(0.016)
	await process_frame
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.REINFORCEMENT_DIALOGUE)
	assert(is_instance_valid(tutorial.active_story_bubble))
	assert("弄死他" in tutorial.active_story_bubble.text)
	assert(tutorial.active_story_bubble.position.y + tutorial.active_story_bubble.size.y <= -170.0)
	tutorial.story_typewriter.reveal_immediately()
	assert(tutorial.active_story_hint.visible and tutorial.active_story_hint.text == "J  //  继续")
	await process_frame
	tutorial.story_typewriter.request_advance()
	for _index in range(4):
		await process_frame
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.FOCUS_BARRAGE)
	assert(tutorial.finale_gunners.size() == 4)
	assert(tutorial.projectiles.size() == 4 and tutorial.barrage_spawned == 4)
	for reinforcement in tutorial.finale_gunners:
		assert(reinforcement.alive and not reinforcement.is_physics_processing())

	tutorial._update_tutorial_phase(0.5)
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.FOCUS_DASH)
	assert(tutorial.tutorial_paused and not paused)
	assert(tutorial.instruction_label.text == "按住 L，再按 D + J")
	assert("弹反四发子弹" in tutorial.instruction_detail_label.text)
	assert(tutorial.focus_text.visible and tutorial.focus_fill.get_parent().visible)
	for frozen_shot in tutorial.projectiles:
		assert(not frozen_shot.is_processing())
	for index in range(tutorial.projectiles.size()):
		var row_shot: Node = tutorial.projectiles[index]
		assert(row_shot.has_meta("tutorial_finale_round"))
		assert(row_shot.global_position.is_equal_approx(tutorial.player.global_position + Vector2(tutorial.FINALE_PROJECTILE_X_OFFSETS[index], tutorial.FINALE_PROJECTILE_Y_OFFSET)))
		if index > 0:
			assert(row_shot.global_position.x > tutorial.projectiles[index - 1].global_position.x)
	tutorial._process(0.016)
	assert(tutorial.instruction_input_armed)
	Input.action_press("attack")
	tutorial._accept_focus_dash_instruction()
	assert(tutorial.tutorial_paused and not tutorial.finale_combo_started)
	Input.action_release("attack")
	Input.action_press("focus")
	Input.action_press("move_right")
	Input.action_press("attack")
	var finale_start_x: float = tutorial.player.global_position.x
	var dash_finish_x := -1.0
	var observed_active_dash := false
	for _index in range(300):
		await physics_frame
		if tutorial.player.dash_time > 0.0:
			observed_active_dash = true
		elif observed_active_dash and dash_finish_x < 0.0:
			dash_finish_x = tutorial.player.global_position.x
		if tutorial.tutorial_phase == tutorial.TutorialPhase.COMPLETE:
			break
	Input.action_release("attack")
	Input.action_release("focus")
	Input.action_release("move_right")
	assert(tutorial.finale_combo_started)
	assert(observed_active_dash and dash_finish_x - finale_start_x >= 230.0)
	assert(tutorial.finale_reflected_count == 4)
	assert(tutorial.finale_kill_count == 4)
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.COMPLETE)
	assert(tutorial.tutorial_transition_started)
	assert(save_store.has_completed_tutorial())
	assert(tutorial.projectiles.is_empty())
	assert(tutorial.player.alive and not tutorial.player.is_focusing)
	assert(is_equal_approx(tutorial.player.focus_energy, 100.0))
	assert(not tutorial.player.is_physics_processing())
	tutorial.tv_transition.set_closed(false)
	tutorial.story_transition_scale = 0.0
	tutorial.tutorial_phase = tutorial.TutorialPhase.EXIT_RUN
	tutorial.exit_run_started = true
	tutorial.player.global_position.x = 1361.0
	tutorial._update_tutorial_phase(0.016)
	for _index in range(4):
		await process_frame
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.COMPLETE)
	assert(tutorial.tv_transition.is_closed)
	assert(is_equal_approx(tutorial.tv_transition.top_bar.size.y, 360.0))

	tutorial._prepare_tutorial_scene(true)
	await process_frame
	tutorial.player.set_physics_process(false)
	tutorial.rewind_sequence.reset_history()
	for rewind_step in range(8):
		tutorial.player.global_position.x = tutorial.TUTORIAL_PLAYER_POSITION.x + rewind_step * 18.0
		tutorial._capture_rewind_frame(tutorial.rewind_sequence.SAMPLE_INTERVAL)
	tutorial.player.die()
	await process_frame
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.FAILED)
	assert(tutorial.rewind_sequence.is_waiting_for_input() and not tutorial.rewind_sequence.playing)
	var frozen_failure_x: float = tutorial.player.global_position.x
	tutorial._process(0.8)
	assert(is_equal_approx(tutorial.player.global_position.x, frozen_failure_x))
	Input.action_press("restart")
	tutorial._process(0.0)
	Input.action_release("restart")
	assert(tutorial.rewind_sequence.playing)
	assert(is_equal_approx(tutorial.rewind_sequence.playback_duration, 2.0))
	tutorial.rewind_sequence._process(tutorial.rewind_sequence.playback_duration + 0.01)
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.FAILED)
	assert(tutorial.rewind_sequence.is_splicing_reset() and tutorial.rewind_sequence.overlay.visible)
	assert(is_equal_approx(tutorial.player.global_position.x, tutorial.TUTORIAL_PLAYER_POSITION.x))
	tutorial.rewind_sequence._process(tutorial.rewind_sequence.RESET_COVER_SECONDS + 0.01)
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.BLADE_APPROACH)
	assert(tutorial.rewind_sequence.is_splicing_reset() and tutorial.rewind_sequence.wash.color.a > 0.99)
	tutorial.rewind_sequence._process(tutorial.rewind_sequence.RESET_HOLD_SECONDS + 0.01)
	await process_frame
	assert(tutorial.player.alive and not tutorial.rewind_sequence.playing)

	Input.action_release("attack")
	Input.action_release("focus")
	Input.action_release("move_right")
	paused = false
	for child in tutorial.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await create_timer(0.16).timeout
	tutorial.free()
	tutorial = null
	tutorial_scene = null
	save_store.set_tutorial_complete(false)
	print("[TUTORIAL_SMOKE_PASS] tutorial bullet-parry slowdown/zoom, lightning arrival, gunner run-in, Focus dash, rewind, and completion verified")
	quit(0)
