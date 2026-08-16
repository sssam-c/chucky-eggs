extends Control

var _slot_circuit_ids: Array[String] = []
var _slot_circuit_colors: Array[Color] = []
var _highlighted_circuit_id := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func material_texture_count() -> int:
	return 0


func set_slot_count(slot_count: int) -> void:
	assert(slot_count == 5, "The machine has exactly five slots.")


func set_belt_section_appearances(circuit_ids: Array, colors: Array) -> void:
	_slot_circuit_ids.assign(circuit_ids)
	_slot_circuit_colors.assign(colors)
	queue_redraw()


func belt_section_circuit_id(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= _slot_circuit_ids.size():
		return ""
	return _slot_circuit_ids[slot_index]


func set_highlighted_circuit(circuit_id: String) -> void:
	if _highlighted_circuit_id == circuit_id:
		return
	_highlighted_circuit_id = circuit_id
	queue_redraw()


func highlighted_circuit_id() -> String:
	return _highlighted_circuit_id


func _draw() -> void:
	# Flat temporary workshop wall. Final material treatment belongs to art.
	draw_rect(Rect2(Vector2.ZERO, size), Color("080707"))
	for plank_y in range(0, int(size.y), 54):
		var shade := Color("201915") if int(plank_y / 54) % 2 == 0 else Color("271e19")
		draw_rect(Rect2(0, plank_y, size.x, 52), shade)
		draw_line(Vector2(0, plank_y + 52), Vector2(size.x, plank_y + 52), Color("0f0d0c"), 3.0)

	# The ambience layer owns the soft workshop light; this durable component
	# keeps only physical fixtures and materials.
	_draw_contact_shadow(Rect2(1092, 54, 105, 105), 8.0)
	draw_rect(Rect2(1092, 54, 105, 105), Color("3a180e"), true)
	draw_rect(Rect2(1100, 62, 89, 89), Color("b14818"), true)
	for bar in [1144.0]:
		draw_line(Vector2(bar, 62), Vector2(bar, 151), Color("40170f"), 6.0)
		draw_line(Vector2(1100, 106), Vector2(1189, 106), Color("40170f"), 6.0)

	# Cyan supply pipe and three-egg chute.
	_draw_spoon_mount_shadows()
	_draw_pipe(Vector2(34, 8), Vector2(34, 278), 42.0)
	_draw_pipe(Vector2(34, 18), Vector2(148, 18), 42.0)
	draw_rect(Rect2(13, 54, 116, 246), Color(0.05, 0.15, 0.16, 0.86), true)
	draw_rect(Rect2(13, 54, 116, 246), Color("2d7d7e"), false, 5.0)
	for brace_y in [54.0, 132.0, 210.0, 294.0]:
		draw_rect(Rect2(6, brace_y - 7, 130, 14), Color("192327"), true)
		draw_line(Vector2(8, brace_y - 5), Vector2(134, brace_y - 5), Color("4ba5a1"), 3.0)
		draw_circle(Vector2(15, brace_y), 4.0, Color("c17831"))
		draw_circle(Vector2(127, brace_y), 4.0, Color("c17831"))

	_draw_straight_machine()


func _draw_straight_machine() -> void:
	# One continuous left-to-right conveyor. Four marks between the five bays
	# communicate flow without creating a second row of visual targets.
	_draw_iron_panel(Rect2(166, 314, 1050, 111))
	_draw_straight_belt_sections()
	draw_line(Vector2(171, 326), Vector2(1209, 326), Color("ad6532"), 3.0)
	for arrow_x in [380.0, 570.0, 760.0, 950.0]:
		_draw_route_arrow(Vector2(arrow_x, 339.0), Vector2.RIGHT)
	_draw_rollers(196, 1200, 391)
	draw_rect(Rect2(1199, 323, 35, 116), Color("070809"), true)
	draw_line(Vector2(1215, 335), Vector2(1232, 425), Color("b35628"), 4.0)
	# Fallen eggs land in this open collection bin and return through the hopper
	# when its current sequence is exhausted.
	draw_rect(Rect2(1128, 356, 94, 72), Color("120b06"), true)
	draw_rect(Rect2(1135, 364, 80, 58), Color("6b3d1e"), true)
	draw_line(Vector2(1134, 364), Vector2(1216, 364), Color("e0a044"), 6.0, true)
	draw_line(Vector2(1144, 373), Vector2(1152, 416), Color("2a160c"), 4.0, true)
	draw_line(Vector2(1206, 373), Vector2(1198, 416), Color("2a160c"), 4.0, true)

	# Foreground three-circuit console rails.
	_draw_iron_panel(Rect2(166, 430, 1050, 104), Color("754126"))
	draw_line(Vector2(168, 432), Vector2(1214, 432), Color("9f5529"), 4.0)
	for rail_x in [188.0, 508.0, 828.0, 1148.0]:
		draw_rect(Rect2(rail_x, 438, 14, 94), Color("2b2b2c"), true)
		draw_line(Vector2(rail_x + 3, 441), Vector2(rail_x + 3, 528), Color("754126"), 3.0)
	draw_line(Vector2(215, 438), Vector2(485, 438), Color("c43b36"), 4.0)
	draw_line(Vector2(535, 438), Vector2(805, 438), Color("287cbd"), 4.0)
	draw_line(Vector2(855, 438), Vector2(1125, 438), Color("cf4f8b"), 4.0)


func _draw_rollers(from_x: int, to_x: int, roller_y: int) -> void:
	for roller_x in range(from_x, to_x, 82):
		draw_circle(Vector2(roller_x + 3, roller_y + 5), 23.0, Color(0, 0, 0, 0.58))
		draw_circle(Vector2(roller_x, roller_y), 22.0, Color("08090a"))
		draw_circle(Vector2(roller_x, roller_y), 14.0, Color("303033"))
		draw_arc(Vector2(roller_x - 1, roller_y - 1), 14.0, PI, TAU, 14, Color(0.72, 0.66, 0.56, 0.26), 2.0, true)
		draw_circle(Vector2(roller_x, roller_y), 5.0, Color("a35b2e"))


func _draw_straight_belt_sections() -> void:
	var boundaries := [166.0, 380.0, 570.0, 760.0, 950.0, 1216.0]
	for slot_index in range(5):
		_draw_belt_section(
			Rect2(
				boundaries[slot_index] + 3.0,
				319.0,
				boundaries[slot_index + 1] - boundaries[slot_index] - 6.0,
				70.0
			),
			slot_index
		)


func _draw_belt_section(rect: Rect2, slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slot_circuit_colors.size():
		return
	var color := _slot_circuit_colors[slot_index]
	var fill := color.darkened(0.58)
	fill.a = 0.78
	var circuit_id := belt_section_circuit_id(slot_index)
	var highlighted := not _highlighted_circuit_id.is_empty() and circuit_id == _highlighted_circuit_id
	if not _highlighted_circuit_id.is_empty():
		fill = color.darkened(0.36 if highlighted else 0.74)
		fill.a = 0.96 if highlighted else 0.48
	draw_rect(rect, fill, true)
	var edge := color.lightened(0.08)
	edge.a = 1.0 if highlighted else 0.42 if not _highlighted_circuit_id.is_empty() else 0.86
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), edge, 5.0, true)
	if highlighted:
		draw_rect(rect.grow(-4.0), Color(color.lightened(0.30), 0.56), false, 2.0)
	draw_line(
		Vector2(rect.end.x, rect.position.y + 5.0),
		Vector2(rect.end.x, rect.end.y - 3.0),
		Color(0.04, 0.04, 0.05, 0.72),
		3.0,
		true
	)


