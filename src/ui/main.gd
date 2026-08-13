extends Control

signal playback_started
signal presentation_event(event_type: String)
signal playback_completed
signal production_loading_started(producer_count: int, egg_count: int)
signal production_loading_completed

const ChickenDaySession = preload("res://src/game/chicken_day_session.gd")

@onready var _score_label: Label = %Score
@onready var _thwacks_label: Label = %Thwacks
@onready var _feedback_label: Label = %Feedback
@onready var _result_overlay: Control = %ResultOverlay
@onready var _result_card: PanelContainer = $ResultOverlay/Card
@onready var _result_label: Label = %Result
@onready var _result_score_label: Label = %ResultScore
@onready var _result_summary_label: Label = %Summary
@onready var _flock_summary_label: Label = %FlockSummary
@onready var _reward_choices_container: HBoxContainer = %RewardChoices
@onready var _restart_button: Button = %Restart
@onready var _mute_button: CheckButton = %Mute
@onready var _reduced_motion_button: CheckButton = %ReducedMotion
@onready var _belt: Control = %Belt
@onready var _drop_label: Label = %Drop
@onready var _echo_trace: Control = %EchoTrace
@onready var _hatch_payoff: Control = %HatchPayoff
@onready var _presenter: Node = %Presentation
@onready var _production_loader: Control = %ProductionLoader
@onready var _hopper_count_label: Label = %HopperCount
@onready var _belt_slots: Array[Button] = [%Slot1, %Slot2, %Slot3, %Slot4, %Slot5]
@onready var _pipe_slots: Array[Button] = [%Next1, %Next2, %Next3]
@onready var _circuit_buttons: Array[Button] = [%RedCircuit, %BlueCircuit, %PinkCircuit]
@onready var _hammers: Array[Control] = [%Hammer1, %Hammer2, %Hammer3, %Hammer4, %Hammer5]
@onready var _producer_choice_buttons: Array[Button] = [%Choice1, %Choice2, %Choice3]

var _session = ChickenDaySession.new()
var _input_locked := false
var _request_generation := 0


func _ready() -> void:
	for circuit_button: Button in _circuit_buttons:
		circuit_button.connect("circuit_requested", _on_circuit_requested)
	for choice_index in range(_producer_choice_buttons.size()):
		_producer_choice_buttons[choice_index].pressed.connect(
			_on_producer_choice_pressed.bind(choice_index)
		)
	_restart_button.pressed.connect(_on_restart_pressed)
	_mute_button.toggled.connect(set_muted)
	_reduced_motion_button.toggled.connect(set_reduced_motion)
	_presenter.event_presented.connect(_on_presentation_event)
	_production_loader.loading_started.connect(
		func(producer_count: int, egg_count: int) -> void:
			production_loading_started.emit(producer_count, egg_count)
	)
	_presenter.configure(
		_belt_slots,
		_pipe_slots,
		_circuit_buttons,
		_hammers,
		_echo_trace,
		_hatch_payoff,
		_score_label,
		_thwacks_label,
		_drop_label
	)
	_render([], true)
	_circuit_buttons[0].grab_focus()


func _on_circuit_requested(circuit_id: String) -> void:
	if _input_locked:
		return

	var events: Array[Dictionary] = _session.submit_circuit(circuit_id)
	if events.is_empty() or events[0].type == "thwack_rejected":
		return

	_input_locked = true
	_request_generation += 1
	var request_generation := _request_generation
	_set_circuit_interaction(false)
	playback_started.emit()
	var completed: bool = await _presenter.play_events(events)
	if not completed or request_generation != _request_generation:
		return

	_input_locked = false
	_render(events)
	playback_completed.emit()


func _on_restart_pressed() -> void:
	restart_day()


func _on_producer_choice_pressed(choice_index: int) -> void:
	if _input_locked:
		return
	var state: Dictionary = _session.state()
	if state.phase != "reward" or choice_index >= state.reward_choices.size():
		return
	var selected: Dictionary = state.reward_choices[choice_index]
	var events: Array[Dictionary] = _session.select_producer(selected.kind)
	if events.is_empty() or events[0].type == "producer_selection_rejected":
		return
	var day_started_event := _event_of_type(events, "day_started")
	if day_started_event.is_empty():
		return

	_input_locked = true
	_request_generation += 1
	var request_generation := _request_generation
	_set_circuit_interaction(false)
	_result_overlay.visible = false
	var completed: bool = await _production_loader.begin(
		day_started_event.production,
		day_started_event.day_number,
		day_started_event.daily_egg_count,
		is_reduced_motion()
	)
	if not completed or request_generation != _request_generation:
		return

	_input_locked = false
	_render(events, true)
	production_loading_completed.emit()


func restart_day() -> void:
	_request_generation += 1
	_presenter.cancel_playback()
	_production_loader.cancel()
	_input_locked = false
	_session.restart()
	_render([], true)
	_circuit_buttons[0].grab_focus()


func replace_session(session) -> void:
	_request_generation += 1
	_presenter.cancel_playback()
	_production_loader.cancel()
	_input_locked = false
	_session = session
	_render([], true)
	_circuit_buttons[0].grab_focus()


func set_muted(muted: bool) -> void:
	_presenter.set_muted(muted)
	_mute_button.set_pressed_no_signal(muted)


func is_muted() -> bool:
	return _presenter.is_muted()


