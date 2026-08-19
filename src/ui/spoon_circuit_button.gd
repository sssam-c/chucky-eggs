extends Button

signal circuit_requested(circuit_id: String)
signal preview_changed(circuit_id: String, active: bool)

@export var circuit_id := "red"
@export var slot_indices: Array[int] = []
@export var circuit_color := Color("b6322c")
@export_enum("diamond", "circle", "triangle", "square", "hexagon", "spark") var circuit_symbol := "diamond"
@export_enum("lever", "spoon", "button") var control_style := "lever"

var press_amount := 0.0:
	set(value):
		press_amount = clampf(value, 0.0, 1.0)
		queue_redraw()

var _available := false
var _target_descriptions: Array[String] = []
var _hover_preview := false
var _focus_preview := false
var _preview_active := false


func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = ""
	queue_redraw()


func set_available(available: bool) -> void:
	_available = available
	if not available:
		_hover_preview = false
		_focus_preview = false
		_refresh_preview_state()
	disabled = not available
	mouse_filter = Control.MOUSE_FILTER_STOP if available else Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL if available else Control.FOCUS_NONE
	_refresh_accessibility()
	queue_redraw()


func set_target_descriptions(descriptions: Array[String]) -> void:
	_target_descriptions = descriptions.duplicate()
	_refresh_accessibility()


func set_press_amount(amount: float) -> void:
	press_amount = amount


func reset_pose() -> void:
	press_amount = 0.0


func control_form() -> String:
	return control_style


func mapping_text() -> String:
	var slot_names: Array[String] = []
	for slot_index: int in slot_indices:
		slot_names.append(str(slot_index + 1))
	return "+".join(slot_names)


func is_preview_active() -> bool:
	return _preview_active


func lever_handle_center() -> Vector2:
	var pivot := _lever_pivot()
	var lever_length := clampf(size.y * 0.52, 46.0, 64.0)
	var eased := smoothstep(0.0, 1.0, press_amount)
	var angle := lerpf(-2.02, -0.55, eased)
	return pivot + Vector2.from_angle(angle) * lever_length


func _refresh_accessibility() -> void:
	tooltip_text = ""
	accessibility_name = "%s %s %s" % [
		circuit_id.capitalize(), circuit_symbol, control_style,
	]
	var slot_names: Array[String] = []
	for slot_index: int in slot_indices:
		slot_names.append(str(slot_index + 1))
	if slot_names.is_empty():
		accessibility_description = "Not installed on the current machine."
		return
	var connection_text := "slot %s" % slot_names[0]
	if slot_names.size() == 2:
		connection_text = "slots %s and %s" % slot_names
	elif slot_names.size() > 2:
		connection_text = "slots %s, and %s" % [
			", ".join(slot_names.slice(0, -1)),
			slot_names[-1],
		]
	var target_text := ""
	for target_index in range(_target_descriptions.size()):
		target_text += "%sSlot %d: %s" % [
			" " if target_index > 0 else "",
			slot_indices[target_index] + 1,
			_target_descriptions[target_index],
		]
	accessibility_description = "Fires %s.%s%s" % [
		connection_text,
		" " if not target_text.is_empty() else "",
		target_text,
	]


