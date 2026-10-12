extends Node2D

const PlayerActor = preload("res://scripts/player.gd")
const EnemyActor = preload("res://scripts/enemy.gd")
const ProjectileActor = preload("res://scripts/projectile.gd")
const TouchInput = preload("res://scripts/touch_input.gd")
const TuningPanel = preload("res://scripts/tuning_panel.gd")
const TuningStore = preload("res://scripts/tuning_store.gd")
const HitboxDebugOverlay = preload("res://scripts/hitbox_debug_overlay.gd")
const BloodEffects = preload("res://scripts/blood_effects.gd")
const ProjectileExplosions = preload("res://scripts/projectile_explosions.gd")
const WorldArt = preload("res://scripts/world_art.gd")
const EnvironmentArt = preload("res://scripts/environment_art.gd")
const CrtFilter = preload("res://scripts/crt_filter.gd")
const PauseMenu = preload("res://scripts/pause_menu.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const StoryStore = preload("res://scripts/story_store.gd")
const TVTransition = preload("res://scripts/tv_transition.gd")
const RewindSequence = preload("res://scripts/rewind_sequence.gd")
const BOSS_SCENE := "res://scenes/boss_battle.tscn"
const NEXT_SCENE := "res://scenes/interior_level.tscn"
const BGM_STREAM: AudioStream = preload("res://assets/audio/zero_hour_bgm.ogg")
const RAIN_STREAM: AudioStream = preload("res://assets/audio/rain_loop.ogg")
const SLASH_STREAM: AudioStream = preload("res://assets/audio/slash.ogg")
const PARRY_STREAM: AudioStream = preload("res://assets/audio/parry.ogg")
const ENEMY_HIT_STREAM: AudioStream = preload("res://assets/audio/enemy_hit.ogg")
const VICTORY_STREAM: AudioStream = preload("res://assets/audio/victory.ogg")
const THUNDER_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/thunder_1.ogg"),
	preload("res://assets/audio/thunder_2.ogg"),
	preload("res://assets/audio/thunder_3.ogg")
]

const WORLD_WIDTH := 5200.0
const FLOOR_Y := 650.0
const START_POS := Vector2(150, 600)
const TOTAL_ENEMIES := 12
const GATE_X := WORLD_WIDTH - 170.0
const EXIT_TRIGGER_X := WORLD_WIDTH - 75.0
const ZONE_NEON: Array[Color] = [Color("35d9eb"), Color("ff3f9f"), Color("ffb24d"), Color("8b6cff")]
const ENEMY_BARK_CHANCE := 0.56

enum RunState { PLAYING, DEAD, COMPLETE }

var state: RunState = RunState.PLAYING
var player: CharacterBody2D
var enemies: Array[Node] = []
var projectiles: Array[Node] = []
var platforms: Array[Rect2] = []
var camera: Camera2D
var world_art: Node2D
var environment_art: Node2D
var elapsed := 0.0
var death_clock := 0.0
var gate_open := false
var rain_clock := 0.0
var rain_drops: Array[Dictionary] = []
var rain_splashes: Array[Dictionary] = []
var rain_rng := RandomNumberGenerator.new()
var parry_sparks: Array[Dictionary] = []
var kills := 0
var attempts := 1
var bgm_player: AudioStreamPlayer
var rain_audio_player: AudioStreamPlayer
var tuning_panel: CanvasLayer
var hitbox_debug_overlay: Node2D
var blood_effects: Node2D
var projectile_explosions: Node2D
var crt_filter: CanvasLayer
var pause_menu: CanvasLayer
var entrance_transition: CanvasLayer
var last_sfx_stream: AudioStream
var last_sfx_volume_db := 0.0
var last_sfx_pitch_scale := 1.0
var sfx_voices: Array[AudioStreamPlayer] = []
var lightning_overlay: ColorRect
var fx_rng := RandomNumberGenerator.new()
var thunder_timer := 8.0
var lightning_flash := 0.0
var lightning_echo_timer := -1.0
var pending_thunder_stream: AudioStream
var thunder_sound_delay := -1.0
var pending_thunder_shake := 0.0
var shake_strength := 0.0
var last_slash_direction := Vector2.RIGHT
var enemy_bark_counts := {"blade": 0, "gunner": 0}
var enemy_bark_bubbles: Dictionary = {}
var enemy_bark_rng := RandomNumberGenerator.new()
var enemy_bark_roll_override := -1.0
var entrance_transition_active := false
var entrance_transition_duration := 0.54
var auto_boss_scene_change := true
var boss_transition_requested := false
var rewind_sequence: CanvasLayer
var auto_death_title_scene_change := true
var death_title_requested := false
var parry_slow_remaining := 0.0
var parry_zoom_remaining := 0.0

var enemies_label: Label
var timer_label: Label
var objective_label: Label
var status_label: Label
var hint_label: Label
var controls_panel: ColorRect
var controls_label: Label
var focus_fill: ColorRect
var focus_text: Label
var focus_wash: ColorRect

