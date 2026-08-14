extends Control

@export var slot_index := -1
@export var circuit_id := "red"
@export var circuit_color := Color("b6322c")
@export_enum("diamond", "circle", "triangle", "hexagon", "spark") var circuit_symbol := "diamond"

const DEFAULT_SINGLE_CONTACT := Vector2(85.0, 170.0)
const SINGLE_HINGE_TO_CONTACT := 32.0
const SINGLE_STORED_RISE := 96.0
const STORED_BOWL_RADII := Vector2(31.0, 43.0)
const CONTACT_BOWL_RADII := Vector2(44.0, 11.0)
const PAIRED_SPINE_OFFSET := 70.0
const PAIRED_ARM_LENGTH := 72.0
const PAIRED_PIVOT_RISE := 18.0

var strike_amount := 0.0:
	set(value):
		strike_amount = clampf(value, -0.12, 1.0)
		# Stored spoons belong to the back wall; a tipped bowl passes in front
		# of the conveyor and must visibly cover the egg crown at contact.
		z_index = 5 if strike_amount >= 0.5 else 0
		queue_redraw()

var _bowl_size_scale := 1.0
var _has_paired_carriage := false
var _paired_targets: Array[Vector2] = []
var _single_contact_target := DEFAULT_SINGLE_CONTACT


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_strike_amount(amount: float) -> void:
	strike_amount = amount


func reset_pose() -> void:
	strike_amount = 0.0


func pivot_global_position() -> Vector2:
	if _has_paired_carriage:
		var midpoint := (_paired_targets[0] + _paired_targets[1]) * 0.5
		return get_global_transform() * (midpoint + Vector2(PAIRED_SPINE_OFFSET, 0.0))
	return get_global_transform() * _single_hinge()


func stored_bowl_global_position() -> Vector2:
	if _has_paired_carriage:
		return stored_bowl_global_positions()[0]
	return get_global_transform() * _single_stored_bowl()


func stored_bowl_global_positions() -> Array[Vector2]:
	if not _has_paired_carriage:
		return [stored_bowl_global_position()]
	var points: Array[Vector2] = []
	for head: Vector2 in _paired_head_positions(0.0):
		points.append(get_global_transform() * head)
	return points


func current_bowl_global_positions() -> Array[Vector2]:
	if not _has_paired_carriage:
		return [get_global_transform() * _single_bowl_position(strike_amount)]
	var points: Array[Vector2] = []
	for head: Vector2 in _paired_head_positions(strike_amount):
		points.append(get_global_transform() * head)
	return points


func spine_global_position() -> Vector2:
	if not _has_paired_carriage:
		return pivot_global_position()
	var midpoint := (_paired_targets[0] + _paired_targets[1]) * 0.5
	return get_global_transform() * Vector2(
		_paired_targets[0].x + PAIRED_SPINE_OFFSET,
		midpoint.y
	)


func contact_bowl_global_position() -> Vector2:
	if _has_paired_carriage:
		return get_global_transform() * _paired_targets[0]
	return get_global_transform() * _single_contact_target


func contact_points_global() -> Array[Vector2]:
	if not _has_paired_carriage:
		return [contact_bowl_global_position()]
	var points: Array[Vector2] = []
	for target: Vector2 in _paired_targets:
		points.append(get_global_transform() * target)
	return points


func set_bowl_scale(value: float) -> void:
	_bowl_size_scale = maxf(value, 1.0)
	queue_redraw()


func bowl_scale() -> float:
	return _bowl_size_scale


func configure_wall_spoon(contact_target: Vector2) -> void:
	_has_paired_carriage = false
	_paired_targets.clear()
	_single_contact_target = contact_target
	z_index = 5 if strike_amount >= 0.5 else 0
	queue_redraw()


func is_wall_pinned_spoon() -> bool:
	return not _has_paired_carriage


func stored_bowl_screen_size() -> Vector2:
	return STORED_BOWL_RADII * 2.0 * _bowl_size_scale


func contact_bowl_screen_size() -> Vector2:
	return CONTACT_BOWL_RADII * 2.0 * _bowl_size_scale


func configure_paired_carriage(top_target: Vector2, bottom_target: Vector2) -> void:
	_has_paired_carriage = true
	_paired_targets.assign([top_target, bottom_target])
	z_index = 5 if strike_amount >= 0.5 else 0
	queue_redraw()


func clear_paired_carriage() -> void:
	_has_paired_carriage = false
	_paired_targets.clear()
	z_index = 0
	queue_redraw()


func is_paired_carriage() -> bool:
	return _has_paired_carriage


func is_idle_back_facing() -> bool:
	return true


func _draw() -> void:
	if _has_paired_carriage:
		_draw_paired_carriage()
		return
	_draw_wall_spoon()


