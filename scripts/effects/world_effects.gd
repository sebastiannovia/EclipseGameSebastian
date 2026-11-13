extends Node2D

# A bounded pool of small world-space particles, drawn at the internal resolution.
const MAX_PARTICLES := 240
const GOLD := Color(1.0, 0.76, 0.37)
const TURQUOISE := Color(0.36, 0.91, 0.86)
const DUST := Color(0.94, 0.82, 0.59)

class Spark:
	var point: Vector2
	var velocity: Vector2
	var color: Color
	var remaining: float
	var lifetime: float
	var gravity: float
	var size: float
	var star: bool

var _particles: Array[Spark] = []
var _player: Player
var _camera: Camera2D
var _ambient_time := 0.0
var _trail_time := 0.0
var _portal_time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = 12
	_rng.randomize()
	_player = get_tree().get_first_node_in_group("player") as Player
	if _player == null:
		set_process(false)
		return
	_camera = _player.get_node_or_null("Camera2D") as Camera2D
	_player.visual_jump.connect(_on_jump)
	_player.visual_landing.connect(_on_landing)
	_player.grapple_attached.connect(_on_attach)
	_player.grapple_released.connect(_on_release)


func _process(delta: float) -> void:
	for index in range(_particles.size() - 1, -1, -1):
		var particle: Spark = _particles[index]
		particle.remaining -= delta
		if particle.remaining <= 0.0:
			_particles.remove_at(index)
			continue
		particle.velocity.y += particle.gravity * delta
		particle.point += particle.velocity * delta
	_ambient_time += delta
	_portal_time += delta
	_trail_time += delta
	if _camera != null and _ambient_time >= 0.20:
		_ambient_time = 0.0
		var center: Vector2 = _camera.get_screen_center_position()
		_spawn(center + Vector2(_rng.randf_range(-320, 320), _rng.randf_range(-180, 180)),
			Vector2(_rng.randf_range(-6, -2), _rng.randf_range(-3, 1)),
			Color(0.78, 0.94, 0.88, 0.55), 3.5, 0.0, 1.0, false)
	if _player.is_physics_processing() and _player.is_grappling and _trail_time >= 0.03:
		_trail_time = 0.0
		if _player.velocity.length() > 65.0:
			_spawn(_player.global_position + Player.ROPE_TIE, -_player.velocity * 0.05,
				Color(TURQUOISE, 0.9), 0.48, 0.0, 2.0, true)
	if _portal_time >= 0.10:
		_portal_time = 0.0
		for portal_name in ["EntrancePortal", "ExitPortal"]:
			var portal: Node2D = get_parent().get_node_or_null("Portales/" + portal_name) as Node2D
			if portal == null or portal.global_position.distance_to(_player.global_position) > 360.0:
				continue
			var angle: float = _rng.randf_range(0.0, TAU)
			var point: Vector2 = portal.global_position + Vector2(cos(angle) * 23, -43 + sin(angle) * 32)
			_spawn(point, Vector2(0, -12), GOLD if portal_name == "ExitPortal" else TURQUOISE,
				1.0, 0.0, 2.0, true)
	queue_redraw()


func _spawn(point: Vector2, velocity: Vector2, color: Color, lifetime: float,
		gravity: float, size: float, star: bool) -> void:
	if _particles.size() >= MAX_PARTICLES:
		return
	var particle := Spark.new()
	particle.point = point
	particle.velocity = velocity
	particle.color = color
	particle.remaining = lifetime
	particle.lifetime = lifetime
	particle.gravity = gravity
	particle.size = size
	particle.star = star
	_particles.append(particle)


func _burst(point: Vector2, count: int, color: Color, dust: bool) -> void:
	for index in count:
		var direction := Vector2.from_angle(_rng.randf_range(-PI, 0.0) if dust else _rng.randf_range(0, TAU))
		_spawn(point, direction * _rng.randf_range(25, 70), color,
			_rng.randf_range(0.40, 0.75), 65.0 if dust else 0.0,
			_rng.randf_range(2, 3), not dust)


func _on_jump() -> void:
	_burst(_player.global_position, 12, DUST, true)


func _on_landing(impact: float) -> void:
	if impact > 40.0:
		_burst(_player.global_position, 20 if impact >= 330.0 else 11, DUST, true)


func _on_attach(_creature: Node2D) -> void:
	_burst(_player.get_anchor_position(), 18, TURQUOISE, false)


func _on_release(_creature: Node2D) -> void:
	_burst(_player.global_position + Player.ROPE_TIE, 9, GOLD, false)


func _draw() -> void:
	for particle in _particles:
		var color := particle.color
		# Hold the initial flash, then fade instead of dimming immediately.
		color.a *= clampf(particle.remaining / (particle.lifetime * 0.65), 0.0, 1.0)
		var point: Vector2 = to_local(particle.point).round()
		var size: float = ceilf(particle.size)
		var bounds := Rect2(point - Vector2.ONE * floorf(size * 0.5), Vector2(size, size))
		if particle.star:
			# Crisp square glow and a bright core preserve the pixel-art edges.
			draw_rect(bounds.grow(2.0), Color(color, color.a * 0.16))
		elif size >= 2.0:
			draw_rect(bounds.grow(1.0), Color(0.20, 0.16, 0.24, color.a * 0.35))
		draw_rect(bounds, color)
		if particle.star:
			draw_line(point + Vector2(-size, 0), point + Vector2(size, 0), color, 1.0)
			draw_line(point + Vector2(0, -size), point + Vector2(0, size), color, 1.0)
			draw_rect(Rect2(point, Vector2.ONE), Color(1.0, 1.0, 0.92, color.a))
