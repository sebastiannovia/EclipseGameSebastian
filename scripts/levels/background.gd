extends Node2D
class_name LevelBackground

# Temporary environment for the level: a warm gradient sky, a low sun, two
# ranges of purple mountains, hazy floating islands and drifting clouds.
#
# Everything is drawn by this one node from a seeded generator, so the level
# needs no art files and the same level always looks the same. Depth comes from
# parallax ratios: a layer is drawn offset by `camera * ratio`, so it slides
# across the view at (1 - ratio) of the player's speed. No Parallax2D setup, and
# the result does not depend on the viewport size.

@export_range(-10000.0, 10000.0, 1.0) var content_left: float = -560.0
@export_range(-10000.0, 10000.0, 1.0) var content_right: float = 3100.0
@export var generator_seed: int = 20261110

const FAR_RATIO: float = 0.18    ## distant mountains
const MID_RATIO: float = 0.34    ## near mountains
const ISLAND_RATIO: float = 0.52 ## background floating islands
const CLOUD_RATIO: float = 0.70  ## clouds
const SUN_RATIO: float = 0.86    ## the sun almost keeps up with the camera

const SKY_TOP := Color(0.23, 0.14, 0.30, 1.0)
const SKY_UPPER := Color(0.58, 0.27, 0.28, 1.0)
const SKY_MID := Color(0.93, 0.54, 0.24, 1.0)
const SKY_LOW := Color(1.00, 0.83, 0.50, 1.0)

const MOUNTAIN_FAR := Color(0.38, 0.28, 0.48, 1.0)
const MOUNTAIN_NEAR := Color(0.28, 0.19, 0.35, 1.0)
const ISLAND_DIRT := Color(0.33, 0.24, 0.40, 1.0)
const ISLAND_GRASS := Color(0.46, 0.66, 0.40, 1.0)
const CLOUD_COLOR := Color(1.0, 0.87, 0.64, 0.30)
const SUN_CORE := Color(1.0, 0.92, 0.72, 0.34)
const SUN_HALO := Color(1.0, 0.74, 0.42, 0.12)

const CLOUD_DRIFT: float = 7.0 ## px/s the clouds slide independently of the camera
const MARGIN: float = 40.0     ## sky overdraw so no band edge is ever on screen

var _screen_center: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0

var _far_range: PackedVector2Array = PackedVector2Array()
var _near_range: PackedVector2Array = PackedVector2Array()
var _islands: Array = []
var _clouds: Array = []


func _ready() -> void:
	_generate()


func _process(delta: float) -> void:
	_elapsed += delta
	var camera: Camera2D = get_viewport().get_camera_2d() as Camera2D
	if camera != null:
		# The screen centre, not the node position: limits and margins move the
		# screen centre, and the layers have to follow what is actually on screen.
		_screen_center = camera.get_screen_center_position()
	queue_redraw()


func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = generator_seed

	_far_range = _build_range(rng, 168.0, -96.0, -8.0, 230.0)
	_near_range = _build_range(rng, 205.0, -18.0, 62.0, 160.0)

	for index in 16:
		var half_width: float = rng.randf_range(16.0, 44.0)
		var centre := Vector2(
			rng.randf_range(content_left, content_right),
			rng.randf_range(-150.0, 92.0)
		)
		_islands.append([centre, half_width, rng.randf_range(12.0, 24.0)])

	for index in 13:
		var centre := Vector2(
			rng.randf_range(content_left, content_right),
			rng.randf_range(-196.0, -66.0)
		)
		_clouds.append([centre, rng.randf_range(0.7, 1.7)])


## A mountain silhouette: base at base_y, peaks between peak_min and peak_max,
## closing the polygon at both ends of the content span.
func _build_range(rng: RandomNumberGenerator, base_y: float, peak_min: float, peak_max: float, step: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(content_left - 60.0, base_y)])
	var x: float = content_left
	while x < content_right:
		x += step * rng.randf_range(0.7, 1.3)
		points.append(Vector2(x - step * 0.5, rng.randf_range(peak_min + 42.0, base_y - 14.0)))
		points.append(Vector2(x, rng.randf_range(peak_min, peak_max)))
	points.append(Vector2(content_right + 60.0, base_y))
	return points