func _ready() -> void:
	_ensure_input_actions()
	_build_background()
	_build_world()
	_init_rain()
	_build_hud()
	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 720
	add_child(camera)
	camera.make_current()
	_apply_camera_distance()
	world_art.setup(camera)
	_setup_audio()
	_setup_rewind()
	add_child(TouchInput.new())
	tuning_panel = TuningPanel.new()
	add_child(tuning_panel)
	hitbox_debug_overlay = HitboxDebugOverlay.new()
	hitbox_debug_overlay.setup(self)
	add_child(hitbox_debug_overlay)
	blood_effects = BloodEffects.new()
	add_child(blood_effects)
	projectile_explosions = ProjectileExplosions.new()
	add_child(projectile_explosions)
	crt_filter = CrtFilter.new()
	add_child(crt_filter)
	crt_filter.set_filter_enabled(false)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.pause_requested.connect(_open_pause_menu)
	pause_menu.restart_requested.connect(_restart_room)
	pause_menu.tutorial_requested.connect(_replay_tutorial)
	pause_menu.title_requested.connect(func(): get_tree().change_scene_to_file("res://scenes/title_screen.tscn"))
	pause_menu.pause_changed.connect(_on_pause_changed)
	_start_room()
	player.set_control_enabled(false)
	entrance_transition_active = true
	entrance_transition = TVTransition.new()
	add_child(entrance_transition)
	entrance_transition.set_closed(true)
	call_deferred("_open_entrance_transition")
	get_viewport().size_changed.connect(_on_viewport_changed)
	_on_viewport_changed()

func _process(delta: float) -> void:
	_tick_parry_feedback(delta)
	_apply_camera_distance()
	if state == RunState.DEAD:
		_handle_death_choice_input()
		_update_screen_effects(delta)
		_update_hud()
		queue_redraw()
		return
	if is_instance_valid(player):
		player.set_external_time_scale(_current_parry_time_scale())
	var simulation_scale := _current_gameplay_time_scale()
	if is_instance_valid(blood_effects):
		blood_effects.simulation_scale = simulation_scale
	if is_instance_valid(projectile_explosions):
		projectile_explosions.simulation_scale = simulation_scale
	rain_clock += delta * simulation_scale
	_update_rain(delta, simulation_scale)
	_update_storm(delta)
	_update_parry_sparks(delta * simulation_scale)
	_update_audio_tuning()
	if state == RunState.PLAYING and Input.is_action_just_pressed("restart"):
		_restart_room()
	if state == RunState.PLAYING and is_instance_valid(player):
		elapsed += delta
		_update_enemy_barks(delta)
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.simulation_scale = simulation_scale
		for shot in projectiles:
			if is_instance_valid(shot):
				shot.simulation_scale = simulation_scale
		var living := _living_enemy_count()
		if living == 0 and not gate_open:
			gate_open = true
			if is_instance_valid(environment_art):
				environment_art.set_gate_open(true)
			objective_label.text = "出口已开启  //  前往橙色闸门"
			status_label.text = "区域肃清"
			_status_flash(Color("58f1ff"))
		if gate_open and player.global_position.x > EXIT_TRIGGER_X:
			_complete_run()
		_update_camera()
	if state == RunState.PLAYING:
		_capture_rewind_frame(delta)
	_update_screen_effects(delta)
	_update_hud()
	queue_redraw()

func _draw() -> void:
	# Layered rain uses per-drop velocity and depth; motion is updated with focus time scale.
	for drop in rain_drops:
		var position: Vector2 = drop["position"]
		var velocity: Vector2 = drop["velocity"]
		var depth: float = drop["depth"]
		var length: float = drop["length"]
		var tail := position - velocity.normalized() * length
		draw_line(position, tail, Color(0.48, 0.82, 0.9, lerpf(0.12, 0.48, depth)), lerpf(0.65, 1.8, depth), true)
		if depth > 0.78:
			draw_line(position, position - velocity.normalized() * length * 0.35, Color(0.82, 0.95, 1.0, 0.34), 1.0, true)
	for splash in rain_splashes:
		var splash_position: Vector2 = splash["position"]
		var splash_life: float = splash["life"]
		var spread := (0.26 - splash_life) * 38.0
		draw_line(splash_position - Vector2(spread, 0), splash_position + Vector2(spread, 0), Color(0.5, 0.87, 0.95, splash_life * 2.1), 1.2, true)
		draw_arc(splash_position, 3.0 + spread * 0.45, PI, TAU, 10, Color(0.58, 0.9, 0.96, splash_life * 1.8), 1.0)
	for spark in parry_sparks:
		var spark_position: Vector2 = spark["position"]
		var spark_velocity: Vector2 = spark["velocity"]
		var spark_life: float = spark["life"]
		var spark_max_life: float = spark["max_life"]
		var life_ratio := clampf(spark_life / spark_max_life, 0.0, 1.0)
		var warmth: float = spark["warmth"]
		var spark_color := Color(1.0, lerpf(0.48, 0.92, warmth), lerpf(0.04, 0.58, warmth), life_ratio)
		var trail := spark_velocity.normalized() * float(spark["length"]) * life_ratio
		draw_line(spark_position, spark_position - trail, spark_color, lerpf(0.45, 1.25, warmth), true)
		if bool(spark["core"]) and life_ratio > 0.45:
			draw_circle(spark_position, 2.2 * life_ratio, Color(1.0, 0.97, 0.82, life_ratio))

func _build_background() -> void:
	world_art = WorldArt.new()
	world_art.name = "OriginalFixedSkyline"
	add_child(world_art)

