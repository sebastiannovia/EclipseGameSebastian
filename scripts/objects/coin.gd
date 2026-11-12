
extends Area2D
class_name CoinPickup

@export_range(1, 999, 1) var value: int = 1
@export_range(0.2, 4.0, 0.1) var animation_speed: float = 0.4
@export_range(0.0, 8.0, 0.25) var bob_height: float = 1.0

const TRACKER_GROUP: StringName = &"collectible_tracker"
const PICKUP_DURATION: float = 0.38
const NORMAL_COIN_FRAME_COUNT: int = 8

@onready var _collision: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var _artwork: Sprite2D = get_node_or_null("Artwork") as Sprite2D

var _home_position: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _pickup_elapsed: float = 0.0
var _collected: bool = false


func _ready() -> void:
	if _collision == null:
		push_error("CoinPickup: Missing CollisionShape2D child.")
		set_process(false)
		return

	_home_position = position
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_elapsed += delta
	if _artwork != null and not _collected:
		_artwork.frame = int(floor(_elapsed * animation_speed * NORMAL_COIN_FRAME_COUNT)) % NORMAL_COIN_FRAME_COUNT

	if _collected:
		_pickup_elapsed += delta
		queue_redraw()

		if _pickup_elapsed >= _pickup_duration():
			queue_free()

		return

	position = _home_position + Vector2(
		0.0,
		sin(_elapsed * TAU * animation_speed) * bob_height
	)

	queue_redraw()


func _draw() -> void:
	if _collected:
		_draw_pickup_effect()
		return
	if _artwork != null:
		return

	var flip_width: float = 0.93 + 0.07 * absf(cos(_elapsed * TAU * animation_speed))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(flip_width, 1.0))
	_draw_idle_art()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_idle_art() -> void:
	# A faceted gold coin with a dark rim and a restrained engraved sun mark.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -11), Vector2(4, -11), Vector2(8, -9), Vector2(11, -4),
		Vector2(11, 4), Vector2(8, 9), Vector2(4, 11), Vector2(-4, 11),
		Vector2(-8, 9), Vector2(-11, 4), Vector2(-11, -4), Vector2(-8, -9),
	]), Color(0.31, 0.16, 0.07, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -9), Vector2(4, -9), Vector2(7, -7), Vector2(9, -3),
		Vector2(9, 3), Vector2(7, 7), Vector2(4, 9), Vector2(-4, 9),
		Vector2(-7, 7), Vector2(-9, 3), Vector2(-9, -3), Vector2(-7, -7),
	]), Color(0.76, 0.43, 0.13, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3, -7), Vector2(3, -7), Vector2(6, -5), Vector2(7, -2),
		Vector2(7, 2), Vector2(5, 5), Vector2(3, 7), Vector2(-3, 7),
		Vector2(-5, 5), Vector2(-7, 2), Vector2(-7, -2), Vector2(-5, -5),
	]), Color(0.91, 0.62, 0.22, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -4), Vector2(3, 0), Vector2(0, 4), Vector2(-3, 0),
	]), Color(0.56, 0.31, 0.10, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6, -5), Vector2(-4, -7), Vector2(-1, -7), Vector2(-4, -5),
	]), Color(1.0, 0.79, 0.42, 1.0))


func _draw_pickup_effect() -> void:
	var progress: float = clampf(_pickup_elapsed / PICKUP_DURATION, 0.0, 1.0)
	var alpha: float = 1.0 - progress
	for index in 5:
		var angle: float = TAU * float(index) / 5.0 - PI * 0.5
		var point: Vector2 = Vector2.from_angle(angle) * (2.0 + progress * 8.0)
		var size: float = 1.5 * alpha + 0.5
		draw_colored_polygon(PackedVector2Array([
			point + Vector2(0, -size), point + Vector2(size * 0.6, 0),
			point + Vector2(0, size), point + Vector2(-size * 0.6, 0),
		]), Color(0.88, 0.59, 0.22, alpha))


func _on_body_entered(body: Node2D) -> void:
	if _collected or not (body is Player):
		return

	_collected = true
	if _artwork != null:
		_artwork.visible = false

	set_deferred("monitoring", false)
	_collision.set_deferred("disabled", true)

	_award_collection()
	queue_redraw()


func _award_collection() -> void:
	var tracker: Node = get_tree().get_first_node_in_group(TRACKER_GROUP)

	if tracker != null and tracker.has_method("add_coins"):
		tracker.call("add_coins", maxi(1, value))
	else:
		push_warning("CoinPickup: No collectible tracker found.")


func _pickup_duration() -> float:
	return PICKUP_DURATION
