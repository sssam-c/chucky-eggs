extends Control

signal playback_started
signal presentation_event(event_type: String)
signal playback_completed
signal production_loading_started(producer_count: int, egg_count: int)
signal production_loading_completed

const ChickenDaySession = preload("res://src/game/chicken_day_session.gd")
const ChickenDay = preload("res://src/domain/chicken_day.gd")

@onready var _score_label: Label = %Score
@onready var _cash_label: Label = %Cash
@onready var _thwacks_label: Label = %Thwacks
@onready var _feedback_label: Label = %Feedback
@onready var _result_overlay: Control = %ResultOverlay
@onready var _result_card: PanelContainer = $ResultOverlay/Card
@onready var _result_label: Label = %Result
@onready var _result_score_label: Label = %ResultScore
@onready var _cash_payout_label: Label = %CashPayout
@onready var _result_summary_label: Label = %Summary
@onready var _flock_summary_label: Label = %FlockSummary
@onready var _restart_button: Button = %Restart
@onready var _workshop_overlay: Control = %WorkshopOverlay
@onready var _workshop_balance_label: Label = %WorkshopBalance
@onready var _workshop_summary_label: Label = %WorkshopSummary
@onready var _workshop_status_label: Label = %WorkshopStatus
@onready var _merge_summary_label: Label = %MergeSummary
@onready var _merge_buttons: Dictionary = {
	"chicken": %MergeChicken,
	"cuckoo": %MergeCuckoo,
	"plover": %MergePlover,
	"spoonbill": %MergeSpoonbill,
}
@onready var _extra_thwack_button: Button = %ExtraThwack
@onready var _retirement_buttons: Dictionary = {
	"chicken": %RetireChicken,
	"cuckoo": %RetireCuckoo,
	"plover": %RetirePlover,
	"spoonbill": %RetireSpoonbill,
}
@onready var _continue_workshop_button: Button = %ContinueWorkshop
@onready var _mute_button: CheckButton = %Mute
@onready var _reduced_motion_button: CheckButton = %ReducedMotion
@onready var _belt: Control = %Belt
@onready var _machine_stage: Control = $Content/Stage/Workshop
@onready var _drop_label: Label = %Drop
@onready var _echo_trace: Control = %EchoTrace
@onready var _hatch_payoff: Control = %HatchPayoff
@onready var _presenter: Node = %Presentation
@onready var _production_loader: Control = %ProductionLoader
@onready var _hopper_count_label: Label = %HopperCount
@onready var _belt_slots: Array[Button] = [
	%Slot1, %Slot2, %Slot3, %Slot4, %Slot5, %Slot6,
	%Slot7, %Slot8, %Slot9, %Slot10,
]
@onready var _pipe_slots: Array[Button] = [%Next1, %Next2, %Next3]
@onready var _circuit_buttons: Array[Button] = [
	%RedCircuit, %BlueCircuit, %GreenCircuit, %PurpleCircuit, %PinkCircuit,
]
@onready var _hammers: Array[Control] = [%Hammer1, %Hammer2, %Hammer3, %Hammer4, %Hammer5]
@onready var _producer_choice_buttons: Array[Button] = [%Choice1, %Choice2, %Choice3]

var _session = ChickenDaySession.new()
var _input_locked := false
var _request_generation := 0
var _dev_day_number := 0


func _ready() -> void:
	for circuit_button: Button in _circuit_buttons:
		circuit_button.connect("circuit_requested", _on_circuit_requested)
		circuit_button.connect("preview_changed", _on_circuit_preview_changed)
	for choice_index in range(_producer_choice_buttons.size()):
		_producer_choice_buttons[choice_index].pressed.connect(
			_on_producer_choice_pressed.bind(choice_index)
		)
	for kind: String in _merge_buttons:
		_merge_buttons[kind].pressed.connect(_on_merge_pressed.bind(kind))
	_extra_thwack_button.pressed.connect(_on_factory_upgrade_pressed.bind("extra_thwack"))
	for kind: String in _retirement_buttons:
		_retirement_buttons[kind].pressed.connect(_on_retirement_pressed.bind(kind))
	_restart_button.pressed.connect(_on_restart_pressed)
	_continue_workshop_button.pressed.connect(_on_leave_shop_pressed)
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
	if state.phase != "shop" or choice_index >= state.shop_stock.recruitment.size():
		return
	var selected: Dictionary = state.shop_stock.recruitment[choice_index]
	var events: Array[Dictionary] = _session.purchase_producer(selected.kind)
	_render(events)


