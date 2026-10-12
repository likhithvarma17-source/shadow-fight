extends Node2D

const TuningStore = preload("res://scripts/tuning_store.gd")

signal hit_player
signal hit_enemy(enemy: Node)
signal intercepted_projectile(projectile: Node, position: Vector2, velocity: Vector2)
signal expired

const DEFAULT_WORLD_BOUNDS := Rect2(-100.0, -100.0, 5400.0, 920.0)
const HIT_RADIUS := 8.0

var velocity := Vector2.ZERO
var simulation_scale := 1.0
var player: Node2D
var enemies: Array = []
var projectiles: Array = []
var source_shooter: Node
var alive := true
var reflected := false
var life := 4.0
var last_sweep_from := Vector2.ZERO
var last_sweep_to := Vector2.ZERO
var last_hit_fraction := -1.0
var last_hit_enemy: Node
var intercepted_projectile_count := 0
var last_interception_positions: Array[Vector2] = []
var retain_for_rewind := false
var world_bounds := DEFAULT_WORLD_BOUNDS

func setup(direction: Vector2, target_player: Node2D, target_enemies: Array, shooter: Node = null, target_projectiles: Array = [], bounds: Rect2 = DEFAULT_WORLD_BOUNDS) -> void:
	velocity = direction.normalized() * TuningStore.get_value("gunner_projectile_speed")
	player = target_player
	enemies = target_enemies
	projectiles = target_projectiles
	source_shooter = shooter
	world_bounds = bounds
	rotation = velocity.angle()

func _process(delta: float) -> void:
	if not alive:
		return
	var step := delta * simulation_scale
	var sweep_from := global_position
	var sweep_to := sweep_from + velocity * step
	last_sweep_from = sweep_from
	last_sweep_to = sweep_to
	if reflected:
		var first_hit := _find_first_enemy_on_segment(sweep_from, sweep_to)
		var stop_fraction := float(first_hit.get("fraction", 1.0))
		var intercepted := _find_hostile_projectiles_on_segment(sweep_from, sweep_to, stop_fraction)
		for interception in intercepted:
			var hostile_projectile: Node = interception["projectile"]
			if not is_instance_valid(hostile_projectile) or not hostile_projectile.intercept():
				continue
			var interception_position: Vector2 = sweep_from.lerp(sweep_to, float(interception["fraction"]))
			intercepted_projectile_count += 1
			last_interception_positions.append(interception_position)
			intercepted_projectile.emit(hostile_projectile, interception_position, Vector2(interception["velocity"]))
		if not first_hit.is_empty():
			last_hit_fraction = first_hit["fraction"]
			last_hit_enemy = first_hit["enemy"]
			global_position = sweep_from.lerp(sweep_to, last_hit_fraction)
			hit_enemy.emit(last_hit_enemy)
			_expire()
			return
	global_position = sweep_to
	life -= step
	rotation = velocity.angle()
	if life <= 0.0 or not world_bounds.has_point(global_position):
		_expire()
		return
	if not reflected and is_instance_valid(player) and player.alive and player.has_method("hurtbox_overlaps_circle") and player.hurtbox_overlaps_circle(global_position, HIT_RADIUS):
			hit_player.emit()
			_expire()
	queue_redraw()

func _find_hostile_projectiles_on_segment(sweep_from: Vector2, sweep_to: Vector2, stop_fraction: float) -> Array[Dictionary]:
	var hits: Array[Dictionary] = []
	for projectile in projectiles:
		if projectile == self or not is_instance_valid(projectile) or not projectile.alive or projectile.reflected or not projectile.has_method("get_hit_radius"):
			continue
		var combined_radius := HIT_RADIUS + float(projectile.get_hit_radius())
		var entry_fraction := _segment_circle_entry_fraction(sweep_from, sweep_to, projectile.global_position, combined_radius)
		if entry_fraction < 0.0 or entry_fraction > stop_fraction:
			continue
		hits.append({
			"projectile": projectile,
			"fraction": entry_fraction,
			"velocity": projectile.velocity
		})
	hits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["fraction"]) < float(b["fraction"]))
	return hits

