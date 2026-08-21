extends Control

const PlaceholderStyle = preload("res://src/ui/species_placeholder_style.gd")
const SpeciesIconRenderer = preload("res://src/ui/species_icon_renderer.gd")
const TOOLTIP_CARD_SCENE = preload("res://src/ui/egg_tooltip_card.tscn")
const HOVER_POPOVER_SCENE = preload("res://src/ui/egg_hover_popover.tscn")
const MAGNIFIER_CURSOR = preload("res://assets/ui/cursors/egg_inspect.svg")
const SHELL_COLOR := Color("f3efe5")
const NEUTRAL_ICON_COLOR := Color("3b3028")
const PINK_CIRCUIT_COLOR := Color("cf4f8b")

static var _magnifier_cursor_registered := false

var _egg: Dictionary = {}
var _preview := false
var _hover_popover: Control


func _ready() -> void:
	_register_magnifier_cursor()
	mouse_default_cursor_shape = Control.CURSOR_HELP
	_hover_popover = HOVER_POPOVER_SCENE.instantiate()
	add_child(_hover_popover)
	mouse_entered.connect(show_hover_card)
	mouse_exited.connect(hide_hover_card)
	visibility_changed.connect(_on_visibility_changed)
	_sync_hover_card()


static func _register_magnifier_cursor() -> void:
	if _magnifier_cursor_registered:
		return
	Input.set_custom_mouse_cursor(MAGNIFIER_CURSOR, Input.CURSOR_HELP, Vector2(12.0, 12.0))
	_magnifier_cursor_registered = true


func set_egg(egg: Dictionary, preview := false) -> void:
	_egg = egg.duplicate(true)
	_preview = preview
	_sync_hover_card()
	queue_redraw()


func clear_egg() -> void:
	_egg = {}
	_sync_hover_card()
	queue_redraw()


func placeholder_color() -> Color:
	return shell_color()


func shell_color() -> Color:
	return SHELL_COLOR


func _draw() -> void:
	if _egg.is_empty():
		return

	var center := _shell_center()
	var radii := _shell_radii()
	var radius_x := radii.x
	var radius_y := radii.y

	_draw_placeholder_shell(center, radius_x, radius_y)

	var toughness: int = _egg.get("toughness", 4)
	var max_toughness: int = _egg.get("max_toughness", 4)
	var damage_taken := maxi(max_toughness - toughness, 0)
	if damage_taken >= 1:
		_draw_crack(center + Vector2(4.0, -8.0), [
			Vector2(0, -20), Vector2(-7, -8), Vector2(2, 0), Vector2(-5, 11), Vector2(1, 22),
		])
	if damage_taken >= 2:
		_draw_crack(center + Vector2(-5.0, 3.0), [
			Vector2(0, 0), Vector2(-15, 6), Vector2(-22, 17),
		])
	if damage_taken >= 3:
		_draw_crack(center + Vector2(7.0, 5.0), [
			Vector2(0, 0), Vector2(14, 8), Vector2(19, 21),
		])
		_draw_crack(center + Vector2(0.0, -1.0), [
			Vector2(0, 0), Vector2(11, -13), Vector2(9, -25),
		])
	if damage_taken >= 4:
		_draw_crack(center + Vector2(-8.0, 17.0), [
			Vector2(0, 0), Vector2(-8, 11), Vector2(-6, 23),
		])
	if damage_taken >= 5:
		_draw_crack(center + Vector2(-7.0, -13.0), [
			Vector2(0, 0), Vector2(-12, -9), Vector2(-14, -21),
		])

	# Keep decision-critical marks above shell decoration and accumulated cracks.
	_draw_information_marks()


func _sync_hover_card() -> void:
	mouse_filter = (
		Control.MOUSE_FILTER_PASS if not _egg.is_empty()
		else Control.MOUSE_FILTER_IGNORE
	)
	tooltip_text = ""
	if is_instance_valid(_hover_popover):
		_hover_popover.configure(_egg)
		if _egg.is_empty():
			_hover_popover.cancel()


