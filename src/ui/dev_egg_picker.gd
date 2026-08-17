class_name DevEggPicker
extends Control

signal selection_submitted(egg_kinds: Array[String], starting_spoon_integrity: int)
signal dismissed

const ChickenDay = preload("res://src/domain/chicken_day.gd")
const ProducerFlock = preload("res://src/domain/producer_flock.gd")
const MAX_STARTING_SPOON_INTEGRITY := 99

@onready var _species_buttons: VBoxContainer = %SpeciesButtons
@onready var _egg_order_list: ItemList = %EggOrder
@onready var _move_up: Button = %MoveUp
@onready var _move_down: Button = %MoveDown
@onready var _remove: Button = %Remove
@onready var _integrity: SpinBox = %Patience
@onready var _total: Label = %Total
@onready var _cancel: Button = %Cancel
@onready var _start: Button = %Start

var _egg_order: Array[String] = []


func _ready() -> void:
	for kind: String in ProducerFlock.KNOWN_KINDS:
		var display_name := "Soft-Shelled" if kind == "soft_shelled" else kind.capitalize()
		var add_button := Button.new()
		add_button.name = "Add%s" % kind.capitalize()
		add_button.text = "+  %s" % display_name.to_upper()
		add_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_button.accessibility_name = "Add %s egg" % display_name
		add_button.pressed.connect(add_egg.bind(kind))
		_species_buttons.add_child(add_button)

	_move_up.pressed.connect(_move_selected.bind(-1))
	_move_down.pressed.connect(_move_selected.bind(1))
	_remove.pressed.connect(_remove_selected)
	_egg_order_list.item_selected.connect(_on_order_selection_changed)
	_cancel.pressed.connect(dismiss)
	_start.pressed.connect(submit_selection)
	_integrity.min_value = 1.0
	_integrity.max_value = float(MAX_STARTING_SPOON_INTEGRITY)
	_integrity.value = float(ChickenDay.STARTING_SPOON_INTEGRITY)
	_refresh_order()


func open_with(
	egg_kinds: Array[String],
	starting_integrity_value := ChickenDay.STARTING_SPOON_INTEGRITY
) -> void:
	set_egg_order(egg_kinds)
	set_starting_spoon_integrity(int(starting_integrity_value))
	show()
	if _egg_order.is_empty():
		_start.grab_focus()
	else:
		_egg_order_list.grab_focus()


func set_egg_order(egg_kinds: Array) -> void:
	_egg_order.clear()
	for kind_value in egg_kinds:
		var kind := String(kind_value)
		if kind in ProducerFlock.KNOWN_KINDS:
			_egg_order.append(kind)
	_refresh_order(0)


func egg_order() -> Array[String]:
	return _egg_order.duplicate()


func add_egg(kind: String) -> void:
	if kind not in ProducerFlock.KNOWN_KINDS:
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


func set_starting_spoon_integrity(value: int) -> void:
	_integrity.value = clampi(value, 1, MAX_STARTING_SPOON_INTEGRITY)


func starting_spoon_integrity() -> int:
	return int(_integrity.value)


# Temporary aliases keep old debug tooling usable while the prototype is tentative.
func set_starting_patience(value: int) -> void:
	set_starting_spoon_integrity(value)


func starting_patience() -> int:
	return starting_spoon_integrity()


func total_egg_count() -> int:
	return _egg_order.size()


func selected_egg_kinds() -> Array[String]:
	return egg_order()


func submit_selection() -> void:
	if _egg_order.is_empty():
		return
	hide()
	selection_submitted.emit(egg_order(), starting_spoon_integrity())


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