func _build_world() -> void:
	_add_platform(Rect2(0, FLOOR_Y, WORLD_WIDTH, 90))
	_add_platform(Rect2(535, 530, 260, 30))
	_add_platform(Rect2(1050, 470, 300, 30))
	_add_platform(Rect2(1660, 545, 300, 30))
	_add_platform(Rect2(2180, 500, 180, 30))
	_add_platform(Rect2(2550, 430, 270, 30))
	_add_platform(Rect2(3000, 540, 320, 30))
	_add_platform(Rect2(3520, 460, 300, 30))
	_add_platform(Rect2(4050, 535, 270, 30))
	_add_platform(Rect2(4500, 450, 260, 30))
	_add_wall(Rect2(-30, 0, 30, 720))
	_add_wall(Rect2(WORLD_WIDTH, 0, 30, 720))
	environment_art = EnvironmentArt.new()
	environment_art.name = "TexturedRooftopEnvironment"
	environment_art.setup(platforms)
	add_child(environment_art)

func _add_platform(rect: Rect2) -> void:
	platforms.append(rect)
	_add_wall(rect, true)

func _add_wall(rect: Rect2, one_way: bool = false) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = rect.position + rect.size * 0.5
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.one_way_collision = one_way
	collision.one_way_collision_margin = 10.0
	body.add_child(collision)
	add_child(body)

func _start_room() -> void:
	if is_instance_valid(rewind_sequence):
		rewind_sequence.reset_history()
	_reset_parry_feedback()
	state = RunState.PLAYING
	gate_open = false
	boss_transition_requested = false
	_clear_all_enemy_barks()
	enemy_bark_counts = {"blade": 0, "gunner": 0}
	enemy_bark_rng.randomize()
	if is_instance_valid(environment_art):
		environment_art.set_gate_open(false)
	elapsed = 0.0
	kills = 0
	status_label.text = ""
	I18n.set_formatted(objective_label, "任务  //  消灭 %d 名敌人", TOTAL_ENEMIES)
	hint_label.text = "方向 + 斩击可突进  •  斩击子弹可弹反"
	_spawn_player()
	_spawn_enemy("blade", Vector2(690, 475), 555, 770)
	_spawn_enemy("gunner", Vector2(1210, 415), 1080, 1320)
	_spawn_enemy("blade", Vector2(1760, 490), 1680, 1930)
	_spawn_enemy("gunner", Vector2(2210, 445), 2190, 2340)
	_spawn_enemy("blade", Vector2(2660, 375), 2570, 2790)
	_spawn_enemy("gunner", Vector2(3080, 485), 3020, 3290)
	_spawn_enemy("blade", Vector2(3640, 405), 3540, 3790)
	_spawn_enemy("gunner", Vector2(4140, 480), 4070, 4290)
	_spawn_enemy("blade", Vector2(4590, 395), 4520, 4730)
	_spawn_enemy("gunner", Vector2(4860, 595), 4780, 5050)
	_spawn_enemy("blade", Vector2(2860, 595), 2840, 2960)
	_spawn_enemy("gunner", Vector2(3920, 595), 3860, 4020)
	_capture_rewind_frame(0.0)

func _spawn_player() -> void:
	player = PlayerActor.new()
	player.position = START_POS
	player.set_drop_through_floor_y(FLOOR_Y - 8.0)
	player.z_index = 5
	player.died.connect(_on_player_died)
	player.slash.connect(_on_player_slash)
	add_child(player)

func _spawn_enemy(kind: String, at: Vector2, patrol_left: float, patrol_right: float) -> void:
	var enemy := EnemyActor.new()
	enemy.kind = kind
	enemy.retain_for_rewind = true
	enemy.player = player
	enemy.position = at
	enemy.patrol_left = patrol_left
	enemy.patrol_right = patrol_right
	enemy.z_index = 4
	enemy.fire_projectile.connect(_on_enemy_fire)
	enemy.killed.connect(_on_enemy_killed)
	var bark_entries := StoryStore.get_barks(kind)
	var bark_index := int(enemy_bark_counts.get(kind, 0))
	if not bark_entries.is_empty():
		enemy.set_meta("story_bark", bark_entries[bark_index % bark_entries.size()])
		enemy_bark_counts[kind] = bark_index + 1
	add_child(enemy)
	enemies.append(enemy)

func _on_enemy_fire(origin: Vector2, direction: Vector2, shooter: Node) -> void:
	if state != RunState.PLAYING:
		return
	if not is_instance_valid(shooter) or not bool(shooter.get("alive")) or not bool(shooter.get("combat_active")) or direction.length_squared() < 0.0001:
		return
	var shot := ProjectileActor.new()
	shot.position = origin
	shot.retain_for_rewind = true
	shot.setup(direction, player, enemies, shooter, projectiles, _projectile_world_bounds())
	shot.hit_player.connect(_on_projectile_hit_player)
	shot.hit_enemy.connect(_on_projectile_hit_enemy)
	shot.intercepted_projectile.connect(_on_projectile_intercepted)
	shot.expired.connect(_on_projectile_expired.bind(shot))
	shot.z_index = 6
	add_child(shot)
	projectiles.append(shot)

func _projectile_world_bounds() -> Rect2:
	return ProjectileActor.DEFAULT_WORLD_BOUNDS

func _on_projectile_hit_player() -> void:
	if is_instance_valid(player):
		player.die()

func _on_projectile_hit_enemy(enemy: Node) -> void:
	if is_instance_valid(enemy) and enemy.alive:
		enemy.kill()

func _on_projectile_intercepted(_projectile: Node, position: Vector2, intercepted_velocity: Vector2) -> void:
	if is_instance_valid(projectile_explosions):
		projectile_explosions.spawn_burst(position, intercepted_velocity)
	_play_sfx(PARRY_STREAM, -2.0, 0.012)
	_add_screen_shake(2.8)

func _on_projectile_expired(shot: Node) -> void:
	projectiles.erase(shot)

