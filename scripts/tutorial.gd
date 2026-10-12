extends "res://scripts/game.gd"

const PhoneBriefing = preload("res://scripts/phone_briefing.gd")
const LightningMaterialization = preload("res://scripts/lightning_materialization.gd")
const DialogueTypewriter = preload("res://scripts/dialogue_typewriter.gd")

const TUTORIAL_SCENE_WIDTH := 1280.0
const TUTORIAL_WORLD_WIDTH := 1760.0
const STORY_GROUND_Y := 649.0
const TUTORIAL_PLAYER_POSITION := Vector2(360.0, STORY_GROUND_Y)
const BLADE_START_POSITION := Vector2(790.0, STORY_GROUND_Y)
const GUNNER_POSITION := Vector2(990.0, STORY_GROUND_Y)
const REINFORCEMENT_POSITIONS: Array[Vector2] = [
	Vector2(820.0, STORY_GROUND_Y),
	Vector2(930.0, STORY_GROUND_Y),
	Vector2(1040.0, STORY_GROUND_Y),
	Vector2(1150.0, STORY_GROUND_Y)
]
const REINFORCEMENT_ENTRY_POSITIONS: Array[Vector2] = [
	Vector2(1380.0, STORY_GROUND_Y),
	Vector2(1470.0, STORY_GROUND_Y),
	Vector2(1560.0, STORY_GROUND_Y),
	Vector2(1650.0, STORY_GROUND_Y)
]
const FINALE_PROJECTILE_X_OFFSETS: Array[float] = [82.0, 134.0, 186.0, 238.0]
const FINALE_PROJECTILE_Y_OFFSET := -44.0

const REINFORCEMENT_ENTRY_SPEED := 390.0
const EXIT_SPEED := 315.0
const FINALE_SETUP_TIME := 0.42

enum TutorialPhase {
	STORY_BRIEFING,
	ARRIVAL_MATERIALIZE,
	ARRIVAL_DIALOGUE,
	BLADE_APPROACH,
	BLADE_EXECUTE,
	GUNNER_DIALOGUE,
	GUNNER_FIRE,
	PARRY_EXECUTE,
	REINFORCEMENT_ENTRY,
	REINFORCEMENT_DIALOGUE,
	FOCUS_BARRAGE,
	FOCUS_DASH,
	EXIT_RUN,
	COMPLETE,
	FAILED
}

