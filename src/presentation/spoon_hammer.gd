extends Control

@export var slot_index := -1
@export var circuit_id := "red"
@export var circuit_color := Color("b6322c")
@export_enum("diamond", "circle", "triangle", "hexagon", "spark") var circuit_symbol := "diamond"

const DEFAULT_SINGLE_CONTACT := Vector2(85.0, 170.0)
const SINGLE_HINGE_TO_CONTACT := 16.0
const SINGLE_STORED_RISE := 96.0
const WALL_EXTENSION_PROJECTION := 26.0
const STORED_BOWL_RADII := Vector2(31.0, 43.0)
const CONTACT_BOWL_RADII := Vector2(48.0, 15.0)
const SINGLE_FRAME_BOWL_SCALE := Vector2(
	STORED_BOWL_RADII.x / 24.0,
	STORED_BOWL_RADII.y / 34.0
)
const DOUBLE_SPOON_FRAMES := [
	preload("res://src/presentation/spoon_frames/double_spoon_00_stored.tres"),
	preload("res://src/presentation/spoon_frames/double_spoon_01_tilt.tres"),
	preload("res://src/presentation/spoon_frames/double_spoon_02_foreshorten.tres"),
	preload("res://src/presentation/spoon_frames/double_spoon_03_edge_approach.tres"),
	preload("res://src/presentation/spoon_frames/double_spoon_04_edge_on.tres"),
	preload("res://src/presentation/spoon_frames/double_spoon_05_emerge.tres"),
	preload("res://src/presentation/spoon_frames/double_spoon_06_fall.tres"),
	preload("res://src/presentation/spoon_frames/double_spoon_07_pre_contact.tres"),
	preload("res://src/presentation/spoon_frames/double_spoon_08_contact.tres"),
]

@onready var _bowl_layer: Control = $ForegroundBowls

var strike_amount := 0.0:
	set(value):
		strike_amount = clampf(value, -0.12, 1.0)
		# Every handle stays on the wall plane at contact. The shared bowl layer
		# alone crosses in front of eggs, so both layouts land bowl-first.
		z_index = 0
		_sync_bowl_layer()
		queue_redraw()

var extension_amount := 0.0:
	set(value):
		extension_amount = clampf(value, 0.0, 1.0)
		_sync_bowl_layer()
		queue_redraw()

var _bowl_size_scale := 1.0
var _circuit_marked := true
var _has_telescoping_spoon := false
var _telescoping_targets: Array[Vector2] = []
var _single_contact_target := DEFAULT_SINGLE_CONTACT


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_bowl_layer()
	queue_redraw()


func set_strike_amount(amount: float) -> void:
	strike_amount = amount


func reset_pose() -> void:
	strike_amount = 0.0
	extension_amount = 0.0


func pivot_global_position() -> Vector2:
	return get_global_transform() * _single_hinge()


func stored_bowl_global_position() -> Vector2:
	return get_global_transform() * _single_stored_bowl()


func stored_bowl_global_positions() -> Array[Vector2]:
	return [stored_bowl_global_position()]


func current_bowl_global_positions() -> Array[Vector2]:
	return [get_global_transform() * _single_bowl_position(strike_amount)]


func contact_bowl_global_position() -> Vector2:
	return get_global_transform() * _active_contact_target()


func contact_points_global() -> Array[Vector2]:
	if not _has_telescoping_spoon:
		return [contact_bowl_global_position()]
	var points: Array[Vector2] = []
	for target: Vector2 in _telescoping_targets:
		points.append(get_global_transform() * target)
	return points


func set_bowl_scale(value: float) -> void:
	_bowl_size_scale = maxf(value, 1.0)
	_sync_bowl_layer()
	queue_redraw()


func bowl_scale() -> float:
	return _bowl_size_scale


func set_neutral_appearance() -> void:
	circuit_id = ""
	circuit_color = Color("8b6a43")
	_circuit_marked = false
	queue_redraw()


func is_circuit_marked() -> bool:
	return _circuit_marked


func configure_wall_spoon(contact_target: Vector2) -> void:
	_has_telescoping_spoon = false
	_telescoping_targets.clear()
	_single_contact_target = contact_target
	extension_amount = 0.0
	z_index = 0
	_sync_bowl_layer()
	queue_redraw()


