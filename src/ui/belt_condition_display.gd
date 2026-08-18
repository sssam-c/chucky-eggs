class_name BeltConditionDisplay
extends Control

@onready var _label: Label = %BeltConditionLabel
@onready var _bar: ProgressBar = %BeltConditionBar

var _current_condition := 0
var _maximum_condition := 1


func _ready() -> void:
	render_condition(_current_condition, _maximum_condition)


func render_condition(current: int, maximum: int) -> void:
	_current_condition = maxi(current, 0)
	_maximum_condition = maxi(maximum, 1)
	if not is_instance_valid(_label) or not is_instance_valid(_bar):
		return
	_label.text = "BELT CONDITION  %d / %d" % [_current_condition, _maximum_condition]
	_bar.max_value = float(_maximum_condition)
	_bar.value = float(_current_condition)
	_bar.accessibility_name = "Belt Condition: %d of %d" % [
		_current_condition, _maximum_condition,
	]
	tooltip_text = "%d belt movements remain" % _current_condition


func current_condition() -> int:
	return _current_condition


func maximum_condition() -> int:
	return _maximum_condition
