extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	# Warm workshop glow and right-hand hatch.
	draw_circle(Vector2(710, 92), 62.0, Color(0.72, 0.28, 0.06, 0.08))
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

	# Rear mechanism rail and copper linkages.
	draw_rect(Rect2(174, 257, 1035, 24), Color("17191b"), true)
	draw_rect(Rect2(174, 257, 1035, 24), Color("704224"), false, 4.0)
	for station in range(5):
		var center_x := 282.0 + station * 190.0
		draw_line(Vector2(center_x + 62, 268), Vector2(center_x, 457), Color("4e2416"), 13.0, true)
		draw_line(Vector2(center_x + 62, 268), Vector2(center_x, 457), Color("c76b2e"), 5.0, true)
		draw_circle(Vector2(center_x + 62, 268), 8.0, Color("d6873c"))

	# Conveyor body, upper tray, rollers, and drop mouth.
	draw_rect(Rect2(166, 314, 1050, 111), Color("171719"), true)
	draw_rect(Rect2(166, 314, 1050, 111), Color("6d4026"), false, 5.0)
	draw_line(Vector2(171, 326), Vector2(1209, 326), Color("ad6532"), 3.0)
	for roller_x in range(196, 1200, 82):
		draw_circle(Vector2(roller_x, 391), 22.0, Color("08090a"))
		draw_circle(Vector2(roller_x, 391), 14.0, Color("303033"))
		draw_circle(Vector2(roller_x, 391), 5.0, Color("a35b2e"))
	draw_rect(Rect2(1199, 323, 35, 116), Color("070809"), true)
	draw_line(Vector2(1215, 335), Vector2(1232, 425), Color("b35628"), 4.0)

	# Foreground key rails.
	draw_rect(Rect2(166, 430, 1050, 104), Color("0b0b0d"), true)
	draw_line(Vector2(168, 432), Vector2(1214, 432), Color("9f5529"), 4.0)
	for station in range(6):
		var rail_x := 173.0 + station * 190.0
		draw_rect(Rect2(rail_x, 438, 14, 94), Color("2b2b2c"), true)
		draw_line(Vector2(rail_x + 3, 441), Vector2(rail_x + 3, 528), Color("754126"), 3.0)


func _draw_pipe(from: Vector2, to: Vector2, width: float) -> void:
	draw_line(from, to, Color("101416"), width + 10.0, true)
	draw_line(from, to, Color("236164"), width, true)
	draw_line(from - Vector2(width * 0.18, 0), to - Vector2(width * 0.18, 0), Color(0.35, 0.76, 0.74, 0.35), 5.0, true)
