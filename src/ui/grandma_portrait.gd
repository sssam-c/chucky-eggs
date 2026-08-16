class_name GrandmaPortrait
extends Control

var _reduced_motion := false
var _idle_time := 0.0
var _hunger_ratio := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(delta: float) -> void:
	if _reduced_motion:
		return
	_idle_time = fmod(_idle_time + delta, TAU * 4.0)
	queue_redraw()


func set_reduced_motion(reduced: bool) -> void:
	_reduced_motion = reduced
	set_process(not reduced)
	if reduced:
		_idle_time = 0.0
	queue_redraw()


func is_idle_motion_active() -> bool:
	return is_processing() and not _reduced_motion


func set_hunger_ratio(ratio: float) -> void:
	_hunger_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func hunger_ratio() -> float:
	return _hunger_ratio


func bowl_global_position() -> Vector2:
	var design_size := Vector2(126.0, 150.0)
	var portrait_scale := minf(size.x / design_size.x, size.y / design_size.y)
	var portrait_offset := (size - design_size * portrait_scale) * 0.5
	return get_global_transform() * (
		portrait_offset + Vector2(63.0, 111.0) * portrait_scale
	)


func _draw() -> void:
	var design_size := Vector2(126.0, 150.0)
	var portrait_scale := minf(size.x / design_size.x, size.y / design_size.y)
	var portrait_offset := (size - design_size * portrait_scale) * 0.5
	draw_set_transform(portrait_offset, 0.0, Vector2.ONE * portrait_scale)
	var bob := sin(_idle_time * 1.8) * 1.5 if not _reduced_motion else 0.0
	var blink := absf(sin(_idle_time * 0.73)) > 0.985 if not _reduced_motion else false
	var origin := Vector2(design_size.x * 0.5, 8.0 + bob)

	# Chair and apron establish a readable seated silhouette at HUD scale.
	draw_rect(Rect2(origin + Vector2(-45, 68), Vector2(90, 54)), Color("51331f"), true)
	draw_circle(origin + Vector2(0, 94), 44.0, Color("253b3a"))
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(-30, 74), origin + Vector2(30, 74),
		origin + Vector2(39, 122), origin + Vector2(-39, 122),
	]), Color("d79b3b"))
	draw_line(origin + Vector2(0, 78), origin + Vector2(0, 119), Color("ffe09a"), 3.0)

	# Hair, bun, face and glasses are deliberately flat temporary art.
	draw_circle(origin + Vector2(31, 25), 17.0, Color("d8d1c2"))
	draw_circle(origin + Vector2(0, 43), 38.0, Color("d8d1c2"))
	draw_circle(origin + Vector2(0, 48), 31.0, Color("d8a976"))
	draw_circle(origin + Vector2(-25, 42), 9.0, Color("e2ddd2"))
	draw_circle(origin + Vector2(25, 42), 9.0, Color("e2ddd2"))

	for eye_x in [-12.0, 12.0]:
		draw_arc(origin + Vector2(eye_x, 47), 9.0, 0.0, TAU, 20, Color("4a342b"), 2.0)
		if blink:
			draw_line(
				origin + Vector2(eye_x - 3, 47),
				origin + Vector2(eye_x + 3, 47), Color("3a2923"), 2.0
			)
		else:
			draw_circle(origin + Vector2(eye_x, 47), 2.1, Color("2b211f"))
	draw_line(origin + Vector2(-3, 47), origin + Vector2(3, 47), Color("4a342b"), 2.0)
	# The mouth is sweet at first glance and wrong on the second: too wide,
	# crowded with tiny teeth, and most open while her appetite is empty.
	var mouth_radii := Vector2(
		lerpf(13.0, 9.0, _hunger_ratio),
		lerpf(6.5, 3.5, _hunger_ratio)
	)
	_draw_ellipse(origin + Vector2(0, 62), mouth_radii, Color("291313"))
	for tooth_x in [-7.0, -2.5, 2.5, 7.0]:
		draw_rect(
			Rect2(origin + Vector2(tooth_x - 1.5, 57.5), Vector2(3.0, 3.5)),
			Color("fff3d2"), true
		)

	# Eager hands and a waiting bowl turn the portrait into a persistent actor.
	for hand_x in [-32.0, 32.0]:
		draw_circle(origin + Vector2(hand_x, 99), 11.0, Color("c98e63"))
		draw_circle(origin + Vector2(hand_x - signf(hand_x) * 2.0, 97), 4.0, Color("e0ad7d"))
	_draw_ellipse(origin + Vector2(0, 111), Vector2(35, 10), Color("2a1710"))
	_draw_ellipse(origin + Vector2(0, 108), Vector2(32, 8), Color("b17634"))
	_draw_ellipse(origin + Vector2(0, 106), Vector2(27, 5), Color("17100c"))


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for point_index in range(28):
		var angle := TAU * float(point_index) / 28.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