func _draw() -> void:
	if control_style == "button":
		_draw_shape_button()
		return
	if control_style == "spoon":
		_draw_spoon_hit_area()
		return
	var highlighted := (is_hovered() or has_focus()) and _available
	var pivot := _lever_pivot()
	var handle := lever_handle_center()
	var live_color := circuit_color if _available else circuit_color.darkened(0.48)
	var outline := Color("ffe3a1") if highlighted else live_color.darkened(0.42)
	var glow_strength := 0.20 + press_amount * 0.42 if _available else 0.05

	# A coloured conduit exits the control and visually joins the rail beneath
	# the conveyor. The circuit badge on each spoon repeats the same symbol.
	draw_line(Vector2(pivot.x, 0), pivot - Vector2(0, 12), Color("0b0c0e"), 14.0, true)
	draw_line(Vector2(pivot.x, 0), pivot - Vector2(0, 12), live_color, 5.0, true)
	draw_circle(Vector2(pivot.x, 2), 7.0, Color("111316"))
	draw_circle(Vector2(pivot.x, 2), 4.0, live_color.lightened(0.18))

	# Cast base, lever gate, and pivot housing.
	_draw_oval(pivot + Vector2(4, 10), Vector2(58, 22), Color(0.0, 0.0, 0.0, 0.60))
	var base := PackedVector2Array([
		pivot + Vector2(-54, -15), pivot + Vector2(54, -15),
		pivot + Vector2(45, 18), pivot + Vector2(-45, 18),
	])
	draw_colored_polygon(base, Color("17191b"))
	var base_outline := base.duplicate()
	base_outline.append(base[0])
	draw_polyline(base_outline, outline, 4.0, true)
	draw_arc(pivot, 39.0, -2.08, -0.49, 24, Color("08090a"), 13.0, true)
	draw_arc(pivot, 39.0, -2.08, -0.49, 24, live_color.darkened(0.12), 5.0, true)
	for gate_angle in [-2.02, -1.28, -0.55]:
		var gate_point := pivot + Vector2.from_angle(gate_angle) * 39.0
		draw_circle(gate_point, 4.5, Color("d58a42") if _available else Color("59463d"))

	# The metal shaft has a dark under-stroke and a bright edge so its sweep is
	# readable even against the workshop wall.
	draw_line(pivot, handle, Color("08090a"), 15.0, true)
	draw_line(pivot, handle, Color("9da09e") if _available else Color("555554"), 9.0, true)
	draw_line(pivot + Vector2(-2, -1), handle + Vector2(-2, -1), Color(1.0, 0.95, 0.82, 0.52), 2.0, true)
	draw_circle(pivot, 19.0, Color("0c0d0f"))
	draw_circle(pivot, 14.0, live_color.darkened(0.18))
	draw_circle(pivot, 6.0, Color("a6a29a"))

	# The knob is the only visible legend: colour plus the established symbol.
	draw_circle(handle, 28.0, Color(live_color, glow_strength))
	draw_circle(handle, 22.0, Color("111316"))
	draw_circle(handle, 18.0, live_color.lightened(0.18) if highlighted else live_color)
	draw_arc(handle, 18.0, 0.0, TAU, 24, Color("fff0cf") if highlighted else outline, 3.0, true)
	draw_circle(handle - Vector2(5, 5), 4.0, Color(1.0, 0.88, 0.72, 0.40))
	_draw_symbol(handle, Color("fff0cf") if _available else Color("8e8377"))


func _draw_spoon_hit_area() -> void:
	var highlighted := (is_hovered() or has_focus()) and _available
	var live_color := circuit_color if _available else circuit_color.darkened(0.52)
	var bounds := Rect2(Vector2(28.0, 8.0), size - Vector2(56.0, 28.0))
	if highlighted:
		draw_style_box(
			_get_spoon_highlight_style(live_color),
			bounds
		)
	var badge_center := Vector2(size.x * 0.5, 24.0)
	draw_circle(badge_center, 15.0, Color("111316"))
	draw_circle(badge_center, 11.0, live_color)
	_draw_symbol(badge_center, Color("fff0cf") if _available else Color("8e8377"))


func _draw_shape_button() -> void:
	var highlighted := (is_hovered() or has_focus()) and _available
	var live_color := circuit_color if _available else circuit_color.darkened(0.58)
	var pressed_offset := roundf(press_amount * 7.0)
	var outer_rect := Rect2(5.0, 5.0 + pressed_offset, size.x - 10.0, size.y - 14.0)
	var shadow_rect := Rect2(
		outer_rect.position + Vector2(0.0, 8.0 - pressed_offset * 0.35),
		outer_rect.size
	)
	draw_style_box(_button_shadow_style(), shadow_rect)
	draw_style_box(_button_outer_style(live_color, highlighted), outer_rect)
	var face_rect := outer_rect.grow(-9.0)
	draw_style_box(_button_face_style(live_color, highlighted), face_rect)
	var symbol_center := face_rect.get_center() - Vector2(0.0, 1.0)
	_draw_filled_symbol(symbol_center, live_color, highlighted)


func _button_shadow_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.62)
	style.set_corner_radius_all(10)
	return style


