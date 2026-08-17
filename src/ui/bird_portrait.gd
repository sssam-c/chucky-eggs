class_name BirdPortrait
extends Control

const PlaceholderStyle = preload("res://src/ui/species_placeholder_style.gd")

var _kind := "chicken"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_bird_kind(kind: String) -> void:
	_kind = kind if PlaceholderStyle.COLOURS.has(kind) else "chicken"
	queue_redraw()


func bird_kind() -> String:
	return _kind


func placeholder_color() -> Color:
	return PlaceholderStyle.colour(_kind)


func placeholder_shape() -> String:
	return PlaceholderStyle.shape(_kind)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.47
	draw_circle(center + Vector2(0, 2), radius + 2.0, Color(0, 0, 0, 0.34))
	draw_circle(center, radius, Color("202124"))
	draw_circle(center, radius - 3.0, Color("ded8ca"))
	_draw_placeholder_bird(center, radius * 0.72, placeholder_color())


func _draw_placeholder_bird(center: Vector2, scale_value: float, color: Color) -> void:
	var body_center := center + Vector2(-scale_value * 0.08, scale_value * 0.05)
	match placeholder_shape():
		"long_tail":
			_draw_shape(PackedVector2Array([
				body_center + Vector2(-0.42, 0.05) * scale_value,
				body_center + Vector2(-0.92, 0.48) * scale_value,
				body_center + Vector2(-0.50, 0.27) * scale_value,
			]), color)
			_draw_ellipse(body_center, Vector2(0.55, 0.37) * scale_value, color)
			_draw_head_and_beak(center + Vector2(0.36, -0.25) * scale_value, scale_value, color, 0.19)
		"compact":
			_draw_ellipse(body_center, Vector2(0.52, 0.43) * scale_value, color)
			_draw_head_and_beak(center + Vector2(0.30, -0.24) * scale_value, scale_value, color, 0.21)
		"long_legged":
			_draw_ellipse(body_center + Vector2(0, -0.10) * scale_value, Vector2(0.53, 0.31) * scale_value, color)
			_draw_head_and_beak(center + Vector2(0.35, -0.34) * scale_value, scale_value, color, 0.17)
			for leg_x in [-0.18, 0.10]:
				draw_line(
					center + Vector2(leg_x, 0.20) * scale_value,
					center + Vector2(leg_x - 0.04, 0.65) * scale_value,
					color, maxf(2.0, scale_value * 0.09), true
				)
		"spoon_bill":
			_draw_ellipse(body_center, Vector2(0.48, 0.36) * scale_value, color)
			var head := center + Vector2(0.28, -0.27) * scale_value
			draw_circle(head, scale_value * 0.18, color)
			draw_line(head, head + Vector2(0.52, 0.02) * scale_value, color, maxf(4.0, scale_value * 0.15), true)
			draw_circle(head + Vector2(0.54, 0.02) * scale_value, scale_value * 0.11, color)
		"topknot":
			_draw_ellipse(body_center, Vector2(0.48, 0.39) * scale_value, color)
			var head := center + Vector2(0.28, -0.24) * scale_value
			_draw_head_and_beak(head, scale_value, color, 0.19)
			draw_line(
				head + Vector2(-0.04, -0.15) * scale_value,
				head + Vector2(-0.18, -0.48) * scale_value,
				color, maxf(2.0, scale_value * 0.07), true
			)
		"casque":
			_draw_ellipse(body_center, Vector2(0.54, 0.38) * scale_value, color)
			var head := center + Vector2(0.31, -0.28) * scale_value
			_draw_head_and_beak(head, scale_value, color, 0.20)
			_draw_shape(PackedVector2Array([
				head + Vector2(-0.17, -0.12) * scale_value,
				head + Vector2(-0.03, -0.40) * scale_value,
				head + Vector2(0.12, -0.13) * scale_value,
			]), color)
		"tall_neck":
			_draw_ellipse(
				body_center + Vector2(-0.12, 0.10) * scale_value,
				Vector2(0.48, 0.34) * scale_value,
				color
			)
			var head := center + Vector2(0.23, -0.54) * scale_value
			draw_line(
				center + Vector2(0.12, -0.12) * scale_value,
				head, color, maxf(4.0, scale_value * 0.14), true
			)
			_draw_head_and_beak(head, scale_value, color, 0.14)
			for leg_x in [-0.24, 0.02]:
				draw_line(
					center + Vector2(leg_x, 0.28) * scale_value,
					center + Vector2(leg_x - 0.03, 0.67) * scale_value,
					color, maxf(2.0, scale_value * 0.07), true
				)
		"long_beak":
			_draw_ellipse(body_center, Vector2(0.56, 0.45) * scale_value, color)
			var head := center + Vector2(0.27, -0.25) * scale_value
			draw_circle(head, scale_value * 0.18, color)
			_draw_shape(PackedVector2Array([
				head + Vector2(0.12, -0.03) * scale_value,
				head + Vector2(0.80, 0.10) * scale_value,
				head + Vector2(0.13, 0.10) * scale_value,
			]), color)
		_:
			_draw_ellipse(body_center, Vector2(0.55, 0.42) * scale_value, color)
			_draw_head_and_beak(center + Vector2(0.32, -0.28) * scale_value, scale_value, color, 0.22)
			for comb_offset in [-0.13, 0.0, 0.13]:
				draw_circle(
					center + Vector2(0.22 + comb_offset, -0.53) * scale_value,
					scale_value * 0.09, color
				)


func _draw_head_and_beak(
	head: Vector2, scale_value: float, color: Color, head_radius: float
) -> void:
	draw_circle(head, scale_value * head_radius, color)
	_draw_shape(PackedVector2Array([
		head + Vector2(head_radius * 0.75, -0.05) * scale_value,
		head + Vector2(head_radius * 1.55, 0.05) * scale_value,
		head + Vector2(head_radius * 0.72, 0.14) * scale_value,
	]), color)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	_draw_shape(_ellipse_points(center, radii), color)


func _ellipse_points(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(28):
		var angle := TAU * float(point_index) / 28.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


func _draw_shape(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color("303033"), 1.5, true)
