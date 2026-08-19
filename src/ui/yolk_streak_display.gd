class_name YolkStreakDisplay
extends Control

@onready var _streak_text: Label = %StreakText
@onready var _streak_badge: Control = $StreakBadge
@onready var _award_panel: Control = %AwardPanel
@onready var _callout_label: Label = %CalloutLabel
@onready var _calculation_label: Label = %CalculationLabel
@onready var _bowl_landing: Control = %BowlLanding
@onready var _token_layer: Control = %TokenLayer

var _pooled_yolk := 0
var _last_streak := 0
var _last_calculation := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	reset_all()


func set_streak(streak: int) -> void:
	_last_streak = maxi(0, streak)
	_streak_text.text = (
		"NEXT BREAK  ×1" if _last_streak == 0 else "STREAK  ×%d" % _last_streak
	)
	_streak_badge.visible = not _award_panel.visible
	visible = true


func add_hatch(base_yolk: int, streak: int, awarded_yolk: int) -> void:
	_pooled_yolk += maxi(0, awarded_yolk)
	set_streak(streak)
	_callout_label.text = streak_callout(_last_streak)
	_calculation_label.add_theme_font_size_override("font_size", 17)
	_last_calculation = "%d YOLK  ×%d" % [
		maxi(0, base_yolk), _last_streak,
	]
	_calculation_label.text = _last_calculation
	_award_panel.visible = true
	_streak_badge.visible = false
	_award_panel.modulate = Color.WHITE
	_award_panel.scale = Vector2.ONE
	_award_panel.rotation = 0.0
	accessibility_name = "%s Award pending: %d Yolk" % [
		_callout_label.text, maxi(0, awarded_yolk),
	]
	accessibility_description = (
		"The egg's %d Yolk is multiplied by the times %d break streak."
		% [maxi(0, base_yolk), _last_streak]
	)


func resolve_award(awarded_yolk: int) -> void:
	_calculation_label.add_theme_font_size_override("font_size", 17)
	_calculation_label.text = "%s = +%d" % [
		_last_calculation, maxi(0, awarded_yolk),
	]
	accessibility_name = "%s Plus %d Yolk" % [
		_callout_label.text, maxi(0, awarded_yolk),
	]


func show_reset(previous_streak: int) -> void:
	_pooled_yolk = 0
	_last_streak = 0
	_streak_text.text = "STREAK LOST"
	_callout_label.text = "STREAK BROKEN"
	_last_calculation = "NO EGG BROKE"
	_calculation_label.add_theme_font_size_override("font_size", 17)
	_calculation_label.text = "NO EGG BROKE"
	_award_panel.visible = true
	_streak_badge.visible = false
	_award_panel.modulate = Color.WHITE
	_award_panel.scale = Vector2.ONE
	_award_panel.rotation = 0.0
	accessibility_name = "Break streak reset"
	accessibility_description = (
		"The times %d break streak ended because this tap broke no egg."
		% maxi(0, previous_streak)
	)


func finish_reset() -> void:
	reset_transient()
	set_streak(0)


func create_yolk_token(origin_global: Vector2, base_yolk: int) -> Label:
	var token := _new_token(str(maxi(0, base_yolk)), 48.0, 24)
	_token_layer.add_child(token)
	token.global_position = origin_global - token.custom_minimum_size * 0.5
	return token


func create_delivery_parcel(total_yolk: int) -> Label:
	var parcel := _new_token("+%d" % maxi(0, total_yolk), 68.0, 26)
	_token_layer.add_child(parcel)
	parcel.global_position = bowl_global_position() - parcel.custom_minimum_size * 0.5
	return parcel


func begin_delivery(total_yolk: int) -> Label:
	_award_panel.visible = false
	return create_delivery_parcel(total_yolk)


func bowl_global_position() -> Vector2:
	return _bowl_landing.get_global_rect().get_center()


func award_control() -> Control:
	return _award_panel


func calculation_control() -> Control:
	return _calculation_label


func pooled_yolk() -> int:
	return _pooled_yolk


func last_streak() -> int:
	return _last_streak


func streak_text() -> String:
	return _streak_text.text


func callout_text() -> String:
	return _callout_label.text


func is_award_visible() -> bool:
	return _award_panel.visible


func finish_delivery() -> void:
	_pooled_yolk = 0
	reset_transient()


func reset_transient() -> void:
	_award_panel.visible = false
	_streak_badge.visible = true
	_award_panel.modulate = Color.WHITE
	_award_panel.scale = Vector2.ONE
	_award_panel.rotation = 0.0
	_callout_label.text = ""
	_calculation_label.text = ""
	_last_calculation = ""
	if _token_layer != null:
		for token: Node in _token_layer.get_children():
			token.queue_free()


func reset_all() -> void:
	_pooled_yolk = 0
	_last_streak = 0
	visible = true
	modulate = Color.WHITE
	scale = Vector2.ONE
	rotation = 0.0
	if _streak_text != null:
		set_streak(0)
		reset_transient()


static func streak_callout(streak: int) -> String:
	match streak:
		1:
			return "YOLK!"
		2:
			return "DOUBLE YOLKER!"
		3:
			return "TRIPLE YOLKER!"
		4:
			return "QUADRUPLE YOLKER!"
		5:
			return "QUINTUPLE YOLKER!"
		6:
			return "SEXTUPLE YOLKER!"
		_:
			return "%d× YOLKER!" % maxi(0, streak)


func _new_token(label_text: String, diameter: float, font_size: int) -> Label:
	var token := Label.new()
	token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.z_index = 40
	token.text = label_text
	token.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	token.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	token.add_theme_color_override("font_color", Color("fff1a8"))
	token.add_theme_color_override("font_shadow_color", Color("5a2505"))
	token.add_theme_constant_override("shadow_outline_size", 4)
	token.add_theme_font_size_override("font_size", font_size)
	token.add_theme_stylebox_override("normal", _token_style())
	token.custom_minimum_size = Vector2(diameter, diameter)
	token.pivot_offset = token.custom_minimum_size * 0.5
	return token


func _token_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e4970c")
	style.border_color = Color("ffcf32")
	style.set_border_width_all(3)
	style.set_corner_radius_all(40)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 6
	return style