func _on_merge_pressed(kind: String) -> void:
	if _input_locked:
		return
	var state: Dictionary = _session.state()
	var offer := _first_merge_offer(state.shop_stock.merges, kind)
	if offer.is_empty():
		return
	_render(_session.queue_merge(kind, int(offer.tier)))


func _on_factory_upgrade_pressed(upgrade_id: String) -> void:
	if _input_locked:
		return
	_render(_session.purchase_factory_upgrade(upgrade_id))


func _on_retirement_pressed(kind: String) -> void:
	if _input_locked:
		return
	_render(_session.purchase_retirement(kind))


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
	_workshop_overlay.visible = false
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
	_input_locked = false
	_session = session
	_dev_day_number = dev_day_number
	_render([], true)
	_focus_first_available_lever()


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
	_configure_machine(state.machine_slot_count, state.machine_circuits)
	_score_label.text = "SCORE %d / %d" % [state.score, state.target_score]
	_cash_label.text = "CASH £%d" % state.cash
	_cash_label.accessibility_name = "Cash balance £%d" % state.cash
	_thwacks_label.text = "THWACKS %d" % state.remaining_thwacks
	_hopper_count_label.text = "HOPPER %d" % state.hopper_egg_count

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
		var has_egg := false
		for slot_index: int in circuit_button.slot_indices:
			var egg: Dictionary = state.slots[slot_index] if slot_index < state.slots.size() else {}
			has_egg = has_egg or not egg.is_empty()
			descriptions.append("empty" if egg.is_empty() else _belt_slots[slot_index].egg_description())
		circuit_button.set_target_descriptions(descriptions)
		circuit_button.set_available(has_egg and state.phase == "day" and not _input_locked)

	_result_overlay.visible = state.phase == "failed"
	_workshop_overlay.visible = state.phase == "shop"
	if _result_overlay.visible:
		_result_label.text = "DAY FAILED"
		_result_score_label.text = "%d / %d POINTS" % [state.score, state.target_score]
		_cash_payout_label.text = "NO CASH EARNED  •  BALANCE £%d" % state.cash
		_flock_summary_label.text = "FLOCK %d PRODUCERS  •  DAILY OUTPUT %d EGGS" % [
			state.producers.size(), state.daily_egg_count,
		]
		_restart_button.visible = true
		_result_card.offset_left = -240.0
		_result_card.offset_top = -190.0
		_result_card.offset_right = 240.0
		_result_card.offset_bottom = 190.0
		_result_summary_label.text = "No shop opens. Retry this day with the same flock and shuffle."
		_restart_button.text = "RETRY DAY %d" % state.day_number
		_restart_button.grab_focus.call_deferred()

	if _workshop_overlay.visible:
		_render_shop(state, events)

	if fresh_day:
		_feedback_label.text = "%sDAY %d  •  EMPTY STRIKES ARE WASTED" % [
			"DEV MODE  •  " if is_dev_mode() else "",
			state.day_number,
		]
	else:
		_feedback_label.text = _feedback_for(events)


