class_name SpeciesIconRenderer
extends RefCounted

const PlaceholderStyle = preload("res://src/ui/species_placeholder_style.gd")


static func draw(
	canvas: CanvasItem,
	kind: String,
	center: Vector2,
	scale_value: float,
	color: Color,
	outline_color := Color("303033"),
	outline_width := 1.5
) -> void:
	var body_center := center + Vector2(-scale_value * 0.08, scale_value * 0.05)
	match PlaceholderStyle.shape(kind):
		"round_comb":
			_draw_shape(canvas, PackedVector2Array([
				center + Vector2(-0.28, -0.08) * scale_value,
				center + Vector2(-0.65, -0.52) * scale_value,
				center + Vector2(-0.72, -0.22) * scale_value,
				center + Vector2(-0.91, -0.06) * scale_value,
				center + Vector2(-0.69, 0.18) * scale_value,
				center + Vector2(-0.34, 0.23) * scale_value,
			]), color, outline_color, outline_width)
			_draw_ellipse(
				canvas, center + Vector2(-0.04, 0.10) * scale_value,
				Vector2(0.43, 0.47) * scale_value,
				color, outline_color, outline_width
			)
			var chicken_head := center + Vector2(0.28, -0.45) * scale_value
			canvas.draw_line(
				center + Vector2(0.16, -0.18) * scale_value,
				chicken_head, color, maxf(2.0, scale_value * 0.20), true
			)
			_draw_head_and_beak(
				canvas, chicken_head, scale_value, color, 0.17,
				outline_color, outline_width
			)
			for comb_offset in [-0.10, 0.0, 0.10]:
				canvas.draw_circle(
					chicken_head + Vector2(comb_offset, -0.19) * scale_value,
					scale_value * 0.07, color
				)
			for leg_x in [-0.16, 0.08]:
				canvas.draw_line(
					center + Vector2(leg_x, 0.38) * scale_value,
					center + Vector2(leg_x - 0.02, 0.68) * scale_value,
					color, maxf(1.5, scale_value * 0.055), true
				)
		"status_oily":
			_draw_shape(canvas, PackedVector2Array([
				center + Vector2(0.0, -0.68) * scale_value,
				center + Vector2(0.46, 0.12) * scale_value,
				center + Vector2(0.36, 0.48) * scale_value,
				center + Vector2(0.0, 0.66) * scale_value,
				center + Vector2(-0.36, 0.48) * scale_value,
				center + Vector2(-0.46, 0.12) * scale_value,
			]), color, outline_color, outline_width)
		"status_nostalgic":
			canvas.draw_arc(
				center, scale_value * 0.48, -2.35, 2.35, 24, color,
				maxf(2.0, scale_value * 0.15), true
			)
			_draw_shape(canvas, PackedVector2Array([
				center + Vector2(-0.66, -0.12) * scale_value,
				center + Vector2(-0.24, -0.48) * scale_value,
				center + Vector2(-0.20, 0.12) * scale_value,
			]), color, outline_color, outline_width)
		"status_gloopy":
			for tooth_index in range(8):
				var angle := TAU * float(tooth_index) / 8.0
				var inner := center + Vector2.from_angle(angle) * scale_value * 0.42
				var outer := center + Vector2.from_angle(angle) * scale_value * 0.66
				canvas.draw_line(
					inner, outer, color, maxf(2.0, scale_value * 0.17), true
				)
			canvas.draw_circle(center, scale_value * 0.48, color)
			canvas.draw_circle(center, scale_value * 0.18, outline_color)
		"long_tail":
			_draw_shape(canvas, PackedVector2Array([
				center + Vector2(-0.37, 0.02) * scale_value,
				center + Vector2(-1.02, 0.47) * scale_value,
				center + Vector2(-0.49, 0.14) * scale_value,
			]), color, outline_color, outline_width)
			_draw_shape(canvas, PackedVector2Array([
				center + Vector2(-0.38, 0.07) * scale_value,
				center + Vector2(-0.91, 0.31) * scale_value,
				center + Vector2(-0.47, 0.18) * scale_value,
			]), color, outline_color, outline_width)
			_draw_ellipse(
				canvas, center + Vector2(-0.06, 0.04) * scale_value,
				Vector2(0.52, 0.31) * scale_value,
				color, outline_color, outline_width
			)
			_draw_head_and_beak(
				canvas, center + Vector2(0.37, -0.22) * scale_value,
				scale_value, color, 0.19, outline_color, outline_width
			)
		"compact":
			_draw_shape(canvas, PackedVector2Array([
				center + Vector2(-0.34, 0.06) * scale_value,
				center + Vector2(-0.76, 0.25) * scale_value,
				center + Vector2(-0.43, 0.18) * scale_value,
			]), color, outline_color, outline_width)
			_draw_shape(canvas, PackedVector2Array([
				center + Vector2(-0.34, 0.07) * scale_value,
				center + Vector2(-0.68, 0.10) * scale_value,
				center + Vector2(-0.42, 0.16) * scale_value,
			]), color, outline_color, outline_width)
			_draw_ellipse(
				canvas, center + Vector2(-0.05, 0.06) * scale_value,
				Vector2(0.48, 0.34) * scale_value,
				color, outline_color, outline_width
			)
			_draw_head_and_beak(
				canvas, center + Vector2(0.34, -0.20) * scale_value,
				scale_value, color, 0.19, outline_color, outline_width
			)
		"long_legged":
			_draw_ellipse(
				canvas, body_center + Vector2(0, -0.10) * scale_value,
				Vector2(0.53, 0.31) * scale_value, color,
				outline_color, outline_width
			)
			_draw_head_and_beak(
				canvas, center + Vector2(0.35, -0.34) * scale_value,
				scale_value, color, 0.17, outline_color, outline_width
			)
			for leg_x in [-0.18, 0.10]:
				canvas.draw_line(
					center + Vector2(leg_x, 0.20) * scale_value,
					center + Vector2(leg_x - 0.04, 0.65) * scale_value,
					color, maxf(1.5, scale_value * 0.09), true
				)
		"spoon_bill":
			_draw_ellipse(
				canvas, center + Vector2(-0.14, 0.16) * scale_value,
				Vector2(0.45, 0.28) * scale_value,
				color, outline_color, outline_width
			)
			var head := center + Vector2(0.27, -0.46) * scale_value
			canvas.draw_line(
				center + Vector2(0.02, 0.04) * scale_value,
				center + Vector2(0.10, -0.35) * scale_value,
				color, maxf(2.0, scale_value * 0.16), true
			)
			canvas.draw_line(
				center + Vector2(0.10, -0.35) * scale_value,
				head, color, maxf(2.0, scale_value * 0.15), true
			)
			canvas.draw_circle(head, scale_value * 0.14, color)
			canvas.draw_line(
				head, head + Vector2(0.48, 0.02) * scale_value,
				color, maxf(2.0, scale_value * 0.09), true
			)
			canvas.draw_circle(
				head + Vector2(0.52, 0.02) * scale_value,
				scale_value * 0.10, color
			)
			for leg_x in [-0.18, 0.06]:
				canvas.draw_line(
					center + Vector2(leg_x, 0.23) * scale_value,
					center + Vector2(leg_x - 0.03, 0.66) * scale_value,
					color, maxf(1.5, scale_value * 0.06), true
				)
		"woodpecker":
			# An upright, braced silhouette with a straight chisel bill reads as a
			# woodpecker even when it is used as a low-contrast egg watermark.
			_draw_ellipse(
				canvas, center + Vector2(-0.10, 0.08) * scale_value,
				Vector2(0.32, 0.52) * scale_value,
				color, outline_color, outline_width
			)
			var woodpecker_head := center + Vector2(0.16, -0.42) * scale_value
			canvas.draw_circle(woodpecker_head, scale_value * 0.21, color)
			_draw_shape(canvas, PackedVector2Array([
				woodpecker_head + Vector2(0.14, -0.07) * scale_value,
				woodpecker_head + Vector2(0.86, -0.01) * scale_value,
				woodpecker_head + Vector2(0.14, 0.08) * scale_value,
			]), color, outline_color, outline_width)
			_draw_shape(canvas, PackedVector2Array([
				center + Vector2(-0.24, 0.40) * scale_value,
				center + Vector2(-0.34, 0.90) * scale_value,
				center + Vector2(-0.04, 0.48) * scale_value,
			]), color, outline_color, outline_width)
			_draw_shape(canvas, PackedVector2Array([
				center + Vector2(-0.08, 0.43) * scale_value,
				center + Vector2(0.02, 0.84) * scale_value,
				center + Vector2(0.12, 0.38) * scale_value,
			]), color, outline_color, outline_width)
		"topknot":
			_draw_ellipse(
				canvas, body_center, Vector2(0.48, 0.39) * scale_value,
				color, outline_color, outline_width
			)
			var head := center + Vector2(0.28, -0.24) * scale_value
			_draw_head_and_beak(
				canvas, head, scale_value, color, 0.19,
				outline_color, outline_width
			)
			canvas.draw_line(
				head + Vector2(-0.04, -0.15) * scale_value,
				head + Vector2(-0.18, -0.48) * scale_value,
				color, maxf(1.5, scale_value * 0.07), true
			)
		"casque":
			_draw_ellipse(
				canvas, body_center, Vector2(0.54, 0.38) * scale_value,
				color, outline_color, outline_width
			)
			var head := center + Vector2(0.31, -0.28) * scale_value
			_draw_head_and_beak(
				canvas, head, scale_value, color, 0.20,
				outline_color, outline_width
			)
			_draw_shape(canvas, PackedVector2Array([
				head + Vector2(-0.17, -0.12) * scale_value,
				head + Vector2(-0.03, -0.40) * scale_value,
				head + Vector2(0.12, -0.13) * scale_value,
			]), color, outline_color, outline_width)
		"tall_neck":
			_draw_ellipse(
				canvas, body_center + Vector2(-0.12, 0.10) * scale_value,
				Vector2(0.48, 0.34) * scale_value, color,
				outline_color, outline_width
			)
			var head := center + Vector2(0.23, -0.54) * scale_value
			canvas.draw_line(
				center + Vector2(0.12, -0.12) * scale_value,
				head, color, maxf(2.0, scale_value * 0.14), true
			)
			_draw_head_and_beak(
				canvas, head, scale_value, color, 0.14,
				outline_color, outline_width
			)
			for leg_x in [-0.24, 0.02]:
				canvas.draw_line(
					center + Vector2(leg_x, 0.28) * scale_value,
					center + Vector2(leg_x - 0.03, 0.67) * scale_value,
					color, maxf(1.5, scale_value * 0.07), true
				)
		"long_beak":
			_draw_ellipse(
				canvas, body_center, Vector2(0.56, 0.45) * scale_value,
				color, outline_color, outline_width
			)
			var head := center + Vector2(0.27, -0.25) * scale_value
			canvas.draw_circle(head, scale_value * 0.18, color)
			_draw_shape(canvas, PackedVector2Array([
				head + Vector2(0.12, -0.03) * scale_value,
				head + Vector2(0.80, 0.10) * scale_value,
				head + Vector2(0.13, 0.10) * scale_value,
			]), color, outline_color, outline_width)
		_:
			_draw_ellipse(
				canvas, body_center, Vector2(0.55, 0.42) * scale_value,
				color, outline_color, outline_width
			)
			_draw_head_and_beak(
				canvas, center + Vector2(0.32, -0.28) * scale_value,
				scale_value, color, 0.22, outline_color, outline_width
			)
			for comb_offset in [-0.13, 0.0, 0.13]:
				canvas.draw_circle(
					center + Vector2(0.22 + comb_offset, -0.53) * scale_value,
					scale_value * 0.09, color
				)