func set_reduced_motion(reduced: bool) -> void:
	_presenter.set_reduced_motion(reduced)
	_reduced_motion_button.set_pressed_no_signal(reduced)


func is_reduced_motion() -> bool:
	return _presenter.is_reduced_motion()


func is_input_locked() -> bool:
	return _input_locked


func _render(events: Array[Dictionary], fresh_day := false) -> void:
	var state: Dictionary = _session.state()
	_score_label.text = "SCORE %d / %d" % [state.score, state.target_score]
	_thwacks_label.text = "THWACKS %d" % state.remaining_thwacks
	_hopper_count_label.text = "HOPPER %d" % state.hopper_egg_count

	for slot_index in range(_belt_slots.size()):
		_belt_slots[slot_index].render_egg(
			state.slots[slot_index],
			false,
			false
		)
	for preview_index in range(_pipe_slots.size()):
		var egg: Dictionary = state.pipe[preview_index] if preview_index < state.pipe.size() else {}
		_pipe_slots[preview_index].render_egg(egg, false, true)

	for circuit_button: Button in _circuit_buttons:
		var descriptions: Array[String] = []
		var has_egg := false
		for slot_index: int in circuit_button.slot_indices:
			var egg: Dictionary = state.slots[slot_index]
			has_egg = has_egg or not egg.is_empty()
			descriptions.append("empty" if egg.is_empty() else _belt_slots[slot_index].egg_description())
		circuit_button.set_target_descriptions(descriptions)
		circuit_button.set_available(has_egg and not state.ended and not _input_locked)

	_result_overlay.visible = state.ended
	if state.ended:
		var choosing_producer: bool = state.phase == "reward"
		_result_label.text = "CHOOSE A PRODUCER" if choosing_producer else "DAY FAILED"
		_result_score_label.text = "%d / %d POINTS" % [state.score, state.target_score]
		_flock_summary_label.text = "FLOCK %d PRODUCERS  •  DAILY OUTPUT %d EGGS" % [
			state.producers.size(), state.daily_egg_count,
		]
		_reward_choices_container.visible = choosing_producer
		_restart_button.visible = not choosing_producer
		if choosing_producer:
			_result_card.offset_left = -500.0
			_result_card.offset_top = -230.0
			_result_card.offset_right = 500.0
			_result_card.offset_bottom = 230.0
			_result_summary_label.text = "Success! Add one producer. Its full daily yield joins tomorrow's shuffled hopper."
			for choice_index in range(_producer_choice_buttons.size()):
				_producer_choice_buttons[choice_index].render_choice(state.reward_choices[choice_index])
			_producer_choice_buttons[0].grab_focus.call_deferred()
		else:
			_result_card.offset_left = -240.0
			_result_card.offset_top = -170.0
			_result_card.offset_right = 240.0
			_result_card.offset_bottom = 170.0
			_result_summary_label.text = "No producer joins the flock. Retry this day with the same flock and shuffle."
			_restart_button.text = "RETRY DAY %d" % state.day_number
			_restart_button.grab_focus.call_deferred()

	if fresh_day:
		_feedback_label.text = "DAY %d  •  RED 1+3  •  BLUE 2+4  •  PINK 5 — EMPTY STRIKES ARE WASTED" % state.day_number
	else:
		_feedback_label.text = _feedback_for(events)


func _set_circuit_interaction(enabled: bool) -> void:
	for circuit_button: Button in _circuit_buttons:
		var has_egg := false
		for slot_index: int in circuit_button.slot_indices:
			has_egg = has_egg or not _belt_slots[slot_index].current_egg().is_empty()
		circuit_button.set_available(enabled and has_egg)


func _on_presentation_event(event_type: String) -> void:
	presentation_event.emit(event_type)


func _event_of_type(events: Array[Dictionary], event_type: String) -> Dictionary:
	for event: Dictionary in events:
		if event.type == event_type:
			return event
	return {}


func _feedback_for(events: Array[Dictionary]) -> String:
	for event: Dictionary in events:
		if event.type == "day_ended":
			return "The final bell rings. Every unhatched egg is discarded."
	var hatch_events := events.filter(
		func(event: Dictionary) -> bool: return event.type == "egg_hatched"
	)
	if hatch_events.size() > 1:
		var points_awarded := 0
		for event: Dictionary in hatch_events:
			points_awarded += event.points_awarded
		return "Crack! %d eggs hatched for %d points." % [hatch_events.size(), points_awarded]
	for event: Dictionary in events:
		if event.type == "egg_hatched":
			return "Crack! A %s hatched for %d %s." % [
				String(event.get("kind", "egg")).capitalize(),
				event.points_awarded,
				"point" if event.points_awarded == 1 else "points",
			]
	for event: Dictionary in events:
		if event.type == "eggs_swapped":
			return "Scuttle! The Plover swapped one slot toward the pipe."
	for event: Dictionary in events:
		if event.type == "egg_discarded":
			return "An egg fell from the belt. The spoon cannot save them all."
	for event: Dictionary in events:
		if event.type == "egg_damaged" and event.get("damage_amount", 1) > 1:
			return "Spark crack! Pink dealt 2 damage to the Spoonbill."
	for event: Dictionary in events:
		if event.type == "egg_damaged" and event.get("cause", "") == "cuckoo_echo":
			return "Echo crack! The Cuckoo copied another egg's damage."
	for event: Dictionary in events:
		if event.type == "egg_damaged":
			return "Thwack! The circuit landed. The belt moved."
	return "Choose an egg on the belt."
