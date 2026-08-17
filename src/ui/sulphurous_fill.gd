class_name SulphurousFill
extends Control

const BASE_COLOUR := Color("658b2b")
const DARK_COLOUR := Color("304f22")
const BUBBLE_COLOUR := Color("9eba3b")
const HIGHLIGHT_COLOUR := Color("c6d95b")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), BASE_COLOUR, true)
	draw_rect(Rect2(Vector2(0.0, size.y * 0.72), Vector2(size.x, size.y * 0.28)), DARK_COLOUR, true)

	var spacing := 21.0
	var bubble_x := 8.0
	var bubble_index := 0
	while bubble_x < size.x + 8.0:
		var radius := 3.0 + float(bubble_index % 3)
		var bubble_y := size.y * (0.34 if bubble_index % 2 == 0 else 0.58)
		draw_circle(Vector2(bubble_x, bubble_y), radius + 1.0, DARK_COLOUR)
		draw_circle(Vector2(bubble_x, bubble_y), radius, BUBBLE_COLOUR)
		draw_circle(
			Vector2(bubble_x - radius * 0.3, bubble_y - radius * 0.3),
			maxf(1.0, radius * 0.28),
			HIGHLIGHT_COLOUR
		)
		bubble_x += spacing
		bubble_index += 1

	for drip_index in range(3):
		var drip_x := 3.0 + float(drip_index) * 7.0
		if drip_x >= size.x:
			break
		draw_circle(
			Vector2(drip_x, size.y * (0.22 + 0.17 * float(drip_index))),
			2.5,
			HIGHLIGHT_COLOUR
		)
