extends Control

const CONVEYOR_ENTRY_LOCAL := Vector2(224.0, 408.0)
const HOPPER_OUTLET_LOCAL := Vector2(224.0, 408.0)
const CONVEYOR_PANEL_RECT := Rect2(206.0, 386.0, 686.0, 96.0)
const BIN_VISUAL_RECT := Rect2(806.0, 514.0, 140.0, 174.0)

var _slot_circuit_ids: Array[String] = []
var _slot_circuit_colors: Array[Color] = []
var _highlighted_circuit_id := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func material_texture_count() -> int:
	return 0


func uses_curved_bin_exit() -> bool:
	return true


func hopper_outlet_global_position() -> Vector2:
	return get_global_transform() * HOPPER_OUTLET_LOCAL


func conveyor_entry_global_position() -> Vector2:
	return get_global_transform() * CONVEYOR_ENTRY_LOCAL


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
	# Gravity hopper and three-egg magazine. The lowest visible egg is next,
	# matching the downward queue motion before it reaches the conveyor.
	_draw_spoon_mount_shadows()
	_draw_supply_hopper()

	_draw_straight_machine()


func _draw_straight_machine() -> void:
	# One continuous left-to-right conveyor. Four marks between the five bays
	# communicate flow without creating a second row of visual targets.
	_draw_iron_panel(CONVEYOR_PANEL_RECT)
	_draw_straight_belt_sections()
	draw_line(Vector2(211, 398), Vector2(887, 398), Color("ad6532"), 3.0)
	for arrow_x in [351.0, 486.0, 621.0, 756.0]:
		_draw_route_arrow(Vector2(arrow_x, 411.0), Vector2.RIGHT)
	_draw_rollers(232, 886, 457)
	_draw_curved_bin_exit()

	# Fallen eggs land in this open collection bin and return through the hopper
	# when its current sequence is exhausted. Its larger face is also the click
	# target for inspecting stored eggs.
	draw_rect(BIN_VISUAL_RECT, Color("120b06"), true)
	draw_rect(BIN_VISUAL_RECT.grow(-8.0), Color("6b3d1e"), true)
	draw_rect(Rect2(816, 530, 120, 144), Color("160d08"), true)
	draw_line(Vector2(812, 528), Vector2(940, 528), Color("e0a044"), 7.0, true)
	draw_line(Vector2(828, 540), Vector2(838, 670), Color("2a160c"), 5.0, true)
	draw_line(Vector2(924, 540), Vector2(914, 670), Color("2a160c"), 5.0, true)

	# A shallow three-bay fascia gives the existing controls the remaining floor
	# space without creating a large decorative cabinet beneath the playfield.
	_draw_iron_panel(Rect2(206, 490, 594, 206), Color("754126"))
	draw_line(Vector2(208, 492), Vector2(798, 492), Color("9f5529"), 4.0)
	for rail_x in [208.0, 405.0, 603.0, 798.0]:
		draw_rect(Rect2(rail_x, 498, 10, 188), Color("2b2b2c"), true)
		draw_line(Vector2(rail_x + 3, 501), Vector2(rail_x + 3, 682), Color("754126"), 2.0)
	draw_line(Vector2(220, 498), Vector2(386, 498), Color("c43b36"), 4.0)
	draw_line(Vector2(418, 498), Vector2(584, 498), Color("287cbd"), 4.0)
	draw_line(Vector2(616, 498), Vector2(782, 498), Color("cf4f8b"), 4.0)
	for bolt in [Vector2(226, 510), Vector2(395, 510), Vector2(593, 510), Vector2(788, 510), Vector2(226, 677), Vector2(395, 677), Vector2(593, 677), Vector2(788, 677)]:
		draw_circle(bolt, 3.5, Color("b56c32"))


func _draw_curved_bin_exit() -> void:
	# The curve begins only after bay five. It is a physical fall-off route into
	# the existing bin, not another gameplay position.
	var center := Vector2(892, 471)
	for stroke in [
		{"color": Color("070809"), "width": 84.0},
		{"color": Color("252629"), "width": 74.0},
		{"color": Color("754126"), "width": 66.0},
		{"color": Color("17191b"), "width": 56.0},
	]:
		draw_arc(
			center, 45.0, -PI * 0.5, 0.0, 24,
			stroke.color, stroke.width, true
		)
		draw_line(
			Vector2(937, 471), Vector2(937, 520),
			stroke.color, stroke.width, true
		)
	draw_line(Vector2(891, 426), Vector2(923, 441), Color("e0a044"), 3.0, true)
	_draw_route_arrow(Vector2(937, 489), Vector2.DOWN)


