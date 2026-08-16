extends Control

signal playback_started
signal presentation_event(event_type: String)
signal playback_completed
signal production_loading_started(producer_count: int, egg_count: int)
signal production_loading_completed
signal workshop_transition_settled(token: int, completed: bool)

const ChickenDaySession = preload("res://src/game/chicken_day_session.gd")
const ChickenDay = preload("res://src/domain/chicken_day.gd")
const MotionTokens = preload("res://src/presentation/motion_tokens.gd")
const FlockBirdButtonScene = preload("res://src/ui/flock_bird_button.tscn")

const SETTINGS_MUTE_AUDIO := 0
const SETTINGS_REDUCED_MOTION := 1

@onready var _score_label: Label = %Score
@onready var _thwacks_label: Label = %Thwacks
@onready var _result_overlay: Control = %ResultOverlay
@onready var _result_card: PanelContainer = $ResultOverlay/Card
@onready var _result_label: Label = %Result
@onready var _result_score_label: Label = %ResultScore
@onready var _cash_payout_label: Label = %CashPayout
@onready var _result_summary_label: Label = %Summary
@onready var _flock_summary_label: Label = %FlockSummary
@onready var _restart_button: Button = %Restart
@onready var _result_reveal_controls: Array[Control] = [
	%Result, %ResultScore, %CashPayout, %FlockSummary, %Summary, %Restart,
]
@onready var _bird_offer_overlay: Control = %BirdOfferOverlay
@onready var _bird_offer_summary_label: Label = %BirdOfferSummary
@onready var _bird_offer_status_label: Label = %BirdOfferStatus
@onready var _workshop_overlay: Control = %WorkshopOverlay
@onready var _workshop_card: PanelContainer = $WorkshopOverlay/Card
@onready var _workshop_balance_label: Label = %WorkshopBalance
@onready var _workshop_summary_label: Label = %WorkshopSummary
@onready var _workshop_status_label: Label = %WorkshopStatus
@onready var _flock_grid: GridContainer = %FlockGrid
@onready var _continue_workshop_button: Button = %ContinueWorkshop
@onready var _settings_menu: MenuButton = %Settings
@onready var _belt: Control = %Belt
@onready var _machine_stage: Control = $Content/Stage/Workshop
@onready var _workshop_ambience: Control = %Ambience
@onready var _bin_label: Label = %Bin
@onready var _hopper_inspect_button: Button = %HopperInspect
@onready var _bin_inspect_button: Button = %BinInspect
@onready var _container_inspector = %ContainerInspector
@onready var _echo_trace: Control = %EchoTrace
@onready var _hatch_payoff: Control = %HatchPayoff
@onready var _presenter: Node = %Presentation
@onready var _ui_feedback: Node = %UIFeedback
@onready var _production_loader: Control = %ProductionLoader
@onready var _belt_slots: Array[Button] = [
	%Slot1, %Slot2, %Slot3, %Slot4, %Slot5,
]
@onready var _pipe_slots: Array[Button] = [%Next1, %Next2, %Next3]
@onready var _circuit_buttons: Array[Button] = [
	%RedCircuit, %BlueCircuit, %PinkCircuit,
]
@onready var _hammers: Array[Control] = [%Hammer1, %Hammer2, %Hammer3, %Hammer4, %Hammer5]
@onready var _producer_choice_buttons: Array[Button] = [%Choice1, %Choice2, %Choice3]

var _session = ChickenDaySession.new()
var _input_locked := false
var _request_generation := 0
var _dev_day_number := 0
var _workshop_transition: Tween
var _workshop_transition_serial := 0
var _active_workshop_transition_token := 0
var _result_transition: Tween