func is_wall_pinned_spoon() -> bool:
	return true


func stored_bowl_screen_size() -> Vector2:
	return STORED_BOWL_RADII * 2.0 * _bowl_size_scale


func contact_bowl_screen_size() -> Vector2:
	return CONTACT_BOWL_RADII * 2.0 * _bowl_size_scale


func configure_telescoping_spoon(far_target: Vector2, near_target: Vector2) -> void:
	_has_telescoping_spoon = true
	_telescoping_targets.assign([far_target, near_target])
	_single_contact_target = far_target
	extension_amount = 0.0
	z_index = 0
	_sync_bowl_layer()
	queue_redraw()


func clear_telescoping_spoon() -> void:
	_has_telescoping_spoon = false
	_telescoping_targets.clear()
	extension_amount = 0.0
	z_index = 0
	_sync_bowl_layer()
	queue_redraw()


func is_telescoping_spoon() -> bool:
	return _has_telescoping_spoon


func has_paired_handles() -> bool:
	return false


func uses_authored_landing_frames() -> bool:
	return true


func landing_frame_count() -> int:
	return DOUBLE_SPOON_FRAMES.size()


func landing_frame_index() -> int:
	return roundi(
		clampf(strike_amount, 0.0, 1.0) * float(DOUBLE_SPOON_FRAMES.size() - 1)
	)


func uses_authored_double_spoon_frames() -> bool:
	return uses_authored_landing_frames()


func double_spoon_frame_count() -> int:
	return landing_frame_count()


func double_spoon_frame_index() -> int:
	return landing_frame_index()


func bowl_foreground_z_index() -> int:
	return _bowl_layer.z_index if is_instance_valid(_bowl_layer) else 0


func foreground_handle_visuals() -> Array[Dictionary]:
	var frame: DoubleSpoonFrame = DOUBLE_SPOON_FRAMES[landing_frame_index()]
	var visibility := frame.foreground_handle_visibility
	if visibility <= 0.001:
		return []
	return [{
		"from": _single_hinge(),
		"to": _single_bowl_position(strike_amount),
		"spoon_identity": "telescoping" if _has_telescoping_spoon else "single",
		"visibility": visibility,
		"width_scale": 1.0,
		"telescoping": _has_telescoping_spoon,
	}]


func is_foreground_handle_visible() -> bool:
	return not foreground_handle_visuals().is_empty()


func bowl_visuals() -> Array[Dictionary]:
	var frame: DoubleSpoonFrame = DOUBLE_SPOON_FRAMES[landing_frame_index()]
	var radii := frame.near_radii * SINGLE_FRAME_BOWL_SCALE
	if landing_frame_index() == DOUBLE_SPOON_FRAMES.size() - 1:
		radii = CONTACT_BOWL_RADII
	return [{
		"center": _single_bowl_position(strike_amount),
		"radii": radii * _bowl_size_scale,
		"tipped_amount": frame.tipped_amount,
		"draw_neck": true,
		"neck_scale": 1.0,
		"collar_direction": frame.near_collar_direction,
	}]


func is_idle_back_facing() -> bool:
	return true


func _draw() -> void:
	_draw_wall_spoon()


