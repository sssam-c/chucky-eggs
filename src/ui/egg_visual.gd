extends Control

var _egg: Dictionary = {}
var _preview := false


func set_egg(egg: Dictionary, preview := false) -> void:
	_egg = egg.duplicate(true)
	_preview = preview
	queue_redraw()


func clear_egg() -> void:
	_egg = {}
	queue_redraw()


func _draw() -> void:
	if _egg.is_empty():
		return

	var center := Vector2(size.x * 0.5, size.y * 0.51)
	var radius_x := minf(size.x * 0.37, 52.0)
	var radius_y := minf(size.y * 0.44, 68.0)
	if _preview:
		radius_x *= 0.70
		radius_y *= 0.70

	var shell_points := PackedVector2Array()
	for point_index in range(40):
		var angle := TAU * float(point_index) / 40.0
		var vertical := sin(angle)
		var taper := lerpf(0.78, 1.08, (vertical + 1.0) * 0.5)
		shell_points.append(center + Vector2(cos(angle) * radius_x * taper, vertical * radius_y))

	draw_colored_polygon(shell_points, Color("e6bd7a"))
	var outline := shell_points.duplicate()
	outline.append(shell_points[0])
	draw_polyline(outline, Color("572719"), 4.0, true)
	draw_circle(center + Vector2(-radius_x * 0.28, -radius_y * 0.30), radius_x * 0.15, Color(1.0, 0.91, 0.68, 0.58))
	draw_arc(center, radius_x * 0.78, 0.25, 2.35, 20, Color(1.0, 0.88, 0.52, 0.34), 3.0, true)
	draw_arc(center + Vector2(6, 6), radius_x * 0.70, 2.5, 4.7, 18, Color(0.32, 0.12, 0.06, 0.22), 3.0, true)

	var toughness: int = _egg.get("toughness", 4)
	if toughness <= 3:
		_draw_crack(center + Vector2(4.0, -8.0), [
			Vector2(0, -20), Vector2(-7, -8), Vector2(2, 0), Vector2(-5, 11), Vector2(1, 22),
		])
	if toughness <= 2:
		_draw_crack(center + Vector2(-5.0, 3.0), [
			Vector2(0, 0), Vector2(-15, 6), Vector2(-22, 17),
		])
	if toughness <= 1:
		_draw_crack(center + Vector2(7.0, 5.0), [
			Vector2(0, 0), Vector2(14, 8), Vector2(19, 21),
		])
		_draw_crack(center + Vector2(0.0, -1.0), [
			Vector2(0, 0), Vector2(11, -13), Vector2(9, -25),
		])


func _draw_crack(origin: Vector2, offsets: Array[Vector2]) -> void:
	var points := PackedVector2Array()
	for offset: Vector2 in offsets:
		points.append(origin + offset)
	draw_polyline(points, Color("5a251e"), 3.2, true)
	draw_polyline(points, Color(0.18, 0.06, 0.04, 0.38), 1.2, true)
