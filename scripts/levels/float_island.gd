@tool
extends StaticBody2D
class_name FloatIsland

# Native atlas regions use the generated PNG artwork without procedural drawing.
const CUTOUT: Shader = preload("res://shaders/terrain_cutout.gdshader")
const LONG: Texture2D = preload("res://assets/art/terrain_redesign_v2/platform_long.tres")
const MEDIUM: Texture2D = preload("res://assets/art/terrain_redesign_v2/platform_medium.tres")
const SMALL: Texture2D = preload("res://assets/art/terrain_redesign_v2/platform_small.tres")
const SLAB: Texture2D = preload("res://assets/art/terrain_redesign_v2/rock_slab.tres")
const COLUMN: Texture2D = preload("res://assets/art/terrain_redesign_v2/rock_column.tres")
const CEILING: Texture2D = preload("res://assets/art/terrain_redesign_v2/rock_ceiling.tres")

# Retained for compatibility with existing scene properties.
@export var grass_color: Color = Color(0.52, 0.80, 0.38, 1.0)
@export var grass_lit_color: Color = Color(0.79, 0.95, 0.55, 1.0)
@export var dirt_color: Color = Color(0.36, 0.25, 0.44, 1.0)
@export var dirt_dark_color: Color = Color(0.26, 0.17, 0.33, 1.0)
@export var dirt_lit_color: Color = Color(0.47, 0.34, 0.56, 1.0)

@export_range(0.0, 60.0, 1.0) var skirt_depth: float = 22.0 ## how far the tapered underside hangs below the collider
@export_range(2.0, 20.0, 1.0) var grass_thickness: float = 7.0


var _artwork: Sprite2D
var _last_geometry: Array = []


func _ready() -> void:
	_update_artwork()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	_update_artwork()


func _update_artwork() -> void:
	var collider := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider == null or not collider.shape is RectangleShape2D:
		return
	var rect := collider.shape as RectangleShape2D
	var axis_x: float = collider.global_transform.x.length()
	var axis_y: float = collider.global_transform.y.length()
	if axis_x <= 0.001 or axis_y <= 0.001:
		return
	var islands: bool = get_parent() != null and get_parent().name == "Islands"
	var geometry: Array = [rect.size, collider.transform, axis_x, axis_y, islands, name, get_index()]
	if geometry == _last_geometry and is_instance_valid(_artwork):
		return
	_last_geometry = geometry
	if not is_instance_valid(_artwork):
		_artwork = Sprite2D.new()
		_artwork.name = "PlatformArtwork"
		_artwork.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_artwork.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
		var material := ShaderMaterial.new()
		material.shader = CUTOUT
		_artwork.material = material
		_artwork.z_index = -1
		add_child(_artwork)

	var texture: Texture2D = SMALL
	var surface_y := 58.0
	var solid_bottom := 210.0
	var world_width: float = rect.size.x * axis_x
	if islands:
		if world_width >= 240.0:
			texture = LONG
			surface_y = 62.0
		elif world_width >= 110.0:
			texture = MEDIUM
			surface_y = 63.0
	else:
		texture = SLAB
		surface_y = 20.0
		solid_bottom = 182.0
		if rect.size.y * axis_y > world_width:
			texture = COLUMN
			surface_y = 53.0
			solid_bottom = 373.0
		elif name == &"RockCeiling":
			texture = CEILING
			surface_y = 12.0
			solid_bottom = 82.0

	var scale_x: float = rect.size.x / texture.get_width()
	var scale_y: float = scale_x * axis_x / axis_y
	if not islands:
		# Fit the solid stone band to the collider; moss and tips extend outside it.
		scale_y = rect.size.y / (solid_bottom - surface_y)
	_artwork.texture = texture
	_artwork.rotation = collider.rotation
	_artwork.scale = collider.scale * Vector2(scale_x, scale_y)
	_artwork.flip_h = islands and get_index() % 2 == 1
	var offset_y: float = scale_y * (texture.get_height() * 0.5 - surface_y)
	_artwork.position = collider.transform * Vector2(0.0, -rect.size.y * 0.5 + offset_y)
