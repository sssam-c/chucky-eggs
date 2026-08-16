extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var inner := Rect2(Vector2.ZERO, size)
	draw_rect(inner, Color("c98218"), true)
	var yolk_radius := minf(8.0, maxf(3.0, size.y * 0.28))
	var yolk_spacing := yolk_radius * 3.0
	var yolk_x := yolk_radius + 4.0
	while yolk_x < size.x + yolk_radius:
		var center := Vector2(yolk_x, size.y * 0.5)
		draw_circle(
			center + Vector2(1.0, 1.5), yolk_radius + 0.5,
			Color(0.34, 0.18, 0.03, 0.48)
		)
		draw_circle(center, yolk_radius, Color("ffd52e"))
		draw_circle(
			center + Vector2(-yolk_radius * 0.25, -yolk_radius * 0.25),
			yolk_radius * 0.3, Color("fff2a1")
		)
		yolk_x += yolk_spacing