var tutorial_phase: TutorialPhase = TutorialPhase.STORY_BRIEFING
var active_tutorial_enemy: Node
var blade_enemy: Node
var gunner_enemy: Node
var finale_gunners: Array[Node] = []
var instruction_layer: CanvasLayer
var instruction_overlay: Control
var instruction_phase_label: Label
var instruction_label: Label
var instruction_detail_label: Label
var phone_briefing: CanvasLayer
var tv_transition: CanvasLayer
var active_story_bubble: Label
var active_story_hint: Label
var active_story_target: Node
var story_typewriter: Node
var tutorial_paused := false
var transition_timer := 0.0
var barrage_timer := 0.0
var barrage_spawned := 0
var auto_scene_change := true
var skip_story_intro := false
var story_transition_scale := 1.0
var tutorial_transition_started := false
var instruction_action: StringName = &""
var instruction_input_armed := false
var story_sequence_active := false
var story_advance_requested := false
var dialogue_running := false
var finale_reflected_count := 0
var finale_kill_count := 0
var finale_combo_started := false
var exit_run_started := false
var materialization_effect: Node2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()
	_build_background()
	_build_tutorial_world()
	_init_rain()
	_build_hud()
	_configure_tutorial_hud()
	camera = Camera2D.new()
	camera.position = Vector2(640.0, 360.0)
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_right = int(TUTORIAL_SCENE_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 720
	camera.zoom = Vector2.ONE
	add_child(camera)
	camera.make_current()
	world_art.setup(camera)
	_setup_audio()
	_setup_rewind()
	add_child(TouchInput.new())
	blood_effects = BloodEffects.new()
	add_child(blood_effects)
	projectile_explosions = ProjectileExplosions.new()
	add_child(projectile_explosions)
	crt_filter = CrtFilter.new()
	add_child(crt_filter)
	crt_filter.set_filter_enabled(false)
	_build_instruction_overlay()
	phone_briefing = PhoneBriefing.new()
	add_child(phone_briefing)
	story_typewriter = DialogueTypewriter.new()
	story_typewriter.name = "WorldDialogueTypewriter"
	add_child(story_typewriter)
	tv_transition = TVTransition.new()
	add_child(tv_transition)
	materialization_effect = LightningMaterialization.new()
	materialization_effect.name = "ShadowMaterializationLightning"
	materialization_effect.global_position = TUTORIAL_PLAYER_POSITION
	add_child(materialization_effect)
	_prepare_tutorial_scene(skip_story_intro)
	if skip_story_intro:
		tv_transition.set_closed(false)
	else:
		tv_transition.set_closed(true)
		call_deferred("_run_story_opening")

func _build_tutorial_world() -> void:
	platforms.clear()
	_add_platform(Rect2(0.0, FLOOR_Y, TUTORIAL_WORLD_WIDTH, 90.0))
	_add_wall(Rect2(-160.0, 0.0, 30.0, 720.0))
	_add_wall(Rect2(TUTORIAL_WORLD_WIDTH, 0.0, 30.0, 720.0))
	environment_art = EnvironmentArt.new()
	environment_art.name = "TutorialRooftopEnvironment"
	environment_art.setup(platforms)
	add_child(environment_art)

func _configure_tutorial_hud() -> void:
	objective_label.text = "入口 // 赤井帮外围屋顶"
	enemies_label.visible = false
	timer_label.visible = false
	controls_panel.visible = false
	controls_label.visible = false
	hint_label.text = "看准时机。撕开防线。"
	focus_text.visible = false
	focus_fill.get_parent().visible = false

func _build_instruction_overlay() -> void:
	instruction_layer = CanvasLayer.new()
	instruction_layer.name = "TutorialInstructionLayer"
	instruction_layer.layer = 65
	instruction_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(instruction_layer)
	instruction_overlay = Control.new()
	instruction_overlay.name = "TutorialInstructionOverlay"
	instruction_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	instruction_overlay.visible = false
	instruction_layer.add_child(instruction_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.015, 0.025, 0.25)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instruction_overlay.add_child(shade)
	var strip := ColorRect.new()
	strip.name = "InstructionStrip"
	strip.set_anchors_preset(Control.PRESET_CENTER)
	strip.position = Vector2(-640.0, -108.0)
	strip.size = Vector2(1280.0, 216.0)
	strip.color = Color(0.005, 0.025, 0.036, 0.91)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instruction_overlay.add_child(strip)
	var top_rule := ColorRect.new()
	top_rule.position = Vector2.ZERO
	top_rule.size = Vector2(1280.0, 2.0)
	top_rule.color = Color("48edff")
	strip.add_child(top_rule)
	var bottom_rule := ColorRect.new()
	bottom_rule.position = Vector2(0.0, 214.0)
	bottom_rule.size = Vector2(1280.0, 2.0)
	bottom_rule.color = Color(1.0, 0.55, 0.28, 0.55)
	strip.add_child(bottom_rule)
	var content := VBoxContainer.new()
	content.position = Vector2(190.0, 26.0)
	content.size = Vector2(900.0, 166.0)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 9)
	strip.add_child(content)
	instruction_phase_label = _hud_label("突入教学", 13, Color("ffad67"))
	instruction_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(instruction_phase_label)
	instruction_label = _hud_label("", 32, Color("effdff"))
	instruction_label.name = "TutorialInstruction"
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(instruction_label)
	instruction_detail_label = _hud_label("", 14, Color("8fb3bc"))
	instruction_detail_label.name = "TutorialInstructionDetail"
	instruction_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(instruction_detail_label)

