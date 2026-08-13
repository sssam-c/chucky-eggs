extends Control

const SHARD_ANGLES := [
	-2.86, -2.43, -2.04, -1.68, -1.28, -0.91, -0.48,
	-0.10, 0.32, 0.73, 1.14, 1.55, 1.98, 2.42,
]

@onready var _points_label: Label = %Points

var burst_progress := 0.0:
	set(value):
		burst_progress = clampf(value, 0.0, 1.0)
		queue_redraw()
var travel_progress := 0.0:
	set(value):
		travel_progress = clampf(value, 0.0, 1.0)
		_place_points_label()
		queue_redraw()
var arrival_progress := 0.0:
	set(value):
		arrival_progress = clampf(value, 0.0, 1.0)
		_place_points_label()
		queue_redraw()

var _origin := Vector2.ZERO
var _target := Vector2.ZERO
var _shell_color := Color("e6bd7a")
var _outline_color := Color("572719")
var _active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	reset_effect()


func begin(origin_global: Vector2, target_global: Vector2, points_awarded: int, kind: String) -> void:
	var inverse := get_global_transform().affine_inverse()
	_origin = inverse * origin_global
	_target = inverse * target_global
	_set_shell_palette(kind)
	_active = true
	visible = true
	burst_progress = 0.0
	travel_progress = 0.0
	arrival_progress = 0.0
	_points_label.text = "+%d" % points_awarded
	_points_label.visible = true
	_points_label.modulate = Color.WHITE
	_place_points_label()
	queue_redraw()


func reset_effect() -> void:
	_active = false
	visible = false
	burst_progress = 0.0
	travel_progress = 0.0
	arrival_progress = 0.0
	if is_instance_valid(_points_label):
		_points_label.text = ""
		_points_label.visible = false
		_points_label.scale = Vector2.ONE
		_points_label.modulate = Color.WHITE
	queue_redraw()


func is_active() -> bool:
	return _active


func point_text() -> String:
	return _points_label.text if is_instance_valid(_points_label) else ""


func fragment_count() -> int:
	return SHARD_ANGLES.size()


func _place_points_label() -> void:
	if not is_instance_valid(_points_label):
		return
	var eased := 1.0 - pow(1.0 - travel_progress, 3.0)
	# Keep the token inside the cabinet while still giving the reward a clear arc.
	var arc_height := -sin(travel_progress * PI) * 56.0
	var center := _origin.lerp(_target, eased) + Vector2(0.0, arc_height)
	_points_label.position = center - _points_label.size * 0.5
	_points_label.pivot_offset = _points_label.size * 0.5
	var travel_punch := 1.0 + sin(travel_progress * PI) * 0.16
	var arrival_punch := 1.0 + sin(arrival_progress * PI) * 0.30
	_points_label.scale = Vector2.ONE * travel_punch * arrival_punch
	_points_label.modulate.a = 1.0 - smoothstep(0.45, 1.0, arrival_progress)


func _set_shell_palette(kind: String) -> void:
	match kind:
		"cuckoo":
			_shell_color = Color("79aeb2")
			_outline_color = Color("183c43")
		"plover":
			_shell_color = Color("b8c66e")
			_outline_color = Color("354421")
		"spoonbill":
			_shell_color = Color("c9a6c8")
			_outline_color = Color("4d2949")
		_:
			_shell_color = Color("e6bd7a")
			_outline_color = Color("572719")


func _draw() -> void:
	if not _active:
		return
	_draw_burst()
	_draw_score_arrival()


func _draw_burst() -> void:
	if burst_progress <= 0.0:
		return
	var expansion := 1.0 - pow(1.0 - burst_progress, 2.0)
	var debris_alpha := 1.0 - smoothstep(0.62, 1.0, burst_progress)
	var flash_alpha := 1.0 - smoothstep(0.0, 0.44, burst_progress)
	draw_circle(_origin, 44.0 + expansion * 34.0, Color(1.0, 0.72, 0.18, flash_alpha * 0.30))
	draw_arc(
		_origin,
		30.0 + expansion * 104.0,
		0.0,
		TAU,
		48,
		Color(1.0, 0.79, 0.28, debris_alpha * 0.72),
		6.0 - burst_progress * 3.0,
		true
	)

	for shard_index in range(SHARD_ANGLES.size()):
		var direction := Vector2.from_angle(SHARD_ANGLES[shard_index])
		var speed := 84.0 + float((shard_index * 29) % 73)
		var gravity := Vector2(0.0, 72.0 * burst_progress * burst_progress)
		var center := _origin + direction * speed * expansion + gravity
		var shard_size := 8.0 + float(shard_index % 4) * 2.2
		var color := _shell_color if shard_index % 3 != 0 else _outline_color
		color.a = debris_alpha
		_draw_shard(center, direction.rotated(burst_progress * (1.8 + shard_index * 0.07)), shard_size, color)

	for spark_index in range(8):
		var angle := -2.72 + float(spark_index) * 0.71
		var direction := Vector2.from_angle(angle)
		var distance := (55.0 + float((spark_index * 17) % 38)) * expansion
		var spark := _origin + direction * distance + Vector2(0.0, 48.0 * burst_progress * burst_progress)
		draw_circle(spark, 5.0 - burst_progress * 2.0, Color(1.0, 0.69, 0.08, debris_alpha * 0.92))


func _draw_score_arrival() -> void:
	if arrival_progress <= 0.0:
		return
	var ring_alpha := 1.0 - arrival_progress
	var radius := 12.0 + arrival_progress * 26.0
	draw_circle(_target, 24.0, Color(1.0, 0.68, 0.08, ring_alpha * 0.18))
	draw_arc(_target, radius, 0.0, TAU, 36, Color(1.0, 0.80, 0.22, ring_alpha), 5.0, true)
	for ray_index in range(8):
		var direction := Vector2.from_angle(float(ray_index) * TAU / 8.0)
		draw_line(
			_target + direction * (15.0 + arrival_progress * 5.0),
			_target + direction * (26.0 + arrival_progress * 10.0),
			Color(1.0, 0.76, 0.20, ring_alpha),
			3.0,
			true
		)


func _draw_shard(center: Vector2, direction: Vector2, shard_size: float, color: Color) -> void:
	var side := direction.orthogonal()
	var points := PackedVector2Array([
		center + direction * shard_size,
		center - direction * shard_size * 0.65 + side * shard_size * 0.58,
		center - direction * shard_size * 0.40 - side * shard_size * 0.72,
	])
	draw_colored_polygon(points, color)
	var outline := points.duplicate()
	outline.append(points[0])
	var edge := _outline_color
	edge.a = color.a
	draw_polyline(outline, edge, 2.0, true)
