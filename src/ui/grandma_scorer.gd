class_name GrandmaScorer
extends Control

@onready var _score_label: Label = %Score
@onready var _status_label: Label = %Status
@onready var _yolk_bar: Control = %YolkBar
@onready var _portrait: Control = %GrandmaPortrait
@onready var _hardware: Control = %StationHardware
@onready var _dialogue: PanelContainer = %Dialogue
@onready var _dialogue_text: Label = %DialogueText


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	render_appetite(0, 10)


func render_appetite(score: int, target: int) -> void:
	var safe_target := maxi(1, target)
	var ratio := clampf(float(score) / float(safe_target), 0.0, 1.0)
	_score_label.text = "APPETITE %d / %d" % [score, target]
	_score_label.accessibility_name = "Grandma appetite: %d of %d points" % [score, target]
	_yolk_bar.set_ratio(ratio)
	_portrait.set_hunger_ratio(ratio)
	_hardware.set_appetite_ratio(ratio)
	if ratio >= 1.0:
		_status_label.text = "APPETITE MET"
	elif ratio >= 0.66:
		_status_label.text = "ALMOST FED"
	elif ratio > 0.0:
		_status_label.text = "STILL PECKISH"
	else:
		_status_label.text = "RAVENOUS"


func appetite_ratio() -> float:
	return _yolk_bar.ratio()


func score_target_global_position() -> Vector2:
	return _portrait.bowl_global_position()


func feedback_control() -> Control:
	return _yolk_bar


func set_status(status: String) -> void:
	_status_label.text = status


func show_dialogue(dialogue: String) -> void:
	_dialogue_text.text = dialogue
	_dialogue.visible = not dialogue.is_empty()


func hide_dialogue() -> void:
	_dialogue.visible = false


func has_status_space() -> bool:
	return is_instance_valid(_status_label)


func has_dialogue_space() -> bool:
	return is_instance_valid(_dialogue) and is_instance_valid(_dialogue_text)


func set_reduced_motion(reduced: bool) -> void:
	_portrait.set_reduced_motion(reduced)


func is_idle_motion_active() -> bool:
	return _portrait.is_idle_motion_active()
