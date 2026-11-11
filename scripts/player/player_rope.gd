extends Node2D
class_name PlayerRope

# Draws the rope from the player's chest to the creature it is hooked to.
#
# It is a direct child of the body (not of Visuals) because Visuals mirrors its
# children left-right to turn the character around, and a mirrored rope would
# point at the wrong creature. It reads the player and the creature and decides
# nothing: no rope is drawn at all while the hook is not attached.

const ROPE_TIE := Vector2(0.0, -14.0) ## must match Player.ROPE_TIE

@export var rope_color: Color = Color(0.93, 0.85, 0.66, 1.0)
@export var taut_color: Color = Color(1.0, 0.7, 0.3, 1.0)
@export var hook_color: Color = Color(1.0, 0.86, 0.46, 1.0)

@onready var _player: Player = get_parent() as Player


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _player == null or not _player.is_grappling:
		return
	var creature: Node2D = _player.get_grapple_creature()
	if creature == null:
		return

	var from: Vector2 = ROPE_TIE
	var to: Vector2 = _player.get_anchor_position() - global_position

	# The rope is rigid, so the drawn span is the rope length whenever the swing
	# is pulling on it. Nearer means slack, and slack reads as a duller line.
	var length: float = maxf(1.0, _player.get_rope_length())
	var taut: float = clampf((to - from).length() / length, 0.0, 1.0)
	var color: Color = rope_color.lerp(taut_color, taut)

	draw_line(from, to, color, 2.0)
	draw_line(from, to, Color(1.0, 0.95, 0.85, 0.35), 1.0)
	draw_circle(to, 2.5, hook_color)
	draw_circle(from, 1.8, Color(rope_color, 0.85))
