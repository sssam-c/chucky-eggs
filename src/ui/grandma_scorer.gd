class_name GrandmaScorer
extends Control

@onready var _score_label: Label = %Score
@onready var _status_label: Label = %Status
@onready var _effects_label: Label = %Effects
@onready var _yolk_bar: Control = %YolkBar
@onready var _portrait: Control = %GrandmaPortrait
@onready var _hardware: Control = %StationHardware
@onready var _dialogue: PanelContainer = %Dialogue
@onready var _dialogue_text: Label = %DialogueText


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	render_appetite(0, 10)
	render_effects({})


func render_appetite(score: int, base_target: int, sulphurous_suppression := 0) -> void:
	var safe_base_target := maxi(1, base_target)
	var safe_suppression := clampi(
		int(sulphurous_suppression), 0, safe_base_target - 1
	)
	var effective_target := safe_base_target - safe_suppression
	var yolk_ratio := clampf(float(score) / float(safe_base_target), 0.0, 1.0)
	var suppression_ratio := float(safe_suppression) / float(safe_base_target)
	var combined_ratio := clampf(yolk_ratio + suppression_ratio, 0.0, 1.0)
	_score_label.text = "APPETITE %d / %d" % [score, effective_target]
	_score_label.accessibility_name = (
		"Grandma appetite: %d of %d points; %d Appetite suppressed for this day"
		% [score, effective_target, safe_suppression]
	)
	_yolk_bar.set_ratio(yolk_ratio)
	_yolk_bar.set_suppression_ratio(suppression_ratio)
	_portrait.set_hunger_ratio(combined_ratio)
	_hardware.set_appetite_ratio(combined_ratio)
	if combined_ratio >= 1.0:
		_status_label.text = "APPETITE MET"
	elif combined_ratio >= 0.66:
		_status_label.text = "ALMOST FED"
	elif combined_ratio > 0.0:
		_status_label.text = "STILL PECKISH"
	else:
		_status_label.text = "RAVENOUS"


func appetite_ratio() -> float:
	return _yolk_bar.ratio()


func sulphurous_suppression_ratio() -> float:
	return _yolk_bar.suppression_ratio()


func render_effects(effects: Dictionary) -> void:
	var lines: Array[String] = []
	var accessible: Array[String] = []
	var appetiser_charges := int(effects.get("appetiser_charges", 0))
	if appetiser_charges > 0:
		lines.append(
			"APPETISER ×2 · NEXT EGG"
			if appetiser_charges == 1
			else "APPETISER ×2 · %d EGGS" % appetiser_charges
		)
		accessible.append(
			"one Appetiser charge"
			if appetiser_charges == 1
			else "%s Appetiser charges" % _count_word(appetiser_charges)
		)
	var sulphurous_suppression := int(effects.get("sulphurous_suppression", 0))
	if sulphurous_suppression > 0:
		lines.append(
			"SULPHUROUS · −%d APPETITE THIS DAY" % sulphurous_suppression
		)
		accessible.append(
			"Sulphurous suppresses %d Appetite for the rest of this day"
			% sulphurous_suppression
		)
	var filling_reserve := int(effects.get("deceptively_filling_reserve", 0))
	if filling_reserve > 0:
		lines.append("FILLING · %d YOLK LEFT" % filling_reserve)
		accessible.append("Deceptively Filling has %d slow-release Yolk left" % filling_reserve)
	if lines.is_empty():
		_effects_label.text = "NO ACTIVE EGG EFFECTS"
		_effects_label.accessibility_name = "No active egg effects"
		return
	_effects_label.text = "\n".join(lines)
	_effects_label.accessibility_name = "; ".join(accessible)


func _count_word(value: int) -> String:
	match value:
		2:
			return "two"
		3:
			return "three"
	return str(value)


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