func _prepare_tutorial_scene(start_at_combat: bool, preserve_rewind_splice: bool = false) -> void:
	if is_instance_valid(rewind_sequence):
		if not preserve_rewind_splice:
			rewind_sequence.cancel(true)
		rewind_sequence.queue_recorded_nodes_for_cleanup()
		rewind_sequence.reset_history()
	get_tree().paused = false
	_reset_parry_feedback()
	tutorial_paused = false
	tutorial_transition_started = false
	exit_run_started = false
	story_sequence_active = false
	dialogue_running = false
	state = RunState.PLAYING
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	for shot in projectiles:
		if is_instance_valid(shot):
			shot.queue_free()
	if is_instance_valid(player):
		player.queue_free()
	enemies.clear()
	projectiles.clear()
	finale_gunners.clear()
	parry_sparks.clear()
	if is_instance_valid(blood_effects):
		blood_effects.clear_particles()
	if is_instance_valid(projectile_explosions):
		projectile_explosions.clear_effects()
	_spawn_player()
	player.global_position = TUTORIAL_PLAYER_POSITION
	player.visible = start_at_combat
	player.set_control_enabled(false)
	player.set_forced_idle_visual(true)
	if is_instance_valid(materialization_effect):
		materialization_effect.global_position = TUTORIAL_PLAYER_POSITION
		materialization_effect.hide_effect()
	_spawn_enemy("blade", BLADE_START_POSITION, 720.0, 850.0)
	blade_enemy = enemies[-1]
	blade_enemy.action_clock = 10.0
	_spawn_enemy("gunner", GUNNER_POSITION, 900.0, 1080.0)
	gunner_enemy = enemies[-1]
	gunner_enemy.action_clock = 10.0
	gunner_enemy.set_physics_process(false)
	active_tutorial_enemy = blade_enemy
	finale_reflected_count = 0
	finale_kill_count = 0
	finale_combo_started = false
	barrage_spawned = 0
	instruction_overlay.visible = false
	phone_briefing.visible = false
	_set_story_hud_visible(start_at_combat)
	if start_at_combat:
		blade_enemy.set_physics_process(true)
		player.set_physics_process(true)
		tutorial_phase = TutorialPhase.BLADE_APPROACH
		objective_label.text = "突入 01 // 近身战"
		status_label.text = "观察敌人接近"
		_capture_rewind_frame(0.0)
	else:
		blade_enemy.set_physics_process(false)
		player.set_physics_process(false)
		tutorial_phase = TutorialPhase.STORY_BRIEFING

func _run_story_opening() -> void:
	phone_briefing.visible = true
	await tv_transition.open_screen(0.56)
	story_sequence_active = true
	await phone_briefing.play_sequence(StoryStore.get_scene("opening_briefing"))
	story_sequence_active = false
	story_advance_requested = false
	await tv_transition.close_screen(0.46)
	phone_briefing.visible = false
	_set_story_hud_visible(true)
	await tv_transition.open_screen(0.54)
	tutorial_phase = TutorialPhase.ARRIVAL_MATERIALIZE
	objective_label.text = "入口 // 赤井帮外围屋顶"
	status_label.text = "雷暴异常"
	call_deferred("_run_materialization_arrival")

func _process(delta: float) -> void:
	_tick_parry_feedback(delta)
	_apply_camera_distance()
	if state == RunState.DEAD:
		_handle_death_choice_input()
		_update_screen_effects(delta)
		_update_hud()
		queue_redraw()
		return
	if tutorial_paused:
		_update_instruction_input()
		_update_hud()
		queue_redraw()
		return
	if is_instance_valid(player):
		player.set_external_time_scale(_current_parry_time_scale())
	var simulation_scale := _current_gameplay_time_scale()
	if tutorial_phase == TutorialPhase.EXIT_RUN:
		simulation_scale = 1.0
	if is_instance_valid(blood_effects):
		blood_effects.simulation_scale = simulation_scale
	if is_instance_valid(projectile_explosions):
		projectile_explosions.simulation_scale = simulation_scale
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.simulation_scale = simulation_scale
	for shot in projectiles:
		if is_instance_valid(shot):
			shot.simulation_scale = simulation_scale
	rain_clock += delta * simulation_scale
	_update_rain(delta, simulation_scale)
	_update_storm(delta)
	_update_parry_sparks(delta * simulation_scale)
	_update_audio_tuning()
	_update_tutorial_phase(delta)
	if state == RunState.PLAYING and is_instance_valid(player) and player.visible and tutorial_phase not in [TutorialPhase.STORY_BRIEFING, TutorialPhase.ARRIVAL_MATERIALIZE, TutorialPhase.ARRIVAL_DIALOGUE, TutorialPhase.COMPLETE]:
		_capture_rewind_frame(delta)
	_update_screen_effects(delta)
	_update_hud()
	camera.position = Vector2(640.0, 360.0)
	queue_redraw()

func _apply_camera_distance() -> void:
	if not is_instance_valid(camera):
		return
	var zoom_value := 1.0 + TuningStore.get_value("parry_zoom_amount") * _parry_zoom_weight()
	camera.zoom = Vector2(zoom_value, zoom_value)