func _ready() -> void:
	_configure_settings_menu()
	for circuit_button: Button in _circuit_buttons:
		circuit_button.connect("circuit_requested", _on_circuit_requested)
		circuit_button.connect("preview_changed", _on_circuit_preview_changed)
	for choice_index in range(_producer_choice_buttons.size()):
		_producer_choice_buttons[choice_index].pressed.connect(
			_on_producer_choice_pressed.bind(choice_index)
		)
	var microinteraction_controls: Array = []
	microinteraction_controls.append_array(_producer_choice_buttons)
	microinteraction_controls.append(_continue_workshop_button)
	microinteraction_controls.append(_restart_button)
	microinteraction_controls.append(_settings_menu)
	microinteraction_controls.append(_hopper_inspect_button)
	microinteraction_controls.append(_bin_inspect_button)
	_ui_feedback.configure(microinteraction_controls)
	_restart_button.pressed.connect(_on_restart_pressed)
	_continue_workshop_button.pressed.connect(_on_leave_shop_pressed)
	_hopper_inspect_button.pressed.connect(_on_hopper_inspect_pressed)
	_bin_inspect_button.pressed.connect(_on_bin_inspect_pressed)
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
		_bin_label
	)
	var requested_dev_day := _requested_dev_day()
	if requested_dev_day > 0 and OS.is_debug_build():
		_start_dev_day(requested_dev_day)
	else:
		_render([], true)
		_circuit_buttons[0].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("dev_start_day_3", false):
		start_dev_day(3)
		get_viewport().set_input_as_handled()


func _on_circuit_requested(circuit_id: String) -> void:
	if _input_locked:
		return
	_container_inspector.dismiss()

	var events: Array[Dictionary] = _session.submit_circuit(circuit_id)
	if events.is_empty() or events[0].type == "thwack_rejected":
		return

	_input_locked = true
	_request_generation += 1
	var request_generation := _request_generation
	_set_circuit_interaction(false)
	_set_container_inspection_enabled(false)
	playback_started.emit()
	var completed: bool = await _presenter.play_events(events)
	if not completed or request_generation != _request_generation:
		return

	_input_locked = false
	_render(events)
	playback_completed.emit()


func _on_hopper_inspect_pressed() -> void:
	if _input_locked:
		return
	var state: Dictionary = _session.state()
	if String(state.phase) != "day":
		return
	_container_inspector.show_contents(
		"hopper", state.hopper_contents, _hopper_inspect_button
	)
	_ui_feedback.panel_opened()


func _on_bin_inspect_pressed() -> void:
	if _input_locked:
		return
	var state: Dictionary = _session.state()
	if String(state.phase) != "day":
		return
	_container_inspector.show_contents("bin", state.bin, _bin_inspect_button)
	_ui_feedback.panel_opened()


func _on_restart_pressed() -> void:
	if String(_session.state().phase) == "bird_offer":
		_dismiss_success_result()
		return
	restart_day()


func _on_producer_choice_pressed(choice_index: int) -> void:
	if _input_locked:
		return
	var state: Dictionary = _session.state()
	if state.phase != "bird_offer" or choice_index >= state.bird_offer.size():
		return
	_render(_session.claim_bird_offer(choice_index))


func _on_flock_bird_pressed(producer_index: int) -> void:
	if _input_locked:
		return
	_render(_session.remove_bird(producer_index))


func _on_leave_shop_pressed() -> void:
	if _input_locked:
		return
	var events: Array[Dictionary] = _session.leave_shop()
	if events.is_empty() or events[0].type == "shop_leave_rejected":
		return
	var day_started_event := _event_of_type(events, "day_started")
	if day_started_event.is_empty():
		return

	_input_locked = true
	_request_generation += 1
	var request_generation := _request_generation
	_set_circuit_interaction(false)
	var store_closed := await _play_workshop_exit()
	if not store_closed or request_generation != _request_generation:
		return
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
	_focus_first_available_lever()
	production_loading_completed.emit()


func restart_day() -> void:
	_request_generation += 1
	_presenter.cancel_playback()
	_production_loader.cancel()
	_cancel_workshop_motion()
	_cancel_result_motion()
	_ui_feedback.cancel_all()
	_container_inspector.dismiss()
	_input_locked = false
	_session.restart()
	_render([], true)
	_circuit_buttons[0].grab_focus()


