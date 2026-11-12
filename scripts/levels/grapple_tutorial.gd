
extends Node2D
class_name GrappleTutorial

@onready var _control: Label = get_node("Control") as Label

var _completed: bool = false


func _ready() -> void:
	_configure_label()
	set_controller_prompts(false)


func _configure_label() -> void:
	# Position and size of the text inside the stone plate.
	# The sign itself measures approximately 256 x 116 pixels.
	_control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_control.position = Vector2(-112.0, -19.0)
	_control.size = Vector2(224.0, 36.0)

	# Text alignment.
	_control.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_control.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Prevent text from escaping the sign.
	_control.autowrap_mode = TextServer.AUTOWRAP_OFF
	_control.clip_text = true

	# Font size.
	_control.add_theme_font_size_override("font_size", 16)

	# Improve small-size text rendering.
	var original_font: FontFile = _control.get_theme_font("font") as FontFile

	if original_font != null:
		# Duplicate the font to avoid modifying other UI elements.
		var sign_font: FontFile = original_font.duplicate() as FontFile

		sign_font.multichannel_signed_distance_field = false
		sign_font.hinting = TextServer.HINTING_LIGHT

		_control.add_theme_font_override("font", sign_font)


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
	# The ornamental plate is a high-resolution pixel-art sprite child. Keep the
	# existing stone post as world-space drawing behind that plate.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7.0, 51.0), Vector2(7.0, 51.0),
		Vector2(5.0, 92.0), Vector2(-5.0, 92.0),
	]), Color(0.25, 0.2, 0.26, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-2.0, 54.0), Vector2(1.0, 54.0),
		Vector2(0.0, 90.0), Vector2(-3.0, 90.0),
	]), Color(0.72, 0.53, 0.31, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11.0, 90.0), Vector2(11.0, 90.0),
		Vector2(14.0, 96.0), Vector2(-14.0, 96.0),
	]), Color(0.42, 0.3, 0.31, 1.0))
	draw_line(Vector2(-9.0, 93.0), Vector2(9.0, 93.0), Color(0.82, 0.61, 0.34, 1.0), 1.0)
