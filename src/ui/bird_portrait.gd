class_name BirdPortrait
extends Control

var _kind := "chicken"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_bird_kind(kind: String) -> void:
	_kind = kind
	queue_redraw()


func bird_kind() -> String:
	return _kind


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.46
	draw_circle(center, radius, Color("171516"))
	draw_circle(center, radius - 3.0, _backdrop_color())
	draw_arc(center, radius - 3.0, 0.0, TAU, 32, Color("e3a84b"), 3.0, true)

	var body_color := _body_color()
	var ink := _ink_color()
	var body_center := center + Vector2(-4.0, 13.0)
	_draw_body_ellipse(body_center, Vector2(radius * 0.52, radius * 0.43), body_color)
	draw_arc(body_center, radius * 0.40, 0.15, 2.8, 20, body_color.lightened(0.20), 3.0, true)
	var head_center := center + Vector2(9.0, -10.0)
	draw_circle(head_center, radius * 0.31, body_color)
	draw_arc(head_center, radius * 0.31, 0.0, TAU, 24, ink, 2.5, true)
	_draw_species_marks(center, radius, head_center, body_color, ink)
	draw_circle(head_center + Vector2(6.0, -4.0), 3.4, Color("fff1ba"))
	draw_circle(head_center + Vector2(6.5, -4.0), 1.7, ink)


func _draw_body_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for point_index in range(28):
		var angle := TAU * float(point_index) / 28.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, _ink_color(), 2.5, true)


func _draw_species_marks(
	center: Vector2,
	radius: float,
	head_center: Vector2,
	body_color: Color,
	ink: Color
) -> void:
	match _kind:
		"cuckoo":
			for stripe_y in [-2.0, 7.0, 16.0]:
				draw_line(center + Vector2(-20, stripe_y), center + Vector2(4, stripe_y + 4), ink, 2.2, true)
			_draw_beak(head_center + Vector2(10, 1), 15.0, Color("c98a38"), ink)
		"plover":
			draw_line(head_center + Vector2(-7, -11), head_center + Vector2(4, -16), ink, 3.0, true)
			draw_line(head_center + Vector2(-6, -7), head_center + Vector2(8, -10), Color("f0e1aa"), 3.0, true)
			_draw_beak(head_center + Vector2(10, 1), 18.0, Color("362e21"), ink)
		"spoonbill":
			draw_arc(center + Vector2(-6, 9), radius * 0.30, 0.1, 2.7, 12, Color("f7d5e8"), 3.0, true)
			_draw_spoon_beak(head_center + Vector2(9, 1), ink)
		_:
			var comb := PackedVector2Array([
				head_center + Vector2(-9, -11), head_center + Vector2(-7, -20),
				head_center + Vector2(-1, -14), head_center + Vector2(3, -22),
				head_center + Vector2(7, -12),
			])
			draw_colored_polygon(comb, Color("d84a32"))
			draw_polyline(comb, ink, 2.0, true)
			_draw_beak(head_center + Vector2(10, 1), 13.0, Color("e8a334"), ink)


func _draw_beak(origin: Vector2, length: float, color: Color, ink: Color) -> void:
	var beak := PackedVector2Array([
		origin + Vector2(0, -5), origin + Vector2(length, 0), origin + Vector2(0, 5),
	])
	draw_colored_polygon(beak, color)
	var outline := beak.duplicate()
	outline.append(beak[0])
	draw_polyline(outline, ink, 2.0, true)


func _draw_spoon_beak(origin: Vector2, ink: Color) -> void:
	draw_line(origin, origin + Vector2(20, 1), Color("d6a8bb"), 8.0, true)
	draw_circle(origin + Vector2(24, 1), 7.0, Color("d6a8bb"))
	draw_line(origin, origin + Vector2(20, 1), ink, 1.6, true)
	draw_arc(origin + Vector2(24, 1), 7.0, 0.0, TAU, 18, ink, 1.6, true)


func _body_color() -> Color:
	match _kind:
		"cuckoo": return Color("78aeb2")
		"plover": return Color("aaba54")
		"spoonbill": return Color("dba7c8")
	return Color("e6b969")


func _backdrop_color() -> Color:
	match _kind:
		"cuckoo": return Color("173b40")
		"plover": return Color("34401d")
		"spoonbill": return Color("4b2944")
	return Color("55291b")


func _ink_color() -> Color:
	match _kind:
		"cuckoo": return Color("102d31")
		"plover": return Color("293215")
		"spoonbill": return Color("48243f")
	return Color("4b2418")
