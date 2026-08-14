extends Control

@export var slot_index := -1
@export var circuit_id := "red"
@export var circuit_color := Color("b6322c")
@export_enum("diamond", "circle", "triangle", "hexagon", "spark") var circuit_symbol := "diamond"

const DEFAULT_SINGLE_CONTACT := Vector2(85.0, 170.0)
const SINGLE_HINGE_TO_CONTACT := 16.0
const SINGLE_STORED_RISE := 96.0
const STORED_BOWL_RADII := Vector2(31.0, 43.0)
const CONTACT_BOWL_RADII := Vector2(48.0, 15.0)
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
		# A double spoon keeps its one rigid handle on the wall layer. Only its
		# bowls pass in front of the eggs, so the shaft never cuts across them.
		z_index = 0 if _has_double_bowled_spoon else (5 if strike_amount >= 0.5 else 0)
		_sync_bowl_layer()
		queue_redraw()

var _bowl_size_scale := 1.0
var _has_double_bowled_spoon := false
var _double_targets: Array[Vector2] = []
var _single_contact_target := DEFAULT_SINGLE_CONTACT


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_bowl_layer()
	queue_redraw()


func set_strike_amount(amount: float) -> void:
	strike_amount = amount


func reset_pose() -> void:
	strike_amount = 0.0


func pivot_global_position() -> Vector2:
	if _has_double_bowled_spoon:
		return get_global_transform() * _double_hinge()
	return get_global_transform() * _single_hinge()


func stored_bowl_global_position() -> Vector2:
	if _has_double_bowled_spoon:
		return stored_bowl_global_positions()[0]
	return get_global_transform() * _single_stored_bowl()


func stored_bowl_global_positions() -> Array[Vector2]:
	if not _has_double_bowled_spoon:
		return [stored_bowl_global_position()]
	var points: Array[Vector2] = []
	for head: Vector2 in _double_bowl_positions(0.0):
		points.append(get_global_transform() * head)
	return points


func current_bowl_global_positions() -> Array[Vector2]:
	if not _has_double_bowled_spoon:
		return [get_global_transform() * _single_bowl_position(strike_amount)]
	var points: Array[Vector2] = []
	for head: Vector2 in _double_bowl_positions(strike_amount):
		points.append(get_global_transform() * head)
	return points


func contact_bowl_global_position() -> Vector2:
	if _has_double_bowled_spoon:
		return get_global_transform() * _double_targets[0]
	return get_global_transform() * _single_contact_target


func contact_points_global() -> Array[Vector2]:
	if not _has_double_bowled_spoon:
		return [contact_bowl_global_position()]
	var points: Array[Vector2] = []
	for target: Vector2 in _double_targets:
		points.append(get_global_transform() * target)
	return points


func set_bowl_scale(value: float) -> void:
	_bowl_size_scale = maxf(value, 1.0)
	_sync_bowl_layer()
	queue_redraw()


func bowl_scale() -> float:
	return _bowl_size_scale


func configure_wall_spoon(contact_target: Vector2) -> void:
	_has_double_bowled_spoon = false
	_double_targets.clear()
	_single_contact_target = contact_target
	z_index = 5 if strike_amount >= 0.5 else 0
	_sync_bowl_layer()
	queue_redraw()


func is_wall_pinned_spoon() -> bool:
	return true


func stored_bowl_screen_size() -> Vector2:
	return STORED_BOWL_RADII * 2.0 * _bowl_size_scale


func contact_bowl_screen_size() -> Vector2:
	return CONTACT_BOWL_RADII * 2.0 * _bowl_size_scale


func configure_double_bowled_spoon(top_target: Vector2, bottom_target: Vector2) -> void:
	_has_double_bowled_spoon = true
	_double_targets.assign([top_target, bottom_target])
	z_index = 0
	_sync_bowl_layer()
	queue_redraw()


func clear_double_bowled_spoon() -> void:
	_has_double_bowled_spoon = false
	_double_targets.clear()
	z_index = 0
	_sync_bowl_layer()
	queue_redraw()


func is_double_bowled_spoon() -> bool:
	return _has_double_bowled_spoon


func has_continuous_handle() -> bool:
	return _has_double_bowled_spoon


func uses_authored_double_spoon_frames() -> bool:
	return true


func double_spoon_frame_count() -> int:
	return DOUBLE_SPOON_FRAMES.size()


func double_spoon_frame_index() -> int:
	return roundi(
		clampf(strike_amount, 0.0, 1.0) * float(DOUBLE_SPOON_FRAMES.size() - 1)
	)


func bowl_foreground_z_index() -> int:
	return _bowl_layer.z_index if is_instance_valid(_bowl_layer) else 0


func foreground_handle_visual() -> Dictionary:
	if not _has_double_bowled_spoon:
		return {}
	var frame: DoubleSpoonFrame = DOUBLE_SPOON_FRAMES[double_spoon_frame_index()]
	var visibility := frame.foreground_handle_visibility
	if visibility <= 0.001:
		return {}
	return {
		"from": _double_hinge(),
		"to": _double_bowl_positions(strike_amount)[1],
		"visibility": visibility,
	}


func is_foreground_handle_visible() -> bool:
	return not foreground_handle_visual().is_empty()


