extends Node2D
class_name GrappleTutorial

@onready var _control: Label = get_node("Control") as Label

var _completed: bool = false


func _ready() -> void:
	_control.text = "E — HOLD TO GRAPPLE"


func set_controller_prompts(controller: bool) -> void:
	if _completed:
		return
	_control.text = "RT — HOLD TO GRAPPLE" if controller else "E — HOLD TO GRAPPLE"


func fade_out() -> void:
	if _completed:
		return
	_completed = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(_hide_sign)


func _hide_sign() -> void:
	visible = false


func _draw() -> void:
	# A short stone post ties the inscription to the starting island.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5.0, 50.0), Vector2(5.0, 50.0),
		Vector2(4.0, 96.0), Vector2(-4.0, 96.0),
	]), Color(0.35, 0.28, 0.31, 1.0))
	draw_line(Vector2(-2.0, 56.0), Vector2(-2.0, 93.0), Color(0.78, 0.57, 0.31, 1.0), 1.0)

	var panel: Rect2 = Rect2(Vector2(-128.0, -58.0), Vector2(256.0, 112.0))
	draw_rect(panel, Color(0.035, 0.055, 0.09, 0.94), true)
	draw_rect(panel, Color(0.91, 0.65, 0.28, 1.0), false, 2.0)
	draw_line(Vector2(-116.0, -27.0), Vector2(116.0, -27.0), Color(0.22, 0.72, 0.69, 0.9), 1.0)
	# Small turquoise diamond gives the old marker a magical accent.
	draw_colored_polygon(PackedVector2Array([
		Vector2(116.0, -49.0), Vector2(121.0, -44.0),
		Vector2(116.0, -39.0), Vector2(111.0, -44.0),
	]), Color(0.28, 0.86, 0.82, 1.0))