func _update_tutorial_phase(delta: float) -> void:
	match tutorial_phase:
		TutorialPhase.ARRIVAL_MATERIALIZE:
			pass
		TutorialPhase.BLADE_APPROACH:
			if is_instance_valid(blade_enemy) and blade_enemy.alive:
				var horizontal_distance: float = blade_enemy.global_position.x - player.global_position.x
				if horizontal_distance <= 108.0:
					blade_enemy.global_position = player.global_position + Vector2(72.0, 0.0)
					blade_enemy.velocity = Vector2.ZERO
					tutorial_phase = TutorialPhase.BLADE_EXECUTE
					_pause_for_instruction("按 J 斩击", "等赤井帮打手进入刀锋范围后出手。", &"attack")
		TutorialPhase.GUNNER_FIRE:
			for shot in projectiles:
				if not is_instance_valid(shot) or not shot.alive or shot.reflected:
					continue
				if shot.global_position.x - player.global_position.x <= 220.0:
					shot.global_position = player.global_position + Vector2(96.0, -44.0)
					shot.velocity = Vector2.LEFT * TuningStore.get_value("gunner_projectile_speed")
					tutorial_phase = TutorialPhase.PARRY_EXECUTE
					_pause_for_instruction("按 J 弹反子弹", "在斩击判定生效时迎向子弹。", &"attack")
					break
		TutorialPhase.REINFORCEMENT_ENTRY:
			_update_reinforcement_entry(delta)
		TutorialPhase.FOCUS_BARRAGE:
			barrage_timer -= delta
			if barrage_timer <= 0.0:
				_arrange_finale_projectiles()
				tutorial_phase = TutorialPhase.FOCUS_DASH
				_pause_for_instruction(
					"按住 L，再按 D + J",
					"进入专注，向右突进斩击；弹反四发子弹并消灭枪手小队。",
					&"focus_dash"
				)
		TutorialPhase.FOCUS_DASH:
			_check_finale_completion()
		TutorialPhase.EXIT_RUN:
			if exit_run_started and is_instance_valid(player):
				player.is_focusing = false
				player.velocity.x = EXIT_SPEED
				if player.global_position.x >= 1360.0:
					exit_run_started = false
					call_deferred("_finish_tutorial_exit")
		TutorialPhase.FAILED:
			pass

func _run_materialization_arrival() -> void:
	if dialogue_running or tutorial_phase != TutorialPhase.ARRIVAL_MATERIALIZE:
		return
	dialogue_running = true
	_set_actor_simulation(false)
	player.visible = false
	await get_tree().create_timer(0.20 * story_transition_scale).timeout
	if tutorial_phase != TutorialPhase.ARRIVAL_MATERIALIZE:
		return
	_trigger_shadow_materialization()
	await get_tree().create_timer(0.07 * story_transition_scale).timeout
	player.visible = true
	player.global_position = TUTORIAL_PLAYER_POSITION
	player.velocity = Vector2.ZERO
	player.set_forced_idle_visual(true)
	await get_tree().create_timer(0.30 * story_transition_scale).timeout
	await _play_world_scene("tutorial_materialize")
	dialogue_running = false
	tutorial_phase = TutorialPhase.ARRIVAL_DIALOGUE
	call_deferred("_run_arrival_dialogue")

func _trigger_shadow_materialization() -> void:
	lightning_flash = 1.0
	lightning_echo_timer = 0.08
	_add_screen_shake(8.5)
	if is_instance_valid(materialization_effect):
		materialization_effect.global_position = TUTORIAL_PLAYER_POSITION
		materialization_effect.strike()
	_play_sfx(THUNDER_STREAMS[0], -2.5, 0.0)

func _run_arrival_dialogue() -> void:
	if dialogue_running:
		return
	dialogue_running = true
	player.set_forced_idle_visual(true)
	_set_actor_simulation(false)
	await _play_world_scene("tutorial_arrival")
	dialogue_running = false
	active_tutorial_enemy = blade_enemy
	blade_enemy.action_clock = 10.0
	blade_enemy.set_physics_process(true)
	gunner_enemy.set_physics_process(false)
	player.set_physics_process(true)
	tutorial_phase = TutorialPhase.BLADE_APPROACH
	objective_label.text = "突入 01 // 近身战"
	status_label.text = "观察敌人接近"

func _run_gunner_alarm() -> void:
	if dialogue_running:
		return
	dialogue_running = true
	player.set_forced_idle_visual(true)
	_set_actor_simulation(false)
	await _play_world_scene("tutorial_gunner_alarm")
	_clear_defeated_tutorial_entities()
	dialogue_running = false
	active_tutorial_enemy = gunner_enemy
	gunner_enemy.action_clock = 0.05
	gunner_enemy.set_physics_process(true)
	player.set_physics_process(true)
	tutorial_phase = TutorialPhase.GUNNER_FIRE
	objective_label.text = "突入 02 // 弹道战"
	status_label.text = "盯住枪口"