func bowl_visuals() -> Array[Dictionary]:
	var eased := smoothstep(0.0, 1.0, maxf(strike_amount, 0.0))
	if not _has_double_bowled_spoon:
		return [{
			"center": _single_bowl_position(strike_amount),
			"radii": STORED_BOWL_RADII.lerp(CONTACT_BOWL_RADII, eased) * _bowl_size_scale,
			"tipped_amount": eased,
		}]
	# Each pose is a complete authored silhouette. Selecting a saved frame avoids
	# independently interpolating the bowls and shaft through an impossible 2D
	# approximation of the utensil's turn toward the player.
	var frame: DoubleSpoonFrame = DOUBLE_SPOON_FRAMES[double_spoon_frame_index()]
	var centers := _double_bowl_positions(strike_amount)
	return [
		{
			"center": centers[0],
			"radii": frame.near_radii * _bowl_size_scale,
			"tipped_amount": frame.tipped_amount,
			"tracked_far_bowl": false,
			"draw_neck": true,
			"neck_scale": 0.76,
			"collar_direction": frame.near_collar_direction,
		},
		{
			"center": centers[1],
			"radii": frame.far_radii * _bowl_size_scale,
			"tipped_amount": frame.tipped_amount,
			"tracked_far_bowl": true,
			"draw_neck": true,
			"neck_scale": 1.0,
			"collar_direction": frame.far_collar_direction,
		},
	]


func is_idle_back_facing() -> bool:
	return true


func _draw() -> void:
	if _has_double_bowled_spoon:
		_draw_double_bowled_spoon()
		return
	_draw_wall_spoon()


func _draw_wall_spoon() -> void:
	var hinge := _single_hinge()
	var head := _single_bowl_position(strike_amount)

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

	# The repeated symbol keeps linked Red and Blue spoons distinguishable
	# without adding labels to the mechanism.
	draw_line(hinge - Vector2(24.0, 0.0), hinge + Vector2(24.0, 0.0), Color("0b0c0e"), 17.0, true)
	draw_line(hinge - Vector2(21.0, 0.0), hinge + Vector2(21.0, 0.0), Color("b77836"), 10.0, true)
	draw_circle(hinge, 13.0, Color("111316"))
	draw_circle(hinge, 9.0, circuit_color.darkened(0.10))
	_draw_circuit_symbol(hinge, circuit_color.lightened(0.38))


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


func _draw_double_bowled_spoon() -> void:
	if _double_targets.size() != 2:
		return
	var hinge := _double_hinge()
	var bowls := _double_bowl_positions(strike_amount)
	var far_bowl: Vector2 = bowls[1]
	var frame: DoubleSpoonFrame = DOUBLE_SPOON_FRAMES[double_spoon_frame_index()]

	# The mount always stays on the wall. The complete authored utensil is drawn
	# together on the bowl layer during the fall. At final contact only, its shaft
	# returns here behind the eggs while the two striking bowls stay in front.
	draw_rect(Rect2(hinge - Vector2(27.0, 20.0), Vector2(54.0, 42.0)), Color("111316"), true)
	draw_rect(Rect2(hinge - Vector2(27.0, 20.0), Vector2(54.0, 42.0)), Color("895326"), false, 4.0)
	if frame.foreground_handle_visibility <= 0.001:
		draw_line(hinge, far_bowl, Color("0b0c0e"), 15.0, true)
		draw_line(hinge, far_bowl, Color("9da09e"), 9.0, true)
		draw_line(hinge - Vector2(2.0, 0.0), far_bowl - Vector2(2.0, 0.0), Color(1.0, 0.95, 0.84, 0.48), 2.0, true)
	draw_line(hinge - Vector2(24.0, 0.0), hinge + Vector2(24.0, 0.0), Color("0b0c0e"), 17.0, true)
	draw_line(hinge - Vector2(21.0, 0.0), hinge + Vector2(21.0, 0.0), Color("b77836"), 10.0, true)
	draw_circle(hinge, 13.0, Color("111316"))
	draw_circle(hinge, 9.0, circuit_color.darkened(0.10))
	_draw_circuit_symbol(hinge, circuit_color.lightened(0.38))


func _double_hinge() -> Vector2:
	if _double_targets.size() != 2:
		return _single_hinge()
	return _double_targets[0] - Vector2(0.0, SINGLE_HINGE_TO_CONTACT)


func _double_bowl_positions(amount: float) -> Array[Vector2]:
	if _double_targets.size() != 2:
		return []
	var hinge := _double_hinge()
	var frame_index := double_spoon_frame_index()
	if frame_index == DOUBLE_SPOON_FRAMES.size() - 1:
		return _double_targets.duplicate()
	var frame: DoubleSpoonFrame = DOUBLE_SPOON_FRAMES[frame_index]
	var anticipation_lift := Vector2(0.0, amount * 18.0) if amount < 0.0 else Vector2.ZERO
	return [
		hinge + frame.near_offset + anticipation_lift,
		hinge + frame.far_offset + anticipation_lift,
	]


func _sync_bowl_layer() -> void:
	if not is_instance_valid(_bowl_layer):
		return
	_bowl_layer.z_index = 6 if _has_double_bowled_spoon and strike_amount >= 0.5 else 0
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
