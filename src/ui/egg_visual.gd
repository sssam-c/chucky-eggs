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

	var kind := String(_egg.get("kind", "chicken"))
	var is_cuckoo := kind == "cuckoo"
	var is_plover := kind == "plover"
	var is_spoonbill := kind == "spoonbill"
	var shell_color := Color("79aeb2") if is_cuckoo else Color("b8c66e") if is_plover else Color("c9a6c8") if is_spoonbill else Color("e6bd7a")
	var outline_color := Color("183c43") if is_cuckoo else Color("354421") if is_plover else Color("4d2949") if is_spoonbill else Color("572719")
	draw_colored_polygon(shell_points, shell_color)
	var outline := shell_points.duplicate()
	outline.append(shell_points[0])
	draw_polyline(outline, outline_color, 4.0, true)
	var highlight := Color(0.76, 1.0, 0.96, 0.54) if is_cuckoo else Color(0.92, 1.0, 0.63, 0.54) if is_plover else Color(1.0, 0.88, 0.98, 0.58) if is_spoonbill else Color(1.0, 0.91, 0.68, 0.58)
	draw_circle(center + Vector2(-radius_x * 0.28, -radius_y * 0.30), radius_x * 0.15, highlight)
	draw_arc(center, radius_x * 0.78, 0.25, 2.35, 20, Color(0.70, 1.0, 0.96, 0.34) if is_cuckoo else Color(0.91, 1.0, 0.55, 0.30) if is_plover else Color(1.0, 0.72, 0.93, 0.34) if is_spoonbill else Color(1.0, 0.88, 0.52, 0.34), 3.0, true)
	draw_arc(center + Vector2(6, 6), radius_x * 0.70, 2.5, 4.7, 18, Color(0.02, 0.18, 0.21, 0.28) if is_cuckoo else Color(0.16, 0.23, 0.05, 0.30) if is_plover else Color(0.25, 0.08, 0.24, 0.28) if is_spoonbill else Color(0.32, 0.12, 0.06, 0.22), 3.0, true)
	if is_cuckoo:
		_draw_cuckoo_marks(center, radius_x, radius_y)
	elif is_plover:
		_draw_plover_marks(center, radius_x, radius_y)
	elif is_spoonbill:
		_draw_spoonbill_marks(center, radius_x, radius_y)

	var toughness: int = _egg.get("toughness", 4)
	var max_toughness: int = _egg.get("max_toughness", 4)
	var damage_taken := maxi(max_toughness - toughness, 0)
	if damage_taken >= 1:
		_draw_crack(center + Vector2(4.0, -8.0), [
			Vector2(0, -20), Vector2(-7, -8), Vector2(2, 0), Vector2(-5, 11), Vector2(1, 22),
		])
	if damage_taken >= 2:
		_draw_crack(center + Vector2(-5.0, 3.0), [
			Vector2(0, 0), Vector2(-15, 6), Vector2(-22, 17),
		])
	if damage_taken >= 3:
		_draw_crack(center + Vector2(7.0, 5.0), [
			Vector2(0, 0), Vector2(14, 8), Vector2(19, 21),
		])
		_draw_crack(center + Vector2(0.0, -1.0), [
			Vector2(0, 0), Vector2(11, -13), Vector2(9, -25),
		])
	if damage_taken >= 4:
		_draw_crack(center + Vector2(-8.0, 17.0), [
			Vector2(0, 0), Vector2(-8, 11), Vector2(-6, 23),
		])
	if damage_taken >= 5:
		_draw_crack(center + Vector2(-7.0, -13.0), [
			Vector2(0, 0), Vector2(-12, -9), Vector2(-14, -21),
		])

	# Keep decision-critical marks above shell decoration and accumulated cracks.
	_draw_information_marks(center, radius_y)


func score_seal_value() -> int:
	if _egg.is_empty():
		return 0
	return int(_egg.get("points", 0))


func effect_emblem() -> String:
	if _egg.is_empty():
		return ""
	match String(_egg.get("kind", "chicken")):
		"cuckoo":
			return "echo"
		"plover":
			return "retreat"
		"spoonbill":
			return "spark"
	return ""


func egg_kind() -> String:
	return String(_egg.get("kind", ""))


func _draw_information_marks(center: Vector2, radius_y: float) -> void:
	var mark_scale := 0.72 if _preview else 1.0
	_draw_score_seal(center + Vector2(0.0, -radius_y * 0.61), mark_scale)
	var emblem_center := center + Vector2(0.0, radius_y * 0.48)
	match effect_emblem():
		"echo":
			_draw_echo_emblem(emblem_center, mark_scale)
		"retreat":
			_draw_retreat_emblem(emblem_center, mark_scale)
		"spark":
			_draw_spark_emblem(emblem_center, mark_scale)


