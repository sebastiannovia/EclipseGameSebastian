extends CanvasLayer
class_name GrappleTutorial

const ACTION_CONFIRM := &"tutorial_confirm"
const ACTION_RESTART := &"restart"

var _pending_dismiss: bool = false
var _waiting_for_confirm_release: bool = false
@onready var _message: Label = get_node("Panel/Content/Message") as Label
@onready var _continue: Button = get_node("Panel/Content/Continue") as Button
@onready var _key_label: Label = get_node("Panel/Content/KeyRow/Keycap/E") as Label
@onready var _hold_label: Label = get_node("Panel/Content/KeyRow/HoldLabel") as Label


func _ready() -> void:
	_continue.pressed.connect(_on_continue_pressed)
	visible = false


func _exit_tree() -> void:
	var scene_tree: SceneTree = get_tree()
	if scene_tree != null:
		scene_tree.paused = false


func show_tutorial() -> void:
	_pending_dismiss = false
	_waiting_for_confirm_release = false
	visible = true
	get_tree().paused = true
	_continue.grab_focus()


func set_controller_prompts(controller: bool) -> void:
	_key_label.text = "RT" if controller else "E"
	_hold_label.text = "— HOLD TO GRAPPLE"
	_message.text = "Hold the trigger to grab a nearby Sky Skimmer\nand swing across the sky."
	_continue.text = "CONTINUE"


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventJoypadButton and event.is_pressed():
		set_controller_prompts(true)
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.35:
		set_controller_prompts(true)
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		set_controller_prompts(false)

	if event.is_action_pressed(ACTION_RESTART):
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		get_tree().call_deferred("reload_current_scene")
		return
	if event.is_action_pressed(ACTION_CONFIRM):
		_pending_dismiss = false
		_waiting_for_confirm_release = true
		get_viewport().set_input_as_handled()
	elif _waiting_for_confirm_release and event.is_action_released(ACTION_CONFIRM):
		_waiting_for_confirm_release = false
		_pending_dismiss = true
		get_viewport().set_input_as_handled()


func _on_continue_pressed() -> void:
	_pending_dismiss = true
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not _pending_dismiss or _waiting_for_confirm_release or Input.is_action_pressed(ACTION_CONFIRM):
		return
	_pending_dismiss = false
	_finish_tutorial()


func _finish_tutorial() -> void:
	visible = false
	get_tree().paused = false
