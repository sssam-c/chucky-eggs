class_name EggBreakBurst
extends Control

var burst_amount := 0.0:
	set(value):
		burst_amount = clampf(value, 0.0, 1.0)
		visible = burst_amount > 0.001
		queue_redraw()

var _shell_color := Color("e6b74f")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	reset()


func configure(shell_color: Color) -> void:
	_shell_color = shell_color
	burst_amount = 0.0


func reset() -> void:
	burst_amount = 0.0


func _draw() -> void:
	if burst_amount <= 0.001:
		return
	var centre := size * 0.5
	var fracture := clampf(burst_amount / 0.48, 0.0, 1.0)
	var scatter := clampf((burst_amount - 0.22) / 0.78, 0.0, 1.0)
	var flash_alpha := (1.0 - scatter) * 0.72
	draw_circle(
		centre,
		lerpf(8.0, 42.0, fracture),
		Color(1.0, 0.91, 0.46, flash_alpha)
	)

	for shard_index in range(9):
		var angle := TAU * float(shard_index) / 9.0 - PI * 0.5
		var crooked := sin(float(shard_index) * 2.17) * 0.19
		var direction := Vector2.from_angle(angle + crooked)
		var crack_end := centre + direction * lerpf(18.0, 57.0, fracture)
		var crack_mid := centre + direction.rotated(-0.17 if shard_index % 2 == 0 else 0.17) * 27.0
		draw_polyline(
			PackedVector2Array([centre, crack_mid, crack_end]),
			Color(0.20, 0.10, 0.04, 0.86 * (1.0 - scatter)),
			3.0,
			true
		)
		if scatter <= 0.0:
			continue
		var distance := lerpf(24.0, 82.0, scatter)
		var shard_centre := centre + direction * distance
		var spin := angle + scatter * (0.8 if shard_index % 2 == 0 else -0.8)
		var tangent := Vector2.from_angle(spin + PI * 0.5)
		var outward := Vector2.from_angle(spin)
		var shard_size := lerpf(11.0, 7.0, scatter)
		var shard := PackedVector2Array([
			shard_centre + outward * shard_size,
			shard_centre - outward * shard_size * 0.65 + tangent * shard_size * 0.65,
			shard_centre - outward * shard_size * 0.55 - tangent * shard_size * 0.72,
		])
		var shard_color := _shell_color
		shard_color.a = 1.0 - scatter * 0.72
		draw_colored_polygon(shard, shard_color)
		var outline := shard.duplicate()
		outline.append(shard[0])
		draw_polyline(outline, Color(0.15, 0.08, 0.035, shard_color.a), 2.0, true)
