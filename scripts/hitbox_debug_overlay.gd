extends Node2D

var game: Node

func setup(owner_game: Node) -> void:
	game = owner_game
	z_index = 50
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	visible = is_instance_valid(game) and game._should_draw_hitbox_preview()
	if visible:
		queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game) or not game._should_draw_hitbox_preview():
		return
	if _should_draw_attack_hitbox():
		_draw_attack_hitbox()
	_draw_player_hurtbox()
	_draw_enemy_hurtboxes()
	_draw_projectile_hitboxes()

func _draw_attack_hitbox() -> void:
	var player = game.player
	if not is_instance_valid(player):
		return
	var origin: Vector2 = player.global_position + Vector2(0.0, -34.0)
	var direction: Vector2 = game._hitbox_preview_direction()
	var rect: Rect2 = game._attack_hitbox_rect()
	draw_set_transform(origin, direction.angle(), Vector2.ONE)
	draw_rect(rect, Color(1.0, 0.34, 0.08, 0.12), true)
	draw_rect(rect, Color(1.0, 0.58, 0.20, 0.98), false, 2.5, true)
	draw_line(Vector2.ZERO, Vector2(rect.end.x, 0.0), Color(1.0, 0.83, 0.48, 0.85), 1.2, true)
	draw_line(Vector2(rect.end.x, 0.0), Vector2(rect.end.x - 10.0, -6.0), Color("ffd17d"), 1.7, true)
	draw_line(Vector2(rect.end.x, 0.0), Vector2(rect.end.x - 10.0, 6.0), Color("ffd17d"), 1.7, true)
	draw_circle(Vector2.ZERO, 3.2, Color("fff0c9"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _should_draw_attack_hitbox() -> bool:
	return (
		is_instance_valid(game)
		and game._should_draw_hitbox_preview()
		and is_instance_valid(game.player)
		and game.player.is_attack_hitbox_active()
	)

func _draw_player_hurtbox() -> void:
	var player = game.player
	if not is_instance_valid(player) or not player.alive:
		return
	_draw_capsule(
		player.get_hurtbox_center_world(),
		player.get_hurtbox_size(),
		Color(0.20, 0.92, 1.0, 0.11),
		Color(0.30, 0.94, 1.0, 0.98)
	)

func _draw_enemy_hurtboxes() -> void:
	for enemy in game.enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		_draw_capsule(
			enemy.get_hurtbox_center_world(),
			enemy.get_hurtbox_size(),
			Color(1.0, 0.18, 0.20, 0.10),
			Color(1.0, 0.30, 0.28, 0.95)
		)

func _draw_projectile_hitboxes() -> void:
	for shot in game.projectiles:
		if not is_instance_valid(shot) or not shot.alive:
			continue
		var radius: float = shot.get_hit_radius()
		var outline := Color("ff83c3") if not shot.reflected else Color("b891ff")
		draw_circle(shot.global_position, radius, Color(outline, 0.16))
		draw_arc(shot.global_position, radius, 0.0, TAU, 24, outline, 2.0, true)
		if shot.velocity.length_squared() > 0.01:
			draw_line(shot.global_position, shot.global_position + shot.velocity.normalized() * 22.0, Color(outline, 0.72), 1.2, true)

func _draw_capsule(center: Vector2, size: Vector2, fill: Color, outline: Color) -> void:
	var radius := size.x * 0.5
	var straight_half := maxf(0.0, (size.y - size.x) * 0.5)
	var top_center := center - Vector2(0.0, straight_half)
	var bottom_center := center + Vector2(0.0, straight_half)
	if straight_half > 0.0:
		draw_rect(Rect2(center.x - radius, top_center.y, radius * 2.0, straight_half * 2.0), fill, true)
	draw_circle(top_center, radius, fill)
	draw_circle(bottom_center, radius, fill)
	draw_line(Vector2(center.x - radius, top_center.y), Vector2(center.x - radius, bottom_center.y), outline, 2.0, true)
	draw_line(Vector2(center.x + radius, top_center.y), Vector2(center.x + radius, bottom_center.y), outline, 2.0, true)
	draw_arc(top_center, radius, PI, TAU, 24, outline, 2.0, true)
	draw_arc(bottom_center, radius, 0.0, PI, 24, outline, 2.0, true)
