extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var spoon := get_parent()
	if not spoon.has_method("bowl_visuals"):
		return
	for handle: Dictionary in spoon.foreground_handle_visuals():
		var visibility: float = handle.visibility
		var width_scale: float = handle.get("width_scale", 1.0)
		# Every falling asset draws its shaft and bowls in one pass. The authored
		# contact asset alone omits this foreground shaft so egg occlusion can put
		# the same handle back on the wall plane without exposing a gap in flight.
		draw_line(handle.from, handle.to, Color(0.04, 0.04, 0.05, visibility), 13.0 * width_scale, true)
		draw_line(handle.from, handle.to, Color(0.62, 0.64, 0.63, visibility), 8.0 * width_scale, true)
		draw_line(
			handle.from - Vector2(1.5, 0.0),
			handle.to - Vector2(1.5, 0.0),
			Color(1.0, 0.95, 0.84, 0.46 * visibility),
			1.5,
			true
		)
		if handle.get("telescoping", false):
			_draw_telescoping_collars(handle.from, handle.to, visibility)
	for visual: Dictionary in spoon.bowl_visuals():
		_draw_bowl(visual.center, visual.radii, visual.tipped_amount)
		if visual.get("draw_neck", false):
			_draw_bowl_neck(
				visual.center,
				visual.radii,
				visual.get("collar_direction", Vector2.DOWN),
				visual.get("neck_scale", 1.0)
			)
		var impact_emphasis: float = visual.get("impact_emphasis", 0.0)
		if impact_emphasis > 0.001:
			_draw_impact_marks(visual.center, visual.radii, impact_emphasis)


func _draw_telescoping_collars(from: Vector2, to: Vector2, visibility: float) -> void:
	for progress in [0.28, 0.48, 0.68]:
		var center := from.lerp(to, progress)
		var outer := Rect2(center - Vector2(11.0, 4.5), Vector2(22.0, 9.0))
		var inner := Rect2(center - Vector2(8.0, 2.5), Vector2(16.0, 5.0))
		draw_rect(outer, Color(0.13, 0.08, 0.03, visibility), true)
		draw_rect(outer, Color(0.62, 0.36, 0.12, visibility), false, 2.0)
		draw_rect(inner, Color(0.78, 0.48, 0.18, visibility), true)


func _draw_impact_marks(center: Vector2, radii: Vector2, emphasis: float) -> void:
	var color := Color(1.0, 0.76, 0.28, emphasis)
	for side in [-1.0, 1.0]:
		var origin := center + Vector2(side * (radii.x + 2.0), radii.y * 0.18)
		draw_line(origin, origin + Vector2(side * 8.0, 5.0), color, 2.5, true)
		draw_line(
			origin + Vector2(side * 1.0, -4.0),
			origin + Vector2(side * 6.0, -8.0),
			color,
			2.0,
			true
		)


func _draw_bowl_neck(
	center: Vector2,
	radii: Vector2,
	direction: Vector2,
	neck_scale: float
) -> void:
	# Both bowls have a visible manufactured socket into their own shaft. At the
	# exact edge-on frame direction is zero, so the sockets compress into brass
	# bands across the narrow paired silhouette instead of jumping sides.
	var collar_center := center
	if not direction.is_zero_approx():
		collar_center += direction * (radii.y + 4.0)
	var half_width := 15.0 * neck_scale
	var outer := Rect2(
		collar_center - Vector2(half_width, 5.5),
		Vector2(half_width * 2.0, 11.0)
	)
	var inner_half_width := 11.5 * neck_scale
	var inner := Rect2(
		collar_center - Vector2(inner_half_width, 3.0),
		Vector2(inner_half_width * 2.0, 6.0)
	)
	draw_rect(outer, Color("25170c"), true)
	draw_rect(outer, Color("8f5725"), false, 2.0)
	draw_rect(inner, Color("bd7931"), true)
	draw_line(
		inner.position + Vector2(2.0, 1.5),
		Vector2(inner.end.x - 2.0, inner.position.y + 1.5),
		Color(1.0, 0.78, 0.39, 0.72),
		1.5,
		true
	)


func _draw_bowl(center: Vector2, radii: Vector2, tipped_amount: float) -> void:
	var bowl := _ellipse_points(center, radii)
	draw_colored_polygon(bowl, Color("777b7c"))

	var stored_visibility := 1.0 - smoothstep(0.15, 0.70, tipped_amount)
	if stored_visibility > 0.001:
		var rim := bowl.duplicate()
		rim.append(bowl[0])
		draw_polyline(rim, Color(Color("dedbd1"), stored_visibility), 3.0, true)
		draw_polyline(
			_ellipse_arc_points(center - Vector2(5.0, 4.0), radii * Vector2(0.58, 0.72), 1.85, 4.55, 16),
			Color(1.0, 0.95, 0.84, 0.46 * stored_visibility), 4.0, true
		)
		draw_polyline(
			_ellipse_arc_points(center + Vector2(3.0, 1.0), radii * Vector2(0.78, 0.80), -0.95, 0.95, 14),
			Color(0.08, 0.08, 0.09, 0.34 * stored_visibility), 4.0, true
		)

	# When the utensil tips toward the player, its broad convex underside is the
	# foreground surface. The dark opening stays tucked above that lower shell.
	var tipped_visibility := smoothstep(0.25, 0.80, tipped_amount)
	if tipped_visibility <= 0.001:
		return
	var lower_shell := _ellipse_arc_points(center, radii * Vector2(0.94, 0.90), PI, 0.0, 22)
	draw_colored_polygon(lower_shell, Color(Color("969a9a"), tipped_visibility))
	draw_polyline(lower_shell, Color(Color("ddd9cf"), tipped_visibility), 2.5, true)
	var opening_center := center - Vector2(0.0, radii.y * 0.24)
	var opening_radii := Vector2(radii.x * 0.80, maxf(radii.y * 0.27, 3.0))
	draw_colored_polygon(_ellipse_points(opening_center, opening_radii), Color(Color("25282a"), tipped_visibility))
	draw_polyline(
		_ellipse_arc_points(opening_center, opening_radii, PI, TAU, 18),
		Color(Color("f0ece0"), tipped_visibility), 2.5, true
	)


func _ellipse_points(center: Vector2, radii: Vector2, point_count := 32) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(point_count):
		var angle := TAU * float(point_index) / float(point_count)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


func _ellipse_arc_points(
	center: Vector2,
	radii: Vector2,
	from_angle: float,
	to_angle: float,
	point_count: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(point_count):
		var progress := float(point_index) / float(maxi(point_count - 1, 1))
		var angle := lerpf(from_angle, to_angle, progress)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
