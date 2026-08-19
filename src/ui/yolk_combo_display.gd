class_name YolkComboDisplay
extends Control

const YolkBallScene = preload("res://src/ui/yolk_ball.tscn")

@onready var _yolk_ball: Control = %YolkBall
@onready var _callout_label: Label = %CalloutLabel
@onready var _multiplier_label: Label = %MultiplierLabel
@onready var _token_layer: Control = %TokenLayer

var _ball_home_position := Vector2.ZERO
var _reduced_motion := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ball_home_position = _yolk_ball.position
	_yolk_ball.pivot_offset = _yolk_ball.size * 0.5
	reset_transient()


func begin_pool(combo_count: int) -> void:
	reset_transient()
	visible = true
	_yolk_ball.visible = true
	_yolk_ball.set_amount(0)
	_yolk_ball.set_reduced_motion(_reduced_motion)
	accessibility_name = "Yolk from %d broken egg%s" % [
		maxi(1, combo_count), "s" if combo_count != 1 else "",
	]


func create_yolk_drop(origin_global: Vector2, base_yolk: int) -> Control:
	var drop: Control = YolkBallScene.instantiate()
	_token_layer.add_child(drop)
	drop.set_compact(true)
	drop.set_amount(base_yolk)
	drop.set_reduced_motion(_reduced_motion)
	drop.size = Vector2(48.0, 44.0)
	drop.custom_minimum_size = drop.size
	drop.pivot_offset = drop.size * 0.5
	drop.global_position = origin_global - drop.size * 0.5
	return drop


func merge_yolk(subtotal: int) -> void:
	_yolk_ball.set_amount(subtotal)
	var growth := clampf(log(float(maxi(1, subtotal)) + 1.0) * 0.11, 0.0, 0.34)
	_yolk_ball.scale = Vector2.ONE * (1.0 + growth)


func show_multiplier(combo_count: int, total_yolk: int) -> void:
	_yolk_ball.set_amount(total_yolk)
	if combo_count >= 2:
		_callout_label.text = combo_callout(combo_count)
		_multiplier_label.text = "×%d" % combo_count
		accessibility_name = "%s %d Yolk" % [_callout_label.text, maxi(0, total_yolk)]
		accessibility_description = (
			"This tap broke %d eggs, multiplying their combined Yolk by %d."
			% [combo_count, combo_count]
		)
	else:
		_callout_label.text = ""
		_multiplier_label.text = ""
		accessibility_name = "%d Yolk" % maxi(0, total_yolk)
		accessibility_description = "Yolk collected from this tap."


func begin_delivery() -> Control:
	_callout_label.visible = false
	_multiplier_label.visible = false
	return _yolk_ball


func finish_delivery() -> void:
	reset_transient()


func ball_control() -> Control:
	return _yolk_ball


func ball_global_position() -> Vector2:
	return _yolk_ball.get_global_rect().get_center()


func ball_amount() -> int:
	return _yolk_ball.amount()


func amount_text() -> String:
	return _yolk_ball.amount_text()


func callout_text() -> String:
	return _callout_label.text


func multiplier_text() -> String:
	return _multiplier_label.text


func set_reduced_motion(reduced: bool) -> void:
	_reduced_motion = reduced
	_yolk_ball.set_reduced_motion(reduced)
	for token: Node in _token_layer.get_children():
		if token.has_method("set_reduced_motion"):
			token.set_reduced_motion(reduced)


func is_shimmer_active() -> bool:
	return _yolk_ball.is_shimmer_active()


func reset_transient() -> void:
	visible = false
	_callout_label.visible = true
	_multiplier_label.visible = true
	_callout_label.text = ""
	_multiplier_label.text = ""
	_yolk_ball.visible = true
	_yolk_ball.position = _ball_home_position
	_yolk_ball.scale = Vector2.ONE
	_yolk_ball.rotation = 0.0
	_yolk_ball.modulate = Color.WHITE
	_yolk_ball.set_amount(0)
	accessibility_name = ""
	accessibility_description = ""
	if _token_layer != null:
		for token: Node in _token_layer.get_children():
			token.queue_free()


static func combo_callout(combo_count: int) -> String:
	match combo_count:
		2:
			return "DOUBLE YOLKER!"
		3:
			return "TRIPLE YOLKER!"
		4:
			return "QUADRUPLE YOLKER!"
		5:
			return "QUINTUPLE YOLKER!"
		_:
			return "%d× YOLKER!" % maxi(2, combo_count)
