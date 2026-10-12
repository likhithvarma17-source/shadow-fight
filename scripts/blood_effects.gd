extends Node2D

const PARTICLE_COUNT := 34

var particles: Array[Dictionary] = []
var simulation_scale := 1.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	z_index = 9
	rng.seed = 0xB100D

func _process(delta: float) -> void:
	var step := delta * simulation_scale
	for index in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[index]
		var velocity: Vector2 = particle["velocity"]
		velocity.y += 1180.0 * step
		velocity *= pow(0.32, step)
		particle["position"] = Vector2(particle["position"]) + velocity * step
		particle["velocity"] = velocity
		particle["life"] = float(particle["life"]) - step
		if float(particle["life"]) <= 0.0:
			particles.remove_at(index)
	queue_redraw()

func spawn_spray(position: Vector2, strike_direction: Vector2) -> void:
	var base_direction := strike_direction.normalized() if strike_direction.length_squared() > 0.01 else Vector2.RIGHT
	for index in range(PARTICLE_COUNT):
		var angle := base_direction.angle() + rng.randf_range(-1.18, 1.18)
		var speed := rng.randf_range(260.0, 760.0)
		var life := rng.randf_range(0.28, 0.68)
		var crimson_mix := rng.randf_range(0.0, 1.0)
		particles.append({
			"position": position + Vector2.from_angle(angle) * rng.randf_range(0.0, 10.0),
			"velocity": Vector2.from_angle(angle) * speed + Vector2(0.0, -rng.randf_range(70.0, 260.0)),
			"life": life,
			"max_life": life,
			"length": rng.randf_range(7.0, 24.0),
			"radius": rng.randf_range(0.8, 2.4),
			"color": Color(lerpf(0.22, 0.62, crimson_mix), lerpf(0.004, 0.025, crimson_mix), lerpf(0.008, 0.018, crimson_mix), 1.0),
			"streak": index < 22
		})
	queue_redraw()

func clear_particles() -> void:
	particles.clear()
	queue_redraw()

func _draw() -> void:
	for particle in particles:
		var life_ratio := clampf(float(particle["life"]) / float(particle["max_life"]), 0.0, 1.0)
		var position: Vector2 = particle["position"]
		var velocity: Vector2 = particle["velocity"]
		var color: Color = particle["color"]
		color.a = life_ratio * 0.82
		if bool(particle["streak"]) and velocity.length_squared() > 1.0:
			var trail := velocity.normalized() * float(particle["length"]) * life_ratio
			draw_line(position, position - trail, color, lerpf(0.55, 1.5, life_ratio), true)
		draw_circle(position, float(particle["radius"]) * lerpf(0.55, 1.0, life_ratio), color)