func _on_player_slash(origin: Vector2, facing: float, direction: Vector2 = Vector2.ZERO, primary: bool = true) -> void:
	if state != RunState.PLAYING:
		return
	var slash_direction := direction.normalized() if direction.length_squared() > 0.01 else Vector2(facing, 0.0)
	last_slash_direction = slash_direction
	if primary:
		_play_sfx(SLASH_STREAM, -2.5, 0.018)
		_add_screen_shake(2.0)
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		if _attack_hitbox_overlaps_rect(enemy.get_hurtbox_rect_world(), origin, slash_direction):
			enemy.kill()
	var reflected_any := false
	for shot in projectiles:
		if not is_instance_valid(shot) or not shot.alive or shot.reflected:
			continue
		if _attack_hitbox_overlaps_circle(shot.global_position, shot.get_hit_radius(), origin, slash_direction):
			var impact_position: Vector2 = shot.global_position
			var incoming_velocity: Vector2 = shot.velocity
			shot.reflect(facing)
			_spawn_parry_sparks(impact_position, incoming_velocity)
			reflected_any = true
	if reflected_any:
		_trigger_parry_feedback()
		_play_sfx(PARRY_STREAM, -0.5, 0.012)
		_add_screen_shake(6.2)

func _point_inside_attack_hitbox(point: Vector2, origin: Vector2, direction: Vector2) -> bool:
	var offset := point - origin
	var forward_distance := offset.dot(direction)
	var lateral_distance := absf(offset.cross(direction))
	return (
		forward_distance > -TuningStore.get_value("attack_hitbox_back")
		and forward_distance < TuningStore.get_value("attack_hitbox_forward")
		and lateral_distance < TuningStore.get_value("attack_hitbox_height") * 0.5
	)

func _attack_hitbox_overlaps_rect(target_rect: Rect2, origin: Vector2, direction: Vector2) -> bool:
	var forward := direction.normalized()
	var lateral := Vector2(-forward.y, forward.x)
	var hitbox_back := TuningStore.get_value("attack_hitbox_back")
	var hitbox_forward := TuningStore.get_value("attack_hitbox_forward")
	var attack_center := origin + forward * ((hitbox_forward - hitbox_back) * 0.5)
	var attack_half := Vector2((hitbox_forward + hitbox_back) * 0.5, TuningStore.get_value("attack_hitbox_height") * 0.5)
	var target_center := target_rect.get_center()
	var target_half := target_rect.size * 0.5
	var center_delta := target_center - attack_center
	for axis in [forward, lateral, Vector2.RIGHT, Vector2.DOWN]:
		var attack_radius := attack_half.x * absf(axis.dot(forward)) + attack_half.y * absf(axis.dot(lateral))
		var target_radius := target_half.x * absf(axis.x) + target_half.y * absf(axis.y)
		if absf(center_delta.dot(axis)) > attack_radius + target_radius:
			return false
	return true

func _attack_hitbox_overlaps_circle(point: Vector2, radius: float, origin: Vector2, direction: Vector2) -> bool:
	var forward := direction.normalized()
	var lateral := Vector2(-forward.y, forward.x)
	var offset := point - origin
	var local_point := Vector2(offset.dot(forward), offset.dot(lateral))
	var closest := Vector2(
		clampf(local_point.x, -TuningStore.get_value("attack_hitbox_back"), TuningStore.get_value("attack_hitbox_forward")),
		clampf(local_point.y, -TuningStore.get_value("attack_hitbox_height") * 0.5, TuningStore.get_value("attack_hitbox_height") * 0.5)
	)
	return local_point.distance_squared_to(closest) <= radius * radius

func _attack_hitbox_rect() -> Rect2:
	var hitbox_back := TuningStore.get_value("attack_hitbox_back")
	var hitbox_forward := TuningStore.get_value("attack_hitbox_forward")
	var hitbox_half_height := TuningStore.get_value("attack_hitbox_height") * 0.5
	return Rect2(-hitbox_back, -hitbox_half_height, hitbox_back + hitbox_forward, hitbox_half_height * 2.0)

func _should_draw_hitbox_preview() -> bool:
	return is_instance_valid(player) and is_instance_valid(tuning_panel) and is_instance_valid(tuning_panel.panel) and tuning_panel.panel.visible

func _hitbox_preview_direction() -> Vector2:
	if player.attack_time > 0.0 and player.attack_direction.length_squared() > 0.01:
		return player.attack_direction.normalized()
	var held_direction := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("aim_up", "aim_down")
	)
	if held_direction.length_squared() > 0.01:
		return held_direction.normalized()
	return Vector2(player.facing, 0.0)

func _on_enemy_killed(at: Vector2) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.alive and enemy.global_position.distance_squared_to(at) < 4.0:
			_clear_enemy_bark(enemy)
			break
	kills += 1
	if is_instance_valid(blood_effects):
		blood_effects.spawn_spray(at + Vector2(0.0, -34.0), last_slash_direction)
	_play_sfx(ENEMY_HIT_STREAM, -1.0, 0.018)
	_add_screen_shake(6.8)
	_status_flash(Color("ffb36b"))

func _on_player_died() -> void:
	if state != RunState.PLAYING:
		return
	_reset_parry_feedback()
	_apply_camera_distance()
	state = RunState.DEAD
	death_clock = 0.0
	_play_sfx(ENEMY_HIT_STREAM, -1.0, 0.018)
	_add_screen_shake(9.0)
	status_label.text = "计划失败  //  等待选择"
	status_label.add_theme_color_override("font_color", Color("ff735f"))
	if not is_instance_valid(rewind_sequence) or not rewind_sequence.arm_rewind(player, enemies, projectiles, camera, bgm_player, rain_audio_player):
		call_deferred("_restart_room")

