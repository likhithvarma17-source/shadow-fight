extends Node2D

const PARTICLE_COUNT := 38
const RING_LIFETIME := 0.30

var particles: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var simulation_scale := 1.0
var total_bursts := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	z_index = 10
	rng.seed = 0xB011E7

func _process(delta: float) -> void:
	var step := delta * simulation_scale
	for index in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[index]
		var velocity: Vector2 = particle["velocity"]
		velocity.y += 360.0 * step
		velocity *= pow(0.075, step)
		particle["position"] = Vector2(particle["position"]) + velocity * step
		particle["velocity"] = velocity
		particle["life"] = float(particle["life"]) - step
		if float(particle["life"]) <= 0.0:
			particles.remove_at(index)
	for index in range(rings.size() - 1, -1, -1):
		rings[index]["life"] = float(rings[index]["life"]) - step
		if float(rings[index]["life"]) <= 0.0:
			rings.remove_at(index)
	queue_redraw()

func spawn_burst(position: Vector2, intercepted_velocity: Vector2) -> void:
	var opposing_direction := -intercepted_velocity.normalized() if intercepted_velocity.length_squared() > 0.01 else Vector2.LEFT
	for index in range(PARTICLE_COUNT):
		var directed := index < 18
		var angle_spread := 1.38 if directed else PI
		var angle := opposing_direction.angle() + rng.randf_range(-angle_spread, angle_spread)
		var speed := rng.randf_range(250.0, 920.0) if directed else rng.randf_range(130.0, 520.0)
		var life := rng.randf_range(0.20, 0.48)
		var color := Color("fff2df")
		if index >= 5 and index < 21:
			color = Color("ff4b2f")
		elif index >= 21:
			color = Color("b90f24")
		particles.append({
			"position": position + Vector2.from_angle(angle) * rng.randf_range(0.0, 5.0),
			"velocity": Vector2.from_angle(angle) * speed,
			"life": life,
			"max_life": life,
			"length": rng.randf_range(11.0, 34.0),
			"radius": rng.randf_range(1.1, 3.2),
			"color": color,
			"core": index < 5
		})
	rings.append({
		"position": position,
		"life": RING_LIFETIME,
		"max_life": RING_LIFETIME
	})
	total_bursts += 1
	queue_redraw()

func clear_effects() -> void:
	particles.clear()
	rings.clear()
	total_bursts = 0
	queue_redraw()

func _draw() -> void:
	for ring in rings:
		var life_ratio := clampf(float(ring["life"]) / float(ring["max_life"]), 0.0, 1.0)
		var progress := 1.0 - life_ratio
		var ring_position: Vector2 = ring["position"]
		draw_circle(ring_position, lerpf(13.0, 24.0, progress), Color(0.9, 0.035, 0.08, life_ratio * 0.44))
		draw_circle(ring_position, lerpf(8.0, 2.0, progress), Color(1.0, 0.94, 0.82, life_ratio * 0.94))
		draw_arc(ring_position, lerpf(6.0, 46.0, progress), 0.0, TAU, 32, Color(1.0, 0.18, 0.09, life_ratio), lerpf(4.0, 1.0, progress), true)
	for particle in particles:
		var life_ratio := clampf(float(particle["life"]) / float(particle["max_life"]), 0.0, 1.0)
		var particle_position: Vector2 = particle["position"]
		var velocity: Vector2 = particle["velocity"]
		var color: Color = particle["color"]
		color.a = life_ratio
		var trail := velocity.normalized() * float(particle["length"]) * life_ratio
		draw_line(particle_position, particle_position - trail, color, 2.8 if bool(particle["core"]) else 1.5, true)
		draw_circle(particle_position, float(particle["radius"]) * life_ratio, color)
