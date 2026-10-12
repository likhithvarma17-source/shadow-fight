extends CharacterBody2D

signal died
signal slash(origin: Vector2, facing: float, direction: Vector2, primary: bool)

const TuningStore = preload("res://scripts/tuning_store.gd")
const AnimFrames = preload("res://scripts/animation_frames.gd")
const CharacterRim = preload("res://scripts/character_rim.gd")
const ATTACK_DURATION := 0.33
const STANDING_HIT_START_FRAME := 2
const STANDING_HIT_END_FRAME := 8
const DEATH_DURATION := 0.82
const SPRITE_SCALE := 0.88
const IDLE_SCALE_RATIO := 1.18
const IDLE_SPRITE_SCALE := SPRITE_SCALE / IDLE_SCALE_RATIO
const RUN_SPRITE_SCALE := IDLE_SPRITE_SCALE
const FOCUS_RING_ENABLED := false
const DROP_THROUGH_DURATION := 0.24
const DROP_THROUGH_SPEED := 90.0

var alive := true
var control_enabled := true
var facing := 1.0
var attack_time := 0.0
var attack_cooldown := 0.0
var attack_direction := Vector2.RIGHT
var dash_time := 0.0
var dash_distance_remaining := 0.0
var focus_energy := 100.0
var is_focusing := false
var animation_clock := 0.0
var death_time := 0.0
var hurtbox_collision: CollisionShape2D
var applied_hurtbox_size := Vector2.ZERO
var attack_damage_started := false
var jump_animation_clock := 0.0
var rim_light: Sprite2D
var simulation_scale := 1.0
var external_time_scale := 1.0
var force_idle_visual := false
var drop_through_floor_y := INF
var drop_through_remaining := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	hurtbox_collision = CollisionShape2D.new()
	hurtbox_collision.name = "PlayerHurtboxCollision"
	var shape := CapsuleShape2D.new()
	hurtbox_collision.shape = shape
	add_child(hurtbox_collision)
	rim_light = CharacterRim.new()
	add_child(rim_light)
	_apply_hurtbox_tuning()
	_sync_rim_light()
	queue_redraw()

func _process(_delta: float) -> void:
	_sync_rim_light()

func _physics_process(delta: float) -> void:
	_apply_hurtbox_tuning()
	if alive:
		is_focusing = control_enabled and Input.is_action_pressed("focus") and focus_energy > 0.5
		if is_focusing:
			focus_energy = maxf(0.0, focus_energy - TuningStore.get_value("focus_drain") * delta)
		else:
			focus_energy = minf(100.0, focus_energy + TuningStore.get_value("focus_regen") * delta)
	else:
		is_focusing = false
	_refresh_simulation_scale()
	var step := delta * simulation_scale
	_update_drop_through(step)
	animation_clock += step
	if not alive:
		death_time = minf(DEATH_DURATION, death_time + step)
		velocity.y += 1150.0 * step
		velocity.x = move_toward(velocity.x, 0.0, 560.0 * step)
		_move_and_slide_scaled()
		queue_redraw()
		return

	attack_time = maxf(0.0, attack_time - step)
	attack_cooldown = maxf(0.0, attack_cooldown - step)
	var move_direction := 0.0
	if control_enabled:
		move_direction = Input.get_axis("move_left", "move_right")
	if absf(move_direction) > 0.1:
		facing = signf(move_direction)
	if control_enabled and Input.is_action_just_pressed("attack"):
		begin_slash(_read_slash_direction(move_direction))

	if dash_time > 0.0 and dash_distance_remaining > 0.0:
		_advance_slash_dash(delta)
		queue_redraw()
		return
	_emit_active_attack_sweep()

	var run_speed: float = TuningStore.get_value("run_speed")
	var acceleration: float = TuningStore.get_value("acceleration")
	velocity.x = move_toward(velocity.x, move_direction * run_speed, acceleration * step)
	if not is_on_floor():
		var gravity_multiplier := TuningStore.get_value("jump_rise_gravity_multiplier") if velocity.y < 0.0 else TuningStore.get_value("jump_fall_gravity_multiplier")
		velocity.y += TuningStore.get_value("gravity") * gravity_multiplier * step
	if control_enabled and Input.is_action_just_pressed("jump") and is_on_floor():
		if Input.is_action_pressed("aim_down") and _can_drop_through_platform():
			_begin_drop_through()
		else:
			velocity.y = -get_jump_launch_speed()
			jump_animation_clock = 0.0
	_move_and_slide_scaled()
	if is_on_floor():
		jump_animation_clock = 0.0
	else:
		jump_animation_clock += step
	queue_redraw()