func replace_session(session) -> void:
	_replace_session(session, 0)


func start_dev_day(day_number := 3) -> bool:
	if not OS.is_debug_build() or day_number < 1:
		return false
	_start_dev_day(day_number)
	return true


func is_dev_mode() -> bool:
	return _dev_day_number > 0


func dev_day_number() -> int:
	return _dev_day_number


func _start_dev_day(day_number: int) -> void:
	var session = ChickenDaySession.new(
		ChickenDaySession.DEFAULT_DAY_SEED,
		null,
		null,
		day_number
	)
	_replace_session(session, day_number)


func _replace_session(session, dev_day_number: int) -> void:
	_request_generation += 1
	_presenter.cancel_playback()
	_production_loader.cancel()
	_cancel_workshop_motion()
	_cancel_result_motion()
	_ui_feedback.cancel_all()
	_container_inspector.dismiss()
	_input_locked = false
	_session = session
	_dev_day_number = dev_day_number
	_render([], true)
	_focus_first_available_lever()


func set_muted(muted: bool) -> void:
	_presenter.set_muted(muted)
	_ui_feedback.set_muted(muted)
	_set_settings_item_checked(SETTINGS_MUTE_AUDIO, muted)


func is_muted() -> bool:
	return _presenter.is_muted()


func set_reduced_motion(reduced: bool) -> void:
	_presenter.set_reduced_motion(reduced)
	_ui_feedback.set_reduced_motion(reduced)
	_workshop_ambience.set_reduced_motion(reduced)
	_set_settings_item_checked(SETTINGS_REDUCED_MOTION, reduced)


func is_reduced_motion() -> bool:
	return _presenter.is_reduced_motion()


func is_input_locked() -> bool:
	return _input_locked


func is_workshop_transition_active() -> bool:
	return _workshop_transition != null and _workshop_transition.is_running()


func is_result_transition_active() -> bool:
	return _result_transition != null and _result_transition.is_running()


func _configure_settings_menu() -> void:
	var popup := _settings_menu.get_popup()
	popup.add_check_item("MUTE AUDIO", SETTINGS_MUTE_AUDIO)
	popup.add_check_item("REDUCE MOTION", SETTINGS_REDUCED_MOTION)
	popup.id_pressed.connect(_on_settings_item_pressed)


func _on_settings_item_pressed(item_id: int) -> void:
	match item_id:
		SETTINGS_MUTE_AUDIO:
			set_muted(not is_muted())
		SETTINGS_REDUCED_MOTION:
			set_reduced_motion(not is_reduced_motion())


func _set_settings_item_checked(item_id: int, checked: bool) -> void:
	var popup := _settings_menu.get_popup()
	var item_index := popup.get_item_index(item_id)
	if item_index >= 0:
		popup.set_item_checked(item_index, checked)


