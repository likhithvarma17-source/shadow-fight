extends Node2D

const PlayerActor = preload("res://scripts/player.gd")
const BossActor = preload("res://scripts/boss.gd")
const ProjectileActor = preload("res://scripts/projectile.gd")
const TouchInput = preload("res://scripts/touch_input.gd")
const TuningPanel = preload("res://scripts/tuning_panel.gd")
const TuningStore = preload("res://scripts/tuning_store.gd")
const HitboxDebugOverlay = preload("res://scripts/hitbox_debug_overlay.gd")
const BloodEffects = preload("res://scripts/blood_effects.gd")
const ProjectileExplosions = preload("res://scripts/projectile_explosions.gd")
const WorldArt = preload("res://scripts/world_art.gd")
const BossArenaArt = preload("res://scripts/boss_arena_art.gd")
const CrtFilter = preload("res://scripts/crt_filter.gd")
const PauseMenu = preload("res://scripts/pause_menu.gd")
const StoryStore = preload("res://scripts/story_store.gd")
const TVTransition = preload("res://scripts/tv_transition.gd")
const PostBossCinematic = preload("res://scripts/post_boss_cinematic.gd")
const RewindSequence = preload("res://scripts/rewind_sequence.gd")
const DialogueTypewriter = preload("res://scripts/dialogue_typewriter.gd")

const BOSS_BGM_STREAM: AudioStream = preload("res://assets/audio/warden_boss_theme.ogg")
const RAIN_STREAM: AudioStream = preload("res://assets/audio/rain_loop.ogg")
const SLASH_STREAM: AudioStream = preload("res://assets/audio/slash.ogg")
const PARRY_STREAM: AudioStream = preload("res://assets/audio/parry.ogg")
const HIT_STREAM: AudioStream = preload("res://assets/audio/enemy_hit.ogg")

const BATTLE_SCENE := "res://scenes/boss_battle.tscn"
const TITLE_SCENE := "res://scenes/title_screen.tscn"
const TUTORIAL_SCENE := "res://scenes/tutorial.tscn"
const ARENA_WIDTH := 1856.0
const FLOOR_Y := 650.0
const FINISHER_SLOW_DURATION := 1.0
const FINISHER_TIME_SCALE := 0.5
const STORY_GROUND_Y := FLOOR_Y - 1.0
const PLAYER_START := Vector2(330.0, STORY_GROUND_Y)
const BOSS_START := Vector2(1500.0, STORY_GROUND_Y)
const INTRO_LOCK_DURATION := 0.72
const CINEMATIC_ASPECT := 2.35

enum BattleState { INTRO, PLAYING, DEAD, POST_BOSS, COMPLETE }

var state: BattleState = BattleState.PLAYING
var player: CharacterBody2D
var boss: CharacterBody2D
var enemies: Array[Node] = []
var projectiles: Array[Node] = []
var platforms: Array[Rect2] = []
var camera: Camera2D
var world_art: Node2D
var arena_art: Node2D
var elapsed := 0.0
var death_clock := 0.0
var intro_lock_clock := INTRO_LOCK_DURATION
var boss_hit_during_player_attack := false
var boss_damage_events := 0
var reflected_damage_events := 0
var melee_parry_events := 0
var parry_sparks: Array[Dictionary] = []
var rain_drops: Array[Dictionary] = []
var rain_splashes: Array[Dictionary] = []
var rain_rng := RandomNumberGenerator.new()
var fx_rng := RandomNumberGenerator.new()
var shake_strength := 0.0
var lightning_flash := 0.0
var thunder_timer := 9.0
var last_sfx_stream: AudioStream
var last_sfx_volume_db := 0.0
var last_sfx_pitch_scale := 1.0
var sfx_voices: Array[AudioStreamPlayer] = []
var bgm_player: AudioStreamPlayer
var rain_audio_player: AudioStreamPlayer
var tuning_panel: CanvasLayer
var touch_input: CanvasLayer
var hitbox_debug_overlay: Node2D
var blood_effects: Node2D
var projectile_explosions: Node2D
var crt_filter: CanvasLayer
var pause_menu: CanvasLayer
var tv_transition: CanvasLayer
var post_boss_cinematic: CanvasLayer
var hud_layer: CanvasLayer
var active_story_bubble: Label
var active_story_hint: Label
var active_story_target: Node
var story_typewriter: Node
var boss_intro_active := false
var boss_intro_finished := false
var story_advance_requested := false
var skip_story_intro := false
var intro_transition_scale := 1.0
var post_boss_transition_scale := 1.0
var post_boss_presentation_scale := 1.0
var post_boss_sequence_finished := false
var rewind_sequence: CanvasLayer
var auto_death_title_scene_change := true
var death_title_requested := false
var parry_slow_remaining := 0.0
var parry_zoom_remaining := 0.0
var finisher_slow_remaining := 0.0

var boss_fill: ColorRect
var boss_health_label: Label
var attack_label: Label
var status_label: Label
var timer_label: Label
var focus_fill: ColorRect
var focus_text: Label
var focus_wash: ColorRect
var lightning_overlay: ColorRect
var end_overlay: Control
var end_title_label: Label
var end_detail_label: Label