func _handle_death_choice_input() -> void:
	if not is_instance_valid(rewind_sequence):
		return
	if Input.is_action_just_pressed("pause_game"):
		rewind_sequence.cancel(false)
		get_tree().paused = false
		death_title_requested = true
		if auto_death_title_scene_change:
			get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
	elif Input.is_action_just_pressed("restart") and rewind_sequence.is_waiting_for_input():
		if rewind_sequence.start_rewind():
			status_label.text = "计划失败  //  倒放中"

func _restart_room(preserve_rewind_splice: bool = false) -> void:
	if is_instance_valid(rewind_sequence):
		if not preserve_rewind_splice:
			rewind_sequence.cancel(true)
		rewind_sequence.queue_recorded_nodes_for_cleanup()
		rewind_sequence.reset_history()
	death_title_requested = false
	attempts += 1
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
	parry_sparks.clear()
	if is_instance_valid(blood_effects):
		blood_effects.clear_particles()
	if is_instance_valid(projectile_explosions):
		projectile_explosions.clear_effects()
	_start_room()

func _complete_run() -> void:
	if state != RunState.PLAYING:
		return
	_reset_parry_feedback()
	_apply_camera_distance()
	state = RunState.COMPLETE
	_clear_all_enemy_barks()
	player.set_control_enabled(false)
	SaveStore.submit_time(elapsed)
	boss_transition_requested = true
	if auto_boss_scene_change:
		call_deferred("_enter_next_stage")

func _living_enemy_count() -> int:
	var count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.alive:
			count += 1
	return count

func _open_entrance_transition() -> void:
	if is_instance_valid(entrance_transition):
		await entrance_transition.open_screen(entrance_transition_duration)
	entrance_transition_active = false
	if state == RunState.PLAYING and is_instance_valid(player) and player.alive and not get_tree().paused:
		player.set_control_enabled(true)

func _update_enemy_barks(delta: float) -> void:
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive or enemy.has_meta("story_bark_shown"):
			continue
		var offset: Vector2 = enemy.global_position - player.global_position
		if absf(offset.x) <= 570.0 and absf(offset.y) <= 250.0:
			_show_enemy_bark(enemy)
	for enemy in enemy_bark_bubbles.keys():
		if not is_instance_valid(enemy) or not enemy.alive:
			_clear_enemy_bark(enemy)
			continue
		var bubble_data: Dictionary = enemy_bark_bubbles[enemy]
		bubble_data["remaining"] = float(bubble_data["remaining"]) - delta
		if float(bubble_data["remaining"]) <= 0.0:
			_clear_enemy_bark(enemy)
		else:
			enemy_bark_bubbles[enemy] = bubble_data

func _show_enemy_bark(enemy: Node) -> void:
	var entry: Dictionary = enemy.get_meta("story_bark", {})
	if entry.is_empty():
		return
	enemy.set_meta("story_bark_shown", true)
	var roll := enemy_bark_roll_override if enemy_bark_roll_override >= 0.0 else enemy_bark_rng.randf()
	enemy.set_meta("story_bark_roll", roll)
	if roll >= ENEMY_BARK_CHANCE:
		return
	var bubble := Label.new()
	bubble.name = "StoryBark"
	bubble.text = String(entry.get("text", ""))
	bubble.position = Vector2(-150.0, -264.0)
	bubble.size = Vector2(300.0, 100.0)
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_theme_font_size_override("font_size", 16)
	bubble.add_theme_color_override("font_color", Color("f6f8f7"))
	bubble.add_theme_constant_override("outline_size", 6)
	bubble.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.96))
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy.add_child(bubble)
	enemy_bark_bubbles[enemy] = {
		"label": bubble,
		"remaining": maxf(0.2, float(entry.get("duration", 3.0)))
	}

func _clear_enemy_bark(enemy) -> void:
	if not enemy_bark_bubbles.has(enemy):
		return
	var bubble_data: Dictionary = enemy_bark_bubbles[enemy]
	var bubble = bubble_data.get("label")
	if is_instance_valid(bubble):
		bubble.queue_free()
	enemy_bark_bubbles.erase(enemy)

func _clear_all_enemy_barks() -> void:
	for enemy in enemy_bark_bubbles.keys():
		_clear_enemy_bark(enemy)
	enemy_bark_bubbles.clear()

func _update_camera() -> void:
	var view_width := get_camera_visible_world_size().x
	var half := view_width * 0.5
	camera.position.x = clampf(player.global_position.x + 120.0, half, WORLD_WIDTH - half)
	camera.position.y = 360.0

func _apply_camera_distance() -> void:
	if not is_instance_valid(camera):
		return
	var distance := clampf(TuningStore.get_value("camera_distance"), 0.75, 1.60)
	var zoom_value := (1.0 / distance) * (1.0 + TuningStore.get_value("parry_zoom_amount") * _parry_zoom_weight())
	camera.zoom = Vector2(zoom_value, zoom_value)

func get_camera_visible_world_size() -> Vector2:
	var view_size := get_viewport_rect().size
	if not is_instance_valid(camera):
		return view_size
	return Vector2(
		view_size.x / maxf(camera.zoom.x, 0.001),
		view_size.y / maxf(camera.zoom.y, 0.001)
	)

