extends Control

signal playback_started
signal presentation_event(event_type: String)
signal playback_completed

const HopperTapSession = preload("res://src/game/hopper_tap_session.gd")

const APPEARANCES := [
	{"color": Color("c43b36"), "symbol": "diamond", "label": "RED  ◆"},
	{"color": Color("287cbd"), "symbol": "circle", "label": "BLUE  ○"},
	{"color": Color("cf4f8b"), "symbol": "spark", "label": "PINK  ✦"},
	{"color": Color("c43b36"), "symbol": "diamond", "label": "RED  ◆"},
	{"color": Color("287cbd"), "symbol": "circle", "label": "BLUE  ○"},
]

@onready var _slots: Array[Button] = [%Slot1, %Slot2, %Slot3, %Slot4, %Slot5]
@onready var _pipe_slots: Array[Button] = [%Next1, %Next2, %Next3]
@onready var _spoon_buttons: Array[Button] = [
	%SpoonButton1, %SpoonButton2, %SpoonButton3, %SpoonButton4, %SpoonButton5,
]
@onready var _spoons: Array[Control] = [%Spoon1, %Spoon2, %Spoon3, %Spoon4, %Spoon5]
@onready var _lane_labels: Array[Label] = [%Lane1, %Lane2, %Lane3, %Lane4, %Lane5]
@onready var _hopper_drop_point: Control = %HopperDropPoint
@onready var _grandma_hunger_panel: Control = %GrandmaSidebar
@onready var _tap_pips_label: Label = %TapPips
@onready var _hopper_count_label: Label = %HopperCount
@onready var _result_panel: PanelContainer = %ResultPanel
@onready var _result_label: Label = %ResultLabel
@onready var _restart_button: Button = %Restart
@onready var _result_restart_button: Button = %ResultRestart
@onready var _presenter: Node = %TapPresenter

var _session = HopperTapSession.new()
var _input_locked := false
var _request_generation := 0


func _ready() -> void:
	var state: Dictionary = _session.state()
	for slot_index in range(_slots.size()):
		var spoon: Dictionary = state.spoons[slot_index]
		var appearance: Dictionary = APPEARANCES[slot_index]
		_slots[slot_index].slot_index = slot_index
		_slots[slot_index].set_circuit_appearance(
			String(spoon.id), appearance.color, String(appearance.symbol)
		)
		_slots[slot_index].set_egg_cup_mode(true)
		_slots[slot_index].set_stage_content_scale(1.18)
		_spoon_buttons[slot_index].circuit_id = String(spoon.id)
		_spoon_buttons[slot_index].slot_indices.assign([slot_index])
		_spoon_buttons[slot_index].circuit_color = appearance.color
		_spoon_buttons[slot_index].circuit_symbol = String(appearance.symbol)
		_spoon_buttons[slot_index].control_style = "spoon"
		_spoon_buttons[slot_index].circuit_requested.connect(_on_spoon_requested)
		_spoons[slot_index].slot_index = slot_index
		_spoons[slot_index].circuit_id = String(spoon.id)
		_spoons[slot_index].circuit_color = appearance.color
		_spoons[slot_index].circuit_symbol = String(appearance.symbol)
		_lane_labels[slot_index].text = String(appearance.label)
		_lane_labels[slot_index].add_theme_color_override("font_color", appearance.color.lightened(0.28))
	_restart_button.pressed.connect(restart)
	_result_restart_button.pressed.connect(restart)
	_presenter.event_presented.connect(
		func(event_type: String) -> void: presentation_event.emit(event_type)
	)
	_presenter.configure(
		_slots,
		_pipe_slots,
		_spoon_buttons,
		_spoons,
		_hopper_drop_point,
		_grandma_hunger_panel,
		_tap_pips_label,
	)
	_render()
	_configure_hammer_contacts.call_deferred()
	_spoon_buttons[0].grab_focus.call_deferred()


func game_state() -> Dictionary:
	return _session.state()


func set_reduced_motion(reduced: bool) -> void:
	_presenter.set_reduced_motion(reduced)


func set_muted(muted: bool) -> void:
	_presenter.set_muted(muted)


func is_input_locked() -> bool:
	return _input_locked


func restart() -> void:
	_request_generation += 1
	_presenter.cancel_playback()
	_session.restart()
	_input_locked = false
	_result_panel.visible = false
	_render()
	_spoon_buttons[0].grab_focus.call_deferred()


func _on_spoon_requested(spoon_id: String) -> void:
	if _input_locked:
		return
	var state: Dictionary = _session.state()
	for spoon: Dictionary in state.spoons:
		if String(spoon.id) == spoon_id:
			_submit_spoon(int(spoon.slot_index))
			return


func _submit_spoon(slot_index: int) -> void:
	if _input_locked:
		return
	var events: Array[Dictionary] = _session.submit_spoon(slot_index)
	if events.is_empty() or String(events[0].type) == "spoon_rejected":
		return
	_input_locked = true
	_request_generation += 1
	var request_generation := _request_generation
	_set_spoons_available(false)
	playback_started.emit()
	var completed: bool = await _presenter.play_events(events)
	if not completed or request_generation != _request_generation:
		return
	_input_locked = false
	_render()
	playback_completed.emit()


func _render() -> void:
	var state: Dictionary = _session.state()
	_grandma_hunger_panel.render_hunger(
		int(state.hunger), int(state.next_hunger_increase),
		HopperTapSession.STARTING_HUNGER
	)
	_tap_pips_label.text = _tap_pips(int(state.taps_remaining), int(state.taps_per_phase))
	_hopper_count_label.text = "%d WAITING" % int(state.hopper_egg_count)
	for slot_index in range(_slots.size()):
		var egg: Dictionary = state.slots[slot_index]
		_slots[slot_index].render_egg(egg, false)
		var target_descriptions: Array[String] = []
		target_descriptions.append(
			"empty" if egg.is_empty() else _slots[slot_index].egg_description()
		)
		_spoon_buttons[slot_index].set_target_descriptions(target_descriptions)
	for preview_index in range(_pipe_slots.size()):
		var egg: Dictionary = state.pipe[preview_index] if preview_index < state.pipe.size() else {}
		_pipe_slots[preview_index].render_egg(egg, false, true)
	_set_spoons_available(not bool(state.ended) and not _input_locked)
	_result_panel.visible = bool(state.ended)
	if state.ended:
		_result_label.text = (
			"GRANDMA IS SATISFIED!\nHUNGER 0"
			if state.succeeded
			else "NO EGGS LEFT\nHUNGER %d" % int(state.hunger)
		)
		_result_restart_button.grab_focus.call_deferred()


func _tap_pips(remaining: int, total: int) -> String:
	var pips: Array[String] = []
	for tap_index in range(total):
		pips.append("●" if tap_index < remaining else "○")
	return "TAPS  %s" % " ".join(pips)


func _set_spoons_available(enabled: bool) -> void:
	var state: Dictionary = _session.state()
	for slot_index in range(_spoon_buttons.size()):
		var occupied: bool = not state.slots[slot_index].is_empty()
		_spoon_buttons[slot_index].set_available(enabled and occupied)


func _configure_hammer_contacts() -> void:
	for slot_index in range(_spoons.size()):
		var contact_global: Vector2 = _slots[slot_index].impact_global_position()
		var contact_local: Vector2 = (
			_spoons[slot_index].get_global_transform().affine_inverse() * contact_global
		)
		_spoons[slot_index].configure_wall_spoon(contact_local)
