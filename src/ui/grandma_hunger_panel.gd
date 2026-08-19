class_name GrandmaHungerPanel
extends Control

@onready var _portrait: Control = %GrandmaPortrait
@onready var _tap_pips_label: Label = %TapPips
@onready var _hunger_card: Control = %HungerCard
@onready var _hunger_value_label: Label = %HungerValue
@onready var _hunger_change_label: Label = %HungerChange
@onready var _next_increase_label: Label = %NextIncrease
@onready var _phase_panel: Control = %PhasePanel
@onready var _phase_label: Label = %PhaseLabel

var _hunger := 10
var _next_hunger_increase := 1
var _starting_hunger := 10


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	render_hunger(_hunger, _next_hunger_increase, _starting_hunger)


func render_hunger(hunger: int, next_hunger_increase: int, starting_hunger := 10) -> void:
	_starting_hunger = maxi(1, starting_hunger)
	_hunger = maxi(0, hunger)
	_next_hunger_increase = maxi(0, next_hunger_increase)
	_refresh_hunger()


func set_hunger(hunger: int) -> void:
	_hunger = maxi(0, hunger)
	_refresh_hunger()


func set_next_increase(next_hunger_increase: int) -> void:
	_next_hunger_increase = maxi(0, next_hunger_increase)
	_refresh_hunger()


func hunger_value() -> int:
	return _hunger


func next_increase() -> int:
	return _next_hunger_increase


func hunger_ratio() -> float:
	return _portrait.hunger_ratio()


func feedback_control() -> Control:
	return _hunger_value_label


func tap_pips_control() -> Label:
	return _tap_pips_label


func delivery_global_position() -> Vector2:
	return _hunger_value_label.get_global_rect().get_center()


func show_hunger_subtraction(hunger_before: int, amount: int, hunger_after: int) -> void:
	_hunger_change_label.text = "%d − %d → %d" % [
		maxi(0, hunger_before), maxi(0, amount), maxi(0, hunger_after),
	]
	_hunger_change_label.visible = true
	_next_increase_label.visible = false


func hide_hunger_subtraction() -> void:
	_hunger_change_label.visible = false
	_next_increase_label.visible = true


func hunger_change_text() -> String:
	return _hunger_change_label.text


func is_hunger_change_visible() -> bool:
	return _hunger_change_label.visible


func hunger_change_control() -> Control:
	return _hunger_change_label


func phase_control() -> Control:
	return _phase_panel


func show_phase(amount: int) -> void:
	_phase_label.text = "HUNGER RISES  +%d" % maxi(0, amount)
	_phase_panel.visible = true


func hide_phase() -> void:
	_phase_panel.visible = false
	_phase_panel.modulate.a = 1.0


func is_phase_visible() -> bool:
	return _phase_panel.visible


func reset_feedback() -> void:
	_hunger_value_label.scale = Vector2.ONE
	hide_hunger_subtraction()
	hide_phase()


func set_reduced_motion(reduced: bool) -> void:
	_portrait.set_reduced_motion(reduced)


func is_idle_motion_active() -> bool:
	return _portrait.is_idle_motion_active()


func _refresh_hunger() -> void:
	_hunger_value_label.text = str(_hunger)
	_next_increase_label.text = "NEXT RESPONSE +%d" % _next_hunger_increase
	# GrandmaPortrait uses 0 for ravenous and 1 for fully fed.
	var fed_ratio := 1.0 - clampf(
		float(_hunger) / float(_starting_hunger), 0.0, 1.0
	)
	_portrait.set_hunger_ratio(fed_ratio)
	_hunger_card.accessibility_name = "Grandma Hunger: %d" % _hunger
	_hunger_card.accessibility_description = (
		"Feed Grandma to zero. Her next Hunger phase adds %d."
		% _next_hunger_increase
	)
