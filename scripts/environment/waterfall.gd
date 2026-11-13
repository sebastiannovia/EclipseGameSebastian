@tool
extends Node2D

const FRAME_RATE: float = 8.0
const WATERFALL_AMBIENCE: AudioStream = preload("res://assets/audio/sfx/stratos_v1/loops/waterfall_loop.wav")
const AUDIBLE_DISTANCE := 150.0

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


var _audio: AudioStreamPlayer2D = null
var _audio_fade: Tween = null
var _audio_active: bool = false


func _ready() -> void:
	_apply_settings()
	if Engine.is_editor_hint():
		return
	_audio = AudioStreamPlayer2D.new()
	_audio.name = "WaterfallAmbience"
	_audio.bus = "Ambience"
	_audio.max_distance = AUDIBLE_DISTANCE
	_audio.volume_db = -12.0
	var loop_stream: AudioStreamWAV = WATERFALL_AMBIENCE.duplicate() as AudioStreamWAV
	loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop_stream.loop_end = int(loop_stream.get_length() * loop_stream.mix_rate)
	_audio.stream = loop_stream
	add_child(_audio)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _audio == null:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var nearby: bool = player != null and global_position.distance_to(player.global_position) <= AUDIBLE_DISTANCE
	if nearby == _audio_active:
		return
	_audio_active = nearby
	if _audio_fade != null and _audio_fade.is_running():
		_audio_fade.kill()
	if nearby:
		if not _audio.playing:
			_audio.volume_db = -12.0
			_audio.play()
		_audio_fade = create_tween()
		_audio_fade.tween_property(_audio, "volume_db", 0.0, 0.22)
	else:
		_audio_fade = create_tween()
		_audio_fade.tween_property(_audio, "volume_db", -40.0, 0.22)
		_audio_fade.tween_callback(_audio.stop)

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
