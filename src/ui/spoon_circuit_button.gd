extends Button

signal circuit_requested(circuit_id: String)
signal preview_changed(circuit_id: String, active: bool)

@export var circuit_id := "red"
@export var slot_indices: Array[int] = []
@export var circuit_color := Color("b6322c")
@export_enum("diamond", "circle", "triangle", "hexagon", "spark") var circuit_symbol := "diamond"

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
	return "lever"


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
	accessibility_name = "%s %s lever" % [circuit_id.capitalize(), circuit_symbol]
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

	# Put the mapping on the physical control so the footer does not need to
	# repeat every circuit. The plate remains readable without circuit colour.
	var mapping := mapping_text()
	if not mapping.is_empty():
		var plate_width := maxf(54.0, 28.0 + float(mapping.length()) * 9.0)
		var plate := Rect2(
			Vector2(pivot.x - plate_width * 0.5, size.y - 25.0),
			Vector2(plate_width, 23.0)
		)
		draw_rect(Rect2(plate.position + Vector2(2, 3), plate.size), Color(0, 0, 0, 0.48), true)
		draw_rect(plate, Color("d6b675") if _available else Color("62594b"), true)
		draw_rect(plate, Color("fff0cf") if highlighted else Color("6b3d1e"), false, 2.0)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(plate.position.x, plate.position.y + 17.0),
			mapping,
			HORIZONTAL_ALIGNMENT_CENTER,
			plate.size.x,
			14,
			Color("3a1b12") if _available else Color("292421")
		)


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
