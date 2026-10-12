extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	I18n.set_language("zh_CN", false)
	await get_tree().process_frame
	var capture_dir := OS.get_environment("GAME_CAPTURE_DIR")
	if capture_dir.is_empty():
		capture_dir = "/tmp/ying-interior-captures"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var story = load("res://scripts/story_store.gd")
	var scene := load("res://scenes/interior_level.tscn") as PackedScene
	var interior = scene.instantiate()
	interior.entrance_transition_duration = 0.0
	interior.auto_boss_scene_change = false
	interior.auto_advance_dialogue = true
	add_child(interior)
	await _settle(8)
	interior.entrance_transition.set_closed(false)
	interior.player.set_control_enabled(false)
	interior.player.set_forced_idle_visual(true)
	assert(interior.floor_groups.size() == 5 and interior.platforms.size() == 17)

	interior.camera.position = Vector2(640.0, interior.INTERIOR_HEIGHT - 360.0)
	interior.status_label.visible = false
	var floor_one: Array[Dictionary] = story.get_scene("interior_floor_1")
	interior._show_interior_bubble(interior.floor_groups[0][0], floor_one[0])
	interior.dialogue_typewriter.begin_line(interior.active_dialogue_bubble, interior.active_dialogue_hint, interior.active_dialogue_bubble.text, 34.0)
	interior.dialogue_typewriter.reveal_immediately()
	assert(interior.active_dialogue_hint.visible)
	assert(interior.floor_groups[0][0].resting_visual)
	assert(interior.floor_groups[0][1].global_position.y < interior.INTERIOR_FLOOR_Y[0] - 100.0)
	await _save_view(capture_dir.path_join("interior_floor1_platform_gunner.png"))
	interior._clear_interior_bubble()

	interior.floor_alerted[0] = true
	interior.status_label.visible = true
	await interior._run_floor_wakeup(0)
	interior.camera.position = Vector2(640.0, interior.INTERIOR_HEIGHT - 360.0)
	assert(0 in interior.world_art.alerted_floors)
	assert(interior.floor_groups[0][0].combat_active)
	await _save_view(capture_dir.path_join("interior_floor1_alert.png"))

	# Floor four dialogue is already visible while every guard there remains at rest.
	interior.floor_alerted[1] = true
	interior.floor_alerted[2] = true
	interior.player.global_position = Vector2(640.0, 1500.0)
	interior.player.set_forced_idle_visual(false)
	interior._update_camera()
	interior._update_visible_floor_chatter()
	await _settle(3)
	assert(interior.floor_chatter_started[3] and not interior.floor_alerted[3])
	assert(not interior.floor_groups[3][0].combat_active)
	var floor_four_entry: Dictionary = story.get_scene("interior_floor_4")[0]
	var floor_four_target = interior._resolve_floor_target(3, String(floor_four_entry["target"]))
	assert(floor_four_target.find_child("AmbientNpcDialogue", false, false) is Label)
	await _save_view(capture_dir.path_join("interior_floor4_early_chatter.png"))

	# Top-floor battle composition includes a gunner stationed on the jump route.
	for floor_index in range(interior.floor_alerted.size()):
		interior.floor_alerted[floor_index] = true
	interior.player.global_position = Vector2(430.0, 650.0)
	interior.player.set_control_enabled(true)
	interior._activate_floor_group(4)
	interior._update_camera()
	var floor_five: Array[Dictionary] = story.get_scene("interior_floor_5")
	interior._show_ambient_npc_bubble(interior.floor_groups[4][0], floor_five[0])
	assert(interior.floor_groups[4][1].kind == "gunner")
	assert(interior.floor_groups[4][1].global_position.y > interior.INTERIOR_FLOOR_Y[4] + 250.0)
	assert(interior.player.control_enabled and not interior.interior_dialogue_active)
	assert(interior.active_dialogue_hint == null)
	await _save_view(capture_dir.path_join("interior_floor5_platform_crossfire.png"))
	interior._clear_enemy_bark(interior.floor_groups[4][0])

	for child in interior.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await get_tree().create_timer(0.15).timeout
	interior.free()
	interior = null
	scene = null
	story = null
	await get_tree().create_timer(0.15).timeout
	print("[INTERIOR_CAPTURE_PASS] five-floor ascent, early off-floor chatter, platform gunners, alerts, and top crossfire captured")
	get_tree().quit()

func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame

func _save_view(path: String) -> void:
	RenderingServer.force_draw(false)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	assert(error == OK)