func make_tooltip_card() -> Control:
	var card := TOOLTIP_CARD_SCENE.instantiate()
	card.configure(_egg)
	return card


func show_hover_card() -> void:
	if _egg.is_empty() or not is_instance_valid(_hover_popover):
		return
	_hover_popover.configure(_egg)
	_hover_popover.show_for(self)


func hide_hover_card() -> void:
	if is_instance_valid(_hover_popover):
		_hover_popover.cancel()


func hover_card_rect() -> Rect2:
	if not is_instance_valid(_hover_popover):
		return Rect2()
	return _hover_popover.popup_rect()


func is_hover_card_visible() -> bool:
	return is_instance_valid(_hover_popover) and _hover_popover.visible


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		hide_hover_card()


func _exit_tree() -> void:
	hide_hover_card()


func score_icon_local_position() -> Vector2:
	var horizontal_offset := 0.0
	if effect_layout_region() == "crack":
		horizontal_offset = -17.0 * _mark_scale()
	return _shell_center() + Vector2(
		horizontal_offset, _shell_radii().y * 0.61
	)


func effect_icon_local_position() -> Vector2:
	match effect_layout_region():
		"tap":
			return tap_effect_icon_local_position()
		"crack":
			return crack_effect_icon_local_position()
	return toughness_local_position()


func toughness_local_position() -> Vector2:
	return _shell_center()


func species_icon_local_position() -> Vector2:
	return toughness_local_position()


func species_icon_scale() -> float:
	return minf(35.0 * _mark_scale(), _shell_radii().x * 0.72)


func tap_effect_icon_local_position() -> Vector2:
	return _shell_center() - Vector2(0.0, _shell_radii().y * 0.58)


func crack_effect_icon_local_position() -> Vector2:
	return _shell_center() + Vector2(
		18.0 * _mark_scale(), _shell_radii().y * 0.61
	)


func echo_wave_local_centers() -> Array[Vector2]:
	var center := toughness_local_position()
	var horizontal_offset := _shell_radii().x * 0.57
	return [
		center - Vector2(horizontal_offset, 0.0),
		center + Vector2(horizontal_offset, 0.0),
	]


func _shell_center() -> Vector2:
	return Vector2(size.x * 0.5, size.y * 0.51)


func _shell_radii() -> Vector2:
	var radii := Vector2(
		minf(size.x * 0.37, 52.0),
		minf(size.y * 0.44, 68.0)
	)
	return radii * (0.70 if _preview else 1.0)


func _mark_scale() -> float:
	return 0.72 if _preview else 1.0


func _draw_placeholder_shell(center: Vector2, radius_x: float, radius_y: float) -> void:
	var shadow_points := _egg_points(
		center + Vector2(2.5, 4.0), radius_x + 2.0, radius_y + 2.0
	)
	draw_colored_polygon(shadow_points, Color(0.0, 0.0, 0.0, 0.34))
	var shell_points := _egg_points(center, radius_x, radius_y)
	draw_colored_polygon(shell_points, placeholder_color())
	var outline := shell_points.duplicate()
	outline.append(shell_points[0])
	draw_polyline(outline, Color("2b2c2f"), 2.5 if not _preview else 1.5, true)
	draw_arc(
		center - Vector2(radius_x * 0.20, radius_y * 0.05),
		radius_x * 0.50,
		PI * 1.05,
		PI * 1.55,
		12,
		Color(1.0, 1.0, 1.0, 0.34),
		2.0 if not _preview else 1.0,
		true
	)