func _ready() -> void:
	_ensure_input_actions()
	_build_background()
	_build_world()
	_build_hud()
	_build_end_overlay()
	_init_rain()
	camera = Camera2D.new()
	camera.name = "BossArenaCamera"
	camera.position = Vector2(ARENA_WIDTH * 0.5, 360.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_right = int(ARENA_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 720
	add_child(camera)
	camera.make_current()
	_apply_camera_distance()
	world_art.setup(camera)
	_setup_audio()
	_setup_rewind()
	touch_input = TouchInput.new()
	add_child(touch_input)
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
	pause_menu.restart_button.text = "重新挑战首领"
	pause_menu.pause_requested.connect(_open_pause_menu)
	pause_menu.restart_requested.connect(_restart_battle)
	pause_menu.tutorial_requested.connect(func(): get_tree().change_scene_to_file(TUTORIAL_SCENE))
	pause_menu.title_requested.connect(func(): get_tree().change_scene_to_file(TITLE_SCENE))
	pause_menu.pause_changed.connect(_on_pause_changed)
	post_boss_cinematic = PostBossCinematic.new()
	add_child(post_boss_cinematic)
	story_typewriter = DialogueTypewriter.new()
	story_typewriter.name = "BossDialogueTypewriter"
	add_child(story_typewriter)
	post_boss_cinematic.exit_requested.connect(func(): get_tree().change_scene_to_file(TITLE_SCENE))
	tv_transition = TVTransition.new()
	add_child(tv_transition)
	_start_battle(not skip_story_intro)
	get_viewport().size_changed.connect(_on_viewport_changed)
	_on_viewport_changed()

func _process(delta: float) -> void:
	_tick_parry_feedback(delta)
	_tick_finisher_slowdown(delta)
	_apply_camera_distance()
	if state == BattleState.DEAD:
		_handle_death_choice_input()
		_update_screen_effects(delta)
		_update_hud()
		queue_redraw()
		return
	if is_instance_valid(player):
		player.set_external_time_scale(_current_parry_time_scale())
	var time_scale := _current_gameplay_time_scale()
	if is_instance_valid(boss):
		boss.simulation_scale = time_scale
	if is_instance_valid(blood_effects):
		blood_effects.simulation_scale = time_scale
	if is_instance_valid(projectile_explosions):
		projectile_explosions.simulation_scale = time_scale
	for shot in projectiles:
		if is_instance_valid(shot):
			shot.simulation_scale = time_scale
	_update_rain(delta, time_scale)
	_update_parry_sparks(delta * time_scale)
	_update_screen_effects(delta)
	_update_audio_tuning()
	if state == BattleState.PLAYING and Input.is_action_just_pressed("restart"):
		_restart_battle()
	if state == BattleState.PLAYING:
		elapsed += delta
		intro_lock_clock -= delta
		if is_instance_valid(player) and intro_lock_clock <= 0.0 and not player.control_enabled:
			player.set_control_enabled(true)
			status_label.text = "交战开始"
			_status_flash(Color("ffb04f"))
		if is_instance_valid(player) and player.attack_time <= 0.0:
			boss_hit_during_player_attack = false
	elif state == BattleState.INTRO:
		if is_instance_valid(player):
			player.is_focusing = false
	if state == BattleState.PLAYING:
		_capture_rewind_frame(delta)
	_update_hud()
	queue_redraw()

func _draw() -> void:
	for drop in rain_drops:
		var position: Vector2 = drop["position"]
		var velocity: Vector2 = drop["velocity"]
		var depth: float = drop["depth"]
		var tail := position - velocity.normalized() * float(drop["length"])
		draw_line(position, tail, Color(0.48, 0.82, 0.90, lerpf(0.12, 0.46, depth)), lerpf(0.65, 1.7, depth), true)
	for splash in rain_splashes:
		var life: float = splash["life"]
		var spread := (0.24 - life) * 34.0
		var at: Vector2 = splash["position"]
		draw_line(at - Vector2(spread, 0.0), at + Vector2(spread, 0.0), Color(0.58, 0.86, 0.92, life * 2.0), 1.1)
	for spark in parry_sparks:
		var life_ratio := clampf(float(spark["life"]) / float(spark["max_life"]), 0.0, 1.0)
		var at: Vector2 = spark["position"]
		var velocity: Vector2 = spark["velocity"]
		var trail := velocity.normalized() * float(spark["length"]) * life_ratio
		var color := Color(1.0, lerpf(0.10, 0.92, float(spark["heat"])), lerpf(0.03, 0.48, float(spark["heat"])), life_ratio)
		draw_line(at, at - trail, color, 1.2, true)

func _build_background() -> void:
	world_art = WorldArt.new()
	world_art.name = "OriginalFixedSkyline"
	add_child(world_art)

func _build_world() -> void:
	_add_platform(Rect2(0.0, FLOOR_Y, ARENA_WIDTH, 90.0))
	_add_platform(Rect2(420.0, 505.0, 240.0, 30.0))
	_add_platform(Rect2(1196.0, 505.0, 240.0, 30.0))
	_add_wall(Rect2(-30.0, 0.0, 30.0, 720.0))
	_add_wall(Rect2(ARENA_WIDTH, 0.0, 30.0, 720.0))
	arena_art = BossArenaArt.new()
	arena_art.name = "BossRooftopArena"
	arena_art.setup(platforms, ARENA_WIDTH)
	add_child(arena_art)

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

func _start_battle(play_story_intro: bool = false) -> void:
	_stop_boss_music()
	if is_instance_valid(rewind_sequence):
		rewind_sequence.reset_history()
	state = BattleState.INTRO if play_story_intro else BattleState.PLAYING
	elapsed = 0.0
	death_clock = 0.0
	intro_lock_clock = INTRO_LOCK_DURATION
	boss_intro_active = false
	boss_intro_finished = not play_story_intro
	story_advance_requested = false
	post_boss_sequence_finished = false
	if is_instance_valid(post_boss_cinematic):
		post_boss_cinematic.visible = false
		post_boss_cinematic.playing = false
		post_boss_cinematic.complete = false
	boss_hit_during_player_attack = false
	boss_damage_events = 0
	reflected_damage_events = 0
	melee_parry_events = 0
	_reset_parry_feedback()
	_reset_finisher_slowdown()
	end_overlay.visible = false
	status_label.text = "处决协议 // 守门人"
	attack_label.text = "看清前兆。打破套路。"
	_spawn_player()
	_spawn_boss()
	if play_story_intro:
		player.set_forced_idle_visual(true)
		player.set_physics_process(false)
		boss.set_physics_process(false)
		_set_combat_hud_visible(false)
		tv_transition.set_closed(true)
		call_deferred("_run_boss_intro")
	else:
		tv_transition.set_closed(false)
		_begin_boss_combat()
	_capture_rewind_frame(0.0)

func _spawn_player() -> void:
	player = PlayerActor.new()
	player.position = PLAYER_START
	player.set_drop_through_floor_y(FLOOR_Y - 8.0)
	player.z_index = 5
	player.set_control_enabled(false)
	player.died.connect(_on_player_died)
	player.slash.connect(_on_player_slash)
	add_child(player)

func _spawn_boss() -> void:
	boss = BossActor.new()
	boss.position = BOSS_START
	boss.player = player
	boss.arena_left = 150.0
	boss.arena_right = ARENA_WIDTH - 150.0
	boss.z_index = 4
	boss.fire_projectile.connect(_on_boss_fire)
	boss.melee_strike.connect(_on_boss_melee_strike)
	boss.health_changed.connect(_on_boss_health_changed)
	boss.damaged.connect(_on_boss_damaged)
	boss.defeated.connect(_on_boss_defeated)
	boss.attack_announced.connect(_on_boss_attack_announced)
	add_child(boss)
	enemies = [boss]
	_on_boss_health_changed(boss.health, boss.max_health)

func _run_boss_intro() -> void:
	if state != BattleState.INTRO:
		return
	await tv_transition.open_to_aspect(CINEMATIC_ASPECT, 0.56 * intro_transition_scale)
	if state != BattleState.INTRO:
		return
	await _play_boss_story_scene("boss_arrival", BattleState.INTRO, intro_transition_scale)
	_clear_boss_story_bubble()
	boss_intro_active = false
	await tv_transition.open_screen(0.46 * intro_transition_scale)
	if state == BattleState.INTRO:
		_begin_boss_combat()

func _play_boss_story_scene(scene_id: String, expected_state: BattleState, duration_scale: float = 1.0) -> void:
	boss_intro_active = true
	for entry in StoryStore.get_scene(scene_id):
		var target := _resolve_boss_story_target(String(entry.get("target", "")))
		if not is_instance_valid(target):
			continue
		_show_boss_story_bubble(target, entry)
		await story_typewriter.play_line(
			active_story_bubble,
			active_story_hint,
			active_story_bubble.text,
			32.0,
			duration_scale <= 0.0
		)
		if state != expected_state:
			break
		_clear_boss_story_bubble()
	boss_intro_active = false

func _resolve_boss_story_target(target_id: String) -> Node:
	match target_id:
		"boss": return boss
		"player": return player
	return null

func _show_boss_story_bubble(target: Node, entry: Dictionary) -> void:
	_clear_boss_story_bubble()
	active_story_target = target
	active_story_bubble = Label.new()
	active_story_bubble.name = "BossIntroDialogue"
	var speaker := String(entry.get("speaker", ""))
	var line := String(entry.get("text", ""))
	active_story_bubble.text = (speaker + "\n" if not speaker.is_empty() else "") + line
	active_story_bubble.position = Vector2(-280.0, -342.0)
	active_story_bubble.size = Vector2(560.0, 140.0)
	active_story_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active_story_bubble.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	active_story_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	active_story_bubble.add_theme_font_size_override("font_size", 20)
	active_story_bubble.add_theme_color_override("font_color", Color("f4f7f5"))
	active_story_bubble.add_theme_constant_override("outline_size", 7)
	active_story_bubble.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.98))
	active_story_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(active_story_bubble)
	active_story_hint = Label.new()
	active_story_hint.name = "BossDialogueAdvanceHint"
	active_story_hint.text = "J  //  继续"
	active_story_hint.position = Vector2(-100.0, -197.0)
	active_story_hint.size = Vector2(200.0, 26.0)
	active_story_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active_story_hint.add_theme_font_size_override("font_size", 13)
	active_story_hint.add_theme_color_override("font_color", Color("80d6d0"))
	active_story_hint.add_theme_constant_override("outline_size", 6)
	active_story_hint.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.98))
	active_story_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	active_story_hint.visible = false
	target.add_child(active_story_hint)