func _draw() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var centre: Vector2 = _screen_center

	_draw_sky(centre, view)

	draw_set_transform(centre * SUN_RATIO + Vector2(-90.0, -26.0))
	_draw_sun()

	draw_set_transform(centre * FAR_RATIO)
	draw_colored_polygon(_far_range, MOUNTAIN_FAR)

	draw_set_transform(centre * MID_RATIO)
	draw_colored_polygon(_near_range, MOUNTAIN_NEAR)

	draw_set_transform(centre * ISLAND_RATIO)
	for island in _islands:
		_draw_background_island(island[0] as Vector2, float(island[1]), float(island[2]))

	draw_set_transform(centre * CLOUD_RATIO + Vector2(_elapsed * CLOUD_DRIFT, 0.0))
	for cloud in _clouds:
		_draw_cloud(cloud[0] as Vector2, float(cloud[1]))

	draw_set_transform(Vector2.ZERO)


## Three stacked bands with vertex colours, so the horizon is a gradient and not
## a hard line. The bands follow the screen, so the sky never runs out.
func _draw_sky(centre: Vector2, view: Vector2) -> void:
	_draw_band(centre, view, 0.0, 0.40, SKY_TOP, SKY_UPPER)
	_draw_band(centre, view, 0.40, 0.66, SKY_UPPER, SKY_MID)
	_draw_band(centre, view, 0.66, 1.0, SKY_MID, SKY_LOW)


func _draw_band(centre: Vector2, view: Vector2, from: float, to: float, top_color: Color, bottom_color: Color) -> void:
	var top: float = centre.y - view.y * 0.5 + view.y * from
	var bottom: float = centre.y - view.y * 0.5 + view.y * to
	var left: float = centre.x - view.x * 0.5 - MARGIN
	var right: float = centre.x + view.x * 0.5 + MARGIN
	draw_polygon(
		PackedVector2Array([Vector2(left, top), Vector2(right, top), Vector2(right, bottom), Vector2(left, bottom)]),
		PackedColorArray([top_color, top_color, bottom_color, bottom_color])
	)


func _draw_sun() -> void:
	draw_circle(Vector2.ZERO, 150.0, Color(SUN_HALO.r, SUN_HALO.g, SUN_HALO.b, 0.07))
	draw_circle(Vector2.ZERO, 104.0, Color(SUN_HALO.r, SUN_HALO.g, SUN_HALO.b, 0.10))
	draw_circle(Vector2.ZERO, 66.0, SUN_HALO)
	draw_circle(Vector2.ZERO, 34.0, Color(SUN_CORE.r, SUN_CORE.g, SUN_CORE.b, 0.24))
	draw_circle(Vector2.ZERO, 18.0, SUN_CORE)


func _draw_background_island(centre: Vector2, half_width: float, depth: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		centre + Vector2(-half_width, 0.0),
		centre + Vector2(half_width, 0.0),
		centre + Vector2(half_width, depth * 0.55),
		centre + Vector2(half_width * 0.45, depth),
		centre + Vector2(-half_width * 0.4, depth),
		centre + Vector2(-half_width, depth * 0.55),
	]), ISLAND_DIRT)
	draw_colored_polygon(PackedVector2Array([
		centre + Vector2(-half_width, 0.0),
		centre + Vector2(half_width, 0.0),
		centre + Vector2(half_width, 3.5),
		centre + Vector2(-half_width, 3.5),
	]), ISLAND_GRASS)


func _draw_cloud(centre: Vector2, scale: float) -> void:
	var puffs := PackedVector2Array([Vector2(-26.0, 0.0), Vector2(-9.0, -9.0), Vector2(9.0, -4.0), Vector2(25.0, 2.0)])
	var radii := PackedFloat32Array([13.0, 17.0, 14.0, 11.0])
	for index in puffs.size():
		draw_circle(centre + puffs[index] * scale, radii[index] * scale, CLOUD_COLOR)