func _render_shop(state: Dictionary, events: Array[Dictionary]) -> void:
	_workshop_balance_label.text = "BALANCE £%d" % state.cash
	_workshop_summary_label.text = (
		"DAY %d COMPLETE  •  £%d BANKED  •  DAY %d TARGET %d  •  FLOCK %d → %d"
		% [
			state.day_number,
			state.last_cash_awarded,
			state.day_number + 1,
			state.next_day_target_score,
			state.producers.size(),
			state.projected_flock_size,
		]
	)

	var recruitment: Array = state.shop_stock.recruitment
	for choice_index in range(_producer_choice_buttons.size()):
		var choice_button: Button = _producer_choice_buttons[choice_index]
		choice_button.visible = choice_index < recruitment.size()
		if not choice_button.visible:
			continue
		choice_button.render_choice(recruitment[choice_index])
		choice_button.disabled = state.cash < int(recruitment[choice_index].price)

	_merge_summary_label.text = (
		"PICK OF THE LITTER  •  %d MERGE%s QUEUED  •  OUTPUTS ARRIVE NEXT DAY"
		% [
			_pending_pair_count(state.pending_merges),
			"" if _pending_pair_count(state.pending_merges) == 1 else "S",
		]
	)
	for kind: String in _merge_buttons:
		_render_merge_button(
			_merge_buttons[kind],
			_first_merge_offer(state.shop_stock.merges, kind),
			kind
		)
	var factory_offer := _offer_with_id(state.shop_stock.factory_upgrades, "extra_thwack")
	_render_shop_offer_button(
		_extra_thwack_button,
		factory_offer,
		"STARTING THWACKS %d → %d  •  £%d" if not factory_offer.is_empty() else "EXTRA STARTING THWACK  •  BOUGHT",
		state.cash,
		[
			int(factory_offer.get("current_starting_thwacks", 0)),
			int(factory_offer.get("next_starting_thwacks", 0)),
			int(factory_offer.get("price", 0)),
		]
	)

	var retirement_price := int(state.shop_stock.retirement.price)
	for kind: String in _retirement_buttons:
		var retirement_group := _lowest_unreserved_quality_group(state.quality_groups, kind)
		var available_count := int(retirement_group.get("available_count", 0))
		var retirement_button: Button = _retirement_buttons[kind]
		retirement_button.text = "%s %s (%d)  •  £%d" % [
			_tier_name(int(retirement_group.get("tier", 0))),
			kind.to_upper(),
			available_count,
			retirement_price,
		]
		retirement_button.accessibility_description = (
			"Retire one %s %s bird for %d pounds."
			% [
				_tier_name(int(retirement_group.get("tier", 0))).to_lower(),
				kind.capitalize(),
				retirement_price,
			]
		)
		retirement_button.disabled = (
			available_count == 0
			or state.projected_flock_size <= 1
			or state.cash < retirement_price
		)

	_continue_workshop_button.text = "LEAVE SHOP & START DAY %d" % (state.day_number + 1)
	if state.machine_refit_due:
		_continue_workshop_button.text = "FREE REFIT & START DAY 3"
	_workshop_status_label.text = _shop_status(events, state.machine_refit_due)
	if events.any(func(event: Dictionary) -> bool: return event.type == "cash_awarded"):
		_focus_first_shop_action.call_deferred()


func _render_shop_offer_button(
	button: Button,
	offer: Dictionary,
	label_format: String,
	cash: int,
	values: Array
) -> void:
	button.text = label_format % values if not offer.is_empty() else label_format
	button.disabled = offer.is_empty() or cash < int(offer.get("price", 0))


func _render_merge_button(button: Button, offer: Dictionary, kind: String) -> void:
	if offer.is_empty():
		button.text = "%s\nNEED 2 MATCHING" % kind.to_upper()
		button.accessibility_name = "%s merge unavailable" % kind.capitalize()
		button.accessibility_description = "Requires two unreserved birds of the same quality tier."
		button.disabled = true
		return
	button.text = "%s ×2  %s → %s\n%d PTS / %d%%  →  %d PTS / %d%%" % [
		kind.to_upper(),
		_tier_name(int(offer.tier)),
		_tier_name(int(offer.output_tier)),
		int(offer.current_points),
		int(offer.current_double_yolk_percent),
		int(offer.next_points),
		int(offer.next_double_yolk_percent),
	]
	button.accessibility_name = "Merge two %s %s birds" % [
		_tier_name(int(offer.tier)).to_lower(), kind.capitalize(),
	]
	button.accessibility_description = (
		"Produces one %s bird. Its egg is worth %d points and has %d percent Double Yolker chance."
		% [
			_tier_name(int(offer.output_tier)).to_lower(),
			int(offer.next_points),
			int(offer.next_double_yolk_percent),
		]
	)
	button.disabled = false