func _render(events: Array[Dictionary], _fresh_day := false) -> void:
	var state: Dictionary = _session.state()
	_configure_machine(state.machine_slot_count, state.machine_circuits)
	_score_label.text = "SCORE %d / %d" % [state.score, state.target_score]
	_thwacks_label.text = "THWACKS %d" % state.remaining_thwacks
	_bin_label.text = "BIN %d" % state.bin_egg_count
	_hopper_inspect_button.text = "HOPPER %d" % state.hopper_egg_count
	_hopper_inspect_button.accessibility_name = "Inspect hopper: %d %s remaining" % [
		state.hopper_egg_count,
		"egg" if int(state.hopper_egg_count) == 1 else "eggs",
	]
	_bin_inspect_button.accessibility_name = "Inspect bin: %d %s stored" % [
		state.bin_egg_count,
		"egg" if int(state.bin_egg_count) == 1 else "eggs",
	]
	_set_container_inspection_enabled(String(state.phase) == "day" and not _input_locked)

	for slot_index in range(_belt_slots.size()):
		var slot_egg: Dictionary = state.slots[slot_index] if slot_index < state.slots.size() else {}
		_belt_slots[slot_index].render_egg(
			slot_egg,
			false,
			false
		)
	for preview_index in range(_pipe_slots.size()):
		var egg: Dictionary = state.pipe[preview_index] if preview_index < state.pipe.size() else {}
		_pipe_slots[preview_index].render_egg(egg, false, true)

	for circuit_button: Button in _circuit_buttons:
		if not circuit_button.visible:
			circuit_button.set_available(false)
			continue
		var descriptions: Array[String] = []
		for slot_index: int in circuit_button.slot_indices:
			var egg: Dictionary = state.slots[slot_index] if slot_index < state.slots.size() else {}
			descriptions.append("empty" if egg.is_empty() else _belt_slots[slot_index].egg_description())
		circuit_button.set_target_descriptions(descriptions)
		circuit_button.set_available(state.phase == "day" and not _input_locked)

	var bird_offer_visible: bool = String(state.phase) == "bird_offer"
	var shop_visible: bool = String(state.phase) == "shop"
	var successful_result: bool = bird_offer_visible and events.any(
		func(event: Dictionary) -> bool: return event.type == "cash_awarded"
	)
	var failed_result: bool = String(state.phase) == "failed"
	if bird_offer_visible:
		_render_bird_offer(state)
	if shop_visible:
		_render_shop(state, events)
	if successful_result or failed_result:
		_hide_bird_offer_immediately()
		_hide_workshop_immediately()
		_render_result(state, successful_result)
		_show_result()
		_restart_button.grab_focus.call_deferred()
	else:
		_hide_result_immediately()
		if bird_offer_visible:
			_hide_workshop_immediately()
			_show_bird_offer()
		elif shop_visible:
			_hide_bird_offer_immediately()
			_show_workshop()
			_focus_first_shop_action.call_deferred()
		else:
			_hide_bird_offer_immediately()
			_hide_workshop_immediately()

	_present_resolved_ui_feedback(events)


func _render_result(state: Dictionary, successful: bool) -> void:
	var producer_count := int(state.producers.size())
	var egg_count := int(state.daily_egg_count)
	_flock_summary_label.text = "FLOCK %d %s  •  DAILY OUTPUT %d %s" % [
		producer_count,
		"PRODUCER" if producer_count == 1 else "PRODUCERS",
		egg_count,
		"EGG" if egg_count == 1 else "EGGS",
	]
	if successful:
		_result_label.text = "DAY %d COMPLETE" % state.day_number
		_result_label.add_theme_color_override("font_color", Color("ffb934"))
		_result_score_label.text = "TARGET MET  •  %d / %d POINTS" % [
			state.score, state.target_score,
		]
		_result_score_label.add_theme_color_override("font_color", Color("8dfff0"))
		_cash_payout_label.text = "+£%d FROM UNUSED THWACKS  •  BALANCE £%d" % [
			state.last_cash_awarded, state.cash,
		]
		_result_summary_label.text = "CHOOSE ONE FREE BIRD  •  THEN REVIEW YOUR FLOCK"
		_restart_button.text = "VIEW BIRD OFFER"
		return
	_result_label.text = "DAY FAILED"
	_result_label.add_theme_color_override("font_color", Color("ff8a3d"))
	_result_score_label.text = "TARGET MISSED  •  %d / %d POINTS" % [
		state.score, state.target_score,
	]
	_result_score_label.add_theme_color_override("font_color", Color("ffb76b"))
	_cash_payout_label.text = "NO CASH EARNED  •  BALANCE £%d" % state.cash
	_result_summary_label.text = "NO SHOP OPENS  •  RETRY WITH THE SAME FLOCK AND SHUFFLE"
	_restart_button.text = "RETRY DAY %d" % state.day_number


