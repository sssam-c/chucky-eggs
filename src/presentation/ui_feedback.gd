class_name UIFeedback
extends Node

signal feedback_presented(kind: String)

const CrunchAudio = preload("res://src/presentation/crunch_audio.gd")
const MotionTokens = preload("res://src/presentation/motion_tokens.gd")

@onready var _focus_player: AudioStreamPlayer = $Audio/Focus
@onready var _press_player: AudioStreamPlayer = $Audio/Press
@onready var _confirm_player: AudioStreamPlayer = $Audio/Confirm
@onready var _reject_player: AudioStreamPlayer = $Audio/Reject
@onready var _panel_player: AudioStreamPlayer = $Audio/Panel

var _registered_controls: Array[BaseButton] = []
var _control_tweens: Dictionary = {}
var _animated_controls: Dictionary = {}
var _muted := false
var _reduced_motion := false
var _last_feedback_kind := ""


func _ready() -> void:
	_focus_player.stream = CrunchAudio.ui_focus()
	_press_player.stream = CrunchAudio.ui_press()
	_confirm_player.stream = CrunchAudio.ui_confirm()
	_reject_player.stream = CrunchAudio.ui_reject()
	_panel_player.stream = CrunchAudio.ui_panel()


func configure(controls: Array) -> void:
	for candidate in controls:
		var control := candidate as BaseButton
		if control == null or is_control_registered(control):
			continue
		_registered_controls.append(control)
		control.focus_entered.connect(_on_focus_entered.bind(control))
		control.button_down.connect(_on_button_down.bind(control))
		control.button_up.connect(_on_button_up.bind(control))
		control.mouse_exited.connect(_on_pointer_exited.bind(control))


func unconfigure(controls: Array) -> void:
	for candidate in controls:
		var control := candidate as BaseButton
		if control == null:
			continue
		_kill_control_tween(control)
		_animated_controls.erase(control.get_instance_id())
		_registered_controls.erase(control)


func set_muted(muted: bool) -> void:
	_muted = muted
	if not muted:
		return
	for player: AudioStreamPlayer in _players():
		player.stop()


func is_muted() -> bool:
	return _muted


func set_reduced_motion(reduced: bool) -> void:
	_reduced_motion = reduced
	if reduced:
		cancel_all()


func is_reduced_motion() -> bool:
	return _reduced_motion


func is_control_registered(control: BaseButton) -> bool:
	return control in _registered_controls


func registered_control_count() -> int:
	return _registered_controls.size()


func is_control_animating(control: Control) -> bool:
	var tween: Tween = _control_tweens.get(control.get_instance_id())
	return tween != null and tween.is_valid() and tween.is_running()


func has_active_motion() -> bool:
	for tween: Tween in _control_tweens.values():
		if tween != null and tween.is_valid() and tween.is_running():
			return true
	return false


func last_feedback_kind() -> String:
	return _last_feedback_kind


func present_value(control: Control, kind: String, accent: Color) -> void:
	_record(kind)
	if _reduced_motion or not is_instance_valid(control):
		return
	_pulse(control, accent, MotionTokens.VALUE_SCALE)


func confirm(control: Control) -> void:
	_record("confirm")
	_play(_confirm_player)
	if _reduced_motion or not is_instance_valid(control):
		return
	_pulse(control, Color(0.58, 1.0, 0.89, 1.0), MotionTokens.FOCUS_SCALE)


func reject(control: Control) -> void:
	_record("reject")
	_play(_reject_player)
	if _reduced_motion or not is_instance_valid(control):
		return
	_kill_control_tween(control)
	control.pivot_offset = control.size * 0.5
	control.rotation = 0.0
	control.modulate = Color(1.0, 0.58, 0.35, 1.0)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_store_tween(control, tween)
	tween.tween_property(control, "rotation", -0.012, MotionTokens.SNAP * 0.5)
	tween.tween_property(control, "rotation", 0.012, MotionTokens.SNAP)
	tween.tween_property(control, "rotation", 0.0, MotionTokens.SETTLE)
	tween.parallel().tween_property(control, "modulate", Color.WHITE, MotionTokens.SETTLE)


func panel_opened() -> void:
	_record("panel")
	_play(_panel_player)


func cancel_all() -> void:
	for tween: Tween in _control_tweens.values():
		if tween != null and tween.is_valid():
			tween.kill()
	_control_tweens.clear()
	for candidate in _animated_controls.values():
		var animated_control := candidate as Control
		if not is_instance_valid(animated_control):
			continue
		animated_control.scale = Vector2.ONE
		animated_control.rotation = 0.0
		animated_control.modulate = Color.WHITE
	_animated_controls.clear()
	for control: BaseButton in _registered_controls:
		if not is_instance_valid(control):
			continue
		control.scale = Vector2.ONE
		control.rotation = 0.0
		control.modulate = Color.WHITE


func _on_focus_entered(control: BaseButton) -> void:
	_play(_focus_player)
	if _reduced_motion or control.disabled:
		return
	_kill_control_tween(control)
	control.pivot_offset = control.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_store_tween(control, tween)
	tween.tween_property(control, "scale", MotionTokens.FOCUS_SCALE, MotionTokens.SNAP)
	tween.tween_property(control, "scale", Vector2.ONE, MotionTokens.SETTLE)


func _on_button_down(control: BaseButton) -> void:
	_play(_press_player)
	if _reduced_motion or control.disabled:
		return
	_kill_control_tween(control)
	control.pivot_offset = control.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_store_tween(control, tween)
	tween.tween_property(control, "scale", MotionTokens.PRESS_SCALE, MotionTokens.SNAP)


func _on_button_up(control: BaseButton) -> void:
	_settle_control(control)


func _on_pointer_exited(control: BaseButton) -> void:
	_settle_control(control)


func _settle_control(control: BaseButton) -> void:
	if _reduced_motion or control.disabled:
		control.scale = Vector2.ONE
		return
	_kill_control_tween(control)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_store_tween(control, tween)
	tween.tween_property(control, "scale", Vector2.ONE, MotionTokens.SETTLE)


func _pulse(control: Control, accent: Color, peak_scale: Vector2) -> void:
	_kill_control_tween(control)
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE
	control.modulate = accent
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_store_tween(control, tween)
	tween.tween_property(control, "scale", peak_scale, MotionTokens.SNAP)
	tween.tween_property(control, "scale", Vector2.ONE, MotionTokens.SETTLE)
	tween.parallel().tween_property(control, "modulate", Color.WHITE, MotionTokens.SETTLE)


func _store_tween(control: Control, tween: Tween) -> void:
	var control_id := control.get_instance_id()
	_control_tweens[control_id] = tween
	_animated_controls[control_id] = control
	tween.finished.connect(func() -> void:
		if _control_tweens.get(control_id) == tween:
			_control_tweens.erase(control_id)
			_animated_controls.erase(control_id)
	, CONNECT_ONE_SHOT)


func _kill_control_tween(control: Control) -> void:
	var control_id := control.get_instance_id()
	var tween: Tween = _control_tweens.get(control_id)
	if tween != null and tween.is_valid():
		tween.kill()
	_control_tweens.erase(control_id)


func _record(kind: String) -> void:
	_last_feedback_kind = kind
	feedback_presented.emit(kind)


func _play(player: AudioStreamPlayer) -> void:
	if _muted:
		return
	player.stop()
	player.play()


func _players() -> Array[AudioStreamPlayer]:
	return [_focus_player, _press_player, _confirm_player, _reject_player, _panel_player]