func _setup_audio() -> void:
	fx_rng.randomize()
	bgm_player = AudioStreamPlayer.new()
	var looping_bgm := BGM_STREAM.duplicate()
	if looping_bgm is AudioStreamOggVorbis:
		looping_bgm.loop = true
	bgm_player.stream = looping_bgm
	bgm_player.volume_db = TuningStore.get_value("bgm_volume_db")
	add_child(bgm_player)
	bgm_player.play()
	rain_audio_player = AudioStreamPlayer.new()
	var looping_rain := RAIN_STREAM.duplicate()
	if looping_rain is AudioStreamOggVorbis:
		looping_rain.loop = true
	rain_audio_player.stream = looping_rain
	rain_audio_player.volume_db = TuningStore.get_value("rain_volume_db")
	add_child(rain_audio_player)
	rain_audio_player.play()
	thunder_timer = fx_rng.randf_range(6.0, 14.0)

func _setup_rewind() -> void:
	rewind_sequence = RewindSequence.new()
	rewind_sequence.name = "DeathRewind"
	add_child(rewind_sequence)
	rewind_sequence.finished.connect(_on_rewind_finished)

func _capture_rewind_frame(delta: float) -> void:
	if is_instance_valid(rewind_sequence) and is_instance_valid(player):
		rewind_sequence.capture(delta, player, enemies, projectiles, camera)

func _on_rewind_finished() -> void:
	if state == RunState.DEAD:
		_restart_room(true)

func _update_audio_tuning() -> void:
	if is_instance_valid(bgm_player):
		bgm_player.volume_db = TuningStore.get_value("bgm_volume_db")
	if is_instance_valid(rain_audio_player):
		rain_audio_player.volume_db = TuningStore.get_value("rain_volume_db")
	var focus_pitch := _current_gameplay_time_scale()
	for index in range(sfx_voices.size() - 1, -1, -1):
		var voice := sfx_voices[index]
		if not is_instance_valid(voice):
			sfx_voices.remove_at(index)
			continue
		var base_pitch: float = voice.get_meta("base_pitch", 1.0)
		voice.pitch_scale = base_pitch * focus_pitch

func _play_sfx(stream: AudioStream, volume_db: float, pitch_jitter: float = 0.0) -> void:
	last_sfx_stream = stream
	last_sfx_volume_db = volume_db + TuningStore.get_value("sfx_volume_db")
	var base_pitch := 1.0 + fx_rng.randf_range(-pitch_jitter, pitch_jitter)
	last_sfx_pitch_scale = base_pitch * _current_gameplay_time_scale()
	if stream == null or DisplayServer.get_name() == "headless":
		return
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	voice.volume_db = last_sfx_volume_db
	voice.pitch_scale = last_sfx_pitch_scale
	voice.set_meta("base_pitch", base_pitch)
	voice.finished.connect(_on_sfx_voice_finished.bind(voice))
	add_child(voice)
	sfx_voices.append(voice)
	voice.play()

func _on_sfx_voice_finished(voice: AudioStreamPlayer) -> void:
	sfx_voices.erase(voice)
	if is_instance_valid(voice):
		voice.queue_free()

func _current_gameplay_time_scale() -> float:
	return player.simulation_scale if state == RunState.PLAYING and is_instance_valid(player) else 1.0

func _current_parry_time_scale() -> float:
	return TuningStore.get_value("melee_parry_time_scale") if state == RunState.PLAYING and parry_slow_remaining > 0.0 else 1.0

func _trigger_parry_feedback() -> void:
	parry_slow_remaining = maxf(0.0, TuningStore.get_value("melee_parry_slow_duration"))
	parry_zoom_remaining = maxf(0.0, TuningStore.get_value("parry_zoom_duration"))
	if is_instance_valid(player):
		player.set_external_time_scale(_current_parry_time_scale())
	var scale := _current_gameplay_time_scale()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.simulation_scale = scale
	for shot in projectiles:
		if is_instance_valid(shot):
			shot.simulation_scale = scale
	if is_instance_valid(blood_effects):
		blood_effects.simulation_scale = scale
	if is_instance_valid(projectile_explosions):
		projectile_explosions.simulation_scale = scale
	_apply_camera_distance()

func _tick_parry_feedback(delta: float) -> void:
	if state != RunState.PLAYING:
		return
	parry_slow_remaining = maxf(0.0, parry_slow_remaining - delta)
	parry_zoom_remaining = maxf(0.0, parry_zoom_remaining - delta)

func _reset_parry_feedback() -> void:
	parry_slow_remaining = 0.0
	parry_zoom_remaining = 0.0
	if is_instance_valid(player):
		player.set_external_time_scale(1.0)

func _parry_zoom_weight() -> float:
	var duration := maxf(0.0, TuningStore.get_value("parry_zoom_duration"))
	if duration <= 0.0 or parry_zoom_remaining <= 0.0:
		return 0.0
	return pow(clampf(parry_zoom_remaining / duration, 0.0, 1.0), 0.65)

func _add_screen_shake(amount: float) -> void:
	shake_strength = maxf(shake_strength, amount)

