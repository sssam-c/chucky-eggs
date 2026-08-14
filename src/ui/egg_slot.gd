extends Button

@export var slot_index := -1

@onready var _content: Control = %EggContent
@onready var _egg_visual: Control = %EggVisual
@onready var _toughness_label: Label = %Toughness
@onready var _caption_label: Label = %Caption

var _egg: Dictionary = {}
var _preview := false
var _content_origin := Vector2.ZERO
var _bare_belt_mode := false


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
		_caption_label.text = "" if preview else "SLOT %d" % (slot_index + 1)
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
	_caption_label.text = "" if preview else "SLOT %d" % (slot_index + 1)
	disabled = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	tooltip_text = ""
	accessibility_name = "%s egg" % String(_egg.kind).capitalize()
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
		String(_egg.kind).to_upper(),
		_egg.toughness,
		_egg.points,
		"POINT" if _egg.points == 1 else "POINTS",
	]


func egg_description() -> String:
	if _egg.is_empty():
		return "No egg in this slot."
	return "%s egg: %d toughness remaining, worth %d %s; %s." % [
		String(_egg.kind).capitalize(),
		_egg.toughness,
		_egg.points,
		"point" if _egg.points == 1 else "points",
		_effect_description(String(_egg.kind)),
	]


func score_seal_value() -> int:
	return _egg_visual.score_seal_value()


func effect_emblem() -> String:
	return _egg_visual.effect_emblem()


func egg_kind() -> String:
	return _egg.get("kind", "")


func impact_global_position() -> Vector2:
	return _egg_visual.global_position + Vector2(_egg_visual.size.x * 0.5, 18.0)


func hatch_global_position() -> Vector2:
	return _egg_visual.global_position + _egg_visual.size * Vector2(0.5, 0.51)


func motion_content() -> Control:
	return _content


func reset_motion() -> void:
	if not is_node_ready():
		return
	_content.position = _content_origin
	_content.rotation = 0.0
	_content.scale = Vector2.ONE
	_content.modulate = Color.WHITE
	_content.z_index = 0


func _effect_description(kind: String) -> String:
	match kind:
		"cuckoo":
			return "copies damage from an adjacent egg"
		"plover":
			return "a surviving direct hit retreats it one bay to the left"
		"spoonbill":
			return "its spark weakness takes 2 damage from Pink's direct strike"
	return "no extra effect"


func _draw() -> void:
	if _preview:
		return
	var center := Vector2(size.x * 0.5, size.y - 30.0)
	if _bare_belt_mode:
		_draw_oval(center + Vector2(0, 4), Vector2(55, 12), Color(0.0, 0.0, 0.0, 0.34))
		draw_line(center + Vector2(-48, 0), center + Vector2(48, 0), Color("a65d31"), 3.0)
		draw_circle(center + Vector2(-48, 0), 3.0, Color("d18b45"))
		draw_circle(center + Vector2(48, 0), 3.0, Color("d18b45"))
		return
	_draw_oval(center + Vector2(0, 6), Vector2(63, 24), Color(0.0, 0.0, 0.0, 0.48))
	_draw_oval(center, Vector2(61, 22), Color("19191b"))
	draw_arc(center, 61.0, PI, TAU, 32, Color("a65d31"), 5.0, true)
	draw_arc(center, 50.0, PI, TAU, 32, Color("4b4d4f"), 8.0, true)
	draw_line(center + Vector2(-57, 2), center + Vector2(57, 2), Color("0b0b0c"), 5.0)
	draw_circle(center + Vector2(-54, 0), 4.0, Color("bd7742"))
	draw_circle(center + Vector2(54, 0), 4.0, Color("bd7742"))


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for point_index in range(32):
		var angle := TAU * float(point_index) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
