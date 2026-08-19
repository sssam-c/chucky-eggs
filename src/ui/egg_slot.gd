extends Button

const PREVIEW_CONTENT_SCALE := Vector2(0.82, 0.82)

@export var slot_index := -1
@export var egg_cup_mode := false

@onready var _content: Control = %EggContent
@onready var _egg_visual: Control = %EggVisual
@onready var _toughness_label: Label = %Toughness

var _egg: Dictionary = {}
var _preview := false
var _content_origin := Vector2.ZERO
var _bare_belt_mode := false
var _circuit_id := ""
var _circuit_color := Color("bd7742")
var _stage_content_scale := 1.0


func _ready() -> void:
	_content_origin = _content.position
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	queue_redraw()


func render_egg(egg: Dictionary, interaction_enabled: bool, preview := false) -> void:
	_egg = egg.duplicate(true)
	_preview = preview
	reset_motion()

	if _egg.is_empty():
		_egg_visual.clear_egg()
		_egg_visual.visible = false
		_toughness_label.visible = false
		disabled = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE
		tooltip_text = ""
		accessibility_name = "Empty slot"
		accessibility_description = "No egg in this slot."
		queue_redraw()
		return

	_egg_visual.visible = true
	_egg_visual.set_egg(_egg, preview)
	_toughness_label.visible = true
	_toughness_label.text = str(_egg.toughness)
	disabled = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	tooltip_text = ""
	accessibility_name = "%s egg" % _kind_display_name(String(_egg.kind))
	accessibility_description = egg_description()
	queue_redraw()


func set_interaction_enabled(enabled: bool) -> void:
	# The foreground circuit levers own interaction; the egg slot is presentation only.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE


func set_bare_belt_mode(enabled: bool) -> void:
	if _bare_belt_mode == enabled:
		return
	_bare_belt_mode = enabled
	queue_redraw()


func is_bare_belt_mode() -> bool:
	return _bare_belt_mode


func set_egg_cup_mode(enabled: bool) -> void:
	if egg_cup_mode == enabled:
		return
	egg_cup_mode = enabled
	queue_redraw()


func is_egg_cup_mode() -> bool:
	return egg_cup_mode


func set_stage_content_scale(value: float) -> void:
	_stage_content_scale = maxf(value, 1.0)
	reset_motion()


func stage_content_scale() -> float:
	return _stage_content_scale


func set_circuit_appearance(circuit_id: String, color: Color, _symbol: String) -> void:
	_circuit_id = circuit_id
	_circuit_color = color
	queue_redraw()


func circuit_id() -> String:
	return _circuit_id


func circuit_color() -> Color:
	return _circuit_color


func apply_damage(remaining_toughness: int) -> void:
	if _egg.is_empty():
		return
	_egg.toughness = remaining_toughness
	_toughness_label.text = str(remaining_toughness)
	_egg_visual.set_egg(_egg, _preview)


func clear_visual() -> void:
	render_egg({}, false, _preview)


func current_egg() -> Dictionary:
	return _egg.duplicate(true)


func egg_summary() -> String:
	if _egg.is_empty():
		return "EMPTY"
	return "%s EGG TOUGHNESS %d %d %s" % [
		_kind_display_name(String(_egg.kind)).to_upper(),
		_egg.toughness,
		_egg.points,
		"POINT" if _egg.points == 1 else "POINTS",
	]


func egg_description() -> String:
	if _egg.is_empty():
		return "No egg in this slot."
	return "%s egg: %d toughness remaining, worth %d %s; %s." % [
		_kind_display_name(String(_egg.kind)),
		_egg.toughness,
		_egg.points,
		"point" if _egg.points == 1 else "points",
		_effect_description(_egg),
	]


func score_seal_value() -> int:
	return _egg_visual.score_seal_value()


func effect_emblem() -> String:
	return _egg_visual.effect_emblem()


func egg_kind() -> String:
	return _egg.get("kind", "")


func impact_global_position() -> Vector2:
	return _egg_visual.get_global_transform() * Vector2(_egg_visual.size.x * 0.5, 18.0)


func hatch_global_position() -> Vector2:
	return _egg_visual.get_global_transform() * (_egg_visual.size * Vector2(0.5, 0.51))


func motion_content() -> Control:
	return _content


func reset_motion() -> void:
	if not is_node_ready():
		return
	_content.position = _content_origin
	_content.pivot_offset = _content.size * 0.5
	_content.rotation = 0.0
	_content.scale = (
		PREVIEW_CONTENT_SCALE
		if _preview
		else Vector2.ONE * _stage_content_scale
	)
	_content.modulate = Color.WHITE
	_content.z_index = 0


func _effect_description(egg: Dictionary) -> String:
	var descriptions: Array[String] = []
	var kind := String(egg.kind)
	match kind:
		"cuckoo":
			descriptions.append("copies damage from an adjacent egg")
		"plover":
			descriptions.append("a surviving direct hit retreats it one bay to the left")
		"spoonbill":
			descriptions.append("its spark weakness takes 2 damage from Pink's direct strike")
	for description: Variant in egg.get("all_other_effects", []):
		descriptions.append(String(description))
	return "; ".join(descriptions) if not descriptions.is_empty() else "no extra effect"
func _kind_display_name(kind: String) -> String:
	return kind.capitalize()


func _draw() -> void:
	if _preview:
		return
	var center := Vector2(size.x * 0.5, size.y - 30.0)
	if egg_cup_mode:
		_draw_egg_cup(center)
		return
	if _bare_belt_mode:
		# The machine stage colours the belt section. The slot adds only a soft
		# contact shadow so eggs remain seated without looking like separate pads.
		_draw_oval(center + Vector2(0, 4), Vector2(55, 12), Color(0.0, 0.0, 0.0, 0.34))
		return
	_draw_oval(center + Vector2(0, 6), Vector2(63, 24), Color(0.0, 0.0, 0.0, 0.48))
	_draw_oval(center, Vector2(61, 22), Color("19191b"))
	draw_arc(center, 61.0, PI, TAU, 32, Color("a65d31"), 5.0, true)
	draw_arc(center, 50.0, PI, TAU, 32, Color("4b4d4f"), 8.0, true)
	draw_line(center + Vector2(-57, 2), center + Vector2(57, 2), Color("0b0b0c"), 5.0)
	draw_circle(center + Vector2(-54, 0), 4.0, Color("bd7742"))
	draw_circle(center + Vector2(54, 0), 4.0, Color("bd7742"))


func _draw_egg_cup(center: Vector2) -> void:
	var cup_top := center - Vector2(0.0, 13.0)
	_draw_oval(center + Vector2(3.0, 27.0), Vector2(62.0, 15.0), Color(0.0, 0.0, 0.0, 0.34))
	var body := PackedVector2Array([
		cup_top + Vector2(-58.0, 2.0),
		cup_top + Vector2(58.0, 2.0),
		center + Vector2(40.0, 29.0),
		center + Vector2(-40.0, 29.0),
	])
	draw_colored_polygon(body, Color("e7d7b7"))
	var body_outline := body.duplicate()
	body_outline.append(body[0])
	draw_polyline(body_outline, Color("6f4d34"), 4.0, true)
	_draw_oval(cup_top, Vector2(61.0, 18.0), Color("6f4d34"))
	_draw_oval(cup_top - Vector2(0.0, 2.0), Vector2(54.0, 13.0), Color("2a1c16"))
	draw_line(
		center + Vector2(-36.0, 20.0),
		center + Vector2(36.0, 20.0),
		_circuit_color.lightened(0.18),
		5.0,
		true
	)


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for point_index in range(32):
		var angle := TAU * float(point_index) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
