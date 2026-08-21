class_name DevEggPicker
extends Control

signal selection_submitted(egg_kinds: Array[String], starting_belt_condition: int)
signal dismissed

const ChickenDay = preload("res://src/domain/chicken_day.gd")
const ProducerFlock = preload("res://src/domain/producer_flock.gd")
const MAX_STARTING_BELT_CONDITION := 99

@onready var _species_buttons: GridContainer = %SpeciesButtons
@onready var _title: Label = $Panel/Margin/Layout/Title
@onready var _instructions: Label = $Panel/Margin/Layout/Instructions
@onready var _egg_order_list: ItemList = %EggOrder
@onready var _move_up: Button = %MoveUp
@onready var _move_down: Button = %MoveDown
@onready var _remove: Button = %Remove
@onready var _condition: SpinBox = %Condition
@onready var _condition_label: Label = $Panel/Margin/Layout/Setup/ConditionLabel
@onready var _total: Label = %Total
@onready var _cancel: Button = %Cancel
@onready var _start: Button = %Start

var _egg_order: Array[String] = []
var _allowed_egg_kinds: Array[String] = ProducerFlock.KNOWN_KINDS.duplicate()


func _ready() -> void:
	_rebuild_species_buttons()

	_move_up.pressed.connect(_move_selected.bind(-1))
	_move_down.pressed.connect(_move_selected.bind(1))
	_remove.pressed.connect(_remove_selected)
	_egg_order_list.item_selected.connect(_on_order_selection_changed)
	_cancel.pressed.connect(dismiss)
	_start.pressed.connect(submit_selection)
	_condition.min_value = 1.0
	_condition.max_value = float(MAX_STARTING_BELT_CONDITION)
	_condition.value = float(ChickenDay.DEFAULT_BELT_CONDITION)
	_refresh_order()


func configure_mode(
	allowed_kinds: Array[String],
	title_text: String,
	instruction_text: String,
	value_label_text: String,
	value_accessibility_name: String,
	start_button_text: String,
	default_value: int
) -> void:
	_allowed_egg_kinds = allowed_kinds.duplicate()
	_title.text = title_text
	_instructions.text = instruction_text
	_condition_label.text = value_label_text
	_condition.accessibility_name = value_accessibility_name
	_start.text = start_button_text
	set_setup_value(default_value)
	_rebuild_species_buttons()
	var retained_order := _egg_order.duplicate()
	set_egg_order(retained_order)


func allowed_egg_kinds() -> Array[String]:
	return _allowed_egg_kinds.duplicate()


func _rebuild_species_buttons() -> void:
	if not is_instance_valid(_species_buttons):
		return
	for child: Node in _species_buttons.get_children():
		child.free()
	for kind: String in _allowed_egg_kinds:
		var display_name := kind.capitalize()
		var add_button := Button.new()
		add_button.name = "Add%s" % kind.capitalize()
		add_button.text = "+  %s" % display_name.to_upper()
		add_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_button.accessibility_name = "Add %s egg" % display_name
		add_button.pressed.connect(add_egg.bind(kind))
		_species_buttons.add_child(add_button)


func open_with(
	egg_kinds: Array[String],
	starting_condition_value := ChickenDay.DEFAULT_BELT_CONDITION
) -> void:
	set_egg_order(egg_kinds)
	set_starting_belt_condition(int(starting_condition_value))
	show()
	if _egg_order.is_empty():
		_start.grab_focus()
	else:
		_egg_order_list.grab_focus()


func set_egg_order(egg_kinds: Array) -> void:
	_egg_order.clear()
	for kind_value in egg_kinds:
		var kind := String(kind_value)
		if kind in _allowed_egg_kinds:
			_egg_order.append(kind)
	_refresh_order(0)


func egg_order() -> Array[String]:
	return _egg_order.duplicate()


func add_egg(kind: String) -> void:
	if kind not in _allowed_egg_kinds:
		return
	_egg_order.append(kind)
	_refresh_order(_egg_order.size() - 1)


func move_egg(from_index: int, to_index: int) -> void:
	if from_index < 0 or from_index >= _egg_order.size():
		return
	if to_index < 0 or to_index >= _egg_order.size() or from_index == to_index:
		return
	var kind: String = _egg_order.pop_at(from_index)
	_egg_order.insert(to_index, kind)
	_refresh_order(to_index)


func remove_egg(index: int) -> void:
	if index < 0 or index >= _egg_order.size():
		return
	_egg_order.remove_at(index)
	_refresh_order(mini(index, _egg_order.size() - 1))


func set_starting_belt_condition(value: int) -> void:
	set_setup_value(value)


func starting_belt_condition() -> int:
	return setup_value()


func set_setup_value(value: int) -> void:
	_condition.value = clampi(value, 1, MAX_STARTING_BELT_CONDITION)


func setup_value() -> int:
	return int(_condition.value)


func total_egg_count() -> int:
	return _egg_order.size()


func selected_egg_kinds() -> Array[String]:
	return egg_order()


func submit_selection() -> void:
	if _egg_order.is_empty():
		return
	hide()
	selection_submitted.emit(egg_order(), starting_belt_condition())


func dismiss() -> void:
	if not visible:
		return
	hide()
	dismissed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		dismiss()
		get_viewport().set_input_as_handled()


func _move_selected(offset: int) -> void:
	var selected := _selected_index()
	move_egg(selected, selected + offset)


func _remove_selected() -> void:
	remove_egg(_selected_index())


func _on_order_selection_changed(_index: int) -> void:
	_refresh_order_actions()


func _selected_index() -> int:
	var selected := _egg_order_list.get_selected_items()
	return int(selected[0]) if not selected.is_empty() else -1


func _refresh_order(selected_index := -1) -> void:
	if not is_instance_valid(_egg_order_list):
		return
	_egg_order_list.clear()
	for index in range(_egg_order.size()):
		_egg_order_list.add_item("%02d   %s" % [index + 1, _egg_order[index].to_upper()])
	if selected_index >= 0 and not _egg_order.is_empty():
		var safe_index := clampi(selected_index, 0, _egg_order.size() - 1)
		_egg_order_list.select(safe_index)
		_egg_order_list.ensure_current_is_visible()
	_refresh_summary()
	_refresh_order_actions()


func _refresh_summary() -> void:
	if not is_instance_valid(_total) or not is_instance_valid(_start):
		return
	var count := total_egg_count()
	_total.text = "TOTAL EGGS  %d" % count
	_total.accessibility_name = "%d starting eggs selected" % count
	_start.disabled = count == 0


func _refresh_order_actions() -> void:
	if not is_instance_valid(_move_up):
		return
	var selected := _selected_index()
	_move_up.disabled = selected <= 0
	_move_down.disabled = selected < 0 or selected >= _egg_order.size() - 1
	_remove.disabled = selected < 0
