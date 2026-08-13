extends Control

signal playback_started
signal presentation_event(event_type: String)
signal playback_completed

const ChickenDaySession = preload("res://src/game/chicken_day_session.gd")

@onready var _score_label: Label = %Score
@onready var _thwacks_label: Label = %Thwacks
@onready var _feedback_label: Label = %Feedback
@onready var _result_overlay: Control = %ResultOverlay
@onready var _result_label: Label = %Result
@onready var _result_score_label: Label = %ResultScore
@onready var _restart_button: Button = %Restart
@onready var _mute_button: CheckButton = %Mute
@onready var _reduced_motion_button: CheckButton = %ReducedMotion
@onready var _belt: Control = %Belt
@onready var _drop_label: Label = %Drop
@onready var _echo_trace: Control = %EchoTrace
@onready var _presenter: Node = %Presentation
@onready var _belt_slots: Array[Button] = [%Slot1, %Slot2, %Slot3, %Slot4, %Slot5]
@onready var _pipe_slots: Array[Button] = [%Next1, %Next2, %Next3]
@onready var _keys: Array[Button] = [%Key1, %Key2, %Key3, %Key4, %Key5]
@onready var _hammers: Array[Control] = [%Hammer1, %Hammer2, %Hammer3, %Hammer4, %Hammer5]

var _session = ChickenDaySession.new()
var _input_locked := false
var _request_generation := 0


func _ready() -> void:
	for key: Button in _keys:
		key.connect("thwack_requested", _on_thwack_requested)
	_restart_button.pressed.connect(_on_restart_pressed)
	_mute_button.toggled.connect(set_muted)
	_reduced_motion_button.toggled.connect(set_reduced_motion)
	_presenter.event_presented.connect(_on_presentation_event)
	_presenter.configure(
		_belt_slots,
		_pipe_slots,
		_keys,
		_hammers,
		_echo_trace,
		_score_label,
		_thwacks_label,
		_drop_label
	)
	_render([], true)
	_keys[0].grab_focus()


func _on_thwack_requested(slot_index: int) -> void:
	if _input_locked:
		return

	var events: Array[Dictionary] = _session.submit_thwack(slot_index)
	if events.is_empty() or events[0].type == "thwack_rejected":
		return

	_input_locked = true
	_request_generation += 1
	var request_generation := _request_generation
	_set_slot_interaction(false)
	playback_started.emit()
	var completed: bool = await _presenter.play_events(events)
	if not completed or request_generation != _request_generation:
		return

	_input_locked = false
	_render(events)
	playback_completed.emit()


func _on_restart_pressed() -> void:
	restart_day()


func restart_day() -> void:
	_request_generation += 1
	_presenter.cancel_playback()
	_input_locked = false
	_session.restart()
	_render([], true)
	_keys[0].grab_focus()


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

	for slot_index in range(_belt_slots.size()):
		_belt_slots[slot_index].render_egg(
			state.slots[slot_index],
			false,
			false
		)
		_keys[slot_index].set_available(
			not state.slots[slot_index].is_empty() and not state.ended and not _input_locked
		)
	for preview_index in range(_pipe_slots.size()):
		var egg: Dictionary = state.pipe[preview_index] if preview_index < state.pipe.size() else {}
		_pipe_slots[preview_index].render_egg(egg, false, true)

	_result_overlay.visible = state.ended
	if state.ended:
		_result_label.text = "DAY COMPLETE" if state.succeeded else "DAY FAILED"
		_result_score_label.text = "%d / %d POINTS" % [state.score, state.target_score]
		_restart_button.grab_focus.call_deferred()

	if fresh_day:
		_feedback_label.text = "Ten points. Cuckoos echo. Plovers retreat when struck."
	else:
		_feedback_label.text = _feedback_for(events)


func _set_slot_interaction(enabled: bool) -> void:
	for slot_index in range(_keys.size()):
		_keys[slot_index].set_available(enabled and not _belt_slots[slot_index].current_egg().is_empty())


func _on_presentation_event(event_type: String) -> void:
	presentation_event.emit(event_type)


func _feedback_for(events: Array[Dictionary]) -> String:
	for event: Dictionary in events:
		if event.type == "day_ended":
			return "The final bell rings. Every unhatched egg is discarded."
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
		if event.type == "egg_damaged" and event.get("cause", "") == "cuckoo_echo":
			return "Echo crack! The Cuckoo copied another egg's damage."
	for event: Dictionary in events:
		if event.type == "egg_damaged":
			return "Thwack! That egg has %d toughness left. The belt moved." % event.remaining_toughness
	return "Choose an egg on the belt."