func _first_merge_offer(offers: Array, kind: String) -> Dictionary:
	for offer: Dictionary in offers:
		if offer.kind == kind:
			return offer
	return {}


func _pending_pair_count(pending_merges: Array) -> int:
	var total := 0
	for pending: Dictionary in pending_merges:
		total += int(pending.pair_count)
	return total


func _lowest_unreserved_quality_group(groups: Array, kind: String) -> Dictionary:
	for group: Dictionary in groups:
		var available_count := int(group.bird_count) - int(group.reserved_count)
		if group.kind == kind and available_count > 0:
			return {
				"tier": int(group.tier),
				"available_count": available_count,
			}
	return {}


func _tier_name(tier: int) -> String:
	match tier:
		0:
			return "STANDARD"
		1:
			return "PRIZE"
		2:
			return "CHAMPION"
	return "TIER %d" % tier


func _offer_with_id(offers: Array, offer_id: String) -> Dictionary:
	for offer: Dictionary in offers:
		if offer.id == offer_id:
			return offer
	return {}


func _shop_status(events: Array[Dictionary], refit_due: bool) -> String:
	if not events.is_empty():
		var event: Dictionary = events[0]
		match String(event.type):
			"producer_purchased":
				return "%s RECRUITED  •  £%d REMAINING" % [
					String(event.producer.kind).to_upper(), event.cash_total,
				]
			"producer_retired":
				return "ONE %s %s RETIRED  •  £%d REMAINING" % [
					_tier_name(int(event.producer.tier)),
					String(event.producer.kind).to_upper(),
					event.cash_total,
				]
			"producer_merge_queued":
				return "%s %s PAIR QUEUED → %s  •  FLOCK WILL BE %d" % [
					String(event.kind).to_upper(),
					_tier_name(int(event.tier)),
					_tier_name(int(event.output_tier)),
					int(event.projected_flock_size),
				]
			"factory_upgrade_purchased":
				return "EXTRA STARTING THWACK INSTALLED  •  £%d REMAINING" % event.cash_total
			"shop_purchase_rejected":
				return "PURCHASE DECLINED  •  %s" % String(event.reason).replace("_", " ").to_upper()
	return (
		"FREE TEN-BAY HAIRPIN REFIT INCLUDED WHEN YOU LEAVE"
		if refit_due
		else "MERGE MATCHES  •  BUY ANY AFFORDABLE ITEMS  •  OR SAVE YOUR CASH"
	)


func _focus_first_shop_action() -> void:
	for choice_button: Button in _producer_choice_buttons:
		if choice_button.visible and not choice_button.disabled:
			choice_button.grab_focus()
			return
	_continue_workshop_button.grab_focus()


