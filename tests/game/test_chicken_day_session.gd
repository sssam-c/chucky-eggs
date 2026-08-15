extends GutTest

const ChickenDaySession = preload("res://src/game/chicken_day_session.gd")
const ProducerFlock = preload("res://src/domain/producer_flock.gd")
const SeededChanceRoller = preload("res://src/core/seeded_chance_roller.gd")

const SUCCESSFUL_DAY_EGGS: Array[String] = [
	"chicken", "cuckoo", "chicken", "spoonbill",
	"cuckoo", "plover", "chicken", "chicken",
	"chicken", "cuckoo", "chicken", "spoonbill",
	"cuckoo", "plover", "chicken", "chicken",
	"chicken", "cuckoo", "chicken", "spoonbill",
	"cuckoo", "plover", "chicken", "chicken",
]
const EARLY_SUCCESS_PLAN: Array[String] = [
	"red", "red", "red", "blue", "red", "red",
	"red", "blue", "blue", "pink", "pink",
]


class IdentityShuffler:
	extends RefCounted

	func shuffle_strings(values: Array[String]) -> Array[String]:
		return values.duplicate()

	func shuffle_dictionaries(values: Array[Dictionary]) -> Array[Dictionary]:
		return values.duplicate(true)


func test_session_builds_a_fifteen_egg_day_from_the_starting_flock() -> void:
	var state: Dictionary = ChickenDaySession.new(42).state()

	assert_eq(state.day_number, 1)
	assert_eq(state.target_score, 15)
	assert_eq(state.cash, 0)
	assert_eq(state.last_cash_awarded, 0)
	assert_eq(state.producers.size(), 15)
	assert_eq(state.daily_egg_count, 15)
	assert_eq(state.hopper_egg_count, 14)
	assert_eq(state.pipe.size(), 3)
	assert_false(state.slots[0].is_empty())


func test_equal_day_seeds_replay_the_same_visible_shuffle() -> void:
	var first: Dictionary = ChickenDaySession.new(42).state()
	var second: Dictionary = ChickenDaySession.new(42).state()

	assert_eq(first.slots, second.slots)
	assert_eq(first.pipe, second.pipe)
	assert_eq(first.slots[0].get("is_double_yolker"), second.slots[0].get("is_double_yolker"))


func test_starting_flock_exposes_exactly_two_ten_percent_parents() -> void:
	var state: Dictionary = ChickenDaySession.new(42).state()

	assert_eq(state.producers.filter(func(producer: Dictionary) -> bool:
		return is_equal_approx(float(producer.get("double_yolk_chance", 0.0)), 0.10)
	).size(), 2)


func test_default_day_one_seed_contains_one_double_yolker_for_the_prototype_playtest() -> void:
	var laid_eggs: Array[Dictionary] = ProducerFlock.new().lay_daily_eggs(
		SeededChanceRoller.new(
			ChickenDaySession.DEFAULT_DAY_SEED + ChickenDaySession.DOUBLE_YOLK_SEED_STEP
		)
	)

	assert_eq(laid_eggs.filter(func(egg: Dictionary) -> bool:
		return bool(egg.is_double_yolker)
	).size(), 1)


func test_session_can_initialize_canonical_day_three_for_dev_tools() -> void:
	var session = ChickenDaySession.new(42, null, IdentityShuffler.new(), 3)
	var state: Dictionary = session.state()

	assert_eq(state.phase, "day")
	assert_eq(state.day_number, 3)
	assert_eq(state.target_score, 20)
	assert_eq(state.machine_slot_count, 10)
	assert_eq(state.slots.size(), 10)
	assert_true(state.machine_refit_complete)
	assert_false(state.machine_refit_due)
	assert_eq(state.remaining_thwacks, 20)

	session.submit_circuit("red")
	session.restart()

	assert_eq(session.state().day_number, 3)
	assert_eq(session.state().machine_slot_count, 10)
	assert_eq(session.state().remaining_thwacks, 20)