func _draw_score_seal(center: Vector2, mark_scale: float) -> void:
	var outer_radius := 15.0 * mark_scale
	var seal_points := PackedVector2Array()
	for point_index in range(20):
		var angle := TAU * float(point_index) / 20.0 - PI * 0.5
		var radius := outer_radius if point_index % 2 == 0 else outer_radius * 0.82
		seal_points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(seal_points, Color("b66a2b"))
	var outline := seal_points.duplicate()
	outline.append(seal_points[0])
	draw_polyline(outline, Color("4b2415"), 2.2 * mark_scale, true)
	draw_circle(center, 10.5 * mark_scale, Color("f1bd55"))
	draw_arc(center, 10.5 * mark_scale, 0.0, TAU, 20, Color("70401e"), 1.7 * mark_scale, true)
	var font_size := 16 if not _preview else 11
	var text_width := 24.0 * mark_scale
	draw_string(
		ThemeDB.fallback_font,
		center + Vector2(-text_width * 0.5, 5.5 * mark_scale),
		str(score_seal_value()),
		HORIZONTAL_ALIGNMENT_CENTER,
		text_width,
		font_size,
		Color("3a1b12")
	)


func _draw_echo_emblem(center: Vector2, mark_scale: float) -> void:
	var ink := Color("143a3e")
	var shine := Color(0.71, 0.96, 0.92, 0.72)
	draw_circle(center, 2.8 * mark_scale, ink)
	for radius in [7.0, 12.0]:
		draw_arc(center, radius * mark_scale, -0.72, 0.72, 10, ink, 2.7 * mark_scale, true)
		draw_arc(center, radius * mark_scale, PI - 0.72, PI + 0.72, 10, ink, 2.7 * mark_scale, true)
	draw_arc(center, 7.0 * mark_scale, -0.58, 0.58, 8, shine, 1.0 * mark_scale, true)


func _draw_retreat_emblem(center: Vector2, mark_scale: float) -> void:
	var ink := Color("293714")
	var line_width := 3.2 * mark_scale
	draw_line(
		center + Vector2(11.0, 0.0) * mark_scale,
		center + Vector2(-8.0, 0.0) * mark_scale,
		ink,
		line_width,
		true
	)
	draw_polyline(PackedVector2Array([
		center + Vector2(-2.0, -7.0) * mark_scale,
		center + Vector2(-10.0, 0.0) * mark_scale,
		center + Vector2(-2.0, 7.0) * mark_scale,
	]), ink, line_width, true)
	draw_arc(
		center + Vector2(5.0, -5.0) * mark_scale,
		6.0 * mark_scale,
		-1.55,
		-0.05,
		8,
		Color(0.83, 0.95, 0.48, 0.72),
		1.4 * mark_scale,
		true
	)


func _draw_spark_emblem(center: Vector2, mark_scale: float) -> void:
	var ink := Color("5a2053")
	var glow := Color(1.0, 0.66, 0.91, 0.78)
	var points := PackedVector2Array([
		center + Vector2(0, -13) * mark_scale,
		center + Vector2(3, -3) * mark_scale,
		center + Vector2(13, 0) * mark_scale,
		center + Vector2(3, 3) * mark_scale,
		center + Vector2(0, 13) * mark_scale,
		center + Vector2(-3, 3) * mark_scale,
		center + Vector2(-13, 0) * mark_scale,
		center + Vector2(-3, -3) * mark_scale,
		center + Vector2(0, -13) * mark_scale,
	])
	draw_colored_polygon(points, glow)
	draw_polyline(points, ink, 2.5 * mark_scale, true)
	draw_circle(center, 2.5 * mark_scale, Color("fff0cf"))


func _draw_crack(origin: Vector2, offsets: Array[Vector2]) -> void:
	var points := PackedVector2Array()
	for offset: Vector2 in offsets:
		points.append(origin + offset)
	draw_polyline(points, Color("5a251e"), 3.2, true)
	draw_polyline(points, Color(0.18, 0.06, 0.04, 0.38), 1.2, true)


func _draw_cuckoo_marks(center: Vector2, radius_x: float, radius_y: float) -> void:
	for offset in [Vector2(-0.34, 0.03), Vector2(0.32, -0.18), Vector2(0.18, 0.34)]:
		var spot_center := center + Vector2(offset.x * radius_x, offset.y * radius_y)
		draw_circle(spot_center, radius_x * 0.11, Color(0.06, 0.23, 0.27, 0.58))
		draw_circle(spot_center - Vector2(2, 2), radius_x * 0.04, Color(0.52, 0.88, 0.86, 0.48))


func _draw_plover_marks(center: Vector2, radius_x: float, radius_y: float) -> void:
	var mark_color := Color(0.16, 0.23, 0.05, 0.70)
	for vertical_offset in [-0.20, 0.08, 0.36]:
		var point := center + Vector2(-radius_x * 0.26, radius_y * vertical_offset)
		draw_polyline(PackedVector2Array([
			point + Vector2(radius_x * 0.26, -radius_y * 0.09),
			point,
			point + Vector2(radius_x * 0.26, radius_y * 0.09),
		]), mark_color, 4.0, true)


func _draw_spoonbill_marks(center: Vector2, radius_x: float, radius_y: float) -> void:
	var mark_color := Color(0.35, 0.12, 0.32, 0.54)
	for vertical_offset in [-0.18, 0.08, 0.34]:
		var line_center := center + Vector2(0.0, radius_y * vertical_offset)
		draw_arc(line_center, radius_x * 0.48, 0.20, PI - 0.20, 14, mark_color, 3.0, true)