func _clear_boss_story_bubble() -> void:
	if is_instance_valid(story_typewriter):
		story_typewriter.reset()
	if is_instance_valid(active_story_bubble):
		active_story_bubble.queue_free()
	if is_instance_valid(active_story_hint):
		active_story_hint.queue_free()
	active_story_bubble = null
	active_story_hint = null
	active_story_target = null

func _begin_boss_combat() -> void:
	boss_intro_active = false
	boss_intro_finished = true
	state = BattleState.PLAYING
	intro_lock_clock = 0.0
	_clear_boss_story_bubble()
	_set_combat_hud_visible(true)
	if is_instance_valid(player):
		player.set_forced_idle_visual(false)
		player.set_physics_process(true)
		player.set_control_enabled(true)
	if is_instance_valid(boss):
		boss.set_physics_process(true)
	_start_boss_music()
	status_label.text = "交战开始"
	attack_label.text = "看清前兆。打破套路。"
	_status_flash(Color("ffb04f"))
	_capture_rewind_frame(0.0)

func _set_combat_hud_visible(is_visible: bool) -> void:
	if is_instance_valid(hud_layer):
		hud_layer.visible = is_visible
	if is_instance_valid(touch_input):
		touch_input.visible = is_visible

func _on_boss_fire(origin: Vector2, direction: Vector2, shooter: Node) -> void:
	if state != BattleState.PLAYING:
		return
	var shot := ProjectileActor.new()
	shot.position = origin
	shot.retain_for_rewind = true
	shot.setup(direction, player, enemies, shooter, projectiles)
	shot.velocity = direction.normalized() * TuningStore.get_value("boss_projectile_speed")
	shot.hit_player.connect(_on_projectile_hit_player)
	shot.hit_enemy.connect(_on_projectile_hit_enemy)
	shot.intercepted_projectile.connect(_on_projectile_intercepted)
	shot.expired.connect(_on_projectile_expired.bind(shot))
	shot.z_index = 6
	add_child(shot)
	projectiles.append(shot)