func _draw_route_arrow(center: Vector2, direction: Vector2) -> void:
	var perpendicular := direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([
		center + direction * 12.0,
		center - direction * 10.0 + perpendicular * 8.0,
		center - direction * 10.0 - perpendicular * 8.0,
	]), Color("f0a23f"))


func _draw_pipe(from: Vector2, to: Vector2, width: float) -> void:
	draw_line(from, to, Color("101416"), width + 10.0, true)
	draw_line(from, to, Color("236164"), width, true)
	draw_line(from - Vector2(width * 0.18, 0), to - Vector2(width * 0.18, 0), Color(0.35, 0.76, 0.74, 0.35), 5.0, true)


func _draw_iron_panel(rect: Rect2, border := Color("6d4026")) -> void:
	_draw_contact_shadow(rect, 9.0)
	draw_rect(rect, Color("252629"), true)
	draw_rect(rect, border, false, 5.0)
	draw_line(
		rect.position + Vector2(6, 7), Vector2(rect.end.x - 6, rect.position.y + 7),
		Color(0.78, 0.55, 0.30, 0.30), 2.0, true
	)
	for corner in [
		rect.position + Vector2(10, 10),
		Vector2(rect.end.x - 10, rect.position.y + 10),
		Vector2(rect.position.x + 10, rect.end.y - 10),
		rect.end - Vector2(10, 10),
	]:
		draw_circle(corner + Vector2(1, 2), 4.5, Color(0, 0, 0, 0.52))
		draw_circle(corner, 3.8, Color("9a6537"))
		draw_circle(corner - Vector2(1, 1), 1.2, Color(1.0, 0.79, 0.47, 0.48))


func _draw_contact_shadow(rect: Rect2, depth: float) -> void:
	for layer_index in range(4, 0, -1):
		var spread := float(layer_index) * 2.0
		var shadow_rect := rect.grow(spread)
		shadow_rect.position.y += depth * float(layer_index) / 4.0
		draw_rect(shadow_rect, Color(0, 0, 0, 0.035 + layer_index * 0.018), true)


func _draw_spoon_mount_shadows() -> void:
	for spoon_index in range(5):
		var center := Vector2(294.5 + spoon_index * 190.0, 184.0)
		_draw_oval(center + Vector2(6, 7), Vector2(34, 22), Color(0, 0, 0, 0.30))


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for point_index in range(28):
		var angle := TAU * float(point_index) / 28.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
