extends CharacterBody2D

signal fire_projectile(origin: Vector2, direction: Vector2, shooter: Node)
signal killed(at: Vector2)

const AnimFrames = preload("res://scripts/animation_frames.gd")
const TuningStore = preload("res://scripts/tuning_store.gd")
const CharacterRim = preload("res://scripts/character_rim.gd")
const ACTION_DURATION := 0.48
const ACTION_EVENT_REMAINING := 0.19
const DEATH_DURATION := 0.86
const SPRITE_SCALE := 0.72

var kind := "blade"
var player: Node2D
var patrol_left := 0.0
var patrol_right := 0.0
var simulation_scale := 1.0
var alive := true
var facing := -1.0
var patrol_direction := -1.0
var action_clock := 0.5
var windup := 0.0
var action_committed := false
var animation_clock := 0.0
var death_time := 0.0
var alert := 0.0
var rim_light: Sprite2D
var hurtbox_collision: CollisionShape2D
var applied_hurtbox_size := Vector2.ZERO
var retain_for_rewind := false
var combat_active := true
var resting_visual := false
var resting_lean := 1.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	hurtbox_collision = CollisionShape2D.new()
	hurtbox_collision.name = "EnemyHurtboxCollision"
	var shape := CapsuleShape2D.new()
	hurtbox_collision.shape = shape
	add_child(hurtbox_collision)
	rim_light = CharacterRim.new()
	add_child(rim_light)
	_apply_hurtbox_tuning()
	_sync_rim_light()
	queue_redraw()

func _process(_delta: float) -> void:
	_apply_hurtbox_tuning()
	_sync_rim_light()

func _physics_process(delta: float) -> void:
	animation_clock += delta * simulation_scale
	if not alive:
		death_time += delta
		queue_redraw()
		if death_time >= DEATH_DURATION:
			if retain_for_rewind:
				visible = false
				set_physics_process(false)
			else:
				queue_free()
		return
	if not combat_active:
		var rest_step := delta * simulation_scale
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * rest_step)
		if not is_on_floor():
			velocity.y += 1350.0 * rest_step
		move_and_slide()
		queue_redraw()
		return
	var step := delta * simulation_scale
	action_clock -= step
	alert = maxf(0.0, alert - step)
	if not is_on_floor():
		velocity.y += 1350.0 * step
	if not is_instance_valid(player) or not player.alive:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * step)
		move_and_slide()
		queue_redraw()
		return
	var offset: Vector2 = player.global_position - global_position
	var alert_range := TuningStore.get_value("gunner_alert_range") if kind == "gunner" else TuningStore.get_value("blade_alert_range")
	var vertical_range := 230.0 if kind == "gunner" else 170.0
	if absf(offset.x) < alert_range and absf(offset.y) < vertical_range:
		facing = signf(offset.x) if absf(offset.x) > 2.0 else facing
		if kind == "gunner":
			_update_gunner(step, offset)
		else:
			_update_blade(step, offset)
	else:
		_patrol(step)
	move_and_slide()
	queue_redraw()

func _update_gunner(step: float, offset: Vector2) -> void:
	if not alive or not combat_active:
		windup = 0.0
		action_committed = false
		return
	velocity.x = move_toward(velocity.x, 0.0, 500.0 * step)
	if windup > 0.0:
		windup = maxf(0.0, windup - step)
		if not action_committed and windup <= ACTION_EVENT_REMAINING:
			action_committed = true
			if alive and combat_active and is_instance_valid(player) and player.alive:
				var current_offset: Vector2 = player.global_position - global_position
				var direction := Vector2(current_offset.x, current_offset.y - 25.0).normalized()
				fire_projectile.emit(global_position + Vector2(facing * 28.0, -42.0), direction, self)
			return
	if action_clock <= 0.0:
		action_clock = 1.35 / maxf(0.1, TuningStore.get_value("gunner_aggression"))
		windup = ACTION_DURATION
		action_committed = false
		alert = ACTION_DURATION

func _update_blade(step: float, _offset: Vector2) -> void:
	if windup > 0.0:
		windup = maxf(0.0, windup - step)
		velocity.x = move_toward(velocity.x, 0.0, 850.0 * step)
		if not action_committed and windup <= ACTION_EVENT_REMAINING:
			action_committed = true
			if alive and is_instance_valid(player):
				var strike_center := global_position + Vector2(facing * 43.0, -30.0)
				var hits_player: bool = player.hurtbox_overlaps_circle(strike_center, 43.0) if player.has_method("hurtbox_overlaps_circle") else global_position.distance_to(player.global_position) < 88.0
				if hits_player:
					player.die()
		return
	var current_offset: Vector2 = player.global_position - global_position
	if absf(current_offset.x) > 70.0:
		velocity.x = move_toward(velocity.x, facing * TuningStore.get_value("blade_move_speed"), 650.0 * step)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * step)
		if action_clock <= 0.0:
			action_clock = 1.0 / maxf(0.1, TuningStore.get_value("blade_aggression"))
			windup = ACTION_DURATION
			action_committed = false
			alert = ACTION_DURATION

