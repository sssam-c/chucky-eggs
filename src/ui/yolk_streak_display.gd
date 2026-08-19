class_name YolkStreakDisplay
extends Control

@onready var _streak_label: Label = %StreakLabel
@onready var _equation_label: Label = %EquationLabel
@onready var _icons_label: Label = %YolkIcons
@onready var _pool_label: Label = %PoolLabel
@onready var _token_layer: Control = %TokenLayer

var _pooled_yolk := 0
var _last_streak := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	reset_pool()


func prepare_token() -> void:
	visible = true


func add_hatch(base_yolk: int, streak: int, awarded_yolk: int) -> void:
	_pooled_yolk += maxi(0, awarded_yolk)
	_last_streak = maxi(0, streak)
	_streak_label.text = streak_callout(_last_streak)
	_equation_label.text = "%d YOLK  ×%d  =  +%d" % [
		maxi(0, base_yolk), _last_streak, maxi(0, awarded_yolk),
	]
	_icons_label.text = _yolk_icons(_pooled_yolk)
	_pool_label.text = "YOLK POOL  %d" % _pooled_yolk
	accessibility_name = "%s Yolk pool %d" % [_streak_label.text, _pooled_yolk]
	accessibility_description = (
		"The latest egg contributed %d Yolk at a times %d break multiplier."
		% [maxi(0, awarded_yolk), _last_streak]
	)
	visible = true


func show_reset(previous_streak: int) -> void:
	_pooled_yolk = 0
	_last_streak = 0
	_streak_label.text = "STREAK BROKEN"
	_equation_label.text = "NO EGG BROKE THIS TAP"
	_icons_label.text = ""
	_pool_label.text = "NEXT BREAK  ×1"
	accessibility_name = "Break streak reset"
	accessibility_description = (
		"The times %d break streak ended because this tap broke no egg."
		% maxi(0, previous_streak)
	)
	visible = true


func create_token(origin_global: Vector2, awarded_yolk: int) -> Label:
	prepare_token()
	var token := Label.new()
	token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.z_index = 40
	token.text = "+%d" % maxi(0, awarded_yolk)
	token.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	token.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	token.add_theme_color_override("font_color", Color("ffd83d"))
	token.add_theme_color_override("font_shadow_color", Color("5a2505"))
	token.add_theme_constant_override("shadow_outline_size", 5)
	token.add_theme_font_size_override("font_size", 30)
	token.custom_minimum_size = Vector2(88.0, 54.0)
	_token_layer.add_child(token)
	token.global_position = origin_global - token.custom_minimum_size * 0.5
	return token


func pool_global_position() -> Vector2:
	return _pool_label.get_global_rect().get_center()


func pooled_yolk() -> int:
	return _pooled_yolk


func last_streak() -> int:
	return _last_streak


func callout_text() -> String:
	return _streak_label.text


func reset_pool() -> void:
	_pooled_yolk = 0
	_last_streak = 0
	visible = false
	scale = Vector2.ONE
	rotation = 0.0
	modulate = Color.WHITE
	if _streak_label != null:
		_streak_label.text = ""
		_equation_label.text = ""
		_icons_label.text = ""
		_pool_label.text = "YOLK POOL  0"
	if _token_layer != null:
		for token: Node in _token_layer.get_children():
			token.queue_free()


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


func _yolk_icons(yolk: int) -> String:
	var visible_yolks := mini(maxi(0, yolk), 8)
	var icons: Array[String] = []
	for yolk_index in range(visible_yolks):
		icons.append("●")
	if yolk > visible_yolks:
		icons.append("+%d" % (yolk - visible_yolks))
	return " ".join(icons)
