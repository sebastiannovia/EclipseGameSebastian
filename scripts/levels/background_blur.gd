extends Node2D

@export_range(0.0, 8.0, 0.05) var blur_radius: float = 7.0

var _blur_material: ShaderMaterial


func _ready() -> void:
	_apply_blur_radius()


func _apply_blur_radius() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var background := parent.get_node_or_null("Background") as Node2D
	if background == null:
		return
	_blur_material = null
	_apply_to_background(background)


func _apply_to_background(node: Node) -> void:
	if node is Sprite2D or node is AnimatedSprite2D:
		var canvas_item := node as CanvasItem
		if _blur_material == null:
			_blur_material = canvas_item.material as ShaderMaterial
		if _blur_material != null:
			canvas_item.material = _blur_material
			canvas_item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			_blur_material.set_shader_parameter("blur_radius", blur_radius)

	for child in node.get_children():
		_apply_to_background(child)