func _move_and_slide_scaled() -> void:
	if simulation_scale >= 0.999:
		move_and_slide()
		return
	velocity *= simulation_scale
	move_and_slide()
	velocity /= simulation_scale

func begin_slash(input_direction: Vector2) -> bool:
	if not alive or not control_enabled or attack_cooldown > 0.0:
		return false
	var has_movement_direction := input_direction.length_squared() >= 0.01
	var chosen := input_direction
	if not has_movement_direction:
		chosen = Vector2(facing, 0.0)
	attack_direction = chosen.normalized()
	if absf(attack_direction.x) > 0.05:
		facing = signf(attack_direction.x)
	attack_time = ATTACK_DURATION
	attack_cooldown = TuningStore.get_value("attack_cooldown")
	attack_damage_started = false
	dash_distance_remaining = TuningStore.get_value("slash_dash_distance") if has_movement_direction else 0.0
	var dash_speed: float = maxf(1.0, TuningStore.get_value("slash_dash_speed"))
	dash_time = dash_distance_remaining / dash_speed
	if has_movement_direction:
		slash.emit(global_position + Vector2(0, -34), facing, attack_direction, true)
		attack_damage_started = true
	return true

func _read_slash_direction(horizontal: float) -> Vector2:
	var vertical := Input.get_axis("aim_up", "aim_down") if control_enabled else 0.0
	return Vector2(horizontal, vertical).normalized()

func _advance_slash_dash(real_delta: float) -> void:
	# The opening sweep can trigger parry feedback; read the shared scale after the signal returns.
	slash.emit(global_position + Vector2(0, -34), facing, attack_direction, false)
	var delta := real_delta * simulation_scale
	var dash_speed: float = TuningStore.get_value("slash_dash_speed")
	var distance_step := minf(dash_distance_remaining, dash_speed * delta)
	velocity = attack_direction * (distance_step / maxf(delta, 0.0001))
	_move_and_slide_scaled()
	slash.emit(global_position + Vector2(0, -34), facing, attack_direction, false)
	dash_distance_remaining = maxf(0.0, dash_distance_remaining - distance_step)
	dash_time = maxf(0.0, dash_time - delta)
	if dash_distance_remaining <= 0.01 or dash_time <= 0.0:
		_finish_slash_dash()

func _emit_active_attack_sweep() -> void:
	if not is_attack_hitbox_active():
		return
	slash.emit(global_position + Vector2(0, -34), facing, attack_direction, not attack_damage_started)
	attack_damage_started = true

func get_attack_frame_index() -> int:
	if attack_time <= 0.0:
		return -1
	var phase := 1.0 - attack_time / ATTACK_DURATION
	return _phase_index(AnimFrames.HERO_ATTACK, phase)

func is_attack_hitbox_active() -> bool:
	if not alive or attack_time <= 0.0:
		return false
	if dash_time > 0.0 and dash_distance_remaining > 0.0:
		return true
	var frame_index := get_attack_frame_index()
	return frame_index >= STANDING_HIT_START_FRAME and frame_index <= STANDING_HIT_END_FRAME

func _finish_slash_dash() -> void:
	dash_time = 0.0
	dash_distance_remaining = 0.0
	var run_speed: float = TuningStore.get_value("run_speed")
	velocity.x = attack_direction.x * run_speed * 0.62
	if attack_direction.y < -0.05:
		velocity.y = attack_direction.y * run_speed * 0.55
	elif attack_direction.y > 0.05:
		velocity.y = minf(velocity.y, 80.0)

func die() -> void:
	if not alive:
		return
	alive = false
	force_idle_visual = false
	control_enabled = false
	is_focusing = false
	attack_time = 0.0
	attack_damage_started = false
	dash_time = 0.0
	dash_distance_remaining = 0.0
	_cancel_drop_through()
	death_time = 0.0
	velocity = Vector2(-facing * 120.0, -250.0)
	died.emit()
	queue_redraw()

func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	if not enabled:
		is_focusing = false
		dash_time = 0.0
		dash_distance_remaining = 0.0
		_cancel_drop_through()
	_refresh_simulation_scale()

func set_drop_through_floor_y(value: float) -> void:
	drop_through_floor_y = value

func _can_drop_through_platform() -> bool:
	return global_position.y < drop_through_floor_y

func _begin_drop_through() -> void:
	drop_through_remaining = DROP_THROUGH_DURATION
	set_collision_mask_value(1, false)
	velocity.y = maxf(velocity.y, DROP_THROUGH_SPEED)
	jump_animation_clock = 0.0

func _update_drop_through(step: float) -> void:
	if drop_through_remaining <= 0.0:
		return
	drop_through_remaining = maxf(0.0, drop_through_remaining - step)
	if drop_through_remaining <= 0.0:
		set_collision_mask_value(1, true)

