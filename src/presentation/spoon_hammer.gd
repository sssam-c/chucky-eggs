extends Control

@export var slot_index := -1
@export var circuit_id := "red"
@export var circuit_color := Color("b6322c")
@export_enum("diamond", "circle", "spark") var circuit_symbol := "diamond"

const PIVOT := Vector2(142.0, 142.0)
const HANDLE_LENGTH := 110.0
# The bowl shares its egg slot's centre line both at rest and on contact.
# Mirrored angles keep the mount just above the slot's right shoulder.
const IDLE_ANGLE := -2.136
const CONTACT_ANGLE := -4.147

var strike_amount := 0.0:
	set(value):
		strike_amount = clampf(value, -0.12, 1.0)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_strike_amount(amount: float) -> void:
	strike_amount = amount


func reset_pose() -> void:
	strike_amount = 0.0


func pivot_global_position() -> Vector2:
	return get_global_transform() * PIVOT


func stored_bowl_global_position() -> Vector2:
	return get_global_transform() * _bowl_position(IDLE_ANGLE)


func contact_bowl_global_position() -> Vector2:
	return get_global_transform() * _bowl_position(CONTACT_ANGLE)


func is_idle_back_facing() -> bool:
	return true


func _draw() -> void:
	# Iron mounting block and orange hinge stay fixed while the spoon rotates.
	draw_rect(Rect2(PIVOT - Vector2(29, 38), Vector2(58, 65)), Color("111316"), true)
	draw_rect(Rect2(PIVOT - Vector2(29, 38), Vector2(58, 65)), Color("754528"), false, 4.0)
	draw_line(PIVOT + Vector2(-15, 22), PIVOT + Vector2(-26, 48), Color("bb5f27"), 7.0, true)

	var eased := smoothstep(0.0, 1.0, maxf(strike_amount, 0.0))
	var angle := lerpf(IDLE_ANGLE, CONTACT_ANGLE, eased)
	if strike_amount < 0.0:
		angle = IDLE_ANGLE + strike_amount * 0.8
	var axis := Vector2.from_angle(angle)
	var perpendicular := axis.orthogonal()
	var head := _bowl_position(angle)

	# Dark under-stroke makes the silhouette read against the workshop.
	draw_line(PIVOT, head, Color("111215"), 15.0, true)
	draw_line(PIVOT, head, Color("aeb0ad"), 9.0, true)
	draw_line(PIVOT + perpendicular * 2.0, head + perpendicular * 2.0, Color("f5e6c8"), 2.0, true)

	# Convex back of the bowl faces the player in the stored pose.
	var bowl := PackedVector2Array()
	for point_index in range(28):
		var oval_angle := TAU * float(point_index) / 28.0
		bowl.append(head + axis * cos(oval_angle) * 34.0 + perpendicular * sin(oval_angle) * 24.0)
	draw_colored_polygon(bowl, Color("747779"))
	var rim := bowl.duplicate()
	rim.append(bowl[0])
	draw_polyline(rim, Color("dad6ca"), 4.0, true)
	# A broad ridge and edge shadow describe the convex back, not the open bowl.
	draw_arc(head - axis * 5.0 - perpendicular * 3.0, 14.0, 2.55, 5.55, 12, Color(1.0, 0.94, 0.82, 0.52), 5.0, true)
	draw_arc(head + axis * 2.0, 25.0, -0.95, 0.95, 12, Color(0.10, 0.10, 0.11, 0.36), 4.0, true)
	draw_line(head - axis * 14.0, head + axis * 15.0, Color(0.90, 0.88, 0.81, 0.30), 3.0, true)

	draw_circle(PIVOT, 25.0, Color("111316"))
	draw_circle(PIVOT, 20.0, circuit_color.darkened(0.08))
	draw_circle(PIVOT, 13.0, Color("55575a"))
	draw_circle(PIVOT - Vector2(3, 3), 6.0, Color("aaa49a"))
	draw_circle(PIVOT, 4.0, Color("171719"))
	_draw_circuit_symbol(PIVOT + Vector2(0, 42), circuit_color.lightened(0.28))


func _bowl_position(angle: float) -> Vector2:
	return PIVOT + Vector2.from_angle(angle) * HANDLE_LENGTH


func _draw_circuit_symbol(center: Vector2, color: Color) -> void:
	match circuit_symbol:
		"circle":
			draw_arc(center, 7.0, 0.0, TAU, 18, color, 3.0, true)
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