static func _draw_head_and_beak(
	canvas: CanvasItem,
	head: Vector2,
	scale_value: float,
	color: Color,
	head_radius: float,
	outline_color: Color,
	outline_width: float
) -> void:
	canvas.draw_circle(head, scale_value * head_radius, color)
	_draw_shape(canvas, PackedVector2Array([
		head + Vector2(head_radius * 0.75, -0.05) * scale_value,
		head + Vector2(head_radius * 1.55, 0.05) * scale_value,
		head + Vector2(head_radius * 0.72, 0.14) * scale_value,
	]), color, outline_color, outline_width)


static func _draw_ellipse(
	canvas: CanvasItem,
	center: Vector2,
	radii: Vector2,
	color: Color,
	outline_color: Color,
	outline_width: float
) -> void:
	_draw_shape(
		canvas, _ellipse_points(center, radii), color, outline_color, outline_width
	)


static func _ellipse_points(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(28):
		var angle := TAU * float(point_index) / 28.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


static func _draw_shape(
	canvas: CanvasItem,
	points: PackedVector2Array,
	color: Color,
	outline_color: Color,
	outline_width: float
) -> void:
	canvas.draw_colored_polygon(points, color)
	if outline_width > 0.0:
		var outline := points.duplicate()
		outline.append(points[0])
		canvas.draw_polyline(outline, outline_color, outline_width, true)
