extends Node2D
class_name Portal

# A portal drawn from layered ellipses plus a ring of travelling energy sparks.
# No shaders, no particles, no textures: everything here is CanvasItem drawing,
# and the animation is one elapsed-time counter read in _draw.
#
# Placement convention: the node sits on the platform's walking surface (its own
# y is the surface y), so the ring is built upwards from the origin and its
# bottom lip lands on the ground. The player spawn is inside the entrance ring.

@export var radii: Vector2 = Vector2(30.0, 40.0) ## x / y radius of the main ring
@export var outer_color: Color = Color(0.12, 0.39, 0.85, 1.0)
@export var mid_color: Color = Color(0.25, 0.66, 1.0, 1.0)
@export var inner_color: Color = Color(0.52, 0.85, 1.0, 1.0)
@export var core_color: Color = Color(0.95, 0.99, 1.0, 1.0)
@export var spark_color: Color = Color(0.75, 0.94, 1.0, 1.0)
@export var base_color: Color = Color(0.22, 0.16, 0.30, 1.0)
@export var base_lit_color: Color = Color(0.34, 0.26, 0.44, 1.0)

@export_range(0.0, 6.0, 0.05) var spin_speed: float = 1.4 ## radians/second for the travelling sparks
@export_range(0.0, 6.0, 0.05) var pulse_speed: float = 2.4 ## breathing rate of the ring
@export_range(1, 24, 1) var spark_count: int = 9

const SPARK_ORBIT: float = 1.16 ## ring radii are multiplied by this to place the sparks just outside the ring
const SPARK_LENGTH: float = 5.0
const SPARK_WIDTH: float = 2.2
const PORTAL_AMBIENCE: AudioStream = preload("res://assets/audio/sfx/stratos_v1/loops/portal_ambient_loop.wav")
const PORTAL_AUDIBLE_DISTANCE := 320.0

var _elapsed: float = 0.0
var _ambience: AudioStreamPlayer2D = null
var _ambience_fade: Tween = null
var _ambience_active: bool = false


func _ready() -> void:
	_ambience = AudioStreamPlayer2D.new()
	_ambience.name = "PortalAmbience"
	_ambience.bus = "Ambience"
	_ambience.max_distance = PORTAL_AUDIBLE_DISTANCE
	_ambience.volume_db = -12.0
	var loop_stream: AudioStreamWAV = PORTAL_AMBIENCE.duplicate() as AudioStreamWAV
	loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop_stream.loop_end = int(loop_stream.get_length() * loop_stream.mix_rate)
	_ambience.stream = loop_stream
	add_child(_ambience)


func _process(delta: float) -> void:
	_elapsed += delta
	_update_ambience()
	if get_node_or_null("PortalArtwork") == null:
		queue_redraw()


func _draw() -> void:
	if get_node_or_null("PortalArtwork") != null:
		return
	var pulse: float = 1.0 + 0.045 * sin(_elapsed * pulse_speed)
	var rx: float = radii.x * pulse
	var ry: float = radii.y * pulse
	var centre: Vector2 = Vector2(0.0, -ry)

	_draw_base(ry)

	# Soft glow, then the ground lip, then the energy itself.
	_draw_ellipse(centre, Vector2(rx * 1.45, ry * 1.38), Color(mid_color, mid_color.a * 0.16))
	_draw_ellipse(centre, Vector2(rx * 1.22, ry * 1.16), Color(mid_color, mid_color.a * 0.28))
	_draw_ellipse(Vector2(0.0, 0.0), Vector2(rx * 1.5, 6.0), Color(inner_color, inner_color.a * 0.22))

	_draw_ellipse(centre, Vector2(rx, ry), outer_color)
	_draw_ellipse(centre, Vector2(rx * 0.82, ry * 0.86), mid_color)
	_draw_ellipse(centre, Vector2(rx * 0.60, ry * 0.66), inner_color)

	# Core breathes on its own phase so the portal never looks frozen.
	var core_pulse: float = 0.72 + 0.28 * sin(_elapsed * pulse_speed * 1.6)
	_draw_ellipse(centre, Vector2(rx * 0.34, ry * 0.40), Color(core_color, core_color.a * core_pulse))

	# Upward light shaft, widest at the ring and pinched 60 px above it.
	var shaft_top: float = centre.y - ry
	draw_colored_polygon(PackedVector2Array([
		Vector2(-rx * 0.55, shaft_top),
		Vector2(rx * 0.55, shaft_top),
		Vector2(rx * 0.22, shaft_top - 62.0),
		Vector2(-rx * 0.22, shaft_top - 62.0),
	]), Color(inner_color, inner_color.a * 0.13))

	_draw_sparks(centre, rx, ry)