func _run_reinforcement_arrival() -> void:
	if dialogue_running:
		return
	dialogue_running = true
	player.set_forced_idle_visual(true)
	_set_actor_simulation(false)
	_clear_defeated_tutorial_entities()
	finale_gunners.clear()
	for index in range(REINFORCEMENT_ENTRY_POSITIONS.size()):
		var entry_position := REINFORCEMENT_ENTRY_POSITIONS[index]
		var destination := REINFORCEMENT_POSITIONS[index]
		_spawn_enemy("gunner", entry_position, destination.x - 35.0, destination.x + 35.0)
		var reinforcement: Node = enemies[-1]
		reinforcement.action_clock = 10.0
		reinforcement.facing = -1.0
		reinforcement.velocity = Vector2(-REINFORCEMENT_ENTRY_SPEED, 0.0)
		reinforcement.set_physics_process(false)
		finale_gunners.append(reinforcement)
	dialogue_running = false
	tutorial_phase = TutorialPhase.REINFORCEMENT_ENTRY
	objective_label.text = "突入 03 // 增援抵达"
	status_label.text = "四名枪手正在进入"

func _update_reinforcement_entry(delta: float) -> void:
	var all_arrived := true
	for index in range(finale_gunners.size()):
		var reinforcement: Node = finale_gunners[index]
		if not is_instance_valid(reinforcement):
			continue
		var destination := REINFORCEMENT_POSITIONS[index]
		reinforcement.animation_clock += delta
		if reinforcement.global_position.x > destination.x:
			reinforcement.global_position.x = maxf(destination.x, reinforcement.global_position.x - REINFORCEMENT_ENTRY_SPEED * delta)
			reinforcement.velocity = Vector2(-REINFORCEMENT_ENTRY_SPEED, 0.0)
			all_arrived = false
		else:
			reinforcement.global_position = destination
			reinforcement.velocity = Vector2.ZERO
		reinforcement._sync_rim_light()
		reinforcement.queue_redraw()
	if all_arrived:
		tutorial_phase = TutorialPhase.REINFORCEMENT_DIALOGUE
		call_deferred("_run_reinforcement_dialogue")

func _run_reinforcement_dialogue() -> void:
	if dialogue_running:
		return
	dialogue_running = true
	_set_actor_simulation(false)
	for reinforcement in finale_gunners:
		if is_instance_valid(reinforcement):
			reinforcement.velocity = Vector2.ZERO
	await _play_world_scene("tutorial_reinforcements")
	dialogue_running = false
	_start_finale_barrage()

func _start_finale_barrage() -> void:
	player.attack_time = 0.0
	player.attack_cooldown = 0.0
	player.focus_energy = 100.0
	player.set_control_enabled(false)
	player.set_forced_idle_visual(true)
	player.set_physics_process(true)
	barrage_spawned = 0
	for index in range(finale_gunners.size()):
		var reinforcement: Node = finale_gunners[index]
		if not is_instance_valid(reinforcement):
			continue
		_spawn_finale_projectile(reinforcement, index)
		barrage_spawned += 1
	barrage_timer = FINALE_SETUP_TIME
	tutorial_phase = TutorialPhase.FOCUS_BARRAGE
	objective_label.text = "突入 03 // 专注强袭"
	status_label.text = "四名枪手 // 四发子弹"
	focus_text.visible = true
	focus_fill.get_parent().visible = true

func _spawn_finale_projectile(shooter: Node, lane_index: int) -> void:
	var shot := ProjectileActor.new()
	shot.position = Vector2(shooter.global_position.x - 28.0, player.global_position.y + FINALE_PROJECTILE_Y_OFFSET)
	shot.retain_for_rewind = true
	shot.setup(Vector2.LEFT, player, enemies, shooter, projectiles)
	shot.set_meta("tutorial_finale_round", true)
	shot.set_meta("tutorial_finale_index", lane_index)
	shot.hit_player.connect(_on_projectile_hit_player)
	shot.hit_enemy.connect(_on_projectile_hit_enemy)
	shot.intercepted_projectile.connect(_on_projectile_intercepted)
	shot.expired.connect(_on_projectile_expired.bind(shot))
	shot.z_index = 6
	add_child(shot)
	projectiles.append(shot)

func _arrange_finale_projectiles() -> void:
	var hostile_index := 0
	for shot in projectiles:
		if not is_instance_valid(shot) or not shot.alive or shot.reflected:
			continue
		var horizontal_offset := FINALE_PROJECTILE_X_OFFSETS[hostile_index % FINALE_PROJECTILE_X_OFFSETS.size()]
		shot.global_position = player.global_position + Vector2(horizontal_offset, FINALE_PROJECTILE_Y_OFFSET)
		shot.velocity = Vector2.LEFT * TuningStore.get_value("gunner_projectile_speed")
		shot.rotation = PI
		hostile_index += 1