func _show_result() -> void:
	if _result_overlay.visible:
		return
	_cancel_result_motion()
	_result_overlay.visible = true
	_result_card.pivot_offset = _result_card.size * 0.5
	if is_reduced_motion():
		_reset_result_transform()
		_ui_feedback.panel_opened()
		return
	_result_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_result_card.scale = Vector2(0.98, 0.98)
	for control: Control in _result_reveal_controls:
		control.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_result_transition = create_tween().set_parallel(true)
	_result_transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_result_transition.tween_property(
		_result_overlay, "modulate:a", 1.0, MotionTokens.SETTLE
	)
	_result_transition.tween_property(
		_result_card, "scale", Vector2.ONE, MotionTokens.REVEAL
	)
	for control_index in range(_result_reveal_controls.size()):
		_result_transition.tween_property(
			_result_reveal_controls[control_index],
			"modulate:a",
			1.0,
			MotionTokens.SETTLE
		).set_delay(0.04 + MotionTokens.STAGGER * control_index)
	_result_transition.finished.connect(_finish_result_transition)
	_ui_feedback.panel_opened()


func _finish_result_transition() -> void:
	_result_transition = null
	_reset_result_transform()


func _cancel_result_motion() -> void:
	if _result_transition != null:
		_result_transition.kill()
		_result_transition = null
	_reset_result_transform()


func _hide_result_immediately() -> void:
	_cancel_result_motion()
	_result_overlay.visible = false


func _reset_result_transform() -> void:
	_result_overlay.modulate = Color.WHITE
	_result_card.scale = Vector2.ONE
	for control: Control in _result_reveal_controls:
		control.modulate = Color.WHITE


func _dismiss_success_result() -> void:
	if not _result_overlay.visible:
		return
	_hide_result_immediately()
	_show_bird_offer()
	_focus_first_bird_offer.call_deferred()


func _render_bird_offer(state: Dictionary) -> void:
	_bird_offer_summary_label.text = "DAY %d COMPLETE  •  DAY %d TARGET %d" % [
		state.day_number,
		state.day_number + 1,
		state.next_day_target_score,
	]
	for choice_index in range(_producer_choice_buttons.size()):
		var choice_button: Button = _producer_choice_buttons[choice_index]
		choice_button.visible = choice_index < state.bird_offer.size()
		if not choice_button.visible:
			continue
		choice_button.render_choice(state.bird_offer[choice_index])
		choice_button.disabled = false
	_bird_offer_status_label.text = "PICK ONE BIRD  •  THE FLOCK SHOP OPENS NEXT"


func _render_shop(state: Dictionary, events: Array[Dictionary]) -> void:
	_workshop_balance_label.text = "BALANCE £%d" % state.cash
	_workshop_summary_label.text = (
		"DAY %d COMPLETE  •  £%d BANKED\nDAY %d TARGET %d  •  FLOCK %d"
		% [
			state.day_number,
			state.last_cash_awarded,
			state.day_number + 1,
			state.next_day_target_score,
			state.producers.size(),
		]
	)

	for existing: Node in _flock_grid.get_children():
		_ui_feedback.unconfigure([existing])
		_flock_grid.remove_child(existing)
		existing.queue_free()
	var removal_price := int(state.shop_stock.removal.price)
	for producer_index in range(state.flock_overview.size()):
		var bird_button: Button = FlockBirdButtonScene.instantiate()
		_flock_grid.add_child(bird_button)
		bird_button.render_bird(
			state.flock_overview[producer_index],
			removal_price,
			(
				not state.removal_used_tonight
				and state.producers.size() > 1
				and state.cash >= removal_price
			),
			state.removal_used_tonight
		)
		bird_button.pressed.connect(_on_flock_bird_pressed.bind(producer_index))
		_ui_feedback.configure([bird_button])

	_continue_workshop_button.text = "LEAVE SHOP & START DAY %d" % (state.day_number + 1)
	_continue_workshop_button.disabled = false
	_workshop_status_label.text = _shop_status(events, state.removal_used_tonight)
	var rejected := not events.is_empty() and String(events[0].type) == "shop_action_rejected"
	_workshop_status_label.add_theme_color_override(
		"font_color", Color("ff9a60") if rejected else Color("91fff2")
	)