## The stone the ring hangs in: a plinth with a lit top face.
func _draw_base(ry: float) -> void:
	var half_width: float = radii.x * 0.72
	draw_colored_polygon(PackedVector2Array([
		Vector2(-half_width, 0.0),
		Vector2(half_width, 0.0),
		Vector2(half_width * 0.78, -7.0),
		Vector2(-half_width * 0.78, -7.0),
	]), base_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-half_width * 0.78, -7.0),
		Vector2(half_width * 0.78, -7.0),
		Vector2(half_width * 0.62, -10.0),
		Vector2(-half_width * 0.62, -10.0),
	]), base_lit_color)
	# Two uprights framing the ring.
	for side in [-1.0, 1.0]:
		var x: float = side * radii.x * 1.18
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 3.0, 0.0),
			Vector2(x + 3.0, 0.0),
			Vector2(x + 2.0, -ry * 1.25),
			Vector2(x - 2.0, -ry * 1.25),
		]), base_color)


func _draw_ellipse(centre: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for step in 26:
		var angle: float = TAU * float(step) / 26.0
		points.append(centre + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


## Sparks run around the outside of the ring, each one dimming as it climbs, so
## the rotation is legible as a direction and not just as a shimmer.
func _draw_sparks(centre: Vector2, rx: float, ry: float) -> void:
	for index in spark_count:
		var angle: float = _elapsed * spin_speed + TAU * float(index) / float(spark_count)
		var offset: Vector2 = Vector2(cos(angle) * rx * SPARK_ORBIT, sin(angle) * ry * SPARK_ORBIT)
		var point: Vector2 = centre + offset
		# Tangent of the ellipse at this angle, used to lay the spark along the ring.
		var tangent: Vector2 = Vector2(-sin(angle) * rx, cos(angle) * ry).normalized()
		var normal: Vector2 = offset.normalized()
		var fade: float = 0.45 + 0.55 * (0.5 + 0.5 * sin(angle * 2.0 + _elapsed * pulse_speed))
		var color: Color = Color(spark_color, spark_color.a * fade)
		draw_colored_polygon(PackedVector2Array([
			point + tangent * SPARK_LENGTH * 0.5 + normal * SPARK_WIDTH * 0.5,
			point - tangent * SPARK_LENGTH * 0.5 + normal * SPARK_WIDTH * 0.5,
			point - tangent * SPARK_LENGTH * 0.5 - normal * SPARK_WIDTH * 0.5,
			point + tangent * SPARK_LENGTH * 0.5 - normal * SPARK_WIDTH * 0.5,
		]), color)


func _update_ambience() -> void:
	if _ambience == null:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var nearby: bool = player != null and global_position.distance_to(player.global_position) <= PORTAL_AUDIBLE_DISTANCE
	if nearby == _ambience_active:
		return
	_ambience_active = nearby
	if _ambience_fade != null and _ambience_fade.is_running():
		_ambience_fade.kill()
	if nearby:
		if not _ambience.playing:
			_ambience.volume_db = -12.0
			_ambience.play()
		_ambience_fade = create_tween()
		_ambience_fade.tween_property(_ambience, "volume_db", 0.0, 0.22)
	else:
		_ambience_fade = create_tween()
		_ambience_fade.tween_property(_ambience, "volume_db", -40.0, 0.2)
		_ambience_fade.tween_callback(_ambience.stop)

func _exit_tree() -> void:
	if _ambience != null:
		_ambience.stop()