func _update_screen_effects(delta: float) -> void:
	if is_instance_valid(camera):
		if shake_strength > 0.05:
			camera.offset = Vector2(fx_rng.randf_range(-1.0, 1.0), fx_rng.randf_range(-1.0, 1.0)) * shake_strength
			shake_strength = move_toward(shake_strength, 0.0, delta * 24.0)
		else:
			shake_strength = 0.0
			camera.offset = Vector2.ZERO
	if is_instance_valid(lightning_overlay):
		lightning_flash = move_toward(lightning_flash, 0.0, delta * 3.7)
		lightning_overlay.color.a = lightning_flash * 0.30
	if is_instance_valid(rain_audio_player) and is_instance_valid(player):
		var target_pitch := 0.72 if state == RunState.PLAYING and player.is_focusing else 1.0
		if state == RunState.PLAYING and parry_slow_remaining > 0.0:
			target_pitch = minf(target_pitch, TuningStore.get_value("melee_parry_time_scale"))
		rain_audio_player.pitch_scale = move_toward(rain_audio_player.pitch_scale, target_pitch, delta * 3.0)
	if is_instance_valid(bgm_player) and is_instance_valid(player):
		var target_bgm_pitch := 0.72 if state == RunState.PLAYING and player.is_focusing else 1.0
		if state == RunState.PLAYING and parry_slow_remaining > 0.0:
			target_bgm_pitch = minf(target_bgm_pitch, TuningStore.get_value("melee_parry_time_scale"))
		bgm_player.pitch_scale = move_toward(bgm_player.pitch_scale, target_bgm_pitch, delta * 3.0)

func _update_storm(delta: float) -> void:
	thunder_timer -= delta
	if thunder_timer <= 0.0:
		_trigger_thunder()
	if thunder_sound_delay >= 0.0:
		thunder_sound_delay -= delta
		if thunder_sound_delay <= 0.0 and pending_thunder_stream != null:
			_play_sfx(pending_thunder_stream, -5.0, 0.025)
			_add_screen_shake(pending_thunder_shake)
			pending_thunder_stream = null
			pending_thunder_shake = 0.0
			thunder_sound_delay = -1.0
	if lightning_echo_timer >= 0.0:
		lightning_echo_timer -= delta
		if lightning_echo_timer <= 0.0:
			lightning_flash = maxf(lightning_flash, 0.48)
			lightning_echo_timer = -1.0

func _trigger_thunder() -> void:
	lightning_flash = 1.0
	lightning_echo_timer = fx_rng.randf_range(0.07, 0.16)
	pending_thunder_stream = THUNDER_STREAMS[fx_rng.randi_range(0, THUNDER_STREAMS.size() - 1)]
	thunder_sound_delay = fx_rng.randf_range(0.12, 0.72)
	pending_thunder_shake = fx_rng.randf_range(2.2, 3.8)
	thunder_timer = fx_rng.randf_range(8.0, 19.0)

func _update_hud() -> void:
	if not is_instance_valid(player):
		return
	I18n.set_formatted(enemies_label, "敌人  %02d", _living_enemy_count())
	timer_label.text = "%05.2f" % elapsed
	focus_fill.size.x = 230.0 * player.focus_energy / 100.0
	I18n.set_formatted(focus_text, "专注  %03d", int(player.focus_energy))
	focus_wash.color.a = 0.12 if player.is_focusing else 0.0

func _open_pause_menu() -> void:
	if state != RunState.PLAYING or not is_instance_valid(pause_menu):
		return
	if is_instance_valid(tuning_panel) and is_instance_valid(tuning_panel.panel):
		tuning_panel.panel.visible = false
	pause_menu.show_menu()

func _replay_tutorial() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")

func _on_pause_changed(paused: bool) -> void:
	for audio_player in [bgm_player, rain_audio_player]:
		if is_instance_valid(audio_player):
			audio_player.stream_paused = paused
	for voice in sfx_voices:
		if is_instance_valid(voice):
			voice.stream_paused = paused
	if not paused and not entrance_transition_active and state == RunState.PLAYING and is_instance_valid(player) and player.alive:
		player.set_control_enabled(true)

func _spawn_parry_sparks(position: Vector2, incoming_velocity: Vector2) -> void:
	var burst_direction := -incoming_velocity.normalized()
	for index in range(32):
		var angle := burst_direction.angle() + fx_rng.randf_range(-1.45, 1.45)
		var speed := fx_rng.randf_range(240.0, 820.0)
		var life := fx_rng.randf_range(0.16, 0.34)
		parry_sparks.append({
			"position": position + Vector2.from_angle(angle) * fx_rng.randf_range(0.0, 7.0),
			"velocity": Vector2.from_angle(angle) * speed * (0.22 if index == 0 else 1.0),
			"life": life,
			"max_life": life,
			"length": 5.0 if index == 0 else fx_rng.randf_range(11.0, 31.0),
			"warmth": fx_rng.randf_range(0.0, 1.0) if index > 4 else 1.0,
			"core": index == 0
		})

func _update_parry_sparks(delta: float) -> void:
	for index in range(parry_sparks.size() - 1, -1, -1):
		var spark: Dictionary = parry_sparks[index]
		var velocity: Vector2 = spark["velocity"]
		velocity.y += 920.0 * delta
		velocity *= pow(0.11, delta)
		spark["position"] = Vector2(spark["position"]) + velocity * delta
		spark["velocity"] = velocity
		spark["life"] = float(spark["life"]) - delta
		if float(spark["life"]) <= 0.0:
			parry_sparks.remove_at(index)

func _init_rain() -> void:
	rain_rng.seed = 90210
	rain_drops.clear()
	for _index in range(360):
		var depth := rain_rng.randf_range(0.15, 1.0)
		var speed := lerpf(470.0, 1080.0, depth)
		rain_drops.append({
			"position": Vector2(rain_rng.randf_range(0.0, WORLD_WIDTH), rain_rng.randf_range(-80.0, FLOOR_Y)),
			"velocity": Vector2(lerpf(-95.0, -185.0, depth), speed),
			"length": lerpf(15.0, 44.0, depth) * rain_rng.randf_range(0.78, 1.18),
			"depth": depth
		})