func _patrol(step: float) -> void:
	if global_position.x <= patrol_left:
		patrol_direction = 1.0
	elif global_position.x >= patrol_right:
		patrol_direction = -1.0
	facing = patrol_direction
	var patrol_speed := TuningStore.get_value("gunner_patrol_speed") if kind == "gunner" else TuningStore.get_value("blade_patrol_speed")
	velocity.x = move_toward(velocity.x, patrol_direction * patrol_speed, 300.0 * step)

func kill() -> void:
	if not alive:
		return
	alive = false
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	windup = 0.0
	death_time = 0.0
	killed.emit(global_position)
	queue_redraw()

func set_resting(resting: bool, lean: float = 1.0) -> void:
	resting_visual = resting
	combat_active = not resting
	resting_lean = -1.0 if lean < 0.0 else 1.0
	if resting:
		velocity = Vector2.ZERO
		windup = 0.0
		action_committed = false
		alert = 0.0
	queue_redraw()
	_sync_rim_light()

func get_hurtbox_size() -> Vector2:
	var width := TuningStore.get_value("enemy_hurtbox_width")
	var height := maxf(width, TuningStore.get_value("enemy_hurtbox_height"))
	return Vector2(width, height)

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

func _apply_hurtbox_tuning() -> void:
	if not is_instance_valid(hurtbox_collision):
		return
	var size := get_hurtbox_size()
	if size.is_equal_approx(applied_hurtbox_size):
		return
	applied_hurtbox_size = size
	var shape := hurtbox_collision.shape as CapsuleShape2D
	shape.radius = size.x * 0.5
	shape.height = size.y
	hurtbox_collision.position = Vector2(0.0, -size.y * 0.5 + 1.0)

func _resolve_visual_state() -> Dictionary:
	var frames: Array
	var frame_index: int = 0
	if kind == "gunner":
		if not alive:
			frames = AnimFrames.GUNNER_DEATH
			frame_index = _phase_index(frames, death_time / DEATH_DURATION)
		elif windup > 0.0:
			frames = AnimFrames.GUNNER_SHOOT
			frame_index = _phase_index(frames, 1.0 - windup / ACTION_DURATION)
		elif absf(velocity.x) > 10.0:
			frames = AnimFrames.GUNNER_WALK
			frame_index = int(floor(animation_clock * 10.0)) % frames.size()
		else:
			frames = AnimFrames.GUNNER_IDLE
	else:
		if not alive:
			frames = AnimFrames.BLADE_DEATH
			frame_index = _phase_index(frames, death_time / DEATH_DURATION)
		elif windup > 0.0:
			frames = AnimFrames.BLADE_ATTACK
			frame_index = _phase_index(frames, 1.0 - windup / ACTION_DURATION)
		elif absf(velocity.x) > 10.0:
			frames = AnimFrames.BLADE_RUN
			frame_index = int(floor(animation_clock * 11.0)) % frames.size()
		else:
			frames = AnimFrames.BLADE_IDLE
	var texture := frames[frame_index] as Texture2D
	var horizontal_flip := -1.0 if facing < 0.0 else 1.0
	return {
		"texture": texture,
		"scale": SPRITE_SCALE * (0.94 if resting_visual and alive else 1.0),
		"horizontal_flip": horizontal_flip,
		"rotation": resting_lean * 0.055 if resting_visual and alive else 0.0,
		"draw_offset_y": 35.0 if resting_visual and alive else 24.0
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
	rim_light.rotation = float(visual.get("rotation", 0.0))
	if resting_visual and alive:
		rim_light.position.y += 11.0

func _draw() -> void:
	var visual := _resolve_visual_state()
	var texture := visual["texture"] as Texture2D
	var sprite_scale := float(visual["scale"])
	var horizontal_flip := float(visual["horizontal_flip"])
	draw_set_transform(Vector2(0, float(visual.get("draw_offset_y", 24.0))), float(visual.get("rotation", 0.0)), Vector2(horizontal_flip * sprite_scale, sprite_scale))
	draw_texture(texture, Vector2(-96, -192))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if alert > 0.0 and alive:
		draw_arc(Vector2(0, -58), 23.0 + alert * 18.0, 0, TAU, 28, Color(1.0, 0.35, 0.25, minf(1.0, alert * 2.2)), 2.5)

func _phase_index(frames: Array, phase: float) -> int:
	return clampi(int(floor(clampf(phase, 0.0, 0.9999) * frames.size())), 0, frames.size() - 1)
