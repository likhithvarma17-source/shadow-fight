extends CharacterBody2D

signal fire_projectile(origin: Vector2, direction: Vector2, shooter: Node)
signal melee_strike(center: Vector2, radius: float)
signal health_changed(current: int, maximum: int)
signal damaged(amount: int, source: String, at: Vector2)
signal defeated(at: Vector2)
signal attack_announced(label: String, color: Color)

const AnimFrames = preload("res://scripts/animation_frames.gd")
const TuningStore = preload("res://scripts/tuning_store.gd")
const CharacterRim = preload("res://scripts/character_rim.gd")

const SPRITE_SCALE := 1.02
const INTRO_DURATION := 0.85
const MELEE_WINDUP := 0.44
const TELEPORT_APPEAR := 0.22
const MELEE_DASH_DURATION := 1.15
const RANGED_WINDUP := 0.52
const RANGED_SHOT_INTERVAL := 0.14
const STAGGER_DURATION := 0.46
const DEATH_DURATION := 1.05
const HURTBOX_SIZE := Vector2(48.0, 118.0)

enum BossState {
	INTRO,
	RECOVER,
	MELEE_WINDUP,
	MELEE_DASH,
	TELEPORT_IN,
	RANGED_WINDUP,
	RANGED_BURST,
	STAGGER,
	DEAD
}

var player: Node2D
var arena_left := 80.0
var arena_right := 1776.0
var simulation_scale := 1.0
var alive := true
var max_health := 12
var health := 12
var state: BossState = BossState.INTRO
var state_clock := INTRO_DURATION
var animation_clock := 0.0
var death_time := 0.0
var facing := -1.0
var attack_index := 0
var melee_variant := 0
var current_melee_is_teleport := false
var teleport_committed := false
var strike_committed := false
var ranged_shots_remaining := 0
var ranged_shot_clock := 0.0
var damage_invulnerability := 0.0
var hurt_flash := 0.0
var last_damage_source := ""
var total_damage_taken := 0
var dash_attack_count := 0
var teleport_attack_count := 0
var ranged_volley_count := 0
var melee_parry_count := 0
var body_sprite: Sprite2D
var rim_light: Sprite2D
var hurtbox_collision: CollisionShape2D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	max_health = maxi(1, int(round(TuningStore.get_value("boss_max_health"))))
	health = max_health
	hurtbox_collision = CollisionShape2D.new()
	hurtbox_collision.name = "BossHurtboxCollision"
	var capsule := CapsuleShape2D.new()
	capsule.radius = HURTBOX_SIZE.x * 0.5
	capsule.height = HURTBOX_SIZE.y
	hurtbox_collision.shape = capsule
	hurtbox_collision.position = Vector2(0.0, -HURTBOX_SIZE.y * 0.5 + 1.0)
	add_child(hurtbox_collision)
	body_sprite = Sprite2D.new()
	body_sprite.name = "BossBody"
	body_sprite.centered = true
	body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body_sprite.modulate = Color("9296aa")
	add_child(body_sprite)
	rim_light = CharacterRim.new()
	add_child(rim_light)
	_sync_visual()
	if is_instance_valid(rim_light) and rim_light.rim_material:
		rim_light.rim_material.set_shader_parameter("key_color", Color(1.0, 0.15, 0.12, 1.0))
		rim_light.rim_material.set_shader_parameter("bounce_color", Color(1.0, 0.62, 0.18, 0.92))
		rim_light.rim_material.set_shader_parameter("inner_strength", 0.82)
	health_changed.emit(health, max_health)
	queue_redraw()

func _process(delta: float) -> void:
	hurt_flash = maxf(0.0, hurt_flash - delta * 5.5)
	_apply_health_tuning()
	_sync_visual()
	queue_redraw()