func _update_rain(delta: float, time_scale: float) -> void:
	var step := delta * time_scale
	for drop in rain_drops:
		var position: Vector2 = drop["position"]
		position += Vector2(drop["velocity"]) * step
		if position.y >= FLOOR_Y - 2.0:
			if float(drop["depth"]) > 0.62 and rain_splashes.size() < 42:
				rain_splashes.append({"position": Vector2(position.x, FLOOR_Y - 2.0), "life": 0.26})
			position.y = rain_rng.randf_range(-90.0, -10.0)
			position.x = fposmod(position.x + rain_rng.randf_range(120.0, 620.0), WORLD_WIDTH)
		elif position.x < 0.0:
			position.x += WORLD_WIDTH
		drop["position"] = position
	for index in range(rain_splashes.size() - 1, -1, -1):
		rain_splashes[index]["life"] = float(rain_splashes[index]["life"]) - step
		if float(rain_splashes[index]["life"]) <= 0.0:
			rain_splashes.remove_at(index)

func _build_hud() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	lightning_overlay = ColorRect.new()
	lightning_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lightning_overlay.color = Color(0.72, 0.9, 1.0, 0.0)
	lightning_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(lightning_overlay)
	focus_wash = ColorRect.new()
	focus_wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_wash.color = Color(0.15, 0.9, 1.0, 0.0)
	focus_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(focus_wash)

	objective_label = _hud_label("任务", 14, Color("78eafa"))
	objective_label.position = Vector2(38, 32)
	objective_label.size = Vector2(520, 30)
	ui.add_child(objective_label)
	enemies_label = _hud_label("敌人  %02d" % TOTAL_ENEMIES, 18, Color("edfaff"))
	enemies_label.position = Vector2(38, 62)
	enemies_label.size = Vector2(250, 30)
	ui.add_child(enemies_label)
	controls_panel = ColorRect.new()
	controls_panel.color = Color(0.015, 0.035, 0.05, 0.72)
	controls_panel.position = Vector2(28, 92)
	controls_panel.size = Vector2(390, 104)
	controls_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(controls_panel)
	controls_label = _hud_label("操作\n移动  A/D 或方向键   •   跳跃  K\n下穿平台  S/↓ + K   •   方向 + 斩击  J/X\n专注  L/Shift   •   重演  R   •   暂停  ESC   •   调参  F1/P", 11, Color("a8bbc2"))
	controls_label.position = Vector2(38, 100)
	controls_label.size = Vector2(370, 110)
	controls_label.add_theme_constant_override("line_spacing", 2)
	ui.add_child(controls_label)
	timer_label = _hud_label("00.00", 26, Color("edfaff"))
	timer_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	timer_label.position = Vector2(-190, 32)
	timer_label.size = Vector2(150, 36)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(timer_label)

	var focus_back := ColorRect.new()
	focus_back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	focus_back.position = Vector2(38, -61)
	focus_back.size = Vector2(234, 10)
	focus_back.color = Color("172c35")
	ui.add_child(focus_back)
	focus_fill = ColorRect.new()
	focus_fill.position = Vector2(2, 2)
	focus_fill.size = Vector2(230, 6)
	focus_fill.color = Color("33e6ff")
	focus_back.add_child(focus_fill)
	focus_text = _hud_label("专注  100", 12, Color("8fb8c0"))
	focus_text.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	focus_text.position = Vector2(38, -88)
	focus_text.size = Vector2(230, 24)
	ui.add_child(focus_text)

	status_label = _hud_label("", 24, Color("58f1ff"))
	status_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	status_label.position = Vector2(-260, 115)
	status_label.size = Vector2(520, 42)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(status_label)
	hint_label = _hud_label("", 12, Color("78939c"))
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_label.position = Vector2(-550, -47)
	hint_label.size = Vector2(510, 28)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(hint_label)

func _enter_next_stage() -> void:
	boss_transition_requested = false
	get_tree().change_scene_to_file(NEXT_SCENE)

func _status_flash(color: Color) -> void:
	status_label.add_theme_color_override("font_color", color)
	status_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.45)
	tween.tween_property(status_label, "modulate:a", 0.0, 0.35)

func _on_viewport_changed() -> void:
	var size := get_viewport_rect().size
	if is_instance_valid(camera):
		camera.limit_left = 0
		camera.limit_right = int(WORLD_WIDTH)
	if hint_label:
		hint_label.visible = size.x >= 1000.0

func _hud_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color(0.005, 0.012, 0.022, 0.72))
	return label

func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("aim_up", [KEY_W, KEY_UP])
	_add_key_action("aim_down", [KEY_S, KEY_DOWN])
	if InputMap.has_action("jump"):
		InputMap.action_erase_events("jump")
	_add_key_action("jump", [KEY_K])
	_add_key_action("attack", [KEY_J, KEY_X])
	if InputMap.has_action("focus"):
		InputMap.action_erase_events("focus")
	_add_key_action("focus", [KEY_L, KEY_SHIFT])
	_add_key_action("restart", [KEY_R])
	_add_key_action("pause_game", [KEY_ESCAPE])
	if not InputMap.action_has_event("attack", _mouse_event(MOUSE_BUTTON_LEFT)):
		InputMap.action_add_event("attack", _mouse_event(MOUSE_BUTTON_LEFT))

func _add_key_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func _mouse_event(button_index: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	return event