func _on_enemy_fire(origin: Vector2, direction: Vector2, shooter: Node) -> void:
	if tutorial_phase != TutorialPhase.GUNNER_FIRE or shooter != gunner_enemy:
		return
	super._on_enemy_fire(origin, direction, shooter)
	if is_instance_valid(gunner_enemy):
		gunner_enemy.set_physics_process(false)

func _on_player_slash(origin: Vector2, facing: float, direction: Vector2 = Vector2.ZERO, primary: bool = true) -> void:
	super._on_player_slash(origin, facing, direction, primary)
	if tutorial_phase != TutorialPhase.FOCUS_DASH or not finale_combo_started:
		return
	for shot in projectiles:
		if not is_instance_valid(shot) or not shot.reflected or shot.has_meta("finale_reflection_counted"):
			continue
		shot.set_meta("finale_reflection_counted", true)
		if shot.has_meta("tutorial_finale_round"):
			shot.set_process(false)
		finale_reflected_count += 1
	if finale_reflected_count >= 4:
		_release_finale_projectiles()
	_check_finale_completion()

func _release_finale_projectiles() -> void:
	for shot in projectiles:
		if is_instance_valid(shot) and shot.alive and shot.reflected and shot.has_meta("tutorial_finale_round"):
			shot.set_process(true)

func _on_enemy_killed(at: Vector2) -> void:
	super._on_enemy_killed(at)
	_clear_world_bubble_if_target_dead()
	if tutorial_phase == TutorialPhase.BLADE_EXECUTE and is_instance_valid(blade_enemy) and not blade_enemy.alive:
		player.set_control_enabled(false)
		player.set_forced_idle_visual(true)
		tutorial_phase = TutorialPhase.GUNNER_DIALOGUE
		status_label.text = "首杀"
		call_deferred("_run_gunner_alarm")
	elif tutorial_phase == TutorialPhase.PARRY_EXECUTE and is_instance_valid(gunner_enemy) and not gunner_enemy.alive:
		player.set_control_enabled(false)
		player.set_forced_idle_visual(true)
		status_label.text = "弹道逆转"
		call_deferred("_run_reinforcement_arrival")
	elif tutorial_phase == TutorialPhase.FOCUS_DASH:
		finale_kill_count = _count_defeated_finale_gunners()
		_check_finale_completion()

func _on_projectile_hit_player() -> void:
	if tutorial_paused or tutorial_phase == TutorialPhase.FOCUS_BARRAGE:
		return
	super._on_projectile_hit_player()

func _on_player_died() -> void:
	if tutorial_phase == TutorialPhase.COMPLETE or tutorial_phase == TutorialPhase.FAILED:
		return
	_reset_parry_feedback()
	_apply_camera_distance()
	state = RunState.DEAD
	tutorial_phase = TutorialPhase.FAILED
	transition_timer = 0.0
	tutorial_paused = false
	instruction_input_armed = false
	instruction_overlay.visible = false
	_clear_world_bubble()
	_play_sfx(ENEMY_HIT_STREAM, -1.0, 0.0)
	_add_screen_shake(8.0)
	status_label.text = "突入失败 // 等待选择"
	if not is_instance_valid(rewind_sequence) or not rewind_sequence.arm_rewind(player, enemies, projectiles, camera, bgm_player, rain_audio_player):
		call_deferred("_prepare_tutorial_scene", true)

func _on_rewind_finished() -> void:
	if tutorial_phase == TutorialPhase.FAILED:
		_prepare_tutorial_scene(true, true)

func _pause_for_instruction(prompt: String, detail: String, required_action: StringName) -> void:
	tutorial_paused = true
	instruction_action = required_action
	instruction_input_armed = false
	instruction_phase_label.text = "突入教学"
	instruction_label.text = prompt
	instruction_detail_label.text = detail
	instruction_overlay.visible = true
	if is_instance_valid(player) and player.attack_time <= 0.0:
		player.set_forced_idle_visual(true)
	_set_actor_simulation(false)
	if is_instance_valid(bgm_player):
		bgm_player.pitch_scale = 0.72
	if is_instance_valid(rain_audio_player):
		rain_audio_player.pitch_scale = 0.72

