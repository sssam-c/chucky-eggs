extends Button

signal thwack_requested(slot_index: int)

@export var slot_index := -1

var press_amount := 0.0:
	set(value):
		press_amount = clampf(value, 0.0, 1.0)
		queue_redraw()

var _available := false
var _egg_description := ""


func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()


func set_available(available: bool) -> void:
	_available = available
	disabled = not available
	mouse_filter = Control.MOUSE_FILTER_STOP if available else Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL if available else Control.FOCUS_NONE
	_refresh_description()
	queue_redraw()


func set_egg_description(description: String) -> void:
	_egg_description = description
	_refresh_description()


func _refresh_description() -> void:
	tooltip_text = ""
	if _available:
		accessibility_name = "Thwack slot %d" % (slot_index + 1)
		accessibility_description = _egg_description
	else:
		accessibility_name = "Slot %d unavailable" % (slot_index + 1)
		accessibility_description = ""


func set_press_amount(amount: float) -> void:
	press_amount = amount


func reset_pose() -> void:
	press_amount = 0.0


func _draw() -> void:
	var down := press_amount * 10.0
	var hovered := is_hovered() and _available
	var focused := has_focus() and _available
	var top_color := Color("ffe8b4") if _available else Color("b7a482")
	if hovered or focused:
		top_color = Color("fff2c9")
	var outline := Color("e88b39") if hovered or focused else Color("553520")

	draw_rect(Rect2(8, 18, size.x - 16, size.y - 14), Color(0.0, 0.0, 0.0, 0.58), true)
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
	]), Color("a96d3c") if _available else Color("72533a"))
	draw_line(Vector2(18, 16 + down), Vector2(size.x - 18, 16 + down), Color(1.0, 1.0, 0.88, 0.48), 3.0)

	var badge_center := Vector2(size.x * 0.5, size.y - 45 + down * 0.3)
	draw_circle(badge_center, 13.0, Color("392317"))
	draw_string(ThemeDB.fallback_font, badge_center + Vector2(-4.5, 6), str(slot_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffd477"))


func _on_pressed() -> void:
	if _available and slot_index >= 0:
		thwack_requested.emit(slot_index)
