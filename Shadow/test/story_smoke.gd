extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _check_bilingual()
	const FUSION_PIXEL_FONT := "res://assets/template/fonts/manuscc0_regular.tres"
	var fusion_font := load(FUSION_PIXEL_FONT) as Font
	assert(is_instance_valid(fusion_font))
	for glyph in ["赤", "井", "帮", "货", "佣", "毁", "枪", "闯", "……"]:
		for index in range(glyph.length()):
			assert(fusion_font.has_char(glyph.unicode_at(index)))
	var story = load("res://scripts/story_store.gd")
	assert(FileAccess.file_exists(story.STORY_PATH))
	assert(story.reload())
	assert(story.get_last_error().is_empty())
	assert(story.get_version() == 1)
	assert(story.validate_xml_text("<story version=\"1\"><scene id=\"ok\"></scene></story>"))
	assert(not story.validate_xml_text("<story version=\"1\"><scene id=\"truncated\">"))
	var briefing: Array[Dictionary] = story.get_scene("opening_briefing")
	assert(briefing.size() >= 4)
	for entry in briefing:
		assert(not String(entry["text"]).is_empty())
	var arrival: Array[Dictionary] = story.get_scene("tutorial_arrival")
	assert(arrival.size() >= 1)
	assert(arrival[0]["target"] == "blade")
	assert(not String(arrival[0]["text"]).is_empty())
	var materialize: Array[Dictionary] = story.get_scene("tutorial_materialize")
	assert(materialize.size() == 1)
	assert(materialize[0]["target"] == "blade")
	assert("雷" in String(materialize[0]["text"]))
	var alarm: Array[Dictionary] = story.get_scene("tutorial_gunner_alarm")
	assert(alarm.size() >= 1 and alarm[0]["target"] == "gunner" and not String(alarm[0]["text"]).is_empty())
	var reinforcements: Array[Dictionary] = story.get_scene("tutorial_reinforcements")
	assert(reinforcements.size() >= 1 and reinforcements[0]["target"] == "reinforcement_lead")
	var boss_arrival: Array[Dictionary] = story.get_scene("boss_arrival")
	assert(boss_arrival.size() >= 1)
	assert(boss_arrival[0]["target"] == "boss" and boss_arrival[0]["speaker"] == "守门人")
	for entry in boss_arrival:
		assert(String(entry["target"]) in ["boss", "player"])
		assert(not String(entry["text"]).is_empty())
	var boss_passed: Array[Dictionary] = story.get_scene("boss_passed")
	assert(boss_passed.size() >= 1)
	assert(boss_passed[0]["target"] == "boss")
	for entry in boss_passed:
		assert(String(entry["target"]) in ["boss", "player"])
		assert(not String(entry["text"]).is_empty())
	var epilogue: Array[Dictionary] = story.get_scene("post_boss_epilogue")
	assert(epilogue.size() >= 5)
	var epilogue_targets: Array[String] = []
	for entry in epilogue:
		var target := String(entry["target"])
		assert(target in ["warehouse", "crate", "blade", "blade_hold", "cat"])
		assert(not String(entry["text"]).is_empty())
		epilogue_targets.append(target)
	for required_target in ["warehouse", "crate", "blade", "blade_hold", "cat"]:
		assert(required_target in epilogue_targets)
	var blade_barks: Array[Dictionary] = story.get_barks("blade")
	var gunner_barks: Array[Dictionary] = story.get_barks("gunner")
	assert(not blade_barks.is_empty() and not gunner_barks.is_empty())
	for entry in blade_barks + gunner_barks:
		assert(not String(entry["text"]).is_empty())
		assert(is_equal_approx(float(entry["duration"]), 3.0))

	var tutorial_scene := load("res://scenes/tutorial.tscn") as PackedScene
	var tutorial = tutorial_scene.instantiate()
	tutorial.skip_story_intro = true
	tutorial.auto_scene_change = false
	root.add_child(tutorial)
	for _index in range(6):
		await physics_frame
	for grounded_actor in [tutorial.player, tutorial.blade_enemy, tutorial.gunner_enemy]:
		assert(absf(grounded_actor.get_hurtbox_rect_world().end.y - tutorial.FLOOR_Y) <= 1.5)
	assert(is_instance_valid(tutorial.phone_briefing))
	assert(tutorial.phone_briefing.overlay.name == "PhoneBriefingOverlay")
	assert(tutorial.phone_briefing.background.name == "BriefingPhoneBackground")
	assert(tutorial.phone_briefing.background.texture.resource_path == "res://assets/story/briefing_flip_phone.webp")
	assert(tutorial.phone_briefing.background.texture.get_size().is_equal_approx(Vector2(1280.0, 720.0)))
	assert(tutorial.phone_briefing.background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert(tutorial.phone_briefing.text_column.name == "BriefingTextColumn")
	assert(tutorial.phone_briefing.text_column.get_parent() == tutorial.phone_briefing.overlay)
	assert(tutorial.phone_briefing.message_label.get_parent() == tutorial.phone_briefing.text_column)
	assert(tutorial.phone_briefing.overlay.find_child("RetroFlipPhone", true, false) == null)
	assert(tutorial.phone_briefing.overlay.find_child("BriefingScreen", true, false) == null)
	tutorial.phone_briefing.visible = true
	tutorial.phone_briefing.present_line(briefing[3], 3, briefing.size())
	assert(tutorial.phone_briefing.message_label.visible_characters == 0)
	assert(not tutorial.phone_briefing.hint_label.visible)
	tutorial.phone_briefing.typing = false
	assert(tutorial.phone_briefing.message_label.visible_characters == -1)
	assert(tutorial.phone_briefing.hint_label.visible)
	assert(tutorial.phone_briefing.hint_label.text == "J  //  继续")
	assert(tutorial.phone_briefing.typewriter.TYPE_TICK.resource_path == "res://assets/audio/dialogue_type_tick.ogg")
	assert("赤井帮" in tutorial.phone_briefing.message_label.text)
	assert(tutorial.phone_briefing.message_label.get_theme_font("font") == fusion_font)
	assert(tutorial.phone_briefing.progress_label.text == "04 / 06")
	assert(is_instance_valid(tutorial.tv_transition.top_bar))
	tutorial.tv_transition.set_closed(true)
	assert(is_equal_approx(tutorial.tv_transition.top_bar.size.y, 360.0))
	assert(is_equal_approx(tutorial.tv_transition.bottom_bar.position.y, 360.0))
	tutorial.tv_transition.set_closed(false)
	assert(is_zero_approx(tutorial.tv_transition.top_bar.size.y))
	tutorial.phone_briefing.visible = false
	tutorial._show_world_bubble(tutorial.blade_enemy, arrival[0])
	assert(is_instance_valid(tutorial.active_story_bubble))
	assert(tutorial.active_story_bubble.get_parent() == tutorial.blade_enemy)
	assert("赤井帮打手" in tutorial.active_story_bubble.text)
	assert(tutorial.active_story_bubble.position.y + tutorial.active_story_bubble.size.y <= -170.0)
	tutorial.story_typewriter.begin_line(tutorial.active_story_bubble, tutorial.active_story_hint, tutorial.active_story_bubble.text, 34.0)
	assert(not tutorial.active_story_hint.visible)
	tutorial.story_typewriter.reveal_immediately()
	assert(tutorial.active_story_hint.visible and tutorial.active_story_hint.text == "J  //  继续")
	assert(tutorial.active_story_bubble.get_theme_font("font") == fusion_font)
	var bubble_color: Color = tutorial.active_story_bubble.get_theme_color("font_color")
	assert(bubble_color.r > 0.9 and bubble_color.g > 0.9 and bubble_color.b > 0.9)
	var i18n := root.get_node("I18n")
	var current_locale: String = i18n.locale
	i18n.set_language("en", false)
	await _capture_locale("tutorial-en")
	i18n.set_language(current_locale, false)
	tutorial._clear_world_bubble()
	tutorial._prepare_tutorial_scene(false)
	assert(tutorial.player.global_position.is_equal_approx(tutorial.TUTORIAL_PLAYER_POSITION))
	assert(not tutorial.player.visible)
	assert(tutorial.player.force_idle_visual)
	tutorial.tutorial_phase = tutorial.TutorialPhase.ARRIVAL_MATERIALIZE
	tutorial._trigger_shadow_materialization()
	assert(tutorial.materialization_effect.visible and tutorial.materialization_effect.intensity > 0.99)
	assert(tutorial.lightning_flash == 1.0 and tutorial.shake_strength >= 8.5)
	tutorial.player.visible = true
	tutorial._show_world_bubble(tutorial.blade_enemy, materialize[0])
	assert(String(materialize[0]["text"]) in tutorial.active_story_bubble.text)
	assert(tutorial.player.global_position.is_equal_approx(tutorial.TUTORIAL_PLAYER_POSITION))
	assert(tutorial.player.force_idle_visual)
	assert(tutorial.player._resolve_visual_state()["texture"] == load("res://scripts/animation_frames.gd").HERO_IDLE[0])
	tutorial._clear_world_bubble()

	for child in tutorial.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await create_timer(0.12).timeout
	tutorial.free()
	tutorial = null
	await process_frame
	await create_timer(0.12).timeout
	story = null
	tutorial_scene = null
	fusion_font = null
	print("[STORY_SMOKE_PASS] bilingual UI, stored preference, editable story, J-gated dialogue, bundled CJK font, and original story scene wiring verified")
	quit(0)

func _check_bilingual() -> void:
	var i18n := root.get_node("I18n")
	var original_locale: String = i18n.locale
	var saves = load("res://scripts/save_store.gd")
	var best_before: float = saves.get_best_time()
	var tutorial_before: bool = saves.has_completed_tutorial()
	i18n.set_language("zh_CN", false)
	var title := (load("res://scenes/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await process_frame
	title.fade_layer.modulate.a = 0.0
	var heading := title.get_node("TitleContent/GameTitle") as Label
	assert(heading.tr(heading.text) == "SHADOW")
	await _capture_locale("title-zh")
	title.language_button.pressed.emit()
	await process_frame
	assert(i18n.locale == "en" and i18n.load_language() == "en")
	assert(not title.is_starting)
	assert(heading.tr(heading.text) == "SHADOW")
	assert(heading.get_total_character_count() == 6)
	assert(title.language_button.get_global_rect().end.x <= 1280.0)
	await _capture_locale("title-en")
	var count := Label.new()
	root.add_child(count)
	i18n.set_formatted(count, "敌人  %02d", 7)
	assert(count.text == "ENEMIES  07")
	var pause = load("res://scripts/pause_menu.gd").new()
	root.add_child(pause)
	pause.show_menu()
	await process_frame
	assert(paused and pause.is_open())
	assert(pause.resume_button.tr(pause.resume_button.text) == "Resume")
	assert(pause.language_button.get_global_rect().end.y <= 720.0)
	await _capture_locale("pause-en")
	pause.language_button.pressed.emit()
	await process_frame
	assert(paused and pause.is_open())
	assert(count.text == "敌人  07")
	assert(pause.resume_button.tr(pause.resume_button.text) == "继续游戏")
	pause.resume_game()
	assert(not paused)
	i18n.set_language("en", false)
	# Every editable story entry, speaker and composite must have a translation.
	var story = load("res://scripts/story_store.gd")
	story.reload()
	for scene_id in story._scenes:
		for entry in story.get_scene(scene_id):
			var text: String = entry["text"]
			var speaker: String = entry["speaker"]
			assert(i18n.messages.has(text), "Missing story translation: " + text)
			if not speaker.is_empty():
				assert(i18n.messages.has(speaker + "\n" + text))
	var phone = load("res://scripts/phone_briefing.gd").new()
	root.add_child(phone)
	phone.visible = true
	phone.present_line(story.get_scene("opening_briefing")[3], 3, 6)
	phone.typing = false
	await process_frame
	assert("Akai Gang" in phone.message_label.tr(phone.message_label.text))
	await _capture_locale("briefing-en")
	phone.free()
	pause.free()
	count.free()
	title.free()
	assert(saves.get_best_time() == best_before)
	assert(saves.has_completed_tutorial() == tutorial_before)
	i18n.set_language(original_locale)
	print("[BILINGUAL_PASS] live controls, paused refresh, formatted counts, story coverage and preference persistence")

func _capture_locale(filename: String) -> void:
	var directory := OS.get_environment("GAME_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(directory.path_join(filename + ".png")) == OK)
