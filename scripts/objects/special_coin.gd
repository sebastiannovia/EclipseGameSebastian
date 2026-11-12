extends "res://scripts/objects/coin.gd"

const GEM_SHEET: Texture2D = preload("res://assets/art/final_pack/STRATOS_Art_Assets/collectibles/special_gem_spin_6f_40x40.png")
const GEM_PICKUP_SHEET: Texture2D = preload("res://assets/art/final_pack/STRATOS_Art_Assets/effects/gem_pickup_8f_64x64.png")


func _draw_idle_art() -> void:
	var frame: int = int(floor(_elapsed * animation_speed * 8.0)) % 6
	var region := Rect2(Vector2(frame * 40, 0), Vector2(40, 40))
	draw_texture_rect_region(GEM_SHEET, Rect2(-20, -20, 40, 40), region)


func _draw_pickup_effect() -> void:
	var frame: int = mini(7, int(floor(_pickup_elapsed / _pickup_duration() * 8.0)))
	var region := Rect2(Vector2(frame * 64, 0), Vector2(64, 64))
	var alpha: float = 1.0 - clampf(_pickup_elapsed / _pickup_duration(), 0.0, 1.0)
	draw_texture_rect_region(GEM_PICKUP_SHEET, Rect2(-32, -32, 64, 64), region, Color(1, 1, 1, alpha))


func _award_collection() -> void:
	var tracker: Node = get_tree().get_first_node_in_group(TRACKER_GROUP)
	if tracker != null and tracker.has_method("add_special_collectibles"):
		tracker.call("add_special_collectibles", maxi(1, value))


func _pickup_duration() -> float:
	return 0.58