func test_session_is_the_request_pathway_and_returns_a_safe_snapshot() -> void:
	var session = ChickenDaySession.new()
	var exposed_state: Dictionary = session.state()
	exposed_state.remaining_thwacks = 2
	exposed_state.slots[0].toughness = 1

	var events: Array[Dictionary] = session.submit_circuit("red")
	var actual_state: Dictionary = session.state()

	assert_eq(events[0].type, "circuit_fired")
	assert_eq(actual_state.remaining_thwacks, 19)
	assert_eq(actual_state.slots[1].toughness, 2)


func test_restart_replaces_the_day_with_initial_state() -> void:
	var session = ChickenDaySession.new()
	session.submit_circuit("red")

	session.restart()

	assert_eq(session.state().remaining_thwacks, 20)
	assert_eq(session.state().slots[0].toughness, 3)


func test_success_opens_three_distinct_deterministic_producer_choices() -> void:
	var session = _successful_day_session()

	var final_events: Array[Dictionary] = _complete_successful_day(session)
	var state: Dictionary = session.state()
	var offered_kinds: Array = state.reward_choices.map(
		func(choice: Dictionary) -> String: return choice.kind
	)

	assert_eq(state.phase, "reward")
	assert_eq(state.day_number, 1)
	assert_eq(state.next_day_target_score, 20)
	assert_eq(state.reward_choices.size(), 3)
	assert_eq(offered_kinds.duplicate().reduce(
		func(unique: Array, kind: String) -> Array:
			if kind not in unique:
				unique.append(kind)
			return unique,
		[]
	).size(), 3)
	assert_true(offered_kinds.all(func(kind: String) -> bool:
		return kind in ["chicken", "cuckoo", "plover", "spoonbill"]
	))
	assert_eq(final_events[-1].type, "cash_awarded")
	assert_gt(final_events[-1].amount, 0)
	assert_eq(final_events[-1].amount, final_events[-1].remaining_thwacks)
	assert_eq(final_events[-1].cash_total, final_events[-1].amount)


func test_success_banks_one_pound_per_remaining_thwack_exactly_once() -> void:
	var session = _early_success_session()

	var final_events: Array[Dictionary] = _complete_early_successful_day(session)

	assert_eq(final_events.map(func(event: Dictionary) -> String: return event.type).slice(-3), [
		"day_remainder_discarded", "day_ended", "cash_awarded",
	])
	assert_eq(final_events[-2].remaining_thwacks, 9)
	assert_eq(final_events[-1], {
		"type": "cash_awarded",
		"amount": 9,
		"cash_total": 9,
		"remaining_thwacks": 9,
	})
	assert_eq(session.state().cash, 9)
	assert_eq(session.state().last_cash_awarded, 9)

	assert_eq(session.submit_circuit("red"), [{"type": "thwack_rejected", "reason": "wrong_phase"}])
	assert_eq(session.state().cash, 9)


func test_selecting_an_offered_producer_opens_the_workshop_before_day_two() -> void:
	var session = _successful_day_session()
	_complete_successful_day(session)
	var before: Dictionary = session.state()
	var selected: Dictionary = before.reward_choices[0]

	var events: Array[Dictionary] = session.select_producer(selected.kind)
	var after: Dictionary = session.state()

	assert_eq(events.map(func(event: Dictionary) -> String: return event.type), ["producer_added"])
	assert_eq(after.phase, "workshop")
	assert_eq(after.day_number, 1)
	assert_eq(after.producers.size(), before.producers.size() + 1)
	assert_eq(after.daily_egg_count, before.daily_egg_count)
	assert_true(after.reward_choices.is_empty())
	assert_false(after.machine_refit_due)
	assert_false(after.machine_refit_complete)

	var day_events: Array[Dictionary] = session.continue_from_workshop()
	var day_two: Dictionary = session.state()

	assert_eq(day_events.map(func(event: Dictionary) -> String: return event.type), ["day_started"])
	assert_eq(day_events[0].production.size(), day_two.producers.size())
	assert_eq(day_events[0].target_score, 20)
	assert_eq(day_events[0].production.size(), day_two.daily_egg_count)
	assert_true(day_events[0].production.all(func(producer: Dictionary) -> bool:
		return producer.has_all(["kind", "toughness", "points", "effect"])
	))
	assert_eq(day_two.phase, "day")
	assert_eq(day_two.day_number, 2)
	assert_eq(day_two.target_score, 20)
	assert_eq(day_two.daily_egg_count, before.daily_egg_count + 1)
	assert_eq(day_two.machine_slot_count, 5)