func _on_projectile_hit_player() -> void:
	if state == BattleState.PLAYING and is_instance_valid(player):
		player.die()

func _on_projectile_hit_enemy(enemy: Node) -> void:
	if enemy == boss and is_instance_valid(boss) and boss.alive:
		var reflected_damage := maxi(1, int(round(TuningStore.get_value("boss_reflected_damage"))))
		if boss.take_damage(reflected_damage, "REFLECTED ROUND"):
			reflected_damage_events += 1

func _on_projectile_intercepted(_projectile: Node, position: Vector2, intercepted_velocity: Vector2) -> void:
	if is_instance_valid(projectile_explosions):
		projectile_explosions.spawn_burst(position, intercepted_velocity)
	_play_sfx(PARRY_STREAM, -2.0, 0.012)
	_add_screen_shake(2.8)

func _on_projectile_expired(shot: Node) -> void:
	projectiles.erase(shot)

func _on_player_slash(origin: Vector2, facing: float, direction: Vector2 = Vector2.ZERO, primary: bool = true) -> void:
	if state != BattleState.PLAYING:
		return
	var slash_direction := direction.normalized() if direction.length_squared() > 0.01 else Vector2(facing, 0.0)
	if primary:
		_play_sfx(SLASH_STREAM, -2.5, 0.018)
		_add_screen_shake(2.0)
	if is_instance_valid(boss) and boss.alive and not boss_hit_during_player_attack and _attack_hitbox_overlaps_rect(boss.get_hurtbox_rect_world(), origin, slash_direction):
		if boss.can_parry_melee() and boss.parry_melee():
			boss_hit_during_player_attack = true
			melee_parry_events += 1
			if boss.alive:
				_trigger_parry_feedback()
			_spawn_parry_sparks(boss.get_hurtbox_center_world(), (boss.global_position - player.global_position).normalized() * 700.0)
			_play_sfx(PARRY_STREAM, -0.2, 0.01)
			_add_screen_shake(8.0)
			I18n.set_formatted(status_label, "破招反击  //  %d 点伤害", maxi(1, int(round(TuningStore.get_value("boss_melee_parry_damage")))))
			_status_flash(Color("fff0bf"))
		elif boss.take_damage(maxi(1, int(round(TuningStore.get_value("boss_katana_damage")))), "KATANA"):
			boss_hit_during_player_attack = true
	var reflected_any := false
	for shot in projectiles:
		if not is_instance_valid(shot) or not shot.alive or shot.reflected:
			continue
		if _attack_hitbox_overlaps_circle(shot.global_position, shot.get_hit_radius(), origin, slash_direction):
			var impact: Vector2 = shot.global_position
			var incoming: Vector2 = shot.velocity
			shot.reflect(facing)
			_spawn_parry_sparks(impact, incoming)
			reflected_any = true
	if reflected_any:
		_trigger_parry_feedback()
		_play_sfx(PARRY_STREAM, -0.5, 0.012)
		_add_screen_shake(6.2)

func _on_boss_melee_strike(center: Vector2, radius: float) -> void:
	if state != BattleState.PLAYING or not is_instance_valid(player) or not player.alive:
		return
	if player.is_attack_hitbox_active() and is_instance_valid(boss) and boss.can_parry_melee():
		var attack_origin := player.global_position + Vector2(0.0, -34.0)
		if _attack_hitbox_overlaps_rect(boss.get_hurtbox_rect_world(), attack_origin, player.attack_direction):
			if boss.parry_melee():
				boss_hit_during_player_attack = true
				melee_parry_events += 1
				if boss.alive:
					_trigger_parry_feedback()
				_spawn_parry_sparks(center, boss.global_position - player.global_position)
				_play_sfx(PARRY_STREAM, -0.2, 0.01)
				_add_screen_shake(8.0)
				return
	if player.hurtbox_overlaps_circle(center, radius):
		player.die()

func _on_boss_health_changed(current: int, maximum: int) -> void:
	if not is_instance_valid(boss_fill):
		return
	boss_fill.size.x = 496.0 * float(current) / float(maxi(1, maximum))
	I18n.set_formatted(boss_health_label, "守门人  //  %02d / %02d", [current, maximum])

func _on_boss_damaged(amount: int, source: String, at: Vector2) -> void:
	boss_damage_events += 1
	if is_instance_valid(blood_effects):
		blood_effects.spawn_spray(at, Vector2(-boss.facing, -0.18).normalized())
	_play_sfx(HIT_STREAM, -1.0, 0.018)
	_add_screen_shake(5.0 + amount * 1.4)
	if source == "REFLECTED ROUND":
		I18n.set_formatted(status_label, "子弹奉还  //  %d 点伤害", amount)
	elif source == "KATANA":
		I18n.set_formatted(status_label, "斩开护甲  //  %d 点伤害", amount)
	_status_flash(Color("ffb06a"))

func _on_boss_attack_announced(label_text: String, color: Color) -> void:
	attack_label.text = label_text
	attack_label.add_theme_color_override("font_color", color)
	attack_label.modulate.a = 0.25
	create_tween().tween_property(attack_label, "modulate:a", 1.0, 0.14)

func _on_boss_defeated(_at: Vector2) -> void:
	if state != BattleState.PLAYING:
		return
	_reset_parry_feedback()
	_apply_camera_distance()
	state = BattleState.POST_BOSS
	_start_finisher_slowdown()
	player.set_control_enabled(false)
	player.set_forced_idle_visual(true)
	player.set_physics_process(false)
	_set_combat_hud_visible(false)
	for shot in projectiles.duplicate():
		if is_instance_valid(shot):
			shot._expire()
	projectiles.clear()
	_stop_boss_music()
	_add_screen_shake(10.0)
	end_overlay.visible = false
	call_deferred("_run_post_boss_sequence")