func _find_first_enemy_on_segment(sweep_from: Vector2, sweep_to: Vector2) -> Dictionary:
	var closest_enemy: Node
	var closest_fraction := 2.0
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.alive or not enemy.has_method("get_hurtbox_center_world") or not enemy.has_method("get_hurtbox_size"):
			continue
		var hurtbox_center: Vector2 = enemy.get_hurtbox_center_world()
		var hurtbox_size: Vector2 = enemy.get_hurtbox_size()
		var entry_fraction := _segment_capsule_entry_fraction(sweep_from, sweep_to, hurtbox_center, hurtbox_size)
		if entry_fraction >= 0.0 and entry_fraction < closest_fraction:
			closest_fraction = entry_fraction
			closest_enemy = enemy
	if not is_instance_valid(closest_enemy):
		return {}
	return {"enemy": closest_enemy, "fraction": closest_fraction}

func _segment_capsule_entry_fraction(sweep_from: Vector2, sweep_to: Vector2, center: Vector2, size: Vector2) -> float:
	var radius := size.x * 0.5 + HIT_RADIUS
	var straight_half := maxf(0.0, (size.y - size.x) * 0.5)
	var closest_fraction := 2.0
	if straight_half > 0.0:
		var middle_rect := Rect2(center - Vector2(radius, straight_half), Vector2(radius * 2.0, straight_half * 2.0))
		var middle_fraction := _segment_rect_entry_fraction(sweep_from, sweep_to, middle_rect)
		if middle_fraction >= 0.0:
			closest_fraction = middle_fraction
	for cap_center in [center + Vector2.UP * straight_half, center + Vector2.DOWN * straight_half]:
		var cap_fraction := _segment_circle_entry_fraction(sweep_from, sweep_to, cap_center, radius)
		if cap_fraction >= 0.0:
			closest_fraction = minf(closest_fraction, cap_fraction)
	return closest_fraction if closest_fraction <= 1.0 else -1.0

func _segment_circle_entry_fraction(sweep_from: Vector2, sweep_to: Vector2, center: Vector2, radius: float) -> float:
	var movement := sweep_to - sweep_from
	var relative_start := sweep_from - center
	var movement_length_squared := movement.length_squared()
	if relative_start.length_squared() <= radius * radius:
		return 0.0
	if movement_length_squared < 0.000001:
		return -1.0
	var projection := relative_start.dot(movement)
	var discriminant := projection * projection - movement_length_squared * (relative_start.length_squared() - radius * radius)
	if discriminant < 0.0:
		return -1.0
	var entry := (-projection - sqrt(discriminant)) / movement_length_squared
	return entry if entry >= 0.0 and entry <= 1.0 else -1.0

func _segment_rect_entry_fraction(sweep_from: Vector2, sweep_to: Vector2, rect: Rect2) -> float:
	var movement := sweep_to - sweep_from
	var entry := 0.0
	var exit := 1.0
	for axis in range(2):
		var origin := sweep_from.x if axis == 0 else sweep_from.y
		var direction := movement.x if axis == 0 else movement.y
		var minimum := rect.position.x if axis == 0 else rect.position.y
		var maximum := rect.end.x if axis == 0 else rect.end.y
		if absf(direction) < 0.00001:
			if origin < minimum or origin > maximum:
				return -1.0
			continue
		var first := (minimum - origin) / direction
		var second := (maximum - origin) / direction
		if first > second:
			var swap := first
			first = second
			second = swap
		entry = maxf(entry, first)
		exit = minf(exit, second)
		if entry > exit:
			return -1.0
	return entry if exit >= 0.0 and entry <= 1.0 else -1.0

func reflect(_facing: float) -> void:
	if not alive or reflected:
		return
	reflected = true
	velocity = -velocity * 3.0
	rotation = velocity.angle()
	life = 2.5
	queue_redraw()

func intercept() -> bool:
	if not alive or reflected:
		return false
	_expire()
	return true

func get_hit_radius() -> float:
	return HIT_RADIUS

func _expire() -> void:
	if not alive:
		return
	alive = false
	expired.emit()
	if retain_for_rewind:
		visible = false
		set_process(false)
	else:
		queue_free()

func _draw() -> void:
	var color := Color("48eeff") if reflected else Color("ff684f")
	draw_line(Vector2(-16, 0), Vector2(8, 0), Color(color, 0.25), 9.0)
	draw_line(Vector2(-12, 0), Vector2(7, 0), color, 3.0)
	draw_circle(Vector2(8, 0), 3.5, Color("fff3db"))