func test_day_three_mandatorily_refits_every_run_to_the_ten_slot_hairpin() -> void:
	var session = _successful_day_session()
	_complete_successful_day(session)
	session.select_producer(session.state().reward_choices[0].kind)
	var day_two_events: Array[Dictionary] = session.continue_from_workshop()
	assert_eq(day_two_events.map(func(event: Dictionary) -> String: return event.type), ["day_started"])
	assert_eq(session.state().machine_slot_count, 5)

	_complete_successful_day(session)
	session.select_producer(session.state().reward_choices[0].kind)

	var workshop: Dictionary = session.state()
	assert_eq(workshop.phase, "workshop")
	assert_eq(workshop.day_number, 2)
	assert_true(workshop.machine_refit_due)
	assert_false(workshop.machine_refit_complete)
	var cash_before_refit: int = workshop.cash

	var day_events: Array[Dictionary] = session.continue_from_workshop()

	assert_eq(day_events.map(func(event: Dictionary) -> String: return event.type), [
		"machine_refitted", "day_started",
	])
	assert_eq(day_events[0].slot_count, 10)
	assert_eq(day_events[0].circuits, [
		{"id": "red", "slot_indices": [0, 9]},
		{"id": "blue", "slot_indices": [1, 8]},
		{"id": "green", "slot_indices": [2, 7]},
		{"id": "purple", "slot_indices": [3, 6]},
		{"id": "pink", "slot_indices": [4, 5]},
	])
	assert_eq(day_events[0].day_number, 3)
	assert_eq(day_events[1].day_number, 3)
	assert_eq(day_events[1].slot_count, 10)
	assert_eq(session.state().slots.size(), 10)
	assert_eq(session.state().cash, cash_before_refit)
	assert_true(session.state().machine_refit_complete)
	assert_false(session.state().machine_refit_due)


func test_banked_cash_persists_into_day_two() -> void:
	var session = _early_success_session()
	_complete_early_successful_day(session)
	var selected: Dictionary = session.state().reward_choices[0]

	session.select_producer(selected.kind)
	session.continue_from_workshop()

	assert_eq(session.state().day_number, 2)
	assert_eq(session.state().cash, 9)
	assert_eq(session.state().last_cash_awarded, 0)


func test_failed_day_two_awards_nothing_and_retry_preserves_banked_cash() -> void:
	var session = _early_success_session()
	_complete_early_successful_day(session)
	var selected: Dictionary = session.state().reward_choices[0]
	session.select_producer(selected.kind)
	session.continue_from_workshop()
	var final_events: Array[Dictionary] = []

	while session.state().phase == "day":
		var state: Dictionary = session.state()
		var circuit_id := "pink" if not state.slots[4].is_empty() else (
			"red" if not state.slots[0].is_empty() or not state.slots[2].is_empty()
			else "blue"
		)
		final_events = session.submit_circuit(circuit_id)

	assert_eq(session.state().phase, "failed")
	assert_eq(session.state().cash, 9)
	assert_eq(session.state().last_cash_awarded, 0)
	assert_false(final_events.any(func(event: Dictionary) -> bool:
		return event.type == "cash_awarded"
	))

	session.restart()

	assert_eq(session.state().phase, "day")
	assert_eq(session.state().day_number, 2)
	assert_eq(session.state().cash, 9)