func _run_post_boss_sequence() -> void:
	if state != BattleState.POST_BOSS:
		return
	await get_tree().create_timer(maxf(FINISHER_SLOW_DURATION, 1.05 * post_boss_transition_scale)).timeout
	if state != BattleState.POST_BOSS:
		return
	if is_instance_valid(boss):
		boss.velocity = Vector2.ZERO
		boss.set_physics_process(false)
	await tv_transition.open_to_aspect(CINEMATIC_ASPECT, 0.48 * post_boss_transition_scale)
	if state != BattleState.POST_BOSS:
		return
	await _play_boss_story_scene("boss_passed", BattleState.POST_BOSS, post_boss_transition_scale)
	_clear_boss_story_bubble()
	boss_intro_active = false
	await tv_transition.close_screen(0.42 * post_boss_transition_scale)
	if state != BattleState.POST_BOSS:
		return
	post_boss_cinematic.presentation_scale = post_boss_presentation_scale
	post_boss_cinematic.visible = true
	await tv_transition.open_screen(0.50 * post_boss_transition_scale)
	if state != BattleState.POST_BOSS:
		return
	await post_boss_cinematic.play_sequence()
	if state == BattleState.POST_BOSS:
		state = BattleState.COMPLETE
		post_boss_sequence_finished = true

func _on_player_died() -> void:
	if state != BattleState.PLAYING:
		return
	_reset_parry_feedback()
	_apply_camera_distance()
	state = BattleState.DEAD
	death_clock = 0.0
	_play_sfx(HIT_STREAM, -1.0, 0.018)
	_add_screen_shake(10.0)
	status_label.text = "处决失败  //  等待选择"
	status_label.add_theme_color_override("font_color", Color("ff6357"))
	if not is_instance_valid(rewind_sequence) or not rewind_sequence.arm_rewind(player, enemies, projectiles, camera, bgm_player, rain_audio_player):
		call_deferred("_restart_battle")

func _handle_death_choice_input() -> void:
	if not is_instance_valid(rewind_sequence):
		return
	if Input.is_action_just_pressed("pause_game"):
		rewind_sequence.cancel(false)
		get_tree().paused = false
		death_title_requested = true
		if auto_death_title_scene_change:
			get_tree().change_scene_to_file(TITLE_SCENE)
	elif Input.is_action_just_pressed("restart") and rewind_sequence.is_waiting_for_input():
		if rewind_sequence.start_rewind():
			status_label.text = "处决失败  //  倒放中"

func _restart_battle(preserve_rewind_splice: bool = false) -> void:
	if is_instance_valid(rewind_sequence):
		if not preserve_rewind_splice:
			rewind_sequence.cancel(true)
		rewind_sequence.queue_recorded_nodes_for_cleanup()
		rewind_sequence.reset_history()
	death_title_requested = false
	_clear_boss_story_bubble()
	boss_intro_active = false
	for shot in projectiles:
		if is_instance_valid(shot):
			shot.queue_free()
	projectiles.clear()
	enemies.clear()
	if is_instance_valid(player):
		player.queue_free()
	if is_instance_valid(boss):
		boss.queue_free()
	parry_sparks.clear()
	if is_instance_valid(blood_effects):
		blood_effects.clear_particles()
	if is_instance_valid(projectile_explosions):
		projectile_explosions.clear_effects()
	_start_battle(false)

func _attack_hitbox_overlaps_rect(target_rect: Rect2, origin: Vector2, direction: Vector2) -> bool:
	var forward := direction.normalized()
	var lateral := Vector2(-forward.y, forward.x)
	var hitbox_back := TuningStore.get_value("attack_hitbox_back")
	var hitbox_forward := TuningStore.get_value("attack_hitbox_forward")
	var center := origin + forward * ((hitbox_forward - hitbox_back) * 0.5)
	var attack_half := Vector2((hitbox_forward + hitbox_back) * 0.5, TuningStore.get_value("attack_hitbox_height") * 0.5)
	var target_center := target_rect.get_center()
	var target_half := target_rect.size * 0.5
	var delta := target_center - center
	for axis in [forward, lateral, Vector2.RIGHT, Vector2.DOWN]:
		var attack_radius := attack_half.x * absf(axis.dot(forward)) + attack_half.y * absf(axis.dot(lateral))
		var target_radius := target_half.x * absf(axis.x) + target_half.y * absf(axis.y)
		if absf(delta.dot(axis)) > attack_radius + target_radius:
			return false
	return true

func _attack_hitbox_overlaps_circle(point: Vector2, radius: float, origin: Vector2, direction: Vector2) -> bool:
	var forward := direction.normalized()
	var lateral := Vector2(-forward.y, forward.x)
	var offset := point - origin
	var local := Vector2(offset.dot(forward), offset.dot(lateral))
	var closest := Vector2(
		clampf(local.x, -TuningStore.get_value("attack_hitbox_back"), TuningStore.get_value("attack_hitbox_forward")),
		clampf(local.y, -TuningStore.get_value("attack_hitbox_height") * 0.5, TuningStore.get_value("attack_hitbox_height") * 0.5)
	)
	return local.distance_squared_to(closest) <= radius * radius

func _should_draw_hitbox_preview() -> bool:
	return is_instance_valid(player) and is_instance_valid(tuning_panel) and is_instance_valid(tuning_panel.panel) and tuning_panel.panel.visible

func _hitbox_preview_direction() -> Vector2:
	if player.attack_time > 0.0 and player.attack_direction.length_squared() > 0.01:
		return player.attack_direction.normalized()
	var held := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("aim_up", "aim_down"))
	if held.length_squared() > 0.01:
		return held.normalized()
	return Vector2(player.facing, 0.0)