func _show_bird_offer() -> void:
	if _bird_offer_overlay.visible:
		return
	_bird_offer_overlay.visible = true
	_ui_feedback.panel_opened()


func _hide_bird_offer_immediately() -> void:
	_bird_offer_overlay.visible = false


func _show_workshop() -> void:
	if _workshop_overlay.visible:
		return
	_cancel_workshop_transition()
	_workshop_overlay.visible = true
	_workshop_card.pivot_offset = _workshop_card.size * 0.5
	if is_reduced_motion():
		_reset_workshop_transform()
		_ui_feedback.panel_opened()
		return
	_workshop_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_workshop_card.scale = Vector2(0.985, 0.985)
	var token := _begin_workshop_transition()
	_workshop_transition = create_tween().set_parallel(true)
	_workshop_transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_workshop_transition.tween_property(
		_workshop_overlay, "modulate:a", 1.0, MotionTokens.SETTLE
	)
	_workshop_transition.tween_property(
		_workshop_card, "scale", Vector2.ONE, MotionTokens.REVEAL
	)
	_workshop_transition.finished.connect(_finish_workshop_transition.bind(token))
	_ui_feedback.panel_opened()


func _play_workshop_exit() -> bool:
	if not _workshop_overlay.visible:
		return true
	_cancel_workshop_transition()
	if is_reduced_motion():
		_hide_workshop_immediately()
		return true
	var token := _begin_workshop_transition()
	_workshop_transition = create_tween().set_parallel(true)
	_workshop_transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_workshop_transition.tween_property(
		_workshop_overlay, "modulate:a", 0.0, MotionTokens.SETTLE
	)
	_workshop_transition.tween_property(
		_workshop_card, "scale", Vector2(0.985, 0.985), MotionTokens.SETTLE
	)
	_workshop_transition.finished.connect(_finish_workshop_transition.bind(token))
	while true:
		var result: Array = await workshop_transition_settled
		if int(result[0]) != token:
			continue
		if bool(result[1]):
			_workshop_overlay.visible = false
			_reset_workshop_transform()
		return bool(result[1])
	return false


func _begin_workshop_transition() -> int:
	_workshop_transition_serial += 1
	_active_workshop_transition_token = _workshop_transition_serial
	return _active_workshop_transition_token


func _finish_workshop_transition(token: int) -> void:
	if token != _active_workshop_transition_token:
		return
	_workshop_transition = null
	_active_workshop_transition_token = 0
	_reset_workshop_transform()
	workshop_transition_settled.emit(token, true)


func _cancel_workshop_transition() -> void:
	if _workshop_transition == null:
		return
	var cancelled_token := _active_workshop_transition_token
	_workshop_transition.kill()
	_workshop_transition = null
	_active_workshop_transition_token = 0
	_reset_workshop_transform()
	workshop_transition_settled.emit(cancelled_token, false)


func _cancel_workshop_motion() -> void:
	_cancel_workshop_transition()
	_workshop_status_label.modulate = Color.WHITE
	_workshop_status_label.scale = Vector2.ONE


func _hide_workshop_immediately() -> void:
	_cancel_workshop_transition()
	_workshop_overlay.visible = false
	_reset_workshop_transform()


func _reset_workshop_transform() -> void:
	_workshop_overlay.modulate = Color.WHITE
	_workshop_card.scale = Vector2.ONE


