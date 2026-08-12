extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 22.0, Color("171419"))
	draw_circle(center, 18.0, Color("b96338"))
	draw_circle(center, 13.5, Color("4c4b50"))
	draw_circle(center + Vector2(-2.5, -3.0), 8.0, Color("8a8787"))
	draw_circle(center, 3.5, Color("242126"))
	draw_line(center + Vector2(-6.0, 0.0), center + Vector2(6.0, 0.0), Color("c8b59e"), 2.0, true)