func _update_instruction_input() -> void:
	if not instruction_input_armed:
		if _instruction_inputs_released():
			instruction_input_armed = true
		return
	if instruction_action == &"attack" and Input.is_action_just_pressed("attack"):
		_accept_attack_instruction()
	elif instruction_action == &"focus_dash" and Input.is_action_just_pressed("attack") and Input.is_action_pressed("focus") and Input.is_action_pressed("move_right"):
		_accept_focus_dash_instruction()

func _instruction_inputs_released() -> bool:
	if instruction_action == &"focus_dash":
		return not Input.is_action_pressed("attack") and not Input.is_action_pressed("focus") and not Input.is_action_pressed("move_right")
	return not Input.is_action_pressed(instruction_action)

func _accept_attack_instruction() -> void:
	if not tutorial_paused or not instruction_input_armed or (tutorial_phase != TutorialPhase.BLADE_EXECUTE and tutorial_phase != TutorialPhase.PARRY_EXECUTE):
		return
	_resume_instruction()
	player.set_control_enabled(true)
	player.set_forced_idle_visual(false)
	player.attack_cooldown = 0.0
	player.begin_slash(Vector2.ZERO)

func _accept_focus_dash_instruction() -> void:
	if not tutorial_paused or not instruction_input_armed or tutorial_phase != TutorialPhase.FOCUS_DASH:
		return
	if not Input.is_action_pressed("focus") or not Input.is_action_pressed("move_right"):
		return
	_resume_instruction()
	player.set_control_enabled(true)
	player.set_forced_idle_visual(false)
	player.focus_energy = 100.0
	player.is_focusing = true
	player.attack_cooldown = 0.0
	finale_combo_started = true
	status_label.text = "专注已启动 // 斩穿弹幕"
	player.begin_slash(Vector2.RIGHT)

func _resume_instruction() -> void:
	tutorial_paused = false
	instruction_input_armed = false
	instruction_overlay.visible = false
	_set_actor_simulation(true)
	for reinforcement in finale_gunners:
		if is_instance_valid(reinforcement):
			reinforcement.set_physics_process(false)
	if tutorial_phase == TutorialPhase.PARRY_EXECUTE and is_instance_valid(gunner_enemy):
		gunner_enemy.set_physics_process(false)

func _set_actor_simulation(enabled: bool) -> void:
	if is_instance_valid(player):
		player.set_physics_process(enabled)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.set_physics_process(enabled)
	for shot in projectiles:
		if is_instance_valid(shot):
			shot.set_process(enabled)

func _play_world_scene(scene_id: String) -> void:
	var entries := StoryStore.get_scene(scene_id)
	story_sequence_active = true
	for entry in entries:
		var target := _resolve_story_target(String(entry.get("target", "")))
		if not is_instance_valid(target):
			continue
		_show_world_bubble(target, entry)
		await story_typewriter.play_line(
			active_story_bubble,
			active_story_hint,
			active_story_bubble.text,
			34.0,
			story_transition_scale <= 0.0
		)
		_clear_world_bubble()
	story_sequence_active = false

func _resolve_story_target(target_id: String) -> Node:
	match target_id:
		"blade": return blade_enemy
		"gunner": return gunner_enemy
		"player": return player
		"reinforcement_lead": return finale_gunners[0] if not finale_gunners.is_empty() else null
	return null

func _show_world_bubble(target: Node, entry: Dictionary) -> void:
	_clear_world_bubble()
	active_story_target = target
	active_story_bubble = Label.new()
	active_story_bubble.name = "StoryDialogue"
	var speaker := String(entry.get("speaker", ""))
	var line := String(entry.get("text", ""))
	active_story_bubble.text = (speaker + "\n" if not speaker.is_empty() else "") + line
	active_story_bubble.position = Vector2(-170.0, -304.0)
	active_story_bubble.size = Vector2(340.0, 126.0)
	active_story_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active_story_bubble.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	active_story_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	active_story_bubble.add_theme_font_size_override("font_size", 17)
	active_story_bubble.add_theme_color_override("font_color", Color("f4f7f5"))
	active_story_bubble.add_theme_constant_override("outline_size", 6)
	active_story_bubble.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.96))
	active_story_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(active_story_bubble)
	active_story_hint = Label.new()
	active_story_hint.name = "StoryDialogueAdvanceHint"
	active_story_hint.text = "J  //  继续"
	active_story_hint.position = Vector2(-90.0, -176.0)
	active_story_hint.size = Vector2(180.0, 24.0)
	active_story_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active_story_hint.add_theme_font_size_override("font_size", 12)
	active_story_hint.add_theme_color_override("font_color", Color("80d6d0"))
	active_story_hint.add_theme_constant_override("outline_size", 5)
	active_story_hint.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.96))
	active_story_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	active_story_hint.visible = false
	target.add_child(active_story_hint)