func _draw_rollers(from_x: int, to_x: int, roller_y: int) -> void:
	for roller_x in range(from_x, to_x, 82):
		draw_circle(Vector2(roller_x + 3, roller_y + 5), 23.0, Color(0, 0, 0, 0.58))
		draw_circle(Vector2(roller_x, roller_y), 22.0, Color("08090a"))
		draw_circle(Vector2(roller_x, roller_y), 14.0, Color("303033"))
		draw_arc(Vector2(roller_x - 1, roller_y - 1), 14.0, PI, TAU, 14, Color(0.72, 0.66, 0.56, 0.26), 2.0, true)
		draw_circle(Vector2(roller_x, roller_y), 5.0, Color("a35b2e"))


func _draw_straight_belt_sections() -> void:
	var boundaries := [210.0, 351.0, 486.0, 621.0, 756.0, 891.0]
	for slot_index in range(5):
		_draw_belt_section(
			Rect2(
				boundaries[slot_index] + 3.0,
				391.0,
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


func _draw_supply_hopper() -> void:
	var hopper_bounds := Rect2(4, 4, 226, 422)
	_draw_contact_shadow(hopper_bounds, 8.0)

	# Wide receiving bowl and glass-fronted gravity magazine. The three preview
	# eggs occupy this vessel rather than floating in a narrow pipe.
	var bowl := PackedVector2Array([
		Vector2(8, 12), Vector2(214, 12), Vector2(202, 65),
		Vector2(190, 78), Vector2(30, 78), Vector2(18, 65),
	])
	draw_colored_polygon(bowl, Color("252629"))
	var bowl_inner := PackedVector2Array([
		Vector2(20, 25), Vector2(202, 25), Vector2(193, 56),
		Vector2(183, 66), Vector2(39, 66), Vector2(29, 56),
	])
	draw_colored_polygon(bowl_inner, Color("17383a"))
	draw_polyline(
		PackedVector2Array([
			Vector2(8, 12), Vector2(214, 12), Vector2(202, 65),
			Vector2(190, 78), Vector2(30, 78), Vector2(18, 65), Vector2(8, 12),
		]),
		Color("8b512e"),
		5.0,
		true
	)
	draw_line(Vector2(17, 21), Vector2(205, 21), Color("e0a044"), 4.0, true)

	var magazine := Rect2(18, 66, 184, 300)
	draw_rect(magazine, Color("111719"), true)
	draw_rect(magazine.grow(-5.0), Color(0.07, 0.31, 0.32, 0.64), true)
	draw_line(Vector2(32, 77), Vector2(32, 352), Color(0.35, 0.76, 0.74, 0.30), 4.0, true)
	draw_rect(magazine, Color("2d7d7e"), false, 5.0)

	# The tapered throat ends within the conveyor's vertical profile and feeds
	# directly into bay one. No part of the hopper hangs below the track.
	var outlet := PackedVector2Array([
		Vector2(18, 350), Vector2(202, 350), Vector2(212, 382),
		Vector2(230, 390), Vector2(230, 426), Vector2(205, 426),
		Vector2(184, 382), Vector2(38, 382),
	])
	draw_colored_polygon(outlet, Color("252629"))
	draw_polyline(
		PackedVector2Array([
			Vector2(18, 350), Vector2(202, 350), Vector2(212, 382),
			Vector2(230, 390), Vector2(230, 426), Vector2(205, 426),
			Vector2(184, 382), Vector2(38, 382), Vector2(18, 350),
		]),
		Color("8b512e"),
		5.0,
		true
	)
	draw_line(Vector2(207, 399), Vector2(228, 399), Color("e0a044"), 3.0, true)

	# Downward chevrons reinforce queue direction without competing with egg labels.
	for arrow_y in [130.0, 225.0, 320.0]:
		_draw_route_arrow(Vector2(211, arrow_y), Vector2.DOWN)

	for bolt in [Vector2(26, 74), Vector2(194, 74), Vector2(26, 358), Vector2(194, 358)]:
		draw_circle(bolt, 4.0, Color("c17831"))
		draw_circle(bolt - Vector2(1, 1), 1.2, Color(1.0, 0.79, 0.47, 0.52))


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
		var center := Vector2(283.0 + spoon_index * 135.0, 174.0)
		_draw_oval(center + Vector2(6, 7), Vector2(34, 22), Color(0, 0, 0, 0.30))


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for point_index in range(28):
		var angle := TAU * float(point_index) / 28.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
