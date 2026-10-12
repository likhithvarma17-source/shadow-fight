extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	var capture_dir := OS.get_environment("GAME_CAPTURE_DIR")
	if capture_dir.is_empty():
		capture_dir = "/tmp/zero-hour-tutorial-captures"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var save_store = load("res://scripts/save_store.gd")
	save_store.set_tutorial_complete(false)
	var story = load("res://scripts/story_store.gd")
	var scene := load("res://scenes/tutorial.tscn") as PackedScene
	var tutorial = scene.instantiate()
	tutorial.skip_story_intro = true
	tutorial.auto_scene_change = false
	add_child(tutorial)
	await _settle(8)
	Input.action_release("attack")
	Input.action_release("focus")
	Input.action_release("move_right")

	var briefing: Array[Dictionary] = story.get_scene("opening_briefing")
	tutorial.phone_briefing.visible = true
	tutorial.phone_briefing.present_line(briefing[3], 3, briefing.size())
	tutorial.phone_briefing.typing = false
	tutorial.phone_briefing.message_label.visible_characters = -1
	assert("赤井帮" in tutorial.phone_briefing.message_label.text)
	await _save_view(capture_dir.path_join("tutorial_phone_briefing.png"))
	tutorial.tv_transition.top_bar.size.y = 242.0
	tutorial.tv_transition.bottom_bar.position.y = 478.0
	tutorial.tv_transition.bottom_bar.size.y = 242.0
	tutorial.tv_transition.seam.color.a = 0.64
	await _save_view(capture_dir.path_join("tutorial_tv_shutter.png"))
	tutorial.tv_transition.set_closed(false)
	tutorial.phone_briefing.visible = false
	tutorial.objective_label.text = "入口 // 赤井帮外围屋顶"
	tutorial.status_label.text = "雷暴异常"

	var materialize: Array[Dictionary] = story.get_scene("tutorial_materialize")
	tutorial.player.visible = true
	tutorial.player.global_position = tutorial.TUTORIAL_PLAYER_POSITION
	tutorial.player.set_forced_idle_visual(true)
	tutorial.materialization_effect.global_position = tutorial.TUTORIAL_PLAYER_POSITION
	tutorial.materialization_effect.show_preview(0.64)
	tutorial.lightning_flash = 1.0
	tutorial._update_screen_effects(0.016)
	tutorial._show_world_bubble(tutorial.blade_enemy, materialize[0])
	tutorial.story_typewriter.begin_line(tutorial.active_story_bubble, tutorial.active_story_hint, tutorial.active_story_bubble.text, 34.0)
	tutorial.story_typewriter.reveal_immediately()
	assert("雷" in tutorial.active_story_bubble.text)
	assert(absf(tutorial.player.get_hurtbox_rect_world().end.y - tutorial.FLOOR_Y) <= 1.5)
	assert(absf(tutorial.blade_enemy.get_hurtbox_rect_world().end.y - tutorial.FLOOR_Y) <= 1.5)
	assert(tutorial.active_story_bubble.position.y + tutorial.active_story_bubble.size.y <= -170.0)
	await _save_view(capture_dir.path_join("tutorial_lightning_materialization.png"))
	tutorial.materialization_effect.hide_effect()
	tutorial._clear_world_bubble()

	var arrival: Array[Dictionary] = story.get_scene("tutorial_arrival")
	tutorial._show_world_bubble(tutorial.blade_enemy, arrival[0])
	tutorial.story_typewriter.begin_line(tutorial.active_story_bubble, tutorial.active_story_hint, tutorial.active_story_bubble.text, 34.0)
	tutorial.story_typewriter.reveal_immediately()
	assert("你他妈谁啊" in tutorial.active_story_bubble.text)
	await _save_view(capture_dir.path_join("tutorial_arrival_dialogue.png"))
	tutorial._clear_world_bubble()
	tutorial._show_world_bubble(tutorial.player, arrival[1])
	tutorial.story_typewriter.begin_line(tutorial.active_story_bubble, tutorial.active_story_hint, tutorial.active_story_bubble.text, 34.0)
	tutorial.story_typewriter.reveal_immediately()
	assert("……" in tutorial.active_story_bubble.text)
	await _save_view(capture_dir.path_join("tutorial_silent_protagonist.png"))
	tutorial._clear_world_bubble()

	tutorial.blade_enemy.global_position = tutorial.player.global_position + Vector2(100.0, 0.0)
	tutorial._update_tutorial_phase(0.016)
	assert(not get_tree().paused and tutorial.tutorial_paused)
	assert(tutorial.instruction_label.text == "按 J 斩击")
	var instruction_strip := tutorial.instruction_overlay.find_child("InstructionStrip", true, false) as Control
	assert(tutorial.instruction_overlay.get_rect().size.is_equal_approx(Vector2(1280.0, 720.0)))
	assert(instruction_strip.get_rect().is_equal_approx(Rect2(0.0, 252.0, 1280.0, 216.0)))
	await _save_view(capture_dir.path_join("tutorial_slash_prompt.png"))

	tutorial.instruction_input_armed = true
	tutorial._accept_attack_instruction()
	tutorial.blade_enemy.kill()
	await _settle(1)
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.GUNNER_DIALOGUE)
	assert("来人啊" in tutorial.active_story_bubble.text)
	tutorial.story_typewriter.reveal_immediately()
	await _settle(1)
	assert(tutorial.active_story_hint.visible)
	await _save_view(capture_dir.path_join("tutorial_gunner_alarm.png"))
	tutorial.story_typewriter.request_advance()
	await _settle(4)
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.GUNNER_FIRE)
	var gunner: Node = tutorial.gunner_enemy
	tutorial._on_enemy_fire(gunner.global_position + Vector2(-28.0, -42.0), Vector2.LEFT, gunner)
	var shot: Node = tutorial.projectiles[0]
	shot.set_process(false)
	shot.global_position = tutorial.player.global_position + Vector2(108.0, -44.0)
	tutorial._update_tutorial_phase(0.016)
	assert(not get_tree().paused and tutorial.tutorial_paused)
	assert(tutorial.instruction_label.text == "按 J 弹反子弹")
	await _save_view(capture_dir.path_join("tutorial_parry_prompt.png"))

	tutorial.instruction_input_armed = true
	tutorial._accept_attack_instruction()
	shot.global_position = tutorial.player.global_position + Vector2(66.0, -44.0)
	tutorial._on_player_slash(tutorial.player.global_position + Vector2(0.0, -34.0), 1.0, Vector2.RIGHT, true)
	assert(shot.reflected)
	gunner.kill()
	shot._expire()
	await _settle(1)
	assert(tutorial.finale_gunners.size() == 4)
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.REINFORCEMENT_ENTRY)
	tutorial._update_tutorial_phase(1.0)
	for entering_gunner in tutorial.finale_gunners:
		assert(entering_gunner.velocity.x < 0.0)
	await _save_view(capture_dir.path_join("tutorial_reinforcements_entry.png"))
	tutorial._update_tutorial_phase(0.5)
	tutorial._update_tutorial_phase(0.016)
	await _settle(1)
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.REINFORCEMENT_DIALOGUE)
	assert("弄死他" in tutorial.active_story_bubble.text)
	tutorial.story_typewriter.reveal_immediately()
	await _settle(1)
	assert(tutorial.active_story_hint.visible)
	await _save_view(capture_dir.path_join("tutorial_reinforcements_dialogue.png"))
	tutorial.story_typewriter.request_advance()
	await _settle(4)
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.FOCUS_BARRAGE)
	tutorial._update_tutorial_phase(0.5)
	assert(not get_tree().paused and tutorial.tutorial_paused)
	assert(tutorial.projectiles.size() == 4)
	assert(tutorial.instruction_label.text == "按住 L，再按 D + J")
	for index in range(tutorial.projectiles.size()):
		var row_shot: Node = tutorial.projectiles[index]
		assert(row_shot.global_position.is_equal_approx(tutorial.player.global_position + Vector2(tutorial.FINALE_PROJECTILE_X_OFFSETS[index], tutorial.FINALE_PROJECTILE_Y_OFFSET)))
	await _save_view(capture_dir.path_join("tutorial_focus_dash_prompt.png"))

	tutorial.tutorial_paused = false
	tutorial.instruction_overlay.visible = false
	tutorial.finale_combo_started = true
	tutorial.finale_reflected_count = 4
	for reinforcement in tutorial.finale_gunners:
		if is_instance_valid(reinforcement) and reinforcement.alive:
			reinforcement.kill()
	assert(tutorial.tutorial_phase == tutorial.TutorialPhase.COMPLETE)
	assert(tutorial.instruction_overlay.visible)
	await _save_view(capture_dir.path_join("tutorial_breach_complete.png"))

	get_tree().paused = false
	var audio_children: Array[AudioStreamPlayer] = []
	for child in tutorial.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
			audio_children.append(child)
	await get_tree().create_timer(0.35).timeout
	for audio_child in audio_children:
		if is_instance_valid(audio_child):
			audio_child.free()
	audio_children.clear()
	tutorial.free()
	tutorial = null
	scene = null
	story = null
	await get_tree().create_timer(0.20).timeout
	save_store.set_tutorial_complete(false)
	print("[TUTORIAL_CAPTURE_PASS] phone briefing, lightning materialization, idle 影, gunner run-in, horizontal rounds, Focus dash, and breach captured")
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