func _egg_points(center: Vector2, radius_x: float, radius_y: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(48):
		var angle := TAU * float(point_index) / 48.0 - PI * 0.5
		var vertical := sin(angle)
		var taper := lerpf(0.70, 1.03, (vertical + 1.0) * 0.5)
		points.append(center + Vector2(
			cos(angle) * radius_x * taper,
			vertical * radius_y
		))
	return points


func score_seal_value() -> int:
	if _egg.is_empty():
		return 0
	return int(_egg.get("points", 0))


func effect_emblem() -> String:
	if _egg.is_empty():
		return ""
	match String(_egg.get("kind", "chicken")):
		"cuckoo":
			return "echo"
		"plover":
			return "screen_left"
		"spoonbill":
			return "spark"
		"woodpecker":
			return "tap_right"
		"quail":
			return "appetiser"
		"maleo":
			return "sulphurous"
		"ostrich":
			return "shockwave"
		"oily":
			return "oily"
		"nostalgic":
			return "nostalgic"
		"gloopy":
			return "gloopy"
	return ""


func effect_layout_region() -> String:
	match effect_emblem():
		"echo":
			return "adjacency"
		"screen_left", "spark", "oily", "nostalgic", "gloopy":
			return "tap"
		"tap_right", "appetiser", "sulphurous", "shockwave":
			return "crack"
	return ""


func egg_kind() -> String:
	return String(_egg.get("kind", ""))


func species_icon_shape() -> String:
	return PlaceholderStyle.shape(egg_kind())


func affected_circuit_id() -> String:
	return "pink" if egg_kind() == "spoonbill" else ""


func species_icon_color() -> Color:
	return PINK_CIRCUIT_COLOR if affected_circuit_id() == "pink" else NEUTRAL_ICON_COLOR


func species_watermark_color() -> Color:
	var color := species_icon_color()
	color.a = 0.34 if affected_circuit_id() == "pink" else 0.28
	return color


func effect_icon_color() -> Color:
	return PINK_CIRCUIT_COLOR if affected_circuit_id() == "pink" else NEUTRAL_ICON_COLOR


func yolk_drop_local_rect() -> Rect2:
	var half_size := Vector2(12.0, 15.0) * _mark_scale()
	return Rect2(score_icon_local_position() - half_size, half_size * 2.0)


func yolk_value_local_rect() -> Rect2:
	var half_size := Vector2(9.0, 8.0) * _mark_scale()
	return Rect2(score_icon_local_position() - half_size, half_size * 2.0)


func _draw_information_marks() -> void:
	var mark_scale := _mark_scale()
	SpeciesIconRenderer.draw(
		self,
		egg_kind(),
		species_icon_local_position(),
		species_icon_scale(),
		species_watermark_color(),
		Color.TRANSPARENT,
		0.0
	)
	_draw_score_seal(score_icon_local_position(), mark_scale)
	var emblem := effect_emblem()
	if emblem == "echo":
		_draw_echo_adjacency_marks(echo_wave_local_centers(), mark_scale)
		return
	_draw_effect_emblem(emblem, effect_icon_local_position(), mark_scale)


func _draw_effect_emblem(emblem: String, center: Vector2, mark_scale: float) -> void:
	match emblem:
		"screen_left":
			_draw_left_emblem(center, mark_scale)
		"spark":
			_draw_spark_emblem(center, mark_scale)
		"tap_right":
			_draw_tap_right_emblem(center, mark_scale)
		"appetiser":
			_draw_appetiser_emblem(center, mark_scale * 0.84)
		"sulphurous":
			_draw_sulphurous_emblem(center, mark_scale * 0.84)
		"shockwave":
			_draw_shockwave_emblem(center, mark_scale * 0.84)
		"oily":
			_draw_play_emblem(center, mark_scale, false)
		"nostalgic":
			_draw_play_emblem(center, mark_scale, true)
		"gloopy":
			_draw_jammed_cog_emblem(center, mark_scale)


func _draw_score_seal(center: Vector2, mark_scale: float) -> void:
	var is_foul := score_seal_value() < 0
	var drop_center := center
	var drop_points := PackedVector2Array([
		drop_center + Vector2(0.0, -15.0) * mark_scale,
		drop_center + Vector2(4.0, -10.0) * mark_scale,
		drop_center + Vector2(8.0, -4.0) * mark_scale,
		drop_center + Vector2(11.0, 2.0) * mark_scale,
		drop_center + Vector2(11.0, 7.0) * mark_scale,
		drop_center + Vector2(8.0, 12.0) * mark_scale,
		drop_center + Vector2(4.0, 14.0) * mark_scale,
		drop_center + Vector2(0.0, 15.0) * mark_scale,
		drop_center + Vector2(-4.0, 14.0) * mark_scale,
		drop_center + Vector2(-8.0, 12.0) * mark_scale,
		drop_center + Vector2(-11.0, 7.0) * mark_scale,
		drop_center + Vector2(-11.0, 2.0) * mark_scale,
		drop_center + Vector2(-8.0, -4.0) * mark_scale,
		drop_center + Vector2(-4.0, -10.0) * mark_scale,
	])
	draw_colored_polygon(
		drop_points, Color("a7d66d") if is_foul else Color("f1bd55")
	)
	var outline := drop_points.duplicate()
	outline.append(drop_points[0])
	draw_polyline(
		outline, Color("304e2a") if is_foul else Color("70401e"),
		1.8 * mark_scale, true
	)
	draw_arc(
		drop_center - Vector2(1.5, 0.5) * mark_scale,
		4.2 * mark_scale,
		-2.75,
		-1.25,
		8,
		Color(1.0, 0.93, 0.64, 0.72),
		1.2 * mark_scale,
		true
	)
	var font_size := 16 if not _preview else 11
	var value_rect := yolk_value_local_rect()
	draw_string(
		ThemeDB.fallback_font,
		Vector2(value_rect.position.x, center.y + 5.5 * mark_scale),
		str(score_seal_value()),
		HORIZONTAL_ALIGNMENT_CENTER,
		value_rect.size.x,
		font_size,
		Color("142314") if is_foul else Color("3a1b12")
	)


func _draw_echo_adjacency_marks(centers: Array[Vector2], mark_scale: float) -> void:
	var ink := effect_icon_color()
	var shine := ink.lightened(0.48)
	shine.a = 0.72
	if centers.size() != 2:
		return
	for center_index in range(centers.size()):
		var center := centers[center_index]
		var facing_angle := PI if center_index == 0 else 0.0
		draw_circle(center, 2.2 * mark_scale, ink)
		for radius in [5.5, 9.5]:
			draw_arc(
				center,
				radius * mark_scale,
				facing_angle - 0.72,
				facing_angle + 0.72,
				10,
				ink,
				2.3 * mark_scale,
				true
			)
		draw_arc(
			center,
			5.5 * mark_scale,
			facing_angle - 0.56,
			facing_angle + 0.56,
			8,
			shine,
			0.9 * mark_scale,
			true
		)


func _draw_left_emblem(center: Vector2, mark_scale: float) -> void:
	var ink := effect_icon_color()
	var line_width := 3.2 * mark_scale
	draw_line(
		center + Vector2(8.0, 0.0) * mark_scale,
		center + Vector2(-11.0, 0.0) * mark_scale,
		ink,
		line_width,
		true
	)
	draw_polyline(PackedVector2Array([
		center + Vector2(-2.0, -7.0) * mark_scale,
		center + Vector2(-10.0, 0.0) * mark_scale,
		center + Vector2(-2.0, 7.0) * mark_scale,
	]), ink, line_width, true)
	draw_arc(
		center + Vector2(5.0, -5.0) * mark_scale,
		6.0 * mark_scale,
		-PI + 0.05,
		-PI + 1.55,
		8,
		Color(ink, 0.38),
		1.4 * mark_scale,
		true
	)


func _draw_spark_emblem(center: Vector2, mark_scale: float) -> void:
	var glow := effect_icon_color()
	var ink := glow.darkened(0.48)
	var points := PackedVector2Array([
		center + Vector2(0, -13) * mark_scale,
		center + Vector2(3, -3) * mark_scale,
		center + Vector2(13, 0) * mark_scale,
		center + Vector2(3, 3) * mark_scale,
		center + Vector2(0, 13) * mark_scale,
		center + Vector2(-3, 3) * mark_scale,
		center + Vector2(-13, 0) * mark_scale,
		center + Vector2(-3, -3) * mark_scale,
		center + Vector2(0, -13) * mark_scale,
	])
	draw_colored_polygon(points, glow)
	draw_polyline(points, ink, 2.5 * mark_scale, true)
	draw_circle(center, 2.5 * mark_scale, Color("fff0cf"))


func _draw_tap_right_emblem(center: Vector2, mark_scale: float) -> void:
	var ink := effect_icon_color()
	var line_width := 2.6 * mark_scale
	# Spoon bowl + shaft distinguishes a triggered tap from a movement arrow.
	draw_circle(
		center + Vector2(-8.0, 0.0) * mark_scale,
		4.2 * mark_scale,
		ink
	)
	draw_line(
		center + Vector2(-4.0, 0.0) * mark_scale,
		center + Vector2(9.0, 0.0) * mark_scale,
		ink, line_width, true
	)
	draw_polyline(PackedVector2Array([
		center + Vector2(4.0, -5.5) * mark_scale,
		center + Vector2(11.0, 0.0) * mark_scale,
		center + Vector2(4.0, 5.5) * mark_scale,
	]), ink, line_width, true)


func _draw_appetiser_emblem(center: Vector2, mark_scale: float) -> void:
	var ink := effect_icon_color()
	var width := 3.0 * mark_scale
	draw_circle(center, 11.0 * mark_scale, Color(ink, 0.18))
	draw_line(
		center + Vector2(-6, 0) * mark_scale,
		center + Vector2(6, 0) * mark_scale,
		ink, width, true
	)
	draw_line(
		center + Vector2(0, -6) * mark_scale,
		center + Vector2(0, 6) * mark_scale,
		ink, width, true
	)


func _draw_sulphurous_emblem(center: Vector2, mark_scale: float) -> void:
	var ink := effect_icon_color()
	for offset_x in [-7.0, 0.0, 7.0]:
		draw_arc(
			center + Vector2(offset_x, 2) * mark_scale,
			6.0 * mark_scale,
			-2.2,
			0.9,
			10,
			ink,
			2.4 * mark_scale,
			true
		)


func _draw_shockwave_emblem(center: Vector2, mark_scale: float) -> void:
	var ink := effect_icon_color()
	draw_circle(center, 3.0 * mark_scale, ink)
	for radius in [7.0, 12.0]:
		draw_arc(
			center, radius * mark_scale, 0.0, TAU, 24,
			ink, 2.1 * mark_scale, true
		)


func _draw_play_emblem(center: Vector2, mark_scale: float, reversed: bool) -> void:
	var direction := -1.0 if reversed else 1.0
	var ink := effect_icon_color()
	var points := PackedVector2Array([
		center + Vector2(-7.0 * direction, -10.0) * mark_scale,
		center + Vector2(10.0 * direction, 0.0) * mark_scale,
		center + Vector2(-7.0 * direction, 10.0) * mark_scale,
	])
	draw_colored_polygon(points, Color(ink, 0.16))
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, ink, 2.4 * mark_scale, true)


func _draw_jammed_cog_emblem(center: Vector2, mark_scale: float) -> void:
	var ink := effect_icon_color()
	for tooth_index in range(8):
		var angle := TAU * float(tooth_index) / 8.0
		draw_line(
			center + Vector2.from_angle(angle) * 8.0 * mark_scale,
			center + Vector2.from_angle(angle) * 13.0 * mark_scale,
			ink, 3.0 * mark_scale, true
		)
	draw_circle(center, 9.0 * mark_scale, Color(ink, 0.16))
	draw_arc(center, 9.0 * mark_scale, 0.0, TAU, 20, ink, 2.2 * mark_scale, true)
	draw_line(
		center + Vector2(-9.0, 9.0) * mark_scale,
		center + Vector2(9.0, -9.0) * mark_scale,
		ink, 3.0 * mark_scale, true
	)


func _draw_crack(origin: Vector2, offsets: Array[Vector2]) -> void:
	var points := PackedVector2Array()
	for offset: Vector2 in offsets:
		points.append(origin + offset)
	draw_polyline(points, Color("5a251e"), 3.2, true)
	draw_polyline(points, Color(0.18, 0.06, 0.04, 0.38), 1.2, true)