func _present_resolved_ui_feedback(events: Array[Dictionary]) -> void:
	var thwacks_presented := false
	var hopper_presented := false
	var cash_presented := false
	for event: Dictionary in events:
		match String(event.type):
			"thwack_spent":
				if not thwacks_presented:
					_ui_feedback.present_value(_thwacks_label, "thwacks", Color("66f5ed"))
					thwacks_presented = true
			"conveyor_advanced", "bin_reshuffled", "egg_entered":
				if not hopper_presented:
					_ui_feedback.present_value(_hopper_inspect_button, "hopper", Color("66f5ed"))
					hopper_presented = true
			"egg_binned":
				_ui_feedback.present_value(_bin_label, "bin", Color("ffbf42"))
			"cash_awarded":
				if not cash_presented:
					_ui_feedback.present_value(_cash_payout_label, "cash", Color("ffbf42"))
					cash_presented = true
			"bird_removed":
				if not cash_presented:
					_ui_feedback.present_value(
						_workshop_balance_label, "balance", Color("ffbf42")
					)
					cash_presented = true
				_ui_feedback.confirm(_workshop_status_label)
			"bird_offer_claimed":
				_ui_feedback.confirm(_workshop_status_label)
			"shop_action_rejected":
				_ui_feedback.reject(_workshop_status_label)


func _tier_name(tier: int) -> String:
	match tier:
		0:
			return "STANDARD"
		1:
			return "PRIZE"
		2:
			return "CHAMPION"
	return "TIER %d" % tier


func _shop_status(events: Array[Dictionary], removal_used: bool) -> String:
	if not events.is_empty():
		var event: Dictionary = events[0]
		match String(event.type):
			"bird_offer_claimed":
				return "%s %s JOINED YOUR FLOCK  •  NO CHARGE" % [
					_tier_name(int(event.producer.tier)),
					String(event.producer.kind).to_upper(),
				]
			"bird_removed":
				return "%s %s REMOVED  •  £%d REMAINING  •  NIGHTLY REMOVAL USED" % [
					_tier_name(int(event.producer.tier)),
					String(event.producer.kind).to_upper(),
					int(event.cash_total),
				]
			"shop_action_rejected":
				return "ACTION DECLINED  •  %s" % String(event.reason).replace("_", " ").to_upper()
	if removal_used:
		return "NIGHTLY REMOVAL USED  •  KEEP THE REST OF THE FLOCK"
	return "REMOVE ONE BIRD FOR £3  •  OR KEEP THE COMPLETE FLOCK"


func _focus_first_bird_offer() -> void:
	for choice_button: Button in _producer_choice_buttons:
		if choice_button.visible and not choice_button.disabled:
			choice_button.grab_focus()
			return


func _focus_first_shop_action() -> void:
	for bird_button: Button in _flock_grid.get_children():
		if not bird_button.disabled:
			bird_button.grab_focus()
			return
	_continue_workshop_button.grab_focus()


func _set_circuit_interaction(enabled: bool) -> void:
	for circuit_button: Button in _circuit_buttons:
		if not circuit_button.visible:
			circuit_button.set_available(false)
			continue
		circuit_button.set_available(enabled)


func _set_container_inspection_enabled(enabled: bool) -> void:
	_hopper_inspect_button.disabled = not enabled
	_bin_inspect_button.disabled = not enabled


func _focus_first_available_lever() -> void:
	for circuit_button: Button in _circuit_buttons:
		if circuit_button.visible and not circuit_button.disabled:
			circuit_button.grab_focus()
			return


func _requested_dev_day() -> int:
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--dev-day="):
			continue
		return maxi(argument.trim_prefix("--dev-day=").to_int(), 0)
	return 0


