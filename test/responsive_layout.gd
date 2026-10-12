extends SceneTree

const LOGICAL_FRAME := Vector2(1280.0, 720.0)
const TARGET_ASPECT := 16.0 / 9.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var smoke_i18n = root.get_node("I18n")
	smoke_i18n.set_language("zh_CN", false)
	var game_scene := load("res://scenes/game.tscn") as PackedScene
	var interior_scene := load("res://scenes/interior_level.tscn") as PackedScene
	var boss_scene := load("res://scenes/boss_battle.tscn") as PackedScene
	var tutorial_scene := load("res://scenes/tutorial.tscn") as PackedScene
	var title_scene := load("res://scenes/title_screen.tscn") as PackedScene
	var fusion_font := load("res://assets/template/fonts/manuscc0_regular.tres") as Font
	var tuning = load("res://scripts/tuning_store.gd")
	tuning.reset()
	assert(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep")
	assert(ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items")
	assert(Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width")),
		float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	).is_equal_approx(LOGICAL_FRAME))
	for size in [Vector2i(960, 720), Vector2i(1280, 720), Vector2i(1680, 720), Vector2i(720, 1280)]:
		root.size = size
		var title := title_scene.instantiate()
		root.add_child(title)
		await process_frame
		var story_button := title.find_child("StoryPrologueButton", true, false) as Button
		assert(is_instance_valid(story_button))
		assert(story_button.text == "剧情序章  //  从任务简报开始")
		assert(story_button.get_theme_font("font") == fusion_font)
		assert((title.get_node("TitleContent") as Control).get_child_count() == 5)
		assert(title.find_child("BestRunLabel", true, false) == null)
		assert(story_button.get_global_rect().position.x >= 0.0)
		assert(story_button.get_global_rect().end.x <= LOGICAL_FRAME.x)
		title.free()
		title = null
		var game := game_scene.instantiate()
		root.add_child(game)
		await process_frame
		assert(root.content_scale_size == Vector2i(1280, 720))
		assert(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS)
		assert(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP)
		var logical_view_size: Vector2 = game.get_viewport_rect().size
		assert(logical_view_size.is_equal_approx(LOGICAL_FRAME))
		assert(is_equal_approx(logical_view_size.x / logical_view_size.y, TARGET_ASPECT))
		var screen_transform: Transform2D = game.get_viewport().get_final_transform()
		var frame_origin: Vector2 = screen_transform * Vector2.ZERO
		var frame_end: Vector2 = screen_transform * LOGICAL_FRAME
		var frame_size: Vector2 = frame_end - frame_origin
		assert(is_equal_approx(frame_size.x / frame_size.y, TARGET_ASPECT))
		assert(frame_size.x <= float(size.x) + 1.0 and frame_size.y <= float(size.y) + 1.0)
		assert((frame_origin * 2.0 + frame_size).distance_to(Vector2(size)) <= 1.5)
		assert(is_instance_valid(game.camera))
		assert(game.camera.zoom.is_equal_approx(Vector2.ONE / 1.45))
		assert(game.get_camera_visible_world_size().is_equal_approx(LOGICAL_FRAME * 1.45))
		assert(game.world_art.get_visible_world_size().is_equal_approx(LOGICAL_FRAME * 1.45))
		assert(is_instance_valid(game.crt_filter) and not game.crt_filter.is_filter_enabled())
		assert(not game.crt_filter.overlay.visible)
		var crt_rect: Rect2 = game.crt_filter.overlay.get_rect()
		assert(crt_rect.position.is_equal_approx(Vector2.ZERO))
		assert(crt_rect.size.is_equal_approx(LOGICAL_FRAME))
		assert(game.crt_filter.overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		game.rewind_sequence.show_death_preview()
		assert(game.rewind_sequence.death_group.visible and not game.rewind_sequence.rewind_group.visible)
		for death_label in [game.rewind_sequence.death_title, game.rewind_sequence.death_rewind_prompt, game.rewind_sequence.death_exit_prompt]:
			assert(death_label.get_global_rect().position.x >= 0.0)
			assert(death_label.get_global_rect().end.x <= LOGICAL_FRAME.x)
		game.rewind_sequence.show_preview(0.5)
		assert(game.rewind_sequence.overlay.get_rect().size.is_equal_approx(LOGICAL_FRAME))
		assert(game.rewind_sequence.rewind_label.get_global_rect().position.x >= 0.0)
		assert(game.rewind_sequence.rewind_label.get_global_rect().end.x <= LOGICAL_FRAME.x)
		assert(game.rewind_sequence.timecode_label.get_global_rect().end.x <= LOGICAL_FRAME.x)
		game.rewind_sequence.hide_preview()
		var controls_canvas := game.controls_panel.get_parent() as CanvasLayer
		assert(is_instance_valid(controls_canvas) and game.crt_filter.layer < controls_canvas.layer)
		assert(game.crt_filter.layer < game.tuning_panel.layer)
		game._open_pause_menu()
		assert(paused and game.pause_menu.is_open())
		var pause_rect: Rect2 = game.pause_menu.panel.get_global_rect()
		assert(pause_rect.position.x >= 0.0 and pause_rect.position.y >= 0.0)
		assert(pause_rect.end.x <= LOGICAL_FRAME.x and pause_rect.end.y <= LOGICAL_FRAME.y)
		game.pause_menu.resume_game()
		assert(not paused)
		var controls_rect_before: Rect2 = game.controls_panel.get_global_rect()
		tuning.set_value("camera_distance", 1.60)
		game._apply_camera_distance()
		await process_frame
		assert(game.camera.zoom.is_equal_approx(Vector2(0.625, 0.625)))
		assert(game.get_camera_visible_world_size().is_equal_approx(LOGICAL_FRAME * 1.60))
		assert(game.controls_panel.get_global_rect().is_equal_approx(controls_rect_before))
		tuning.set_value("camera_distance", 1.45)
		game._apply_camera_distance()
		game.tuning_panel.panel.visible = true
		assert(game.tuning_panel.tab_buttons[0].text == "角色")
		assert(game.tuning_panel.tab_buttons[1].text == "战斗")
		assert(game.tuning_panel.tab_buttons[2].text == "敌人")
		assert(game.tuning_panel.tab_buttons[3].text == "视听")
		for tab_index in range(game.tuning_panel.tab_pages.size()):
			game.tuning_panel.select_tab(tab_index)
			await process_frame
			var tweak_rect: Rect2 = game.tuning_panel.panel.get_global_rect()
			assert(tweak_rect.position.x >= 0.0 and tweak_rect.position.y >= 0.0)
			assert(tweak_rect.end.x <= LOGICAL_FRAME.x and tweak_rect.end.y <= LOGICAL_FRAME.y)
			assert(game.tuning_panel.get_active_scroll().visible)
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
		game = null
		var interior = interior_scene.instantiate()
		interior.entrance_transition_duration = 0.0
		interior.auto_boss_scene_change = false
		interior.auto_advance_dialogue = true
		root.add_child(interior)
		await process_frame
		assert(interior.get_viewport_rect().size.is_equal_approx(LOGICAL_FRAME))
		assert(interior.camera.zoom.is_equal_approx(Vector2.ONE))
		assert(interior.camera.limit_bottom == int(interior.INTERIOR_HEIGHT))
		assert(interior.world_art.BACKDROP.get_size().is_equal_approx(Vector2(900.0, 1600.0)))
		assert(interior.world_art.WORLD_RECT.size.y == 3475.0)
		interior.player.global_position = Vector2(640.0, 980.0)
		interior._update_camera()
		assert(interior.camera.position.y < 1000.0)
		var story_store = load("res://scripts/story_store.gd")
		var interior_entry: Dictionary = story_store.get_scene("interior_floor_1")[0]
		interior._show_interior_bubble(interior.floor_groups[0][0], interior_entry)
		interior.dialogue_typewriter.begin_line(interior.active_dialogue_bubble, interior.active_dialogue_hint, interior.active_dialogue_bubble.text, 34.0)
		interior.dialogue_typewriter.reveal_immediately()
		assert(interior.active_dialogue_hint.visible and interior.active_dialogue_hint.text == "J  //  继续")
		assert(interior.active_dialogue_hint.get_theme_font("font") == fusion_font)
		interior._clear_interior_bubble()
		var ambient_entry: Dictionary = story_store.get_scene("interior_floor_5")[0]
		interior._show_ambient_npc_bubble(interior.floor_groups[4][0], ambient_entry)
		var ambient_bubble := interior.floor_groups[4][0].find_child("AmbientNpcDialogue", false, false) as Label
		assert(is_instance_valid(ambient_bubble) and ambient_bubble.get_theme_font("font") == fusion_font)
		assert(interior.active_dialogue_hint == null)
		var interior_audio_children: Array[AudioStreamPlayer] = []
		for child in interior.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
				interior_audio_children.append(child)
		await create_timer(0.12).timeout
		for interior_audio in interior_audio_children:
			if is_instance_valid(interior_audio):
				interior_audio.free()
		interior.free()
		interior = null
		var battle := boss_scene.instantiate()
		battle.skip_story_intro = true
		root.add_child(battle)
		await process_frame
		assert(battle.get_viewport_rect().size.is_equal_approx(LOGICAL_FRAME))
		assert(battle.camera.zoom.is_equal_approx(Vector2.ONE / 1.45))
		assert(battle.get_camera_visible_world_size().is_equal_approx(LOGICAL_FRAME * 1.45))
		assert(battle.world_art.get_visible_world_size().is_equal_approx(LOGICAL_FRAME * 1.45))
		assert(is_instance_valid(battle.boss_fill) and battle.boss_fill.get_global_rect().end.x <= LOGICAL_FRAME.x)
		assert(is_instance_valid(battle.boss_health_label) and battle.boss_health_label.get_global_rect().position.x >= 0.0)
		battle.tv_transition.set_aspect_ratio(battle.CINEMATIC_ASPECT)
		var cinematic_bar_height: float = (LOGICAL_FRAME.y - LOGICAL_FRAME.x / 2.35) * 0.5
		assert(is_equal_approx(battle.tv_transition.top_bar.size.y, cinematic_bar_height))
		assert(is_equal_approx(battle.tv_transition.bottom_bar.position.y, LOGICAL_FRAME.y - cinematic_bar_height))
		assert(battle.tv_transition.top_bar.get_global_rect().end.x <= LOGICAL_FRAME.x)
		assert(battle.tv_transition.bottom_bar.get_global_rect().end.y <= LOGICAL_FRAME.y)
		battle.tv_transition.set_aspect_ratio(TARGET_ASPECT)
		assert(is_zero_approx(battle.tv_transition.top_bar.size.y))
		battle.post_boss_cinematic.show_slide_preview(4)
		assert(battle.post_boss_cinematic.overlay.get_rect().size.is_equal_approx(LOGICAL_FRAME))
		assert(battle.post_boss_cinematic.panel.texture.get_size().is_equal_approx(LOGICAL_FRAME))
		var comic_caption_rect: Rect2 = battle.post_boss_cinematic.caption_back.get_global_rect()
		assert(comic_caption_rect.position.x >= 0.0 and comic_caption_rect.position.y >= 0.0)
		assert(comic_caption_rect.end.x <= LOGICAL_FRAME.x and comic_caption_rect.end.y <= LOGICAL_FRAME.y)
		assert(battle.post_boss_cinematic.counter_label.get_global_rect().end.x <= LOGICAL_FRAME.x)
		battle.post_boss_cinematic.show_final_preview()
		assert(battle.post_boss_cinematic.final_title.get_global_rect().position.x >= 0.0)
		assert(battle.post_boss_cinematic.final_title.get_global_rect().end.x <= LOGICAL_FRAME.x)
		battle.post_boss_cinematic.visible = false
		battle._open_pause_menu()
		assert(paused and battle.pause_menu.is_open())
		var boss_pause_rect: Rect2 = battle.pause_menu.panel.get_global_rect()
		assert(boss_pause_rect.position.x >= 0.0 and boss_pause_rect.position.y >= 0.0)
		assert(boss_pause_rect.end.x <= LOGICAL_FRAME.x and boss_pause_rect.end.y <= LOGICAL_FRAME.y)
		battle.pause_menu.resume_game()
		battle.tuning_panel.panel.visible = true
		battle.tuning_panel.select_tab(2)
		await process_frame
		var boss_tweak_rect: Rect2 = battle.tuning_panel.panel.get_global_rect()
		assert(boss_tweak_rect.position.x >= 0.0 and boss_tweak_rect.position.y >= 0.0)
		assert(boss_tweak_rect.end.x <= LOGICAL_FRAME.x and boss_tweak_rect.end.y <= LOGICAL_FRAME.y)
		var battle_audio_children: Array[AudioStreamPlayer] = []
		for child in battle.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
				battle_audio_children.append(child)
		await create_timer(0.12).timeout
		for battle_audio in battle_audio_children:
			if is_instance_valid(battle_audio):
				battle_audio.free()
		battle.free()
		battle = null
		var tutorial = tutorial_scene.instantiate()
		tutorial.skip_story_intro = true
		tutorial.auto_scene_change = false
		root.add_child(tutorial)
		await process_frame
		assert(tutorial.get_viewport_rect().size.is_equal_approx(LOGICAL_FRAME))
		assert(tutorial.phone_briefing.overlay.get_rect().size.is_equal_approx(LOGICAL_FRAME))
		tutorial.phone_briefing.visible = true
		assert(tutorial.phone_briefing.message_label.get_theme_font("font") == fusion_font)
		var background_rect: Rect2 = tutorial.phone_briefing.background.get_global_rect()
		assert(background_rect.position.is_equal_approx(Vector2.ZERO))
		assert(background_rect.size.is_equal_approx(LOGICAL_FRAME))
		var briefing_text_rect: Rect2 = tutorial.phone_briefing.text_column.get_global_rect()
		assert(briefing_text_rect.position.x >= 0.0 and briefing_text_rect.position.y >= 0.0)
		assert(briefing_text_rect.end.x <= LOGICAL_FRAME.x and briefing_text_rect.end.y <= LOGICAL_FRAME.y)
		tutorial.tv_transition.set_closed(true)
		assert(tutorial.tv_transition.top_bar.size.is_equal_approx(Vector2(1280.0, 360.0)))
		assert(tutorial.tv_transition.bottom_bar.get_rect().end.is_equal_approx(LOGICAL_FRAME))
		assert(is_instance_valid(tutorial.materialization_effect))
		assert(tutorial.materialization_effect.global_position.is_equal_approx(tutorial.TUTORIAL_PLAYER_POSITION))
		var tutorial_audio_children: Array[AudioStreamPlayer] = []
		for child in tutorial.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
				tutorial_audio_children.append(child)
		await create_timer(0.12).timeout
		for tutorial_audio in tutorial_audio_children:
			if is_instance_valid(tutorial_audio):
				tutorial_audio.free()
		tutorial.free()
		tutorial = null
		await process_frame
		await create_timer(0.12).timeout
	game_scene = null
	interior_scene = null
	boss_scene = null
	tutorial_scene = null
	title_scene = null
	print("[FIXED_16_9_PASS] vertical interior camera/dialogue, death choices, rewind overlay, boss apertures, comic ending, HUDs, and tweaks stay inside 1280x720 letterboxing")
	quit(0)
