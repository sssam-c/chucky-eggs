extends Control

var intensity := 0.0:
	set(value):
		intensity = clampf(value, 0.0, 1.0)
		queue_redraw()

var _from := Vector2.ZERO
var _to := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_connection(from_global: Vector2, to_global: Vector2) -> void:
	var inverse := get_global_transform().affine_inverse()
	_from = inverse * from_global
	_to = inverse * to_global
	intensity = 0.15
	visible = true


func clear_connection() -> void:
	visible = false
	intensity = 0.0


func _draw() -> void:
	if not visible:
		return
	var midpoint := (_from + _to) * 0.5 + Vector2(0, 28)
	var points := PackedVector2Array()
	for step in range(17):
		var t := float(step) / 16.0
		var first := _from.lerp(midpoint, t)
		var second := midpoint.lerp(_to, t)
		points.append(first.lerp(second, t))
	var glow := Color(0.18, 1.0, 0.94, intensity * 0.22)
	var core := Color(0.58, 1.0, 0.96, intensity * 0.94)
	draw_polyline(points, glow, 13.0, true)
	draw_polyline(points, core, 3.0, true)
	for endpoint in [_from, _to]:
		draw_circle(endpoint, 13.0 + intensity * 5.0, glow)
		draw_arc(endpoint, 10.0 + intensity * 3.0, 0, TAU, 20, core, 2.5, true)
