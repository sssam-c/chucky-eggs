class_name YolkBall
extends Control

@onready var _amount_label: Label = %AmountLabel

var _amount := 0
var _shimmer_phase := 0.0
var _reduced_motion := false
var _compact := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_amount()
	queue_redraw()


func _process(delta: float) -> void:
	if not is_shimmer_active():
		return
	_shimmer_phase = fmod(_shimmer_phase + delta * 2.6, TAU)
	queue_redraw()


func set_amount(amount: int) -> void:
	_amount = maxi(0, amount)
	_refresh_amount()
	queue_redraw()


func amount() -> int:
	return _amount


func amount_text() -> String:
	return _amount_label.text


func set_compact(compact: bool) -> void:
	_compact = compact
	_amount_label.add_theme_font_size_override("font_size", 19 if compact else 34)
	queue_redraw()


func set_reduced_motion(reduced: bool) -> void:
	_reduced_motion = reduced
	queue_redraw()


func is_shimmer_active() -> bool:
	return is_visible_in_tree() and not _reduced_motion


func _refresh_amount() -> void:
	if _amount_label == null:
		return
	_amount_label.text = str(_amount)
	if not _compact:
		_amount_label.add_theme_font_size_override(
			"font_size", mini(42, 28 + _amount)
		)
	accessibility_name = "%d Yolk" % _amount


func _draw() -> void:
	var centre := size * 0.5
	var base_radius := minf(size.x * 0.42, size.y * 0.43)
	var wobble := 0.0 if _reduced_motion else sin(_shimmer_phase * 1.3) * 0.035
	var points := PackedVector2Array()
	var point_count := 30
	for point_index in range(point_count):
		var angle := TAU * float(point_index) / float(point_count)
		var lobe := sin(angle * 3.0 + _shimmer_phase) * 0.035
		lobe += sin(angle * 5.0 - _shimmer_phase * 0.7) * 0.025
		var radius := base_radius * (1.0 + lobe + wobble * cos(angle * 2.0))
		var squash := 0.91 + 0.025 * sin(_shimmer_phase + angle)
		points.append(centre + Vector2(cos(angle) * radius, sin(angle) * radius * squash))

	var shadow_points := PackedVector2Array()
	for point: Vector2 in points:
		shadow_points.append(point + Vector2(0.0, 5.0))
	draw_colored_polygon(shadow_points, Color(0.20, 0.075, 0.005, 0.72))
	draw_colored_polygon(points, Color("e9a20d"))
	var closed_points := PackedVector2Array(points)
	closed_points.append(points[0])
	draw_polyline(closed_points, Color("713006"), 4.0 if not _compact else 2.5, true)

	var drip_y := centre.y + base_radius * 0.76
	draw_circle(Vector2(centre.x - base_radius * 0.42, drip_y), base_radius * 0.14, Color("d98708"))
	draw_circle(Vector2(centre.x + base_radius * 0.30, drip_y + 2.0), base_radius * 0.10, Color("f0ab12"))

	var shimmer_shift := 0.0 if _reduced_motion else sin(_shimmer_phase) * base_radius * 0.10
	draw_circle(
		centre + Vector2(-base_radius * 0.27 + shimmer_shift, -base_radius * 0.29),
		base_radius * 0.19,
		Color(1.0, 0.94, 0.55, 0.72)
	)
	draw_circle(
		centre + Vector2(-base_radius * 0.36 + shimmer_shift, -base_radius * 0.39),
		base_radius * 0.075,
		Color(1.0, 1.0, 0.86, 0.94)
	)
	draw_arc(
		centre,
		base_radius * 0.70,
		0.15,
		1.15,
		12,
		Color(1.0, 0.79, 0.15, 0.68),
		3.0,
		true
	)