func _attack_hitbox_rect() -> Rect2:
	var back := TuningStore.get_value("attack_hitbox_back")
	var forward := TuningStore.get_value("attack_hitbox_forward")
	var half_height := TuningStore.get_value("attack_hitbox_height") * 0.5
	return Rect2(-back, -half_height, back + forward, half_height * 2.0)

func _apply_camera_distance() -> void:
	if not is_instance_valid(camera):
		return
	var distance := clampf(TuningStore.get_value("camera_distance"), 0.75, 1.60)
	var zoom_value := (1.0 / distance) * (1.0 + TuningStore.get_value("parry_zoom_amount") * _parry_zoom_weight())
	camera.zoom = Vector2(zoom_value, zoom_value)
	camera.position = Vector2(ARENA_WIDTH * 0.5, 360.0)

func get_camera_visible_world_size() -> Vector2:
	var size := get_viewport_rect().size
	if not is_instance_valid(camera):
		return size
	return Vector2(size.x / maxf(camera.zoom.x, 0.001), size.y / maxf(camera.zoom.y, 0.001))

func _build_hud() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	hud_layer = ui
	lightning_overlay = ColorRect.new()
	lightning_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lightning_overlay.color = Color(0.80, 0.88, 1.0, 0.0)
	lightning_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(lightning_overlay)
	focus_wash = ColorRect.new()
	focus_wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_wash.color = Color(0.12, 0.82, 1.0, 0.0)
	focus_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(focus_wash)

	var eyebrow := _hud_label("最终目标  //  零号屋顶", 13, Color("ff8278"))
	eyebrow.position = Vector2(38.0, 32.0)
	eyebrow.size = Vector2(390.0, 28.0)
	ui.add_child(eyebrow)
	status_label = _hud_label("处决协议 // 守门人", 20, Color("fff0e8"))
	status_label.position = Vector2(38.0, 60.0)
	status_label.size = Vector2(470.0, 36.0)
	ui.add_child(status_label)
	timer_label = _hud_label("00.00", 24, Color("edfaff"))
	timer_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	timer_label.position = Vector2(-188.0, 34.0)
	timer_label.size = Vector2(150.0, 32.0)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(timer_label)

	var boss_bar := ColorRect.new()
	boss_bar.name = "BossHealthBack"
	boss_bar.position = Vector2(392.0, 104.0)
	boss_bar.size = Vector2(504.0, 16.0)
	boss_bar.color = Color(0.035, 0.025, 0.035, 0.92)
	ui.add_child(boss_bar)
	boss_fill = ColorRect.new()
	boss_fill.name = "BossHealthFill"
	boss_fill.position = Vector2(4.0, 4.0)
	boss_fill.size = Vector2(496.0, 8.0)
	boss_fill.color = Color("e52f3f")
	boss_bar.add_child(boss_fill)
	boss_health_label = _hud_label("守门人  //  25 / 25", 14, Color("ffb7aa"))
	boss_health_label.position = Vector2(392.0, 76.0)
	boss_health_label.size = Vector2(504.0, 26.0)
	boss_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(boss_health_label)
	attack_label = _hud_label("看清前兆。打破套路。", 16, Color("ffb04f"))
	attack_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	attack_label.position = Vector2(-330.0, 136.0)
	attack_label.size = Vector2(660.0, 32.0)
	attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(attack_label)

	var focus_back := ColorRect.new()
	focus_back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	focus_back.position = Vector2(38.0, -61.0)
	focus_back.size = Vector2(234.0, 10.0)
	focus_back.color = Color("172c35")
	ui.add_child(focus_back)
	focus_fill = ColorRect.new()
	focus_fill.position = Vector2(2.0, 2.0)
	focus_fill.size = Vector2(230.0, 6.0)
	focus_fill.color = Color("33e6ff")
	focus_back.add_child(focus_fill)
	focus_text = _hud_label("专注  100", 12, Color("8fb8c0"))
	focus_text.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	focus_text.position = Vector2(38.0, -88.0)
	focus_text.size = Vector2(230.0, 24.0)
	ui.add_child(focus_text)
	var hint := _hud_label("斩击首领  •  格挡近战前兆  •  弹反子弹反击", 12, Color("8b9ba0"))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-720.0, -47.0)
	hint.size = Vector2(680.0, 28.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(hint)

func _build_end_overlay() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 40
	add_child(ui)
	end_overlay = Control.new()
	end_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_overlay.visible = false
	ui.add_child(end_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.005, 0.012, 0.88)
	end_overlay.add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-270.0, -180.0)
	box.size = Vector2(540.0, 360.0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	end_overlay.add_child(box)
	var eyebrow := _hud_label("处决完成", 14, Color("ff8d74"))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(eyebrow)
	end_title_label = _hud_label("守门人已击败", 42, Color("fff1e9"))
	end_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(end_title_label)
	end_detail_label = _hud_label("00.00 秒", 18, Color("ffb04f"))
	end_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(end_detail_label)
	var replay := _action_button("再次挑战守门人")
	replay.name = "BossRematchButton"
	replay.pressed.connect(_restart_battle)
	box.add_child(replay)
	var title_button := _action_button("返回标题画面")
	title_button.name = "BossTitleButton"
	title_button.pressed.connect(func(): get_tree().change_scene_to_file(TITLE_SCENE))
	box.add_child(title_button)

func _update_hud() -> void:
	if not is_instance_valid(player):
		return
	timer_label.text = "%05.2f" % elapsed
	focus_fill.size.x = 230.0 * player.focus_energy / 100.0
	I18n.set_formatted(focus_text, "专注  %03d", int(player.focus_energy))
	focus_wash.color.a = 0.10 if player.is_focusing else 0.0

func _setup_audio() -> void:
	fx_rng.seed = 7713
	bgm_player = AudioStreamPlayer.new()
	var bgm := BOSS_BGM_STREAM.duplicate()
	if bgm is AudioStreamOggVorbis:
		bgm.loop = true
	bgm_player.stream = bgm
	bgm_player.volume_db = TuningStore.get_value("bgm_volume_db")
	add_child(bgm_player)
	rain_audio_player = AudioStreamPlayer.new()
	var rain := RAIN_STREAM.duplicate()
	if rain is AudioStreamOggVorbis:
		rain.loop = true
	rain_audio_player.stream = rain
	rain_audio_player.volume_db = TuningStore.get_value("rain_volume_db")
	add_child(rain_audio_player)
	rain_audio_player.play()

func _start_boss_music() -> void:
	if not is_instance_valid(bgm_player):
		return
	bgm_player.pitch_scale = 1.0
	bgm_player.stream_paused = false
	bgm_player.play(0.0)

func _stop_boss_music() -> void:
	if is_instance_valid(bgm_player):
		bgm_player.stop()

func _setup_rewind() -> void:
	rewind_sequence = RewindSequence.new()
	rewind_sequence.name = "DeathRewind"
	add_child(rewind_sequence)
	rewind_sequence.finished.connect(_on_rewind_finished)

func _capture_rewind_frame(delta: float) -> void:
	if is_instance_valid(rewind_sequence) and is_instance_valid(player):
		rewind_sequence.capture(delta, player, enemies, projectiles, camera)

func _on_rewind_finished() -> void:
	if state == BattleState.DEAD:
		_restart_battle(true)

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
		voice.pitch_scale = float(voice.get_meta("base_pitch", 1.0)) * focus_pitch

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
	voice.finished.connect(_on_sfx_finished.bind(voice))
	add_child(voice)
	sfx_voices.append(voice)
	voice.play()

func _on_sfx_finished(voice: AudioStreamPlayer) -> void:
	sfx_voices.erase(voice)
	if is_instance_valid(voice):
		voice.queue_free()

func _current_gameplay_time_scale() -> float:
	if finisher_slow_remaining > 0.0:
		return FINISHER_TIME_SCALE
	return player.simulation_scale if state == BattleState.PLAYING and is_instance_valid(player) else 1.0

func _current_parry_time_scale() -> float:
	return TuningStore.get_value("melee_parry_time_scale") if state == BattleState.PLAYING and parry_slow_remaining > 0.0 else 1.0

func _trigger_parry_feedback() -> void:
	parry_slow_remaining = maxf(0.0, TuningStore.get_value("melee_parry_slow_duration"))
	parry_zoom_remaining = maxf(0.0, TuningStore.get_value("parry_zoom_duration"))
	if is_instance_valid(player):
		player.set_external_time_scale(_current_parry_time_scale())
	var scale := _current_gameplay_time_scale()
	if is_instance_valid(boss):
		boss.simulation_scale = scale
	if is_instance_valid(blood_effects):
		blood_effects.simulation_scale = scale
	if is_instance_valid(projectile_explosions):
		projectile_explosions.simulation_scale = scale
	for shot in projectiles:
		if is_instance_valid(shot):
			shot.simulation_scale = scale
	_apply_camera_distance()

func _tick_parry_feedback(delta: float) -> void:
	if state != BattleState.PLAYING:
		return
	parry_slow_remaining = maxf(0.0, parry_slow_remaining - delta)
	parry_zoom_remaining = maxf(0.0, parry_zoom_remaining - delta)

func _reset_parry_feedback() -> void:
	parry_slow_remaining = 0.0
	parry_zoom_remaining = 0.0
	if is_instance_valid(player):
		player.set_external_time_scale(1.0)

func _start_finisher_slowdown() -> void:
	finisher_slow_remaining = FINISHER_SLOW_DURATION
	if is_instance_valid(player):
		player.set_external_time_scale(FINISHER_TIME_SCALE)
	if is_instance_valid(boss):
		boss.simulation_scale = FINISHER_TIME_SCALE
	if is_instance_valid(blood_effects):
		blood_effects.simulation_scale = FINISHER_TIME_SCALE
	if is_instance_valid(projectile_explosions):
		projectile_explosions.simulation_scale = FINISHER_TIME_SCALE
	if is_instance_valid(rain_audio_player):
		rain_audio_player.pitch_scale = FINISHER_TIME_SCALE
	for voice in sfx_voices:
		if is_instance_valid(voice):
			voice.pitch_scale = float(voice.get_meta("base_pitch", 1.0)) * FINISHER_TIME_SCALE

func _tick_finisher_slowdown(delta: float) -> void:
	if finisher_slow_remaining <= 0.0:
		return
	finisher_slow_remaining = maxf(0.0, finisher_slow_remaining - delta)
	if finisher_slow_remaining <= 0.0:
		_reset_finisher_slowdown()

func _reset_finisher_slowdown() -> void:
	finisher_slow_remaining = 0.0
	if is_instance_valid(player):
		player.set_external_time_scale(1.0)
	if is_instance_valid(boss):
		boss.simulation_scale = 1.0
	if is_instance_valid(blood_effects):
		blood_effects.simulation_scale = 1.0
	if is_instance_valid(projectile_explosions):
		projectile_explosions.simulation_scale = 1.0

func _parry_zoom_weight() -> float:
	var duration := maxf(0.0, TuningStore.get_value("parry_zoom_duration"))
	if duration <= 0.0 or parry_zoom_remaining <= 0.0:
		return 0.0
	return pow(clampf(parry_zoom_remaining / duration, 0.0, 1.0), 0.65)

func _update_screen_effects(delta: float) -> void:
	if is_instance_valid(camera):
		if shake_strength > 0.05:
			camera.offset = Vector2(fx_rng.randf_range(-1.0, 1.0), fx_rng.randf_range(-1.0, 1.0)) * shake_strength
			shake_strength = move_toward(shake_strength, 0.0, delta * 25.0)
		else:
			shake_strength = 0.0
			camera.offset = Vector2.ZERO
	thunder_timer -= delta
	if thunder_timer <= 0.0:
		lightning_flash = 1.0
		thunder_timer = fx_rng.randf_range(7.0, 16.0)
		_add_screen_shake(3.0)
	lightning_flash = move_toward(lightning_flash, 0.0, delta * 3.6)
	lightning_overlay.color.a = lightning_flash * 0.27
	var target_pitch := 0.72 if state == BattleState.PLAYING and is_instance_valid(player) and player.is_focusing else 1.0
	if state == BattleState.PLAYING and parry_slow_remaining > 0.0:
		target_pitch = minf(target_pitch, TuningStore.get_value("melee_parry_time_scale"))
	if finisher_slow_remaining > 0.0:
		target_pitch = minf(target_pitch, FINISHER_TIME_SCALE)
	if is_instance_valid(bgm_player):
		bgm_player.pitch_scale = move_toward(bgm_player.pitch_scale, target_pitch, delta * 3.0)
	if is_instance_valid(rain_audio_player):
		rain_audio_player.pitch_scale = move_toward(rain_audio_player.pitch_scale, target_pitch, delta * 3.0)

func _init_rain() -> void:
	rain_rng.seed = 424242
	for _index in range(260):
		var depth := rain_rng.randf_range(0.15, 1.0)
		rain_drops.append({
			"position": Vector2(rain_rng.randf_range(0.0, ARENA_WIDTH), rain_rng.randf_range(-80.0, FLOOR_Y)),
			"velocity": Vector2(lerpf(-95.0, -180.0, depth), lerpf(470.0, 1060.0, depth)),
			"length": lerpf(15.0, 42.0, depth),
			"depth": depth
		})

func _update_rain(delta: float, time_scale: float) -> void:
	var step := delta * time_scale
	for drop in rain_drops:
		var position: Vector2 = drop["position"]
		position += Vector2(drop["velocity"]) * step
		if position.y >= FLOOR_Y - 2.0:
			if float(drop["depth"]) > 0.70 and rain_splashes.size() < 32:
				rain_splashes.append({"position": Vector2(position.x, FLOOR_Y - 2.0), "life": 0.24})
			position.y = rain_rng.randf_range(-90.0, -10.0)
			position.x = fposmod(position.x + rain_rng.randf_range(100.0, 520.0), ARENA_WIDTH)
		elif position.x < 0.0:
			position.x += ARENA_WIDTH
		drop["position"] = position
	for index in range(rain_splashes.size() - 1, -1, -1):
		rain_splashes[index]["life"] = float(rain_splashes[index]["life"]) - step
		if float(rain_splashes[index]["life"]) <= 0.0:
			rain_splashes.remove_at(index)

func _spawn_parry_sparks(position: Vector2, incoming_velocity: Vector2) -> void:
	var base := -incoming_velocity.normalized()
	if base.length_squared() < 0.01:
		base = Vector2.UP
	for index in range(34):
		var angle := base.angle() + fx_rng.randf_range(-1.5, 1.5)
		var life := fx_rng.randf_range(0.16, 0.34)
		parry_sparks.append({
			"position": position + Vector2.from_angle(angle) * fx_rng.randf_range(0.0, 7.0),
			"velocity": Vector2.from_angle(angle) * fx_rng.randf_range(260.0, 840.0),
			"life": life,
			"max_life": life,
			"length": fx_rng.randf_range(10.0, 32.0),
			"heat": 1.0 if index < 5 else fx_rng.randf_range(0.0, 1.0)
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

func _open_pause_menu() -> void:
	if state != BattleState.PLAYING or not is_instance_valid(pause_menu):
		return
	if is_instance_valid(tuning_panel) and is_instance_valid(tuning_panel.panel):
		tuning_panel.panel.visible = false
	pause_menu.show_menu()

func _on_pause_changed(paused_value: bool) -> void:
	for audio in [bgm_player, rain_audio_player]:
		if is_instance_valid(audio):
			audio.stream_paused = paused_value
	for voice in sfx_voices:
		if is_instance_valid(voice):
			voice.stream_paused = paused_value

func _add_screen_shake(amount: float) -> void:
	shake_strength = maxf(shake_strength, amount)

func _status_flash(color: Color) -> void:
	status_label.add_theme_color_override("font_color", color)
	status_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.42)
	tween.tween_property(status_label, "modulate:a", 0.38, 0.28)

func _on_viewport_changed() -> void:
	if is_instance_valid(camera):
		camera.limit_left = 0
		camera.limit_right = int(ARENA_WIDTH)

func _hud_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color(0.005, 0.006, 0.012, 0.82))
	return label

func _action_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(330.0, 48.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 14)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("26151b")
	normal.border_color = Color("b83a48")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("e64551")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_color_override("font_hover_color", Color("16070a"))
	return button

func _unhandled_input(event: InputEvent) -> void:
	if state not in [BattleState.INTRO, BattleState.POST_BOSS] or not boss_intro_active:
		return
	if event is InputEventKey and event.echo:
		return
	if event is InputEventKey and event.pressed and (event.keycode == KEY_J or event.physical_keycode == KEY_J):
		story_advance_requested = true
		if is_instance_valid(story_typewriter):
			story_typewriter.request_advance()
		get_viewport().set_input_as_handled()

func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("aim_up", [KEY_W, KEY_UP])
	_add_key_action("aim_down", [KEY_S, KEY_DOWN])
	_add_key_action("jump", [KEY_K])
	_add_key_action("attack", [KEY_J, KEY_X])
	_add_key_action("focus", [KEY_L, KEY_SHIFT])
	_add_key_action("restart", [KEY_R])
	_add_key_action("pause_game", [KEY_ESCAPE])
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	if not InputMap.action_has_event("attack", mouse):
		InputMap.action_add_event("attack", mouse)

func _add_key_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