func _physics_process(delta: float) -> void:
	var step := delta * simulation_scale
	animation_clock += step
	damage_invulnerability = maxf(0.0, damage_invulnerability - step)
	if not alive:
		death_time = minf(DEATH_DURATION, death_time + step)
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * step)
		if not is_on_floor():
			velocity.y += 1200.0 * step
		_move_scaled()
		queue_redraw()
		return
	if not is_on_floor():
		velocity.y += 1500.0 * step
	if not is_instance_valid(player) or not player.alive:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * step)
		_move_scaled()
		return
	facing = signf(player.global_position.x - global_position.x) if absf(player.global_position.x - global_position.x) > 3.0 else facing
	state_clock -= step
	match state:
		BossState.INTRO:
			velocity.x = move_toward(velocity.x, 0.0, 1000.0 * step)
			if state_clock <= 0.0:
				_begin_next_attack()
		BossState.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 850.0 * step)
			if state_clock <= 0.0:
				_begin_next_attack()
		BossState.MELEE_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * step)
			if current_melee_is_teleport and not teleport_committed and state_clock <= 0.18:
				teleport_committed = true
				teleport_attack_count += 1
				var side := -1.0 if player.facing > 0.0 else 1.0
				global_position.x = clampf(player.global_position.x + side * 92.0, arena_left, arena_right)
				facing = signf(player.global_position.x - global_position.x)
				state = BossState.TELEPORT_IN
				state_clock = TELEPORT_APPEAR
				velocity = Vector2.ZERO
			elif not current_melee_is_teleport and state_clock <= 0.0:
				dash_attack_count += 1
				state = BossState.MELEE_DASH
				var dash_speed := TuningStore.get_value("boss_dash_speed")
				state_clock = clampf(absf(player.global_position.x - global_position.x) / maxf(1.0, dash_speed), 0.28, MELEE_DASH_DURATION)
				velocity.x = facing * dash_speed
		BossState.MELEE_DASH:
			velocity.x = facing * TuningStore.get_value("boss_dash_speed")
			if absf(player.global_position.x - global_position.x) <= 86.0 or state_clock <= 0.0:
				_commit_melee_strike()
		BossState.TELEPORT_IN:
			velocity = Vector2.ZERO
			if state_clock <= 0.0:
				_commit_melee_strike()
		BossState.RANGED_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 1100.0 * step)
			if state_clock <= 0.0:
				state = BossState.RANGED_BURST
				ranged_volley_count += 1
				ranged_shots_remaining = 4 if health <= max_health / 2 else 3
				ranged_shot_clock = 0.0
		BossState.RANGED_BURST:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * step)
			ranged_shot_clock -= step
			if ranged_shots_remaining > 0 and ranged_shot_clock <= 0.0:
				_fire_ranged_shot()
				ranged_shots_remaining -= 1
				ranged_shot_clock = RANGED_SHOT_INTERVAL
			elif ranged_shots_remaining <= 0 and ranged_shot_clock <= 0.0:
				_enter_recover()
		BossState.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 1300.0 * step)
			if state_clock <= 0.0:
				_enter_recover(0.35)
		BossState.DEAD:
			pass
	_move_scaled()
	global_position.x = clampf(global_position.x, arena_left, arena_right)
	queue_redraw()

func _begin_next_attack() -> void:
	strike_committed = false
	teleport_committed = false
	if attack_index % 2 == 0:
		current_melee_is_teleport = melee_variant % 2 == 1
		melee_variant += 1
		state = BossState.MELEE_WINDUP
		state_clock = MELEE_WINDUP
		attack_announced.emit(
			"相位突袭 // 斩击格挡" if current_melee_is_teleport else "高速逼近 // 斩击格挡",
			Color("ff4b42")
		)
	else:
		state = BossState.RANGED_WINDUP
		state_clock = RANGED_WINDUP
		attack_announced.emit("弹道连射 // 弹反", Color("ffb04f"))
	attack_index += 1

func _commit_melee_strike() -> void:
	if strike_committed:
		return
	strike_committed = true
	melee_strike.emit(global_position + Vector2(facing * 44.0, -42.0), 58.0)
	if state == BossState.MELEE_DASH or state == BossState.TELEPORT_IN:
		_enter_recover(0.62)

func _fire_ranged_shot() -> void:
	if not is_instance_valid(player):
		return
	var origin := global_position + Vector2(facing * 38.0, -64.0)
	var vertical_bias := float(ranged_shots_remaining - 2) * 12.0
	var target: Vector2 = player.get_hurtbox_center_world() + Vector2(0.0, vertical_bias)
	fire_projectile.emit(origin, (target - origin).normalized(), self)

func can_parry_melee() -> bool:
	if not alive:
		return false
	if state == BossState.MELEE_DASH or state == BossState.TELEPORT_IN:
		return true
	return state == BossState.MELEE_WINDUP and not current_melee_is_teleport and state_clock <= 0.13

func parry_melee() -> bool:
	if not can_parry_melee():
		return false
	melee_parry_count += 1
	strike_committed = true
	velocity = Vector2.ZERO
	state = BossState.STAGGER
	state_clock = STAGGER_DURATION
	var parry_damage := maxi(1, int(round(TuningStore.get_value("boss_melee_parry_damage"))))
	return take_damage(parry_damage, "MELEE PARRY")

func take_damage(amount: int, source: String) -> bool:
	if not alive or damage_invulnerability > 0.0 or amount <= 0:
		return false
	health = maxi(0, health - amount)
	total_damage_taken += amount
	last_damage_source = source
	damage_invulnerability = 0.11
	hurt_flash = 1.0
	damaged.emit(amount, source, global_position + Vector2(0.0, -58.0))
	health_changed.emit(health, max_health)
	if health <= 0:
		alive = false
		state = BossState.DEAD
		death_time = 0.0
		velocity = Vector2(-facing * 150.0, -230.0)
		collision_layer = 0
		collision_mask = 1
		defeated.emit(global_position)
	return true

func kill() -> void:
	damage_invulnerability = 0.0
	take_damage(health, "EXECUTION")