func _cancel_drop_through() -> void:
	drop_through_remaining = 0.0
	set_collision_mask_value(1, true)

func set_external_time_scale(value: float) -> void:
	external_time_scale = clampf(value, 0.01, 1.0)
	_refresh_simulation_scale()

func _refresh_simulation_scale() -> void:
	var focus_scale := TuningStore.FOCUS_TIME_SCALE if is_focusing else 1.0
	simulation_scale = minf(focus_scale, external_time_scale)

func set_forced_idle_visual(enabled: bool) -> void:
	force_idle_visual = enabled
	if enabled:
		velocity.x = 0.0
	queue_redraw()

func _apply_hurtbox_tuning() -> void:
	if not is_instance_valid(hurtbox_collision):
		return
	var size := get_hurtbox_size()
	if size.is_equal_approx(applied_hurtbox_size):
		return
	applied_hurtbox_size = size
	var shape := hurtbox_collision.shape as CapsuleShape2D
	shape.radius = size.x * 0.5
	shape.height = maxf(size.y, size.x)
	hurtbox_collision.position = Vector2(0.0, -size.y * 0.5 + 1.0)

func get_hurtbox_size() -> Vector2:
	return Vector2(
		TuningStore.get_value("player_hurtbox_width"),
		TuningStore.get_value("player_hurtbox_height")
	)

func get_hurtbox_center_world() -> Vector2:
	var size := get_hurtbox_size()
	return global_position + Vector2(0.0, -size.y * 0.5 + 1.0)

func get_hurtbox_rect_world() -> Rect2:
	var size := get_hurtbox_size()
	return Rect2(get_hurtbox_center_world() - size * 0.5, size)

func hurtbox_overlaps_circle(point: Vector2, radius: float) -> bool:
	var size := get_hurtbox_size()
	var capsule_radius := size.x * 0.5
	var straight_half := maxf(0.0, (size.y - size.x) * 0.5)
	var center := get_hurtbox_center_world()
	var nearest_axis_point := Vector2(center.x, clampf(point.y, center.y - straight_half, center.y + straight_half))
	return point.distance_squared_to(nearest_axis_point) <= pow(capsule_radius + radius, 2.0)

func get_jump_launch_speed() -> float:
	return TuningStore.get_value("jump_force") * TuningStore.get_value("jump_launch_multiplier")

func _resolve_visual_state() -> Dictionary:
	var frames: Array = AnimFrames.HERO_IDLE
	var frame_index: int = 0
	var sprite_scale := IDLE_SPRITE_SCALE
	if not alive:
		frames = AnimFrames.HERO_DEATH
		frame_index = _phase_index(frames, death_time / DEATH_DURATION)
		sprite_scale = SPRITE_SCALE
	elif force_idle_visual:
		pass
	elif attack_time > 0.0:
		frames = AnimFrames.HERO_ATTACK
		frame_index = _phase_index(frames, 1.0 - attack_time / ATTACK_DURATION)
		sprite_scale = SPRITE_SCALE
	elif not is_on_floor():
		frames = AnimFrames.HERO_JUMP
		frame_index = mini(int(floor(jump_animation_clock * TuningStore.get_value("jump_animation_fps"))), frames.size() - 1)
		sprite_scale = SPRITE_SCALE
	elif absf(velocity.x) > 24.0:
		frames = AnimFrames.HERO_RUN
		frame_index = int(floor(animation_clock * 12.0)) % frames.size()
		sprite_scale = RUN_SPRITE_SCALE
	var texture := frames[frame_index] as Texture2D
	var horizontal_flip := -1.0 if facing > 0.0 else 1.0
	return {
		"texture": texture,
		"scale": sprite_scale,
		"horizontal_flip": horizontal_flip
	}

func _sync_rim_light() -> void:
	if not is_instance_valid(rim_light):
		return
	var visual := _resolve_visual_state()
	rim_light.set_visual(
		visual["texture"] as Texture2D,
		float(visual["scale"]),
		float(visual["horizontal_flip"]) < 0.0
	)

func _draw() -> void:
	var visual := _resolve_visual_state()
	var texture := visual["texture"] as Texture2D
	var sprite_scale := float(visual["scale"])
	var horizontal_flip := float(visual["horizontal_flip"])
	draw_set_transform(Vector2(0, 24), 0.0, Vector2(horizontal_flip * sprite_scale, sprite_scale))
	draw_texture(texture, Vector2(-96, -192))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _phase_index(frames: Array, phase: float) -> int:
	return clampi(int(floor(clampf(phase, 0.0, 0.9999) * frames.size())), 0, frames.size() - 1)
