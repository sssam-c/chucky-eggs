extends Control

signal playback_started
signal presentation_event(event_type: String)
signal playback_completed

const HopperTapSession = preload("res://src/game/hopper_tap_session.gd")

const APPEARANCES := [
	{"color": Color("c43b36"), "symbol": "diamond"},
	{"color": Color("287cbd"), "symbol": "circle"},
	{"color": Color("cf4f8b"), "symbol": "spark"},
	{"color": Color("58a83f"), "symbol": "triangle"},
	{"color": Color("efa91a"), "symbol": "square"},
]

@onready var _slots: Array[Button] = [%Slot1, %Slot2, %Slot3, %Slot4, %Slot5]
@onready var _pipe_slots: Array[Button] = [%Next1, %Next2, %Next3]
@onready var _spoon_buttons: Array[Button] = [
	%SpoonButton1, %SpoonButton2, %SpoonButton3, %SpoonButton4, %SpoonButton5,
]
@onready var _spoons: Array[Control] = [%Spoon1, %Spoon2, %Spoon3, %Spoon4, %Spoon5]
@onready var _hopper_drop_point: Control = %HopperDropPoint
@onready var _grandma_hunger_panel: Control = %GrandmaSidebar
@onready var _yolk_combo_display: Control = %YolkComboDisplay
@onready var _tap_pips_label: Label = _grandma_hunger_panel.tap_pips_control()
@onready var _hopper_count_label: Label = %HopperCount
@onready var _result_panel: PanelContainer = %ResultPanel
@onready var _result_label: Label = %ResultLabel
@onready var _restart_button: Button = %Restart
@onready var _new_seed_button: Button = %NewSeed
@onready var _result_restart_button: Button = %ResultRestart
@onready var _round_label: Label = %Round
@onready var _seed_label: Label = %Seed
@onready var _round_announcement: Label = %RoundAnnouncement
@onready var _reward_overlay: Control = %RewardOverlay
@onready var _reward_summary: Label = %RewardSummary
@onready var _reward_choices: Array[Button] = [%Choice1, %Choice2, %Choice3]
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
		_spoon_buttons[slot_index].control_style = "button"
		_spoon_buttons[slot_index].circuit_requested.connect(_on_spoon_requested)
		_spoons[slot_index].slot_index = slot_index
		_spoons[slot_index].set_neutral_appearance()
	_restart_button.pressed.connect(restart)
	_new_seed_button.pressed.connect(new_seed)
	_result_restart_button.pressed.connect(_on_result_action)
	for choice_index in range(_reward_choices.size()):
		_reward_choices[choice_index].pressed.connect(
			_on_reward_chosen.bind(choice_index)
		)
	_presenter.event_presented.connect(
		func(event_type: String) -> void: presentation_event.emit(event_type)
	)
	_presenter.configure(
		_slots,
		_pipe_slots,
		_spoon_buttons,
		_spoons,
		_hopper_drop_point,
		_yolk_combo_display,
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
	_replace_session_view()
	_session.restart()
	_finish_session_replacement()


func new_seed() -> void:
	_replace_session_view()
	_session.start_new_run()
	_finish_session_replacement()


func _replace_session_view() -> void:
	_request_generation += 1
	_presenter.cancel_playback()
	_input_locked = false
	_result_panel.visible = false
	_reward_overlay.visible = false


func _finish_session_replacement() -> void:
	_render()
	_spoon_buttons[0].grab_focus.call_deferred()


func _on_result_action() -> void:
	var state: Dictionary = _session.state()
	if not bool(state.run_succeeded) and int(state.round_number) == 2:
		_replace_session_view()
		_session.retry_round()
		_finish_session_replacement()
	elif bool(state.run_succeeded):
		new_seed()
	else:
		restart()


func _on_reward_chosen(choice_index: int) -> void:
	if _input_locked:
		return
	_input_locked = true
	for choice: Button in _reward_choices:
		choice.disabled = true
	var events: Array[Dictionary] = _session.choose_reward(choice_index)
	if events.is_empty() or String(events[0].type) == "reward_rejected":
		_input_locked = false
		_render()
		return
	_input_locked = false
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
		int(state.round_starting_hunger)
	)
	_round_label.text = "ROUND %d / %d" % [
		int(state.round_number), int(state.round_count),
	]
	_seed_label.text = "SEED %d" % int(state.run_seed)
	_round_announcement.text = "ROUND %d  •  %d HUNGER  •  %d EGGS" % [
		int(state.round_number), int(state.round_starting_hunger), int(state.round_egg_count),
	]
	_tap_pips_label.text = _tap_pips(int(state.taps_remaining), int(state.taps_per_phase))
	_yolk_combo_display.reset_transient()
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
	_set_spoons_available(
		not bool(state.ended)
		and not bool(state.awaiting_reward)
		and not bool(state.run_ended)
		and not _input_locked
	)
	_render_reward(state)
	_result_panel.visible = bool(state.run_ended)
	if state.run_ended:
		if state.run_succeeded:
			_result_label.text = "TWO-ROUND RUN COMPLETE\nSEED %d" % int(state.run_seed)
			_result_restart_button.text = "START NEW SEED"
		else:
			_result_label.text = "ROUND %d FAILED\nHUNGER %d" % [
				int(state.round_number), int(state.hunger),
			]
			_result_restart_button.text = (
				"RETRY ROUND 2" if int(state.round_number) == 2 else "RETRY SEED"
			)
		_result_restart_button.grab_focus.call_deferred()


func _render_reward(state: Dictionary) -> void:
	var was_visible := _reward_overlay.visible
	_reward_overlay.visible = bool(state.awaiting_reward)
	if not _reward_overlay.visible:
		return
	_reward_summary.text = (
		"ROUND 1 COMPLETE  •  ADD ONE EGG\n"
		+ "ROUND 2 STARTS WITH %d HUNGER" % HopperTapSession.ROUND_TWO_HUNGER
	)
	for choice_index in range(_reward_choices.size()):
		var choice: Button = _reward_choices[choice_index]
		choice.visible = choice_index < state.reward_offers.size()
		if not choice.visible:
			continue
		choice.render_offer(String(state.reward_offers[choice_index]))
		choice.disabled = _input_locked
	if not was_visible:
		_reward_choices[0].grab_focus.call_deferred()


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
