extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var smoke_i18n = root.get_node("I18n")
	smoke_i18n.set_language("zh_CN", false)
	var story = load("res://scripts/story_store.gd")
	assert(story.reload())
	var tuning = load("res://scripts/tuning_store.gd")
	tuning.reset()
	assert(tuning.CONFIG_VERSION == 16)
	for floor_number in range(1, 6):
		var entries: Array[Dictionary] = story.get_scene("interior_floor_%d" % floor_number)
		assert(entries.size() >= 3)
		for entry in entries:
			assert(String(entry["target"]).begins_with("member_"))
			assert(not String(entry["text"]).is_empty())

	var interior_scene := load("res://scenes/interior_level.tscn") as PackedScene
	assert(interior_scene != null)
	var interior = interior_scene.instantiate()
	interior.entrance_transition_duration = 0.0
	interior.auto_boss_scene_change = false
	interior.auto_advance_dialogue = true
	root.add_child(interior)
	for _frame in range(8):
		await process_frame
	assert(interior.world_art.name == "AkaiHideoutInterior")
	assert(interior.world_art.BACKDROP.resource_path == "res://assets/environment/interior_hideout.webp")
	assert(interior.world_art.BACKDROP.get_size().is_equal_approx(Vector2(900.0, 1600.0)))
	assert(interior.INTERIOR_HEIGHT == 3475.0)
	assert(interior.platforms.size() == 17)
	assert(interior.floor_groups.size() == 5)
	assert(interior.floor_alerted.size() == 5 and interior.floor_chatter_started.size() == 5)
	assert(interior.floor_groups[0].size() == 2)
	for floor_index in range(1, 5):
		assert(interior.floor_groups[floor_index].size() == 3)
	assert(interior.enemies.size() == interior.TOTAL_INTERIOR_ENEMIES)
	assert(interior.TOTAL_INTERIOR_ENEMIES == 14)
	for enemy in interior.enemies:
		assert(enemy.alive and enemy.resting_visual and not enemy.combat_active)
		assert(enemy._resolve_visual_state()["rotation"] != 0.0)

	var platform_gunners := 0
	for floor_group in interior.floor_groups:
		for enemy in floor_group:
			if enemy.kind != "gunner":
				continue
			var standing_on_small_platform := false
			for platform in interior.platforms:
				if platform.size.x >= interior.INTERIOR_WIDTH - 1.0:
					continue
				if is_equal_approx(enemy.global_position.y, platform.position.y - 1.0) and enemy.global_position.x >= platform.position.x and enemy.global_position.x <= platform.end.x:
					standing_on_small_platform = true
					break
			if standing_on_small_platform:
				platform_gunners += 1
	assert(platform_gunners >= 5)

	var ascent_platforms: Array[Rect2] = []
	for platform in interior.platforms:
		ascent_platforms.append(platform)
	ascent_platforms.sort_custom(func(a: Rect2, b: Rect2): return a.position.y > b.position.y)
	for index in range(1, ascent_platforms.size()):
		assert(ascent_platforms[index - 1].position.y - ascent_platforms[index].position.y <= 175.0)

	var first_entry: Dictionary = story.get_scene("interior_floor_1")[0]
	interior._show_interior_bubble(interior.floor_groups[0][0], first_entry)
	interior.dialogue_typewriter.begin_line(interior.active_dialogue_bubble, interior.active_dialogue_hint, interior.active_dialogue_bubble.text, 34.0)
	assert(interior.active_dialogue_bubble.visible_characters == 0)
	assert(not interior.active_dialogue_hint.visible)
	interior.dialogue_typewriter.reveal_immediately()
	assert(interior.active_dialogue_bubble.visible_characters == -1)
	assert(interior.active_dialogue_hint.visible)
	assert(interior.active_dialogue_hint.text == "J  //  继续")
	assert(interior.dialogue_typewriter.TYPE_TICK.resource_path == "res://assets/audio/dialogue_type_tick.ogg")
	interior.dialogue_typewriter.advance_requested = false
	var x_key := InputEventKey.new()
	x_key.keycode = KEY_X
	x_key.pressed = true
	interior.interior_dialogue_active = true
	interior._unhandled_input(x_key)
	assert(not interior.dialogue_typewriter.advance_requested)
	var j_key := InputEventKey.new()
	j_key.keycode = KEY_J
	j_key.pressed = true
	interior._unhandled_input(j_key)
	assert(interior.dialogue_typewriter.advance_requested)
	interior._clear_interior_bubble()
	interior.interior_dialogue_active = false

	interior.player.global_position = Vector2(420.0, interior.INTERIOR_FLOOR_Y[0] - 1.0)
	interior._update_floor_triggers()
	for _frame in range(8):
		await process_frame
	assert(interior.floor_alerted[0])
	assert(0 in interior.world_art.alerted_floors)
	for enemy in interior.floor_groups[0]:
		assert(enemy.combat_active and not enemy.resting_visual)
	for floor_index in range(1, 5):
		for enemy in interior.floor_groups[floor_index]:
			assert(not enemy.combat_active and enemy.resting_visual)

	var parry_shot = load("res://scripts/projectile.gd").new()
	parry_shot.velocity = Vector2.LEFT * tuning.get_value("gunner_projectile_speed")
	parry_shot.position = interior.player.global_position + Vector2(32.0, -34.0)
	interior.add_child(parry_shot)
	interior.projectiles.append(parry_shot)
	interior._on_player_slash(interior.player.global_position + Vector2(0.0, -34.0), 1.0, Vector2.RIGHT, true)
	assert(parry_shot.reflected)
	assert(is_equal_approx(interior.parry_slow_remaining, tuning.get_value("melee_parry_slow_duration")))
	assert(is_equal_approx(interior.parry_zoom_remaining, tuning.get_value("parry_zoom_duration")))
	assert(is_equal_approx(interior._current_gameplay_time_scale(), tuning.get_value("melee_parry_time_scale")))
	assert(is_equal_approx(interior.player.external_time_scale, tuning.get_value("melee_parry_time_scale")))
	assert(interior.camera.zoom.x > 1.0)
	interior._update_camera()
	var interior_half_height: float = interior.get_camera_visible_world_size().y * 0.5
	var expected_interior_center := Vector2(interior.INTERIOR_WIDTH * 0.5, clampf(interior.player.global_position.y - 105.0, interior_half_height, interior.INTERIOR_HEIGHT - interior_half_height))
	assert(interior.camera.position.is_equal_approx(expected_interior_center))
	interior._tick_parry_feedback(tuning.get_value("parry_zoom_duration"))
	interior._apply_camera_distance()
	assert(is_equal_approx(interior.camera.zoom.x, 1.0))
	interior._reset_parry_feedback()
	interior.projectiles.erase(parry_shot)
	parry_shot.free()

	# Upper-floor chatter begins as soon as a resting NPC enters the camera, before combat activation.
	var chatter_probe_positions := [2800.0, 2200.0, 1500.0, 800.0]
	for floor_index in range(1, 5):
		interior.player.global_position = Vector2(640.0, chatter_probe_positions[floor_index - 1])
		interior._update_camera()
		interior._update_visible_floor_chatter()
		for _frame in range(3):
			await process_frame
		assert(interior.floor_chatter_started[floor_index])
		assert(not interior.floor_alerted[floor_index])
		assert(not interior.floor_groups[floor_index][0].combat_active)
		assert(interior.status_label.text == "第 %d 层  //  尚未警觉" % (floor_index + 1))
		var early_entry: Dictionary = story.get_scene("interior_floor_%d" % (floor_index + 1))[0]
		var early_target = interior._resolve_floor_target(floor_index, String(early_entry["target"]))
		var early_bubble := early_target.find_child("AmbientNpcDialogue", false, false) as Label
		assert(is_instance_valid(early_bubble))
		assert(interior.active_dialogue_hint == null)

		interior.player.global_position = Vector2(640.0, interior.INTERIOR_FLOOR_Y[floor_index] + 100.0)
		interior._update_floor_triggers()
		for _frame in range(3):
			await process_frame
		assert(interior.floor_alerted[floor_index] and interior.active_floor_index == floor_index)
		assert(not interior.interior_dialogue_active and interior.player.control_enabled)
		assert(floor_index in interior.world_art.alerted_floors)
		for enemy in interior.floor_groups[floor_index]:
			assert(enemy.combat_active and not enemy.resting_visual)

	# A gunner on the fourth level emits a live projectile inside the expanded world bounds.
	var high_gunner = interior.floor_groups[3][0]
	high_gunner.set_physics_process(false)
	high_gunner.action_clock = 0.0
	high_gunner.windup = 0.0
	var high_projectile_count: int = interior.projectiles.size()
	high_gunner._update_gunner(0.01, interior.player.global_position - high_gunner.global_position)
	high_gunner._update_gunner(0.31, interior.player.global_position - high_gunner.global_position)
	assert(interior.projectiles.size() == high_projectile_count + 1)
	var high_shot = interior.projectiles.back()
	assert(high_shot.world_bounds.is_equal_approx(interior._projectile_world_bounds()))
	assert(high_shot.global_position.y > 820.0)
	high_shot._process(0.05)
	assert(high_shot.alive and high_shot.visible)
	interior.projectiles.erase(high_shot)
	high_shot.free()

	# Down + jump drops through any upper one-way platform, then restores terrain collision.
	interior.set_process(false)
	interior.player.set_physics_process(false)
	interior.player.set_control_enabled(true)
	interior.player.global_position = Vector2(520.0, 899.0)
	interior.player.velocity = Vector2(0.0, 10.0)
	interior.player.move_and_slide()
	assert(interior.player.is_on_floor())
	interior.player.velocity = Vector2.ZERO
	Input.action_press("aim_down")
	Input.action_press("jump")
	interior.player._physics_process(0.02)
	Input.action_release("jump")
	Input.action_release("aim_down")
	assert(interior.player.drop_through_remaining > 0.0)
	assert(not interior.player.get_collision_mask_value(1))
	var drop_start_y: float = interior.player.global_position.y
	for _drop_step in range(8):
		interior.player._physics_process(0.04)
	assert(interior.player.global_position.y > drop_start_y + 20.0)
	assert(is_zero_approx(interior.player.drop_through_remaining))
	assert(interior.player.get_collision_mask_value(1))
	await process_frame
	interior.player.global_position = interior.PLAYER_START
	interior.player.velocity = Vector2(0.0, 10.0)
	interior.player.move_and_slide()
	assert(interior.player.is_on_floor())
	interior.player.velocity = Vector2.ZERO
	Input.action_press("aim_down")
	Input.action_press("jump")
	interior.player._physics_process(0.02)
	Input.action_release("jump")
	Input.action_release("aim_down")
	assert(is_zero_approx(interior.player.drop_through_remaining))
	assert(interior.player.get_collision_mask_value(1))
	assert(interior.player.velocity.y < 0.0)
	interior.set_process(true)

	for enemy in interior.enemies:
		if enemy.alive:
			enemy.kill()
	interior._process(0.01)
	assert(interior.gate_open and interior.world_art.exit_open)
	interior.player.global_position = interior.EXIT_TRIGGER
	interior._process(0.01)
	assert(interior.state == interior.RunState.COMPLETE)
	assert(interior.boss_transition_requested)
	assert(interior.BOSS_SCENE == "res://scenes/boss_battle.tscn")
	assert(interior.NEXT_SCENE == "res://scenes/interior_level.tscn")

	for child in interior.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await create_timer(0.15).timeout
	interior.free()
	interior = null
	interior_scene = null
	story = null
	await process_frame
	print("[INTERIOR_SMOKE_PASS] down+jump platform drop, protected bottom floor, five-floor ascent, gunners, chatter, and boss route verified")
	quit(0)
