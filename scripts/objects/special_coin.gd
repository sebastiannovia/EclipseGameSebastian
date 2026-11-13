extends "res://scripts/objects/coin.gd"

const SPECIAL_PICKUP_SOUND: AudioStream = preload("res://assets/audio/sfx/stratos_v1/sfx/special_coin_pickup.wav")

func _draw_idle_art() -> void:
	# A small turquoise gem with a restrained gold setting and crisp facets.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -14), Vector2(8, -9), Vector2(10, -4), Vector2(8, 7),
		Vector2(0, 14), Vector2(-8, 7), Vector2(-10, -4), Vector2(-8, -9),
	]), Color(0.30, 0.19, 0.12, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -12), Vector2(7, -8), Vector2(8, -3), Vector2(6, 6),
		Vector2(0, 11), Vector2(-6, 6), Vector2(-8, -3), Vector2(-7, -8),
	]), Color(0.83, 0.55, 0.20, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -9), Vector2(5, -6), Vector2(6, -2), Vector2(4, 5),
		Vector2(0, 9), Vector2(-4, 5), Vector2(-6, -2), Vector2(-5, -6),
	]), Color(0.13, 0.52, 0.55, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -8), Vector2(3, -5), Vector2(0, 2), Vector2(-3, -1),
	]), Color(0.50, 0.82, 0.75, 1.0))


func _draw_pickup_effect() -> void:
	var progress: float = clampf(_pickup_elapsed / _pickup_duration(), 0.0, 1.0)
	var alpha: float = 1.0 - progress
	for index in 7:
		var angle: float = TAU * float(index) / 7.0 + progress * 0.25
		var point: Vector2 = Vector2.from_angle(angle) * (3.0 + progress * 11.0)
		var size: float = 1.8 * alpha + 0.5
		var color := Color(0.33, 0.77, 0.73, alpha) if index % 2 == 0 else Color(0.82, 0.55, 0.22, alpha)
		draw_colored_polygon(PackedVector2Array([
			point + Vector2(0, -size), point + Vector2(size * 0.6, 0),
			point + Vector2(0, size), point + Vector2(-size * 0.6, 0),
		]), color)


func _play_pickup_sound() -> void:
	if _pickup_audio == null:
		return
	_pickup_audio.stream = SPECIAL_PICKUP_SOUND
	_pickup_audio.play()


func _award_collection() -> void:
	var tracker: Node = get_tree().get_first_node_in_group(TRACKER_GROUP)
	if tracker != null and tracker.has_method("add_special_collectibles"):
		tracker.call("add_special_collectibles", maxi(1, value))


func _pickup_duration() -> float:
	return maxf(0.58, SPECIAL_PICKUP_SOUND.get_length() + 0.05)
