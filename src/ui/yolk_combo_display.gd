class_name YolkComboDisplay
extends Control

const YolkBallScene = preload("res://src/ui/yolk_ball.tscn")

@onready var _yolk_ball: Control = %YolkBall
@onready var _callout_label: Label = %CalloutLabel
@onready var _multiplier_label: Label = %MultiplierLabel
@onready var _token_layer: Control = %TokenLayer

var _ball_home_position := Vector2.ZERO
var _reduced_motion := false
var _merge_routes: Array[PackedVector2Array] = []
var _delivery_route := PackedVector2Array()

var route_trace_alpha := 0.0:
	set(value):
		route_trace_alpha = clampf(value, 0.0, 1.0)
		queue_redraw()


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
	_yolk_ball.scale = Vector2.ONE * visual_scale_for_yolk(0)
	_yolk_ball.modulate.a = 0.58
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
	drop.size = Vector2(112.0, 100.0) * visual_scale_for_yolk(base_yolk)
	drop.custom_minimum_size = drop.size
	drop.pivot_offset = drop.size * 0.5
	drop.global_position = origin_global - drop.size * 0.5
	if not _reduced_motion:
		_merge_routes.append(_curved_route(
			_to_local(origin_global), _to_local(ball_global_position()), 24.0
		))
		route_trace_alpha = 0.82
	return drop


func merge_yolk(subtotal: int) -> void:
	_yolk_ball.set_amount(subtotal)
	_yolk_ball.modulate.a = 1.0
	_yolk_ball.scale = Vector2.ONE * visual_scale_for_yolk(subtotal)


func show_multiplier(combo_count: int, total_yolk: int) -> void:
	_yolk_ball.set_amount(total_yolk)
	_yolk_ball.scale = Vector2.ONE * visual_scale_for_yolk(total_yolk)
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


func show_delivery_route(destination_global: Vector2) -> void:
	_merge_routes.clear()
	_delivery_route = _curved_route(
		_to_local(ball_global_position()), _to_local(destination_global), 36.0
	)
	route_trace_alpha = 0.92


func clear_route_trace() -> void:
	_merge_routes.clear()
	_delivery_route = PackedVector2Array()
	route_trace_alpha = 0.0


func has_route_trace() -> bool:
	return route_trace_alpha > 0.001 and (
		not _merge_routes.is_empty() or not _delivery_route.is_empty()
	)


func finish_delivery() -> void:
	reset_transient()


func ball_control() -> Control:
	return _yolk_ball


func ball_global_position() -> Vector2:
	return _yolk_ball.get_global_rect().get_center()


func ball_amount() -> int:
	return _yolk_ball.amount()


func ball_visual_scale() -> float:
	return _yolk_ball.scale.x


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
	clear_route_trace()
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


static func visual_scale_for_yolk(yolk: int) -> float:
	return clampf(0.22 + float(maxi(0, yolk)) * 0.19, 0.22, 2.0)


func _draw() -> void:
	if route_trace_alpha <= 0.001:
		return
	var shadow := Color(0.18, 0.055, 0.005, 0.52 * route_trace_alpha)
	var yolk := Color(1.0, 0.66, 0.06, 0.76 * route_trace_alpha)
	for route: PackedVector2Array in _merge_routes:
		if route.size() < 2:
			continue
		draw_polyline(route, shadow, 8.0, true)
		draw_polyline(route, yolk, 3.0, true)
	if _delivery_route.size() >= 2:
		draw_polyline(_delivery_route, shadow, 10.0, true)
		draw_polyline(_delivery_route, yolk, 4.0, true)


func _to_local(global_point: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * global_point


func _curved_route(start: Vector2, finish: Vector2, lift: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var control := (start + finish) * 0.5 - Vector2(0.0, lift)
	for point_index in range(25):
		var weight := float(point_index) / 24.0
		var inverse := 1.0 - weight
		points.append(
			inverse * inverse * start
			+ 2.0 * inverse * weight * control
			+ weight * weight * finish
		)
	return points
