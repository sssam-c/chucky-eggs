class_name WorkshopBackdrop
extends Control

const PLANK_HEIGHT := 54.0
const LAMP_X_RATIOS := [0.35, 0.60, 0.85]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("120d0a"), true)
	_draw_planks()
	_draw_lights()
	_draw_floor()


func _draw_planks() -> void:
	var plank_count := ceili(size.y / PLANK_HEIGHT)
	for plank_index in range(plank_count):
		var top := float(plank_index) * PLANK_HEIGHT
		var plank_color := (
			Color("2a180f") if plank_index % 2 == 0 else Color("24140d")
		)
		draw_rect(Rect2(0.0, top, size.x, PLANK_HEIGHT), plank_color, true)
		draw_line(
			Vector2(0.0, top + PLANK_HEIGHT - 2.0),
			Vector2(size.x, top + PLANK_HEIGHT - 2.0),
			Color("100a08"), 4.0
		)
		draw_line(
			Vector2(0.0, top + 2.0), Vector2(size.x, top + 2.0),
			Color(0.42, 0.23, 0.11, 0.24), 2.0
		)
		var seam_offset := 160.0 if plank_index % 2 == 0 else 320.0
		var seam_x := seam_offset
		while seam_x < size.x:
			draw_line(
				Vector2(seam_x, top + 3.0),
				Vector2(seam_x, top + PLANK_HEIGHT - 3.0),
				Color("110a08"), 3.0
			)
			seam_x += 420.0
	# A heavy beam replaces the removed title banner with environmental structure.
	draw_rect(Rect2(0.0, 0.0, size.x, 58.0), Color("28170f"), true)
	draw_rect(Rect2(0.0, 52.0, size.x, 7.0), Color("6a3a18"), true)
	draw_line(Vector2(0.0, 55.0), Vector2(size.x, 55.0), Color("b66c27"), 2.0)


func _draw_lights() -> void:
	for x_ratio: float in LAMP_X_RATIOS:
		var centre := Vector2(size.x * x_ratio, 75.0)
		var cone := PackedVector2Array([
			centre + Vector2(-11.0, 10.0),
			centre + Vector2(11.0, 10.0),
			centre + Vector2(105.0, 305.0),
			centre + Vector2(-105.0, 305.0),
		])
		draw_colored_polygon(cone, Color(1.0, 0.56, 0.16, 0.035))
		draw_line(centre - Vector2(0.0, 20.0), centre - Vector2(0.0, 5.0), Color("16100d"), 6.0)
		var shade := PackedVector2Array([
			centre + Vector2(-17.0, -6.0), centre + Vector2(17.0, -6.0),
			centre + Vector2(25.0, 7.0), centre + Vector2(-25.0, 7.0),
		])
		draw_colored_polygon(shade, Color("17110e"))
		draw_polyline(shade + PackedVector2Array([shade[0]]), Color("75451f"), 3.0)
		draw_circle(centre + Vector2(0.0, 8.0), 9.0, Color(1.0, 0.71, 0.25, 0.20))
		draw_circle(centre + Vector2(0.0, 8.0), 5.0, Color("ffd25a"))


func _draw_floor() -> void:
	var floor_top := size.y - 54.0
	draw_rect(Rect2(0.0, floor_top, size.x, 54.0), Color("1b100c"), true)
	draw_line(Vector2(0.0, floor_top), Vector2(size.x, floor_top), Color("5b321b"), 5.0)
