extends Control

var _appetite_ratio := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_appetite_ratio(ratio: float) -> void:
	_appetite_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	# Heavy timber and rivets make this read as a permanent machine bay rather
	# than a UI card placed over the workshop.
	var arch_color := Color("6f4124")
	var arch_highlight := Color("b06b32")
	draw_line(Vector2(15, 258), Vector2(15, 122), arch_color, 13.0, true)
	draw_arc(Vector2(143, 122), 128.0, PI, TAU, 40, arch_color, 13.0, true)
	draw_line(Vector2(271, 122), Vector2(271, 258), arch_color, 13.0, true)
	draw_line(Vector2(18, 258), Vector2(268, 258), arch_color, 9.0, true)
	draw_arc(Vector2(143, 122), 120.0, PI, TAU, 40, arch_highlight, 2.0, true)

	for bolt in [Vector2(12, 12), Vector2(274, 12), Vector2(12, 682), Vector2(274, 682), Vector2(26, 248), Vector2(260, 248)]:
		draw_circle(bolt, 4.0, Color("d08a3c"))
		draw_circle(bolt - Vector2(1, 1), 1.3, Color(1.0, 0.85, 0.55, 0.62))

	# Repeated faceplate seams unify the character, meters, and controls as one
	# vertical information rail.
	for seam_y in [270.0, 438.0, 548.0]:
		draw_line(Vector2(12, seam_y), Vector2(274, seam_y), Color("332016"), 3.0)
