class_name BeltConditionDisplay
extends Control

const MOUNT_BOLT_POSITIONS := [
	Vector2(10.0, 10.0),
	Vector2(10.0, 36.0),
	Vector2(606.0, 10.0),
	Vector2(606.0, 36.0),
]

@onready var _label: Label = %BeltConditionLabel
@onready var _bar: ProgressBar = %BeltConditionBar

var _current_condition := 0
var _maximum_condition := 1


func _ready() -> void:
	render_condition(_current_condition, _maximum_condition)
	queue_redraw()


func _draw() -> void:
	# This is a physical service gauge mounted over the conveyor's roller apron,
	# so it shares the machine's iron, brass, highlights, and visible fasteners.
	var face := Rect2(Vector2.ZERO, size)
	draw_rect(face, Color("090a0b"), true)
	draw_rect(face.grow(-2.0), Color("252629"), true)
	draw_rect(face.grow(-2.0), Color("754126"), false, 3.0)
	draw_line(Vector2(4.0, 4.0), Vector2(size.x - 4.0, 4.0), Color("ad6532"), 2.0)
	draw_line(
		Vector2(4.0, size.y - 4.0),
		Vector2(size.x - 4.0, size.y - 4.0),
		Color("111214"),
		2.0
	)

	var label_recess := Rect2(18.0, 8.0, 204.0, size.y - 16.0)
	draw_rect(label_recess, Color("151617"), true)
	draw_rect(label_recess, Color("4f311f"), false, 2.0)

	for bolt: Vector2 in MOUNT_BOLT_POSITIONS:
		draw_circle(bolt, 4.5, Color("0b0c0d"))
		draw_circle(bolt, 3.2, Color("b56c32"))
		draw_line(bolt + Vector2(-1.8, 0.0), bolt + Vector2(1.8, 0.0), Color("3a2418"), 1.0)


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


func mount_bolt_count() -> int:
	return MOUNT_BOLT_POSITIONS.size()