func test_restarting_day_two_preserves_its_twenty_point_target() -> void:
	var session = _successful_day_session()
	_complete_successful_day(session)
	var selected: Dictionary = session.state().reward_choices[0]
	session.select_producer(selected.kind)
	session.continue_from_workshop()
	session.submit_circuit("red")

	session.restart()

	assert_eq(session.state().day_number, 2)
	assert_eq(session.state().target_score, 20)
	assert_eq(session.state().score, 0)
	assert_eq(session.state().remaining_thwacks, 20)


func test_unoffered_producer_cannot_be_selected() -> void:
	var session = _successful_day_session()
	_complete_successful_day(session)
	var before: Dictionary = session.state()
	var unoffered_kind := ""
	for kind in ["chicken", "cuckoo", "plover", "spoonbill"]:
		if not before.reward_choices.any(
			func(choice: Dictionary) -> bool: return choice.kind == kind
		):
			unoffered_kind = kind

	var events: Array[Dictionary] = session.select_producer(unoffered_kind)

	assert_eq(events, [{"type": "producer_selection_rejected", "reason": "not_offered"}])
	assert_eq(session.state(), before)


func test_restart_cannot_bypass_the_mandatory_success_choice() -> void:
	var session = _successful_day_session()
	_complete_successful_day(session)
	var before: Dictionary = session.state()

	session.restart()

	assert_eq(session.state(), before)


func test_failure_offers_no_producer_and_retry_replays_the_same_day() -> void:
	var flock = ProducerFlock.new([{"kind": "chicken"}])
	var session = ChickenDaySession.new(7, flock, IdentityShuffler.new())
	var opening: Dictionary = session.state()

	var final_events: Array[Dictionary] = []
	for circuit_id in ["red", "blue", "red"]:
		final_events = session.submit_circuit(circuit_id)
	assert_eq(session.state().phase, "failed")
	assert_true(session.state().reward_choices.is_empty())
	assert_eq(session.state().cash, 0)
	assert_eq(session.state().last_cash_awarded, 0)
	assert_false(final_events.any(func(event: Dictionary) -> bool:
		return event.type == "cash_awarded"
	))

	session.restart()

	assert_eq(session.state().phase, "day")
	assert_eq(session.state().day_number, 1)
	assert_eq(session.state().producers, opening.producers)
	assert_eq(session.state().slots, opening.slots)
	assert_eq(session.state().pipe, opening.pipe)
	assert_eq(session.state().cash, 0)


func _successful_day_session():
	var producers: Array[Dictionary] = []
	for kind: String in SUCCESSFUL_DAY_EGGS:
		producers.append({"kind": kind})
	return ChickenDaySession.new(42, ProducerFlock.new(producers), IdentityShuffler.new())


func _early_success_session():
	var producers: Array[Dictionary] = []
	for egg_index in range(7):
		producers.append({"kind": "chicken"})
	return ChickenDaySession.new(42, ProducerFlock.new(producers), IdentityShuffler.new())


func _complete_successful_day(session) -> Array[Dictionary]:
	var circuit_plan := [
		"red", "blue", "red", "blue", "red", "blue", "red", "pink", "red", "blue",
		"red", "blue", "red", "blue", "red", "pink", "red", "blue", "red", "blue",
	]
	var final_events: Array[Dictionary] = []
	for circuit_id in circuit_plan:
		final_events = session.submit_circuit(circuit_id)
		if session.state().phase != "day":
			break
	assert_true(session.state().succeeded)
	return final_events


func _complete_early_successful_day(session) -> Array[Dictionary]:
	var final_events: Array[Dictionary] = []
	for circuit_id in EARLY_SUCCESS_PLAN:
		final_events = session.submit_circuit(circuit_id)
		if session.state().phase != "day":
			break
	assert_true(session.state().succeeded)
	return final_events