func _clear_world_bubble() -> void:
	if is_instance_valid(story_typewriter):
		story_typewriter.reset()
	if is_instance_valid(active_story_bubble):
		active_story_bubble.queue_free()
	if is_instance_valid(active_story_hint):
		active_story_hint.queue_free()
	active_story_bubble = null
	active_story_hint = null
	active_story_target = null

func _clear_world_bubble_if_target_dead() -> void:
	if is_instance_valid(active_story_target) and "alive" in active_story_target and not active_story_target.alive:
		_clear_world_bubble()

func _clear_defeated_tutorial_entities() -> void:
	for enemy_index in range(enemies.size() - 1, -1, -1):
		var defeated_enemy: Node = enemies[enemy_index]
		if is_instance_valid(defeated_enemy) and not defeated_enemy.alive:
			defeated_enemy.queue_free()
			enemies.remove_at(enemy_index)
	if is_instance_valid(blood_effects):
		blood_effects.clear_particles()
	parry_sparks.clear()
	active_tutorial_enemy = null

func _count_defeated_finale_gunners() -> int:
	var defeated := 0
	for reinforcement in finale_gunners:
		if not is_instance_valid(reinforcement) or not reinforcement.alive:
			defeated += 1
	return defeated

func _check_finale_completion() -> void:
	if tutorial_phase != TutorialPhase.FOCUS_DASH or tutorial_transition_started:
		return
	finale_kill_count = _count_defeated_finale_gunners()
	if finale_combo_started and finale_reflected_count >= 4 and finale_kill_count >= 4:
		_begin_tutorial_exit()

func _begin_tutorial_exit() -> void:
	if tutorial_transition_started:
		return
	tutorial_transition_started = true
	_reset_parry_feedback()
	_apply_camera_distance()
	player.set_control_enabled(false)
	player.is_focusing = false
	player.set_forced_idle_visual(true)
	for shot in projectiles.duplicate():
		if is_instance_valid(shot):
			shot._expire()
	projectiles.clear()
	instruction_overlay.visible = true
	instruction_phase_label.text = "突入完成"
	instruction_label.text = "赤井帮外围已突破"
	instruction_detail_label.text = "沉默的雇佣兵继续深入据点。"
	if not auto_scene_change:
		_mark_tutorial_complete()
		return
	call_deferred("_start_exit_run_after_beat")

func _start_exit_run_after_beat() -> void:
	await get_tree().create_timer(0.72).timeout
	_clear_defeated_tutorial_entities()
	instruction_overlay.visible = false
	player.set_forced_idle_visual(false)
	player.set_physics_process(true)
	player.velocity = Vector2(EXIT_SPEED, 0.0)
	exit_run_started = true
	tutorial_phase = TutorialPhase.EXIT_RUN
	status_label.text = "入口已控制"

func _finish_tutorial_exit() -> void:
	player.set_physics_process(false)
	await tv_transition.close_screen(0.52 * story_transition_scale)
	_mark_tutorial_complete()
	if auto_scene_change:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/game.tscn")

func _mark_tutorial_complete() -> void:
	SaveStore.mark_tutorial_complete()
	tutorial_phase = TutorialPhase.COMPLETE
	state = RunState.COMPLETE
	player.set_control_enabled(false)
	player.is_focusing = false
	player.focus_energy = 100.0
	player.set_physics_process(false)

func _set_story_hud_visible(is_visible: bool) -> void:
	objective_label.visible = is_visible
	status_label.visible = is_visible
	hint_label.visible = is_visible
	focus_text.visible = false
	focus_fill.get_parent().visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if story_sequence_active and event is InputEventKey and event.pressed and (event.keycode == KEY_J or event.physical_keycode == KEY_J):
		story_advance_requested = true
		if is_instance_valid(phone_briefing) and phone_briefing.visible:
			phone_briefing.request_advance()
		elif is_instance_valid(story_typewriter):
			story_typewriter.request_advance()
		get_viewport().set_input_as_handled()
		return
	if not tutorial_paused or not instruction_input_armed:
		return
	if instruction_action == &"attack" and event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		_accept_attack_instruction()
	elif instruction_action == &"focus_dash" and event.is_action_pressed("attack") and Input.is_action_pressed("focus") and Input.is_action_pressed("move_right"):
		get_viewport().set_input_as_handled()
		_accept_focus_dash_instruction()

func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