func _enter_recover(duration: float = -1.0) -> void:
	state = BossState.RECOVER
	state_clock = TuningStore.get_value("boss_action_interval") if duration < 0.0 else duration
	velocity.x = 0.0

func get_hurtbox_size() -> Vector2:
	return HURTBOX_SIZE

func _apply_health_tuning() -> void:
	if not alive:
		return
	var tuned_max := maxi(1, int(round(TuningStore.get_value("boss_max_health"))))
	if tuned_max == max_health:
		return
	var damage_already_taken := maxi(0, max_health - health)
	max_health = tuned_max
	health = clampi(max_health - damage_already_taken, 1, max_health)
	health_changed.emit(health, max_health)

func get_hurtbox_center_world() -> Vector2:
	return global_position + Vector2(0.0, -HURTBOX_SIZE.y * 0.5 + 1.0)

func get_hurtbox_rect_world() -> Rect2:
	return Rect2(get_hurtbox_center_world() - HURTBOX_SIZE * 0.5, HURTBOX_SIZE)

func hurtbox_overlaps_circle(point: Vector2, radius: float) -> bool:
	var capsule_radius := HURTBOX_SIZE.x * 0.5
	var straight_half := (HURTBOX_SIZE.y - HURTBOX_SIZE.x) * 0.5
	var center := get_hurtbox_center_world()
	var nearest := Vector2(center.x, clampf(point.y, center.y - straight_half, center.y + straight_half))
	return point.distance_squared_to(nearest) <= pow(capsule_radius + radius, 2.0)

func get_state_name() -> String:
	return BossState.keys()[state]

func _move_scaled() -> void:
	if simulation_scale >= 0.999:
		move_and_slide()
		return
	velocity *= simulation_scale
	move_and_slide()
	velocity /= simulation_scale

func _resolve_visual_state() -> Dictionary:
	var frames: Array = AnimFrames.BLADE_IDLE
	var index := 0
	if not alive:
		frames = AnimFrames.BLADE_DEATH
		index = _phase_index(frames, death_time / DEATH_DURATION)
	elif state in [BossState.MELEE_WINDUP, BossState.MELEE_DASH, BossState.TELEPORT_IN, BossState.RANGED_WINDUP, BossState.RANGED_BURST]:
		frames = AnimFrames.BLADE_ATTACK
		var phase := 1.0 - clampf(state_clock / maxf(MELEE_WINDUP, 0.01), 0.0, 1.0)
		index = _phase_index(frames, phase)
	elif absf(velocity.x) > 30.0:
		frames = AnimFrames.BLADE_RUN
		index = int(floor(animation_clock * 13.0)) % frames.size()
	return {"texture": frames[index] as Texture2D, "index": index}

func _sync_visual() -> void:
	if not is_instance_valid(body_sprite) or not is_instance_valid(rim_light):
		return
	var visual := _resolve_visual_state()
	var texture := visual["texture"] as Texture2D
	var flipped := facing < 0.0
	body_sprite.texture = texture
	body_sprite.scale = Vector2.ONE * SPRITE_SCALE
	body_sprite.position = Vector2(0.0, 24.0 - 96.0 * SPRITE_SCALE)
	body_sprite.flip_h = flipped
	body_sprite.modulate = Color.WHITE.lerp(Color("9296aa"), 1.0 - hurt_flash)
	rim_light.set_visual(texture, SPRITE_SCALE, flipped)

func _draw() -> void:
	if not alive:
		return
	var pulse := 0.55 + sin(Time.get_ticks_msec() * 0.018) * 0.25
	if state == BossState.MELEE_WINDUP:
		var radius := 46.0 + (MELEE_WINDUP - state_clock) * 55.0
		draw_arc(Vector2(0.0, -48.0), radius, -PI * 0.85, PI * 0.85, 36, Color(1.0, 0.12, 0.10, pulse), 3.0)
		if current_melee_is_teleport:
			for offset in [-22.0, 0.0, 22.0]:
				draw_line(Vector2(offset, -112.0), Vector2(offset * 0.25, 12.0), Color(1.0, 0.18, 0.12, 0.28), 2.0)
	elif state == BossState.MELEE_DASH or state == BossState.TELEPORT_IN:
		draw_arc(Vector2(0.0, -48.0), 58.0, 0.0, TAU, 32, Color(1.0, 0.78, 0.46, 0.92), 4.0)
		draw_line(Vector2(-facing * 90.0, -46.0), Vector2(-facing * 18.0, -46.0), Color(1.0, 0.10, 0.08, 0.55), 7.0)
	elif state == BossState.RANGED_WINDUP or state == BossState.RANGED_BURST:
		draw_circle(Vector2(facing * 38.0, -64.0), 8.0 + pulse * 5.0, Color(1.0, 0.18, 0.10, 0.75))
		draw_circle(Vector2(facing * 38.0, -64.0), 3.0, Color("fff1c7"))

func _phase_index(frames: Array, phase: float) -> int:
	return clampi(int(floor(clampf(phase, 0.0, 0.9999) * frames.size())), 0, frames.size() - 1)
