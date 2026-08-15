extends Control

var _slot_count := 5


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_slot_count(slot_count: int) -> void:
	if _slot_count == slot_count:
		return
	_slot_count = slot_count
	queue_redraw()


func _draw() -> void:
	# Timber workshop wall.
	draw_rect(Rect2(Vector2.ZERO, size), Color("100d0d"))
	for plank_y in range(0, int(size.y), 54):
		var shade := Color("1b1210") if int(plank_y / 54) % 2 == 0 else Color("211511")
		draw_rect(Rect2(0, plank_y, size.x, 52), shade)
		draw_line(Vector2(0, plank_y + 52), Vector2(size.x, plank_y + 52), Color("080707"), 3.0)
		for knot_x in range(90 + (plank_y % 83), int(size.x), 230):
			draw_circle(Vector2(knot_x, plank_y + 25), 5.0, Color("0d0908"))

	# Warm workshop glow and the starting line's right-hand hatch.
	draw_circle(Vector2(710, 92), 62.0, Color(0.72, 0.28, 0.06, 0.08))
	if _slot_count != 10:
		draw_rect(Rect2(1092, 54, 105, 105), Color("3a180e"), true)
		draw_rect(Rect2(1100, 62, 89, 89), Color("b14818"), true)
		for bar in [1144.0]:
			draw_line(Vector2(bar, 62), Vector2(bar, 151), Color("40170f"), 6.0)
			draw_line(Vector2(1100, 106), Vector2(1189, 106), Color("40170f"), 6.0)

	# Cyan supply pipe and three-egg chute.
	_draw_pipe(Vector2(34, 8), Vector2(34, 278), 42.0)
	_draw_pipe(Vector2(34, 18), Vector2(148, 18), 42.0)
	draw_rect(Rect2(13, 54, 116, 246), Color(0.05, 0.15, 0.16, 0.86), true)
	draw_rect(Rect2(13, 54, 116, 246), Color("2d7d7e"), false, 5.0)
	for brace_y in [54.0, 132.0, 210.0, 294.0]:
		draw_rect(Rect2(6, brace_y - 7, 130, 14), Color("192327"), true)
		draw_line(Vector2(8, brace_y - 5), Vector2(134, brace_y - 5), Color("4ba5a1"), 3.0)
		draw_circle(Vector2(15, brace_y), 4.0, Color("c17831"))
		draw_circle(Vector2(127, brace_y), 4.0, Color("c17831"))

	if _slot_count == 10:
		_draw_hairpin_machine()
	else:
		_draw_straight_machine()


func _draw_straight_machine() -> void:
	# One continuous left-to-right conveyor. Four marks between the five bays
	# communicate flow without creating a second row of visual targets.
	draw_rect(Rect2(166, 314, 1050, 111), Color("171719"), true)
	draw_rect(Rect2(166, 314, 1050, 111), Color("6d4026"), false, 5.0)
	draw_line(Vector2(171, 326), Vector2(1209, 326), Color("ad6532"), 3.0)
	for arrow_x in [380.0, 570.0, 760.0, 950.0]:
		_draw_route_arrow(Vector2(arrow_x, 339.0), Vector2.RIGHT)
	_draw_rollers(196, 1200, 391)
	draw_rect(Rect2(1199, 323, 35, 116), Color("070809"), true)
	draw_line(Vector2(1215, 335), Vector2(1232, 425), Color("b35628"), 4.0)

	# Foreground three-circuit console rails.
	draw_rect(Rect2(166, 430, 1050, 104), Color("0b0b0d"), true)
	draw_line(Vector2(168, 432), Vector2(1214, 432), Color("9f5529"), 4.0)
	for rail_x in [188.0, 508.0, 828.0, 1148.0]:
		draw_rect(Rect2(rail_x, 438, 14, 94), Color("2b2b2c"), true)
		draw_line(Vector2(rail_x + 3, 441), Vector2(rail_x + 3, 528), Color("754126"), 3.0)
	draw_line(Vector2(215, 438), Vector2(485, 438), Color("c43b36"), 4.0)
	draw_line(Vector2(535, 438), Vector2(805, 438), Color("287cbd"), 4.0)
	draw_line(Vector2(855, 438), Vector2(1125, 438), Color("cf4f8b"), 4.0)


func _draw_hairpin_machine() -> void:
	# A tight, target-free bend joins two touching five-bay runs.
	var route := PackedVector2Array([
		Vector2(174, 283), Vector2(1018, 283), Vector2(1052, 299),
		Vector2(1068, 331), Vector2(1052, 359), Vector2(1018, 380), Vector2(174, 380),
	])
	draw_polyline(route, Color("4e2416"), 15.0, true)
	draw_polyline(route, Color("ad6532"), 5.0, true)

	# The two casings share a seam. The narrow right cheek is visibly a bend,
	# not another egg station.
	draw_rect(Rect2(166, 230, 910, 95), Color("171719"), true)
	draw_rect(Rect2(166, 230, 910, 95), Color("6d4026"), false, 5.0)
	draw_rect(Rect2(166, 325, 910, 95), Color("171719"), true)
	draw_rect(Rect2(166, 325, 910, 95), Color("6d4026"), false, 5.0)
	draw_rect(Rect2(1035, 249, 55, 152), Color("171719"), true)
	draw_arc(Vector2(1035, 325), 76.0, -PI * 0.5, PI * 0.5, 28, Color("6d4026"), 5.0, true)
	_draw_rollers(196, 1000, 283)
	_draw_rollers(196, 1000, 380)
	# Put the direction marks on top of the conveyor casing so each leg reads
	# independently: right across the upper run, down through Pink, then left.
	for arrow_x in [346.0, 536.0, 726.0, 916.0]:
		_draw_route_arrow(Vector2(arrow_x, 243), Vector2.RIGHT)
		_draw_route_arrow(Vector2(arrow_x, 408), Vector2.LEFT)
	_draw_route_arrow(Vector2(1080, 325), Vector2.DOWN)

	# Five colour rails identify the circuit levers below the rear-wall spoon bank.
	# Repeated symbols on the mechanisms carry each rail's identity to both spoons.
	draw_line(Vector2(185, 435), Vector2(1075, 435), Color("090a0b"), 13.0, true)
	var spoon_colors := [
		Color("c43b36"), Color("287cbd"), Color("69a645"),
		Color("8f59b8"), Color("cf4f8b"),
	]
	for spoon_index in range(5):
		var center_x := 251.0 + 190.0 * spoon_index
		draw_line(Vector2(center_x - 62.0, 435), Vector2(center_x + 62.0, 435), spoon_colors[spoon_index], 5.0, true)
		draw_circle(Vector2(center_x, 435), 7.0, Color("111316"))
		draw_circle(Vector2(center_x, 435), 4.0, spoon_colors[spoon_index].lightened(0.2))

	# The lower return exits at the left edge beside slot 10.
	draw_rect(Rect2(142, 327, 30, 95), Color("070809"), true)
	draw_line(Vector2(154, 335), Vector2(130, 409), Color("b35628"), 4.0)


func _draw_rollers(from_x: int, to_x: int, roller_y: int) -> void:
	for roller_x in range(from_x, to_x, 82):
		draw_circle(Vector2(roller_x, roller_y), 22.0, Color("08090a"))
		draw_circle(Vector2(roller_x, roller_y), 14.0, Color("303033"))
		draw_circle(Vector2(roller_x, roller_y), 5.0, Color("a35b2e"))


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