func _draw_wall_spoon() -> void:
	var hinge := _single_hinge()
	var eased := smoothstep(0.0, 1.0, maxf(strike_amount, 0.0))
	var head := _single_bowl_position(strike_amount)
	var radii := STORED_BOWL_RADII.lerp(CONTACT_BOWL_RADII, eased) * _bowl_size_scale

	# The mounting plate and hinge remain fixed to the wall while the spoon tips
	# out toward the player, like a small drawbridge.
	draw_rect(Rect2(hinge - Vector2(27.0, 20.0), Vector2(54.0, 42.0)), Color("111316"), true)
	draw_rect(Rect2(hinge - Vector2(27.0, 20.0), Vector2(54.0, 42.0)), Color("895326"), false, 4.0)
	draw_line(hinge + Vector2(-22.0, 15.0), hinge + Vector2(22.0, 15.0), circuit_color.darkened(0.12), 4.0, true)

	# Foreshortening reverses the handle across the fixed hinge and shortens it
	# as the spoon points almost straight at the player.
	draw_line(hinge, head, Color("0b0c0e"), 15.0, true)
	draw_line(hinge, head, Color("9da09e"), 9.0, true)
	draw_line(hinge - Vector2(2.0, 0.0), head - Vector2(2.0, 0.0), Color(1.0, 0.95, 0.84, 0.48), 2.0, true)
	_draw_single_bowl(head, radii, eased)

	# The repeated symbol keeps paired Red and Blue spoons distinguishable
	# without adding labels to the mechanism.
	draw_line(hinge - Vector2(24.0, 0.0), hinge + Vector2(24.0, 0.0), Color("0b0c0e"), 17.0, true)
	draw_line(hinge - Vector2(21.0, 0.0), hinge + Vector2(21.0, 0.0), Color("b77836"), 10.0, true)
	draw_circle(hinge, 13.0, Color("111316"))
	draw_circle(hinge, 9.0, circuit_color.darkened(0.10))
	_draw_circuit_symbol(hinge, circuit_color.lightened(0.38))


func _draw_single_bowl(center: Vector2, radii: Vector2, tipped_amount: float) -> void:
	var bowl := _ellipse_points(center, radii)
	draw_colored_polygon(bowl, Color("858889"))
	var rim := bowl.duplicate()
	rim.append(bowl[0])
	draw_polyline(rim, Color("dedbd1"), 4.0 * sqrt(_bowl_size_scale), true)

	if tipped_amount < 0.45:
		# At rest the player sees the broad convex back of the upright bowl.
		draw_polyline(
			_ellipse_arc_points(center - Vector2(5.0, 4.0), radii * Vector2(0.58, 0.72), 1.85, 4.55, 16),
			Color(1.0, 0.95, 0.84, 0.46), 4.0, true
		)
		draw_polyline(
			_ellipse_arc_points(center + Vector2(3.0, 1.0), radii * Vector2(0.78, 0.80), -0.95, 0.95, 14),
			Color(0.08, 0.08, 0.09, 0.34), 4.0, true
		)
		return

	# Near contact, the opening sits above a broad silver lower shell. Its lower
	# convex edge—not the rim—is the surface that lands on the egg.
	var opening_center := center - Vector2(0.0, radii.y * 0.18)
	var opening_radii := Vector2(radii.x * 0.80, maxf(radii.y * 0.35, 3.0))
	draw_colored_polygon(_ellipse_points(opening_center, opening_radii), Color("343638"))
	draw_polyline(
		_ellipse_arc_points(opening_center, opening_radii, PI, TAU, 18),
		Color("f0ece0"), 3.0, true
	)
	draw_polyline(
		_ellipse_arc_points(center, radii * Vector2(0.92, 0.86), 0.08, PI - 0.08, 20),
		Color("bfc2c0"), 4.0, true
	)


func _single_hinge() -> Vector2:
	return _single_contact_target - Vector2(0.0, SINGLE_HINGE_TO_CONTACT)


func _single_stored_bowl() -> Vector2:
	return _single_hinge() - Vector2(0.0, SINGLE_STORED_RISE)


func _single_bowl_position(amount: float) -> Vector2:
	if amount < 0.0:
		return _single_stored_bowl() + Vector2(0.0, amount * 18.0)
	return _single_stored_bowl().lerp(
		_single_contact_target,
		smoothstep(0.0, 1.0, amount)
	)


func _ellipse_points(center: Vector2, radii: Vector2, point_count := 32) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(point_count):
		var angle := TAU * float(point_index) / float(point_count)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


