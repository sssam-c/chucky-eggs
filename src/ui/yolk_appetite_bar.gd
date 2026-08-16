class_name YolkAppetiteBar
extends Control

@onready var _fill_clip: Control = $FillClip

var _ratio := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_fill)
	_layout_fill()
	queue_redraw()


func set_ratio(value: float) -> void:
	_ratio = clampf(value, 0.0, 1.0)
	_layout_fill()
	queue_redraw()


func ratio() -> float:
	return _ratio


func _layout_fill() -> void:
	if not is_instance_valid(_fill_clip):
		return
	_fill_clip.position = Vector2(4.0, 4.0)
	_fill_clip.size = Vector2(maxf(0.0, (size.x - 8.0) * _ratio), maxf(0.0, size.y - 8.0))
	var yolks := _fill_clip.get_node("Yolks") as Control
	yolks.position = Vector2.ZERO
	yolks.size = Vector2(maxf(0.0, size.x - 8.0), maxf(0.0, size.y - 8.0))
	yolks.queue_redraw()


func _draw() -> void:
	draw_style_box(get_theme_stylebox("panel", "Panel"), Rect2(Vector2.ZERO, size))
	var inner := Rect2(Vector2(4.0, 4.0), size - Vector2(8.0, 8.0))
	draw_rect(inner, Color("21170f"), true)
	for marker_index in range(1, 4):
		var marker_x := inner.position.x + inner.size.x * float(marker_index) / 4.0
		draw_line(
			Vector2(marker_x, inner.position.y + 2.0),
			Vector2(marker_x, inner.end.y - 2.0),
			Color(1.0, 0.91, 0.55, 0.25), 1.0
		)

