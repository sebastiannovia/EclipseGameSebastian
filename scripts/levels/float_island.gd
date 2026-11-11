extends StaticBody2D
class_name FloatIsland

# Temporary art for a level platform: a grass-topped floating island drawn from
# the platform's own RectangleShape2D, so the visible geometry can never drift
# out of step with the collision box.
#
# Convention inherited from the movement bench: the StaticBody2D sits at the
# centre of its rectangle and the rectangle is 40 px thick, so the walking
# surface is 20 px above the node. All drawing here happens in that same local
# space. The dirt skirt hangs *below* the collider and the grass cap sits on the
# collider's own top face: nothing the player can stand on is invisible, and
# nothing visible is solid.

@export var grass_color: Color = Color(0.52, 0.80, 0.38, 1.0)
@export var grass_lit_color: Color = Color(0.79, 0.95, 0.55, 1.0)
@export var dirt_color: Color = Color(0.36, 0.25, 0.44, 1.0)
@export var dirt_dark_color: Color = Color(0.26, 0.17, 0.33, 1.0)
@export var dirt_lit_color: Color = Color(0.47, 0.34, 0.56, 1.0)

@export_range(0.0, 60.0, 1.0) var skirt_depth: float = 22.0 ## how far the tapered underside hangs below the collider
@export_range(2.0, 20.0, 1.0) var grass_thickness: float = 7.0

var _half_size: Vector2 = Vector2.ZERO
var _shape_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		push_warning("%s has no CollisionShape2D to match its artwork to." % name)
		return
	var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
	if rect == null:
		push_warning("%s collision shape is not a RectangleShape2D." % name)
		return
	_half_size = rect.size * 0.5
	_shape_offset = shape_node.position
	queue_redraw()


func _draw() -> void:
	if _half_size == Vector2.ZERO:
		return
	draw_set_transform(_shape_offset, 0.0, Vector2.ONE)

	var left: float = -_half_size.x
	var right: float = _half_size.x
	var top: float = -_half_size.y
	var bottom: float = _half_size.y
	var skirt_y: float = bottom + skirt_depth
	var taper: float = minf(14.0, _half_size.x * 0.45)

	# Dirt body: full width at the walking surface, tapering inwards underneath.
	draw_colored_polygon(PackedVector2Array([
		Vector2(left, top),
		Vector2(right, top),
		Vector2(right, bottom - 5.0),
		Vector2(right - taper, skirt_y),
		Vector2(left + taper, skirt_y),
		Vector2(left, bottom - 5.0),
	]), dirt_color)

	# Shaded lower half, so the islands read as volumes and not as rectangles.
	draw_colored_polygon(PackedVector2Array([
		Vector2(left, bottom - 6.0),
		Vector2(right, bottom - 6.0),
		Vector2(right - taper, skirt_y),
		Vector2(left + taper, skirt_y),
	]), dirt_dark_color)

	# Lit rim down the left face: the sun sits on the left of every level view.
	# Kept as two simple convex shapes; a single five-point strip here crossed
	# itself where the taper began and the renderer refused to triangulate it.
	draw_colored_polygon(PackedVector2Array([
		Vector2(left, top + grass_thickness),
		Vector2(left + 4.0, top + grass_thickness),
		Vector2(left + 4.0, bottom - 5.0),
		Vector2(left, bottom - 5.0),
	]), dirt_lit_color)

	draw_colored_polygon(PackedVector2Array([
		Vector2(left, bottom - 5.0),
		Vector2(left + taper, skirt_y),
		Vector2(left + taper, bottom - 5.0),
	]), dirt_lit_color)

	# Grass cap: exactly the collider's width, so the visual edge is the real edge.
	draw_colored_polygon(PackedVector2Array([
		Vector2(left, top),
		Vector2(right, top),
		Vector2(right, top + grass_thickness),
		Vector2(left, top + grass_thickness),
	]), grass_color)

	# Bright band along the walking surface: the line the feet actually land on.
	draw_colored_polygon(PackedVector2Array([
		Vector2(left, top),
		Vector2(right, top),
		Vector2(right, top + 2.0),
		Vector2(left, top + 2.0),
	]), grass_lit_color)

	_draw_tufts(left, right, top)


## A few blades on each end of the cap: they break the straight top edge and
## make the platform edges obvious against the sky.
func _draw_tufts(left: float, right: float, top: float) -> void:
	var tuft_width: float = 3.0
	var tuft_height: float = 4.0
	for offset in 3:
		var x: float = left + 4.0 + offset * (tuft_width + 2.0)
		if x + tuft_width > right - 2.0:
			break
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, top),
			Vector2(x + tuft_width, top),
			Vector2(x + tuft_width * 0.5, top - tuft_height),
		]), grass_lit_color)
	for offset in 3:
		var x: float = right - 4.0 - tuft_width - offset * (tuft_width + 2.0)
		if x < left + 2.0:
			break
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, top),
			Vector2(x + tuft_width, top),
			Vector2(x + tuft_width * 0.5, top - tuft_height),
		]), grass_color)
