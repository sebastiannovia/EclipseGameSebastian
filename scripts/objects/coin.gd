
extends Area2D
class_name CoinPickup

@export_range(1, 999, 1) var value: int = 1
@export_range(0.2, 4.0, 0.1) var animation_speed: float = 0.8
@export_range(0.0, 8.0, 0.25) var bob_height: float = 2.5

const TRACKER_GROUP: StringName = &"collectible_tracker"
const PICKUP_DURATION: float = 0.38

const COIN_SHEET: Texture2D = preload(
	"res://assets/art/final_pack/STRATOS_Art_Assets/collectibles/coin_spin_6f_32x32.png"
)

const PICKUP_SHEET: Texture2D = preload(
	"res://assets/art/final_pack/STRATOS_Art_Assets/effects/coin_pickup_8f_64x64.png"
)

@onready var _collision: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

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

	if _collected:
		_pickup_elapsed += delta
		queue_redraw()

		if _pickup_elapsed >= PICKUP_DURATION:
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

	_draw_idle_art()


func _draw_idle_art() -> void:
	var frame: int = int(floor(_elapsed * animation_speed * 8.0)) % 6
	var region := Rect2(
		Vector2(frame * 32, 0),
		Vector2(32, 32)
	)

	draw_texture_rect_region(
		COIN_SHEET,
		Rect2(-16, -16, 32, 32),
		region
	)


func _draw_pickup_effect() -> void:
	var frame: int = mini(
		7,
		int(floor(_pickup_elapsed / PICKUP_DURATION * 8.0))
	)

	var region := Rect2(
		Vector2(frame * 64, 0),
		Vector2(64, 64)
	)

	var alpha: float = 1.0 - clampf(
		_pickup_elapsed / PICKUP_DURATION,
		0.0,
		1.0
	)

	draw_texture_rect_region(
		PICKUP_SHEET,
		Rect2(-32, -32, 64, 64),
		region,
		Color(1, 1, 1, alpha)
	)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not (body is Player):
		return

	_collected = true

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
