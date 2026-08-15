class_name WorkshopAmbience
extends Control

const MOTE_TOTAL := 14

var _phase := 0.0
var _reduced_motion := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()


func set_reduced_motion(reduced: bool) -> void:
	_reduced_motion = reduced
	if reduced:
		_phase = 0.0
	set_process(not reduced)
	queue_redraw()


func is_reduced_motion() -> bool:
	return _reduced_motion


func is_motion_active() -> bool:
	return not _reduced_motion and is_processing()


func mote_count() -> int:
	return MOTE_TOTAL


func _process(delta: float) -> void:
	_phase = fmod(_phase + delta, 12.0)
	queue_redraw()


func _draw() -> void:
	# Lighting remains visible in Reduced Motion; only its faint breathing and
	# the drifting dust freeze. These layers sit behind every gameplay object.
	var breath := 0.0 if _reduced_motion else sin(_phase * 0.74) * 0.025
	_draw_soft_glow(Vector2(1126, 104), 150.0, Color(1.0, 0.36, 0.08, 0.15 + breath))
	_draw_soft_glow(Vector2(702, 82), 205.0, Color(0.98, 0.52, 0.16, 0.055 + breath * 0.45))

	# A pair of broad, nearly transparent shafts suggests workshop air without
	# laying a bright effect over the circuit-colour decision surfaces.
	draw_colored_polygon(PackedVector2Array([
		Vector2(1018, 0), Vector2(1168, 0), Vector2(948, size.y), Vector2(778, size.y),
	]), Color(1.0, 0.58, 0.24, 0.025))
	draw_colored_polygon(PackedVector2Array([
		Vector2(614, 0), Vector2(706, 0), Vector2(600, size.y), Vector2(504, size.y),
	]), Color(1.0, 0.68, 0.34, 0.014))

	for mote_index in range(MOTE_TOTAL):
		var base := Vector2(
			fmod(71.0 + mote_index * 89.0, maxf(size.x - 80.0, 1.0)) + 40.0,
			fmod(31.0 + mote_index * 47.0, 265.0) + 18.0
		)
		var drift := Vector2.ZERO
		if not _reduced_motion:
			drift = Vector2(
				sin(_phase * 0.42 + mote_index * 1.31) * 9.0,
				-fmod(_phase * (2.1 + float(mote_index % 3)) + mote_index * 13.0, 42.0)
			)
		var alpha := 0.09 + float(mote_index % 4) * 0.018
		var radius := 1.0 + float(mote_index % 3) * 0.45
		draw_circle(base + drift, radius, Color(1.0, 0.78, 0.46, alpha))


func _draw_soft_glow(center: Vector2, radius: float, color: Color) -> void:
	for ring_index in range(9, 0, -1):
		var ratio := float(ring_index) / 9.0
		var ring_color := color
		ring_color.a *= (1.0 - ratio) * 0.18 + 0.018
		draw_circle(center, radius * ratio, ring_color)