func _ellipse_arc_points(
	center: Vector2,
	radii: Vector2,
	from_angle: float,
	to_angle: float,
	point_count: int
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(point_count):
		var progress := float(point_index) / float(maxi(point_count - 1, 1))
		var angle := lerpf(from_angle, to_angle, progress)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


func _draw_paired_carriage() -> void:
	if _paired_targets.size() != 2:
		return
	var heads: Array[Vector2] = _paired_head_positions(strike_amount)
	var spine_x := _paired_targets[0].x + PAIRED_SPINE_OFFSET
	var spine_top := _paired_targets[0].y - 105.0
	var spine_bottom := _paired_targets[1].y + 50.0

	# The mockup's dominant fixed gantry connects directly to its lever. Both
	# spoon arms swing around pivots on that one post; the post itself never moves.
	draw_line(Vector2(spine_x, spine_top), Vector2(spine_x, spine_bottom), Color("0b0c0e"), 22.0, true)
	draw_line(Vector2(spine_x, spine_top), Vector2(spine_x, spine_bottom), Color("9a612f"), 14.0, true)
	draw_line(Vector2(spine_x - 3.0, spine_top + 2.0), Vector2(spine_x - 3.0, spine_bottom - 2.0), Color(1.0, 0.80, 0.49, 0.45), 3.0, true)
	draw_rect(Rect2(Vector2(spine_x - 27.0, spine_top - 24.0), Vector2(54.0, 48.0)), Color("111316"), true)
	draw_rect(Rect2(Vector2(spine_x - 27.0, spine_top - 24.0), Vector2(54.0, 48.0)), circuit_color.darkened(0.35), false, 4.0)
	draw_circle(Vector2(spine_x, spine_top), 17.0, circuit_color.darkened(0.08))
	_draw_circuit_symbol(Vector2(spine_x, spine_top), circuit_color.lightened(0.32))

	for head_index in range(heads.size()):
		var head: Vector2 = heads[head_index]
		var pivot := _paired_pivot(_paired_targets[head_index])
		draw_rect(Rect2(pivot - Vector2(15.0, 18.0), Vector2(30.0, 36.0)), Color("111316"), true)
		draw_rect(Rect2(pivot - Vector2(15.0, 18.0), Vector2(30.0, 36.0)), Color("9a612f"), false, 4.0)
		draw_line(pivot, head, Color("111215"), 13.0, true)
		draw_line(pivot, head, Color("aeb0ad"), 8.0, true)
		draw_line(pivot - Vector2(0.0, 2.0), head - Vector2(0.0, 2.0), Color("f5e6c8"), 2.0, true)
		_draw_paired_bowl(head)
		draw_circle(pivot, 10.0, Color("111316"))
		draw_circle(pivot, 6.0, Color("d28a43"))
	draw_rect(Rect2(Vector2(spine_x - 17.0, spine_bottom - 15.0), Vector2(34.0, 30.0)), Color("111316"), true)
	draw_rect(Rect2(Vector2(spine_x - 17.0, spine_bottom - 15.0), Vector2(34.0, 30.0)), Color("9a612f"), false, 4.0)


func _paired_pivot(target: Vector2) -> Vector2:
	return target + Vector2(PAIRED_SPINE_OFFSET, -PAIRED_PIVOT_RISE)


func _paired_head_positions(amount: float) -> Array[Vector2]:
	var heads: Array[Vector2] = []
	for target: Vector2 in _paired_targets:
		var pivot := _paired_pivot(target)
		if amount >= 1.0:
			heads.append(target)
			continue
		var contact_vector := target - pivot
		var contact_angle := contact_vector.angle()
		var angle: float
		if amount < 0.0:
			angle = amount * 0.9
		else:
			angle = lerpf(0.0, contact_angle, smoothstep(0.0, 1.0, amount))
		heads.append(pivot + Vector2.from_angle(angle) * PAIRED_ARM_LENGTH)
	return heads


func _draw_paired_bowl(center: Vector2) -> void:
	var bowl := PackedVector2Array()
	for point_index in range(28):
		var oval_angle := TAU * float(point_index) / 28.0
		bowl.append(center + Vector2(cos(oval_angle) * 34.0, sin(oval_angle) * 26.0))
	draw_colored_polygon(bowl, Color("747779"))
	var rim := bowl.duplicate()
	rim.append(bowl[0])
	draw_polyline(rim, Color("dad6ca"), 4.0, true)
	draw_arc(center - Vector2(6.0, 3.0), 15.0, 2.55, 5.55, 12, Color(1.0, 0.94, 0.82, 0.52), 5.0, true)
	draw_arc(center + Vector2(2.0, 0.0), 26.0, -0.95, 0.95, 12, Color(0.10, 0.10, 0.11, 0.36), 4.0, true)
func _draw_circuit_symbol(center: Vector2, color: Color) -> void:
	match circuit_symbol:
		"circle":
			draw_arc(center, 7.0, 0.0, TAU, 18, color, 3.0, true)
		"triangle":
			draw_polyline(PackedVector2Array([
				center + Vector2(0, -9), center + Vector2(9, 7),
				center + Vector2(-9, 7), center + Vector2(0, -9),
			]), color, 3.0, true)
		"hexagon":
			var points := PackedVector2Array()
			for point_index in range(7):
				points.append(center + Vector2.from_angle(
					-PI * 0.5 + TAU * float(point_index) / 6.0
				) * 8.0)
			draw_polyline(points, color, 3.0, true)
		"spark":
			draw_polyline(PackedVector2Array([
				center + Vector2(0, -10), center + Vector2(3, -3),
				center + Vector2(10, 0), center + Vector2(3, 3),
				center + Vector2(0, 10), center + Vector2(-3, 3),
				center + Vector2(-10, 0), center + Vector2(-3, -3),
				center + Vector2(0, -10),
			]), color, 3.0, true)
		_:
			draw_polyline(PackedVector2Array([
				center + Vector2(0, -8), center + Vector2(8, 0), center + Vector2(0, 8), center + Vector2(-8, 0), center + Vector2(0, -8),
			]), color, 3.0, true)