func _set_circuit_interaction(enabled: bool) -> void:
	for circuit_button: Button in _circuit_buttons:
		if not circuit_button.visible:
			circuit_button.set_available(false)
			continue
		var has_egg := false
		for slot_index: int in circuit_button.slot_indices:
			has_egg = has_egg or not _belt_slots[slot_index].current_egg().is_empty()
		circuit_button.set_available(enabled and has_egg)


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
	var hairpin := slot_count == ChickenDay.HAIRPIN_SLOT_COUNT
	for slot_index in range(_belt_slots.size()):
		var active := slot_index < slot_count
		_belt_slots[slot_index].visible = active
		if not active:
			continue
		_belt_slots[slot_index].scale = Vector2.ONE
		# Eggs sit directly on the moving belt in both layouts; individual cups
		# make the early line read as five separate machines instead of one flow.
		_belt_slots[slot_index].set_bare_belt_mode(true)
		if not hairpin:
			_belt_slots[slot_index].position = Vector2(200.0 + 190.0 * slot_index, 170.0)
		else:
			var column_index := slot_index if slot_index < 5 else 9 - slot_index
			var hairpin_y := 170.0 if slot_index < 5 else 300.0
			_belt_slots[slot_index].position = Vector2(185.0 + 190.0 * column_index, hairpin_y)
			_belt_slots[slot_index].scale = Vector2(0.78, 0.78)

	for hammer_index in range(_hammers.size()):
		_hammers[hammer_index].visible = true
		_hammers[hammer_index].scale = Vector2.ONE
		_hammers[hammer_index].set_bowl_scale(1.0)
		_hammers[hammer_index].clear_telescoping_spoon()
		if hairpin:
			_hammers[hammer_index].position = Vector2.ZERO
			_hammers[hammer_index].size = Vector2(1280.0, 560.0)
			var top_target := _local_impact_target(
				_hammers[hammer_index],
				_belt_slots[hammer_index]
			)
			var bottom_target := _local_impact_target(
				_hammers[hammer_index],
				_belt_slots[9 - hammer_index]
			)
			_hammers[hammer_index].configure_telescoping_spoon(
				top_target,
				bottom_target
			)
		else:
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
	_presenter.set_slot_hammer_indices(
		[0, 1, 2, 3, 4, 4, 3, 2, 1, 0]
		if hairpin
		else [0, 1, 2, 3, 4]
	)
	_presenter.set_slot_hammer_extension_amounts(
		[0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0]
		if hairpin
		else [0.0, 0.0, 0.0, 0.0, 0.0]
	)
	if hairpin:
		for button_index in range(_circuit_buttons.size()):
			var slot: Control = _belt_slots[button_index]
			var column_center_x := slot.position.x + slot.size.x * slot.scale.x * 0.5
			_circuit_buttons[button_index].position = Vector2(column_center_x - 85.0, 440.0)
			_circuit_buttons[button_index].size = Vector2(170.0, 112.0)
		_drop_label.position = Vector2(115.0, 365.0)
	else:
		var base_buttons: Array[Button] = [%RedCircuit, %BlueCircuit, %PinkCircuit]
		for button_index in range(base_buttons.size()):
			base_buttons[button_index].position = Vector2(210.0 + 320.0 * button_index, 416.0)
			base_buttons[button_index].size = Vector2(280.0, 112.0)
		_drop_label.position = Vector2(1140.0, 326.0)


func _local_impact_target(hammer: Control, slot: Control) -> Vector2:
	return (
		hammer.get_global_transform().affine_inverse()
		* slot.impact_global_position()
	)


func _circuit_appearance(circuit_id: String) -> Dictionary:
	var appearances := {
		"red": {"color": Color("c43b36"), "symbol": "diamond"},
		"blue": {"color": Color("287cbd"), "symbol": "circle"},
		"green": {"color": Color("69a645"), "symbol": "triangle"},
		"purple": {"color": Color("8f59b8"), "symbol": "hexagon"},
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


func _feedback_for(events: Array[Dictionary]) -> String:
	var double_yolker_hatches := events.filter(
		func(event: Dictionary) -> bool:
			return event.type == "egg_hatched" and bool(event.get("double_yolker", false))
	)
	if double_yolker_hatches.size() == 1:
		var double_hatch: Dictionary = double_yolker_hatches[0]
		return "DOUBLE YOLKER! A %s hatched for %d points." % [
			String(double_hatch.get("kind", "egg")).capitalize(),
			double_hatch.points_awarded,
		]
	if double_yolker_hatches.size() > 1:
		var double_points := 0
		for double_hatch: Dictionary in double_yolker_hatches:
			double_points += int(double_hatch.points_awarded)
		return "DOUBLE YOLKERS! %d lucky eggs hatched for %d points." % [
			double_yolker_hatches.size(),
			double_points,
		]
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
			return "Scuttle! The Plover retreated one bay to the left."
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
