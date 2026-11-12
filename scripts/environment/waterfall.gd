@tool
extends Node2D

const FRAME_RATE: float = 8.0

@export_range(0.1, 30.0, 0.1) var animation_speed: float = 8.0:
	set(value):
		animation_speed = maxf(value, 0.1)
		_apply_settings()

@export_range(0.05, 2.0, 0.001) var visual_scale: float = 1.0:
	set(value):
		visual_scale = maxf(value, 0.05)
		_apply_settings()

@export var flip_h: bool = false:
	set(value):
		flip_h = value
		_apply_settings()

@export_range(0, 7, 1) var start_frame: int = 0:
	set(value):
		start_frame = posmod(value, 8)
		_apply_settings()


func _ready() -> void:
	_apply_settings()


func _apply_settings() -> void:
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	sprite.scale = Vector2.ONE
	scale = Vector2(visual_scale * (-1.0 if flip_h else 1.0), visual_scale)
	sprite.speed_scale = animation_speed / FRAME_RATE
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation("flow"):
		return
	sprite.play("flow")
	sprite.frame = posmod(start_frame, sprite.sprite_frames.get_frame_count("flow"))