func _configure_machine(slot_count: int, circuits: Array) -> void:
	assert(slot_count == ChickenDay.SLOT_COUNT, "The game uses one five-slot track.")
	_machine_stage.set_slot_count(slot_count)
	var slot_circuit_ids: Array[String] = []
	var slot_circuit_colors: Array[Color] = []
	slot_circuit_ids.resize(slot_count)
	slot_circuit_colors.resize(slot_count)
	slot_circuit_ids.fill("")
	slot_circuit_colors.fill(Color("4b4d4f"))
	for circuit: Dictionary in circuits:
		var appearance := _circuit_appearance(String(circuit.id))
		for slot_index: int in circuit.slot_indices:
			slot_circuit_ids[slot_index] = String(circuit.id)
			slot_circuit_colors[slot_index] = appearance.color
	_machine_stage.set_belt_section_appearances(slot_circuit_ids, slot_circuit_colors)
	for slot_index in range(_belt_slots.size()):
		_belt_slots[slot_index].visible = true
		_belt_slots[slot_index].scale = Vector2.ONE
		# Eggs sit directly on the moving belt; individual cups make the track read
		# as five separate machines instead of one flow.
		_belt_slots[slot_index].set_bare_belt_mode(true)
		_belt_slots[slot_index].position = Vector2(200.0 + 190.0 * slot_index, 170.0)

	for hammer_index in range(_hammers.size()):
		_hammers[hammer_index].visible = true
		_hammers[hammer_index].scale = Vector2.ONE
		_hammers[hammer_index].set_bowl_scale(1.0)
		_hammers[hammer_index].position = Vector2(200.0 + 190.0 * hammer_index, 20.0)
		_hammers[hammer_index].size = Vector2(185.0, 250.0)
		var slot: Control = _belt_slots[hammer_index]
		var contact_global: Vector2 = slot.impact_global_position()
		var contact_local: Vector2 = (
			_hammers[hammer_index].get_global_transform().affine_inverse()
			* contact_global
		)
		_hammers[hammer_index].configure_wall_spoon(contact_local)
	for circuit_button: Button in _circuit_buttons:
		circuit_button.visible = false
		circuit_button.set_available(false)
		circuit_button.slot_indices.clear()
	for circuit: Dictionary in circuits:
		var circuit_button: Button = _circuit_button(String(circuit.id))
		circuit_button.visible = true
		circuit_button.slot_indices.assign(circuit.slot_indices)
		circuit_button.queue_redraw()
		var appearance := _circuit_appearance(String(circuit.id))
		for slot_index: int in circuit.slot_indices:
			_belt_slots[slot_index].set_circuit_appearance(
				String(circuit.id),
				appearance.color,
				appearance.symbol
			)
	for hammer: Control in _hammers:
		hammer.set_neutral_appearance()
	_presenter.set_slot_hammer_indices([0, 1, 2, 3, 4])
	for button_index in range(_circuit_buttons.size()):
		_circuit_buttons[button_index].position = Vector2(210.0 + 320.0 * button_index, 416.0)
		_circuit_buttons[button_index].size = Vector2(280.0, 112.0)
	_bin_label.position = Vector2(1130.0, 326.0)


func _circuit_appearance(circuit_id: String) -> Dictionary:
	var appearances := {
		"red": {"color": Color("c43b36"), "symbol": "diamond"},
		"blue": {"color": Color("287cbd"), "symbol": "circle"},
		"pink": {"color": Color("cf4f8b"), "symbol": "spark"},
	}
	return appearances[circuit_id]


func _circuit_button(circuit_id: String) -> Button:
	for circuit_button: Button in _circuit_buttons:
		if circuit_button.circuit_id == circuit_id:
			return circuit_button
	return null


func _on_circuit_preview_changed(circuit_id: String, active: bool) -> void:
	if active:
		_machine_stage.set_highlighted_circuit(circuit_id)
		return
	if _machine_stage.highlighted_circuit_id() != circuit_id:
		return
	for circuit_button: Button in _circuit_buttons:
		if circuit_button.visible and circuit_button.is_preview_active():
			_machine_stage.set_highlighted_circuit(circuit_button.circuit_id)
			return
	_machine_stage.set_highlighted_circuit("")


func _on_presentation_event(event_type: String) -> void:
	presentation_event.emit(event_type)


func _event_of_type(events: Array[Dictionary], event_type: String) -> Dictionary:
	for event: Dictionary in events:
		if event.type == event_type:
			return event
	return {}