func _draw_wall_spoon() -> void:
	var hinge := _single_hinge()
	var head := _single_bowl_position(strike_amount)

	# The mounting plate and hinge remain fixed to the wall while the spoon tips
	# out toward the player, like a small drawbridge.
	draw_rect(Rect2(hinge - Vector2(27.0, 20.0), Vector2(54.0, 42.0)), Color("111316"), true)
	draw_rect(Rect2(hinge - Vector2(27.0, 20.0), Vector2(54.0, 42.0)), Color("895326"), false, 4.0)
	var mount_accent := circuit_color.darkened(0.12) if _circuit_marked else Color("6f4b2b")
	draw_line(hinge + Vector2(-22.0, 15.0), hinge + Vector2(22.0, 15.0), mount_accent, 4.0, true)

	# The authored fall draws handle and bowl together. At final contact the bowl
	# remains in front while this copy of the shaft returns behind the egg.
	var frame: DoubleSpoonFrame = DOUBLE_SPOON_FRAMES[landing_frame_index()]
	if frame.foreground_handle_visibility <= 0.001:
		draw_line(hinge, head, Color("0b0c0e"), 15.0, true)
		draw_line(hinge, head, Color("9da09e"), 9.0, true)
		draw_line(hinge - Vector2(2.0, 0.0), head - Vector2(2.0, 0.0), Color(1.0, 0.95, 0.84, 0.48), 2.0, true)
		if _has_telescoping_spoon:
			_draw_telescoping_collars(hinge, head)

	# Circuit identity now lives on the belt sections. The shared spoon keeps a
	# plain brass fastener instead of implying that it belongs to one circuit.
	draw_line(hinge - Vector2(24.0, 0.0), hinge + Vector2(24.0, 0.0), Color("0b0c0e"), 17.0, true)
	draw_line(hinge - Vector2(21.0, 0.0), hinge + Vector2(21.0, 0.0), Color("b77836"), 10.0, true)
	draw_circle(hinge, 13.0, Color("111316"))
	draw_circle(hinge, 9.0, circuit_color.darkened(0.10) if _circuit_marked else Color("735536"))
	if _circuit_marked:
		_draw_circuit_symbol(hinge, circuit_color.lightened(0.38))
	else:
		draw_circle(hinge, 3.0, Color("d09a52"))


func _single_hinge() -> Vector2:
	return _single_contact_target - Vector2(0.0, SINGLE_HINGE_TO_CONTACT)


func _single_stored_bowl() -> Vector2:
	var projected_extension := 0.0
	if _has_telescoping_spoon:
		projected_extension = WALL_EXTENSION_PROJECTION * extension_amount
	return _single_hinge() - Vector2(0.0, SINGLE_STORED_RISE + projected_extension)


func _single_bowl_position(amount: float) -> Vector2:
	var frame_index := landing_frame_index()
	if frame_index == DOUBLE_SPOON_FRAMES.size() - 1:
		return _active_contact_target()
	var frame: DoubleSpoonFrame = DOUBLE_SPOON_FRAMES[frame_index]
	var offset := frame.near_offset
	if offset.y < 0.0:
		offset.y *= SINGLE_STORED_RISE / 50.0
	var anticipation_lift := Vector2(0.0, amount * 18.0) if amount < 0.0 else Vector2.ZERO
	var extension_shift := Vector2.ZERO
	if _has_telescoping_spoon and _telescoping_targets.size() == 2:
		var row_reach := _telescoping_targets[0].distance_to(_telescoping_targets[1])
		var projected_length := lerpf(
			WALL_EXTENSION_PROJECTION,
			row_reach,
			smoothstep(0.45, 1.0, frame.tipped_amount)
		)
		# The extra length is foreshortened to zero as the spoon faces edge-on,
		# then appears below the pivot as the underside turns toward the player.
		extension_shift.y = (
			-cos(PI * frame.tipped_amount) * projected_length * extension_amount
		)
	return _single_hinge() + offset + extension_shift + anticipation_lift


func _active_contact_target() -> Vector2:
	if not _has_telescoping_spoon or _telescoping_targets.size() != 2:
		return _single_contact_target
	return _telescoping_targets[0].lerp(_telescoping_targets[1], extension_amount)


func _draw_telescoping_collars(from: Vector2, to: Vector2) -> void:
	for progress in [0.28, 0.48, 0.68]:
		var center := from.lerp(to, progress)
		var outer := Rect2(center - Vector2(11.0, 4.5), Vector2(22.0, 9.0))
		var inner := Rect2(center - Vector2(8.0, 2.5), Vector2(16.0, 5.0))
		draw_rect(outer, Color("211308"), true)
		draw_rect(outer, Color("9e5c1e"), false, 2.0)
		draw_rect(inner, Color("c47a2d"), true)


func _sync_bowl_layer() -> void:
	if not is_instance_valid(_bowl_layer):
		return
	_bowl_layer.z_index = 6 if strike_amount >= 0.5 else 0
	_bowl_layer.queue_redraw()
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