func _button_outer_style(_color: Color, highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("24150e")
	style.border_color = Color("d18a35") if highlighted else Color("79502a")
	style.set_border_width_all(3)
	style.set_corner_radius_all(9)
	return style


func _button_face_style(color: Color, highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("2b1911") if _available else Color("181311")
	style.border_color = color.lightened(0.36) if highlighted else color.darkened(0.12)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	return style


func _draw_filled_symbol(center: Vector2, color: Color, highlighted: bool) -> void:
	var fill := color.lightened(0.12) if highlighted else color
	var outline := Color("fff1c4") if highlighted else color.lightened(0.34)
	var symbol_scale := minf(size.x / 150.0, size.y / 84.0)
	var radius := 22.0 * symbol_scale
	match circuit_symbol:
		"circle":
			draw_circle(center + Vector2(0.0, 4.0), radius + 2.0, Color(0.0, 0.0, 0.0, 0.48))
			draw_circle(center, radius, fill)
			draw_arc(center, radius, 0.0, TAU, 28, outline, 3.0, true)
		"triangle":
			_draw_filled_polygon(_regular_polygon(center, radius * 1.15, 3, -PI * 0.5), fill, outline)
		"square":
			var square := PackedVector2Array([
				center + Vector2(-radius, -radius), center + Vector2(radius, -radius),
				center + Vector2(radius, radius), center + Vector2(-radius, radius),
			])
			_draw_filled_polygon(square, fill, outline)
		"spark":
			var star := PackedVector2Array()
			for point_index in range(10):
				var point_radius := radius if point_index % 2 == 0 else radius * 0.46
				star.append(center + Vector2.from_angle(-PI * 0.5 + TAU * point_index / 10.0) * point_radius)
			_draw_filled_polygon(star, fill, outline)
		_:
			var diamond := PackedVector2Array([
				center + Vector2(0.0, -radius), center + Vector2(radius, 0.0),
				center + Vector2(0.0, radius), center + Vector2(-radius, 0.0),
			])
			_draw_filled_polygon(diamond, fill, outline)


func _regular_polygon(center: Vector2, radius: float, sides: int, start_angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(sides):
		points.append(center + Vector2.from_angle(start_angle + TAU * point_index / float(sides)) * radius)
	return points


func _draw_filled_polygon(points: PackedVector2Array, fill: Color, outline: Color) -> void:
	var shadow := PackedVector2Array()
	for point: Vector2 in points:
		shadow.append(point + Vector2(0.0, 5.0))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.48))
	draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, outline, 3.0, true)


func _get_spoon_highlight_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.055 + press_amount * 0.08)
	style.border_color = Color(color.lightened(0.42), 0.90)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	return style

func _lever_pivot() -> Vector2:
	return Vector2(size.x * 0.5, size.y - 36.0)


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for point_index in range(32):
		var angle := TAU * float(point_index) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _draw_symbol(center: Vector2, color: Color) -> void:
	match circuit_symbol:
		"circle":
			draw_arc(center, 8.0, 0.0, TAU, 20, color, 3.0, true)
		"triangle":
			draw_polyline(PackedVector2Array([
				center + Vector2(0, -10), center + Vector2(10, 8),
				center + Vector2(-10, 8), center + Vector2(0, -10),
			]), color, 3.0, true)
		"square":
			draw_rect(Rect2(center - Vector2(8.0, 8.0), Vector2(16.0, 16.0)), color, false, 3.0)
		"hexagon":
			var points := PackedVector2Array()
			for point_index in range(7):
				points.append(center + Vector2.from_angle(
					-PI * 0.5 + TAU * float(point_index) / 6.0
				) * 9.0)
			draw_polyline(points, color, 3.0, true)
		"spark":
			var points := PackedVector2Array([
				center + Vector2(0, -11), center + Vector2(3, -3),
				center + Vector2(11, 0), center + Vector2(3, 3),
				center + Vector2(0, 11), center + Vector2(-3, 3),
				center + Vector2(-11, 0), center + Vector2(-3, -3),
				center + Vector2(0, -11),
			])
			draw_polyline(points, color, 3.0, true)
		_:
			var points := PackedVector2Array([
				center + Vector2(0, -9), center + Vector2(9, 0), center + Vector2(0, 9), center + Vector2(-9, 0), center + Vector2(0, -9),
			])
			draw_polyline(points, color, 3.0, true)


func _on_pressed() -> void:
	if _available:
		circuit_requested.emit(circuit_id)


func _on_mouse_entered() -> void:
	_hover_preview = true
	_refresh_preview_state()


func _on_mouse_exited() -> void:
	_hover_preview = false
	_refresh_preview_state()


func _on_focus_entered() -> void:
	_focus_preview = true
	_refresh_preview_state()


func _on_focus_exited() -> void:
	_focus_preview = false
	_refresh_preview_state()


func _refresh_preview_state() -> void:
	var active := _available and (_hover_preview or _focus_preview)
	if active == _preview_active:
		return
	_preview_active = active
	preview_changed.emit(circuit_id, active)
