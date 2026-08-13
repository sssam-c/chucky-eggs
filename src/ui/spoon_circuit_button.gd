extends Button

signal circuit_requested(circuit_id: String)

@export var circuit_id := "red"
@export var slot_indices: Array[int] = []
@export var circuit_color := Color("b6322c")
@export_enum("diamond", "circle", "spark") var circuit_symbol := "diamond"

var press_amount := 0.0:
	set(value):
		press_amount = clampf(value, 0.0, 1.0)
		queue_redraw()

var _available := false
var _target_descriptions: Array[String] = []


func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = ""
	queue_redraw()


func set_available(available: bool) -> void:
	_available = available
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


func _refresh_accessibility() -> void:
	tooltip_text = ""
	accessibility_name = "%s %s circuit" % [circuit_id.capitalize(), circuit_symbol]
	var slot_names: Array[String] = []
	for slot_index: int in slot_indices:
		slot_names.append(str(slot_index + 1))
	var connection_text := "slot %s" % slot_names[0] if slot_names.size() == 1 else "slots %s and %s" % slot_names
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
	var down := press_amount * 10.0
	var highlighted := (is_hovered() or has_focus()) and _available
	var top_color := circuit_color if _available else circuit_color.darkened(0.48)
	if highlighted:
		top_color = circuit_color.lightened(0.20)
	var outline := Color("ffe3a1") if highlighted else circuit_color.darkened(0.58)

	draw_rect(Rect2(8, 18, size.x - 16, size.y - 14), Color(0.0, 0.0, 0.0, 0.62), true)
	var top := PackedVector2Array([
		Vector2(18, 7 + down),
		Vector2(size.x - 18, 7 + down),
		Vector2(size.x - 7, size.y - 28 + down * 0.35),
		Vector2(7, size.y - 28 + down * 0.35),
	])
	draw_colored_polygon(top, top_color)
	var outline_points := top.duplicate()
	outline_points.append(top[0])
	draw_polyline(outline_points, outline, 4.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(7, size.y - 28 + down * 0.35),
		Vector2(size.x - 7, size.y - 28 + down * 0.35),
		Vector2(size.x - 12, size.y - 10 + down * 0.2),
		Vector2(12, size.y - 10 + down * 0.2),
	]), circuit_color.darkened(0.36) if _available else Color("4a3a38"))
	draw_line(Vector2(18, 16 + down), Vector2(size.x - 18, 16 + down), Color(1.0, 1.0, 0.90, 0.42), 3.0)

	var ink := Color("fff0cf") if _available else Color("aa9c88")
	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 40 + down),
		circuit_id.to_upper(),
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x - 36,
		25,
		ink
	)
	var slot_text: Array[String] = []
	for slot_index: int in slot_indices:
		slot_text.append(str(slot_index + 1))
	var mapping := " + ".join(slot_text)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 70 + down * 0.7),
		mapping,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x - 36,
		19,
		ink
	)
	_draw_symbol(Vector2(size.x * 0.5 - 36.0, 64.0 + down * 0.7), ink)


func _draw_symbol(center: Vector2, color: Color) -> void:
	match circuit_symbol:
		"circle":
			draw_arc(center, 8.0, 0.0, TAU, 20, color, 3.0, true)
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
