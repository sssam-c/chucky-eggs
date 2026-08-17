extends GutTest

const ChickenDaySession = preload("res://src/game/chicken_day_session.gd")
const ProducerFlock = preload("res://src/domain/producer_flock.gd")
const SeededChanceRoller = preload("res://src/core/seeded_chance_roller.gd")

const SUCCESSFUL_DAY_EGGS: Array[String] = [
	"chicken", "chicken", "chicken", "chicken", "chicken", "chicken", "chicken",
	"cuckoo", "cuckoo", "plover", "plover", "spoonbill", "spoonbill",
]
const EARLY_SUCCESS_PLAN: Array[String] = [
	"red", "red", "red", "red", "blue", "red", "blue", "red",
]
const FINAL_PATIENCE_SUCCESS_PLAN: Array[String] = [
	"red", "blue", "red", "red", "red", "blue", "red", "red", "red", "blue",
]


class IdentityShuffler:
	extends RefCounted

	func shuffle_strings(values: Array[String]) -> Array[String]:
		return values.duplicate()

	func shuffle_dictionaries(values: Array[Dictionary]) -> Array[Dictionary]:
		return values.duplicate(true)


class AppetiserInjectingShuffler:
	extends RefCounted

	func shuffle_strings(values: Array[String]) -> Array[String]:
		return values.duplicate()

	func shuffle_dictionaries(values: Array[Dictionary]) -> Array[Dictionary]:
		var eggs := values.duplicate(true)
		if not eggs.is_empty():
			eggs[0]["effects"] = [{"type": "appetiser"}]
		return eggs


func test_session_builds_an_eight_egg_day_with_ten_patience_from_the_starting_flock() -> void:
	var state: Dictionary = ChickenDaySession.new(42).state()

	assert_eq(state.day_number, 1)
	assert_eq(state.target_score, 10)
	assert_eq(state.cash, 0)
	assert_eq(state.last_cash_awarded, 0)
	assert_eq(state.producers.size(), 8)
	assert_eq(state.producers.count({"kind": "sparrow", "tier": 0}), 3)
	assert_eq(state.daily_egg_count, 8)
	assert_eq(state.hopper_egg_count, 7)
	assert_eq(state.pipe.size(), 3)
	assert_eq(state.starting_patience, 10)
	assert_eq(state.current_patience, 10)
	assert_false("starting_thwacks" in state)
	assert_false("remaining_thwacks" in state)
	assert_false(state.slots[0].is_empty())


func test_equal_day_seeds_replay_the_same_visible_shuffle() -> void:
	var first: Dictionary = ChickenDaySession.new(42).state()
	var second: Dictionary = ChickenDaySession.new(42).state()

	assert_eq(first.slots, second.slots)
	assert_eq(first.pipe, second.pipe)
	assert_eq(first.slots[0].get("is_double_yolker"), second.slots[0].get("is_double_yolker"))


func test_starting_flock_exposes_species_level_double_yolk_progress() -> void:
	var state: Dictionary = ChickenDaySession.new(42).state()
	var chicken_group: Dictionary = state.quality_groups.filter(
		func(group: Dictionary) -> bool: return group.kind == "chicken" and group.tier == 0
	)[0]
	var sparrow_group: Dictionary = state.quality_groups.filter(
		func(group: Dictionary) -> bool: return group.kind == "sparrow" and group.tier == 0
	)[0]

	assert_eq(chicken_group.bird_count, 3)
	assert_eq(chicken_group.points, 3)
	assert_eq(chicken_group.double_yolk_chance, 0.02)
	assert_eq(chicken_group.display_double_yolk_percent, 2)
	assert_eq(sparrow_group.bird_count, 3)
	assert_eq(sparrow_group.display_double_yolk_percent, 5)
	assert_true(state.producers.all(func(producer: Dictionary) -> bool:
		return not producer.has("double_yolk_chance")
	))


func test_default_day_one_seed_replays_species_level_double_yolk_rolls() -> void:
	var first: Array[Dictionary] = ProducerFlock.new().lay_daily_eggs(
		SeededChanceRoller.new(
			ChickenDaySession.DEFAULT_DAY_SEED + ChickenDaySession.DOUBLE_YOLK_SEED_STEP
		)
	)
	var second: Array[Dictionary] = ProducerFlock.new().lay_daily_eggs(
		SeededChanceRoller.new(
			ChickenDaySession.DEFAULT_DAY_SEED + ChickenDaySession.DOUBLE_YOLK_SEED_STEP
		)
	)

	assert_eq(first, second)
	assert_true(first.filter(func(egg: Dictionary) -> bool:
		return egg.kind == "chicken"
	).all(func(egg: Dictionary) -> bool:
		return is_equal_approx(float(egg.double_yolk_chance), 0.02)
	))


func test_session_can_initialize_day_three_on_the_single_track_for_dev_tools() -> void:
	var session = ChickenDaySession.new(42, null, IdentityShuffler.new(), 3)
	var state: Dictionary = session.state()

	assert_eq(state.phase, "day")
	assert_eq(state.day_number, 3)
	assert_eq(state.target_score, 9)
	assert_eq(state.machine_slot_count, 5)
	assert_eq(state.slots.size(), 5)
	assert_eq(state.machine_circuits, [
		{"id": "red", "slot_indices": [0, 2]},
		{"id": "blue", "slot_indices": [1, 3]},
		{"id": "pink", "slot_indices": [4]},
	])
	assert_eq(state.current_patience, 10)

	session.submit_circuit("red")
	session.restart()

	assert_eq(session.state().day_number, 3)
	assert_eq(session.state().machine_slot_count, 5)
	assert_eq(session.state().current_patience, 10)


func test_dev_session_uses_exactly_the_selected_starting_egg_species() -> void:
	var session = ChickenDaySession.create_dev_session(
		3,
		["kiwi", "quail", "quail", "ostrich"],
		18,
		IdentityShuffler.new()
	)
	var state: Dictionary = session.state()
	var starting_kinds: Array[String] = []
	for egg: Dictionary in state.slots:
		if not egg.is_empty():
			starting_kinds.append(String(egg.kind))
	for egg: Dictionary in state.hopper_contents:
		starting_kinds.append(String(egg.kind))
	var expected_kinds: Array[String] = ["kiwi", "quail", "quail", "ostrich"]
	starting_kinds.sort()
	var sorted_expected := expected_kinds.duplicate()
	sorted_expected.sort()

	assert_eq(starting_kinds, sorted_expected)
	assert_eq(state.daily_egg_count, 4)
	assert_eq(state.producers.map(func(producer: Dictionary) -> String:
		return String(producer.kind)
	), expected_kinds)
	assert_eq(state.slots[0].kind, "kiwi")
	assert_eq(state.pipe.map(func(egg: Dictionary) -> String:
		return String(egg.kind)
	), ["quail", "quail", "ostrich"])
	assert_eq(state.day_number, 3)
	assert_eq(state.target_score, 9)
	assert_eq(state.starting_patience, 18)
	assert_eq(state.current_patience, 18)

	session.submit_circuit("red")
	session.restart()
	assert_eq(session.state().current_patience, 18)
	assert_eq(session.state().slots[0].kind, "kiwi")


func test_session_is_the_request_pathway_and_returns_a_safe_snapshot() -> void:
	var session = ChickenDaySession.new(
		42, ProducerFlock.new([{"kind": "chicken"}, {"kind": "cuckoo"}]), IdentityShuffler.new()
	)
	var exposed_state: Dictionary = session.state()
	exposed_state.current_patience = 2
	exposed_state.slots[0].toughness = 1
	exposed_state.hopper_contents[0].toughness = 1

	var events: Array[Dictionary] = session.submit_circuit("red")
	var actual_state: Dictionary = session.state()

	assert_eq(events[0].type, "circuit_fired")
	assert_eq(actual_state.current_patience, 9)
	assert_eq(actual_state.slots[1].toughness, 2)
	assert_eq(actual_state.slots[0].kind, "cuckoo")
	assert_eq(actual_state.slots[0].toughness, 4)


func test_restart_replaces_the_day_with_initial_state() -> void:
	var session = ChickenDaySession.new(
		42, ProducerFlock.new([{"kind": "chicken"}]), IdentityShuffler.new()
	)
	session.submit_circuit("red")

	session.restart()

	assert_eq(session.state().current_patience, 10)
	assert_eq(session.state().slots[0].toughness, 3)


func test_restart_clears_active_grandma_effects() -> void:
	var session = ChickenDaySession.new(
		42,
		ProducerFlock.new([{"kind": "sparrow"}, {"kind": "chicken"}]),
		AppetiserInjectingShuffler.new()
	)
	session.submit_circuit("red")
	assert_eq(session.state().grandma_effects.appetiser_charges, 1)

	session.restart()

	assert_eq(session.state().score, 0)
	assert_eq(session.state().grandma_effects, {
		"appetiser_charges": 0,
		"sulphurous_suppression": 0,
		"deceptively_filling_reserve": 0,
	})


func test_success_opens_a_deterministic_bird_offer_before_the_shop() -> void:
	var first = _successful_day_session()
	var second = _successful_day_session()
	_complete_successful_day(first)
	_complete_successful_day(second)
	var state: Dictionary = first.state()

	assert_eq(state.phase, "bird_offer")
	assert_eq(state.bird_offer, second.state().bird_offer)
	assert_eq(state.bird_offer.size(), 3)
	assert_true(state.bird_offer.all(func(offer: Dictionary) -> bool:
		return (
			offer.kind in ProducerFlock.PRODUCER_KINDS
			and int(offer.tier) >= 0
			and not offer.has("price")
			and offer.has_all(["toughness", "points", "double_yolk_chance"])
		)
	))
	assert_true(state.bird_offer.any(func(offer: Dictionary) -> bool:
		return int(offer.tier) > 0
	), "the deterministic fixture proves offers are not limited to Standard quality")
	assert_true(state.shop_stock.is_empty())
	assert_false(state.bird_offer_claimed)


func test_claiming_one_free_bird_opens_the_separate_removal_shop_exactly_once() -> void:
	var session = _successful_day_session()
	_complete_successful_day(session)
	var before: Dictionary = session.state()
	var selected: Dictionary = before.bird_offer[1]

	assert_eq(session.leave_shop(), [{"type": "shop_leave_rejected", "reason": "wrong_phase"}])
	assert_eq(session.remove_bird(0)[0].reason, "wrong_phase")
	var events: Array[Dictionary] = session.claim_bird_offer(1)
	var after: Dictionary = session.state()

	assert_eq(events[0].type, "bird_offer_claimed")
	assert_eq(events[0].producer, {"kind": selected.kind, "tier": selected.tier})
	assert_eq(after.cash, before.cash)
	assert_eq(after.phase, "shop")
	assert_eq(after.shop_stock, {"removal": {"price": 3}})
	assert_eq(after.producers.size(), before.producers.size() + 1)
	assert_true(after.bird_offer.is_empty())
	assert_true(after.bird_offer_claimed)
	assert_eq(session.claim_bird_offer(0)[0].reason, "wrong_phase")


func test_removing_from_the_flock_overview_costs_three_pounds_and_targets_the_chosen_bird() -> void:
	var session = _funded_early_shop_session(3)
	var offer_events: Array[Dictionary] = session.claim_bird_offer(0)
	assert_eq(offer_events[0].type, "bird_offer_claimed")
	var before: Dictionary = session.state()
	assert_gte(before.cash, 3)
	var selected: Dictionary = before.producers[2]

	var events: Array[Dictionary] = session.remove_bird(2)
	var after: Dictionary = session.state()

	assert_eq(events[0].type, "bird_removed")
	assert_eq(events[0].producer, selected)
	assert_eq(events[0].price, 3)
	assert_eq(after.cash, before.cash - 3)
	assert_eq(after.producers.size(), before.producers.size() - 1)
	assert_true(after.removal_used_tonight)


func test_only_one_bird_can_be_removed_during_each_shop_visit() -> void:
	var session = _funded_early_shop_session(6)
	session.claim_bird_offer(0)
	assert_false(session.state().removal_used_tonight)
	session.remove_bird(0)
	var after_first: Dictionary = session.state()

	var rejected: Array[Dictionary] = session.remove_bird(0)

	assert_eq(rejected, [{
		"type": "shop_action_rejected",
		"category": "removal",
		"reason": "nightly_limit",
	}])
	assert_eq(session.state().cash, after_first.cash)
	assert_eq(session.state().producers, after_first.producers)
	assert_true(session.state().removal_used_tonight)

	session.leave_shop()
	assert_false(session.state().removal_used_tonight)


func test_success_banks_one_pound_per_remaining_patience_exactly_once() -> void:
	var session = _early_success_session()

	var final_events: Array[Dictionary] = _complete_early_successful_day(session)

	assert_eq(final_events.map(func(event: Dictionary) -> String: return event.type).slice(-3), [
		"day_remainder_discarded", "day_ended", "cash_awarded",
	])
	assert_eq(final_events[-2].current_patience, 2)
	assert_eq(final_events[-1], {
		"type": "cash_awarded",
		"amount": 2,
		"cash_total": 2,
		"remaining_patience": 2,
	})
	assert_eq(session.state().cash, 2)
	assert_eq(session.state().last_cash_awarded, 2)

	assert_eq(session.submit_circuit("red"), [{"type": "thwack_rejected", "reason": "wrong_phase"}])
	assert_eq(session.state().cash, 2)


func test_success_with_zero_remaining_patience_awards_zero_pounds() -> void:
	var session = _early_success_session()
	var final_events: Array[Dictionary] = []

	for circuit_id in FINAL_PATIENCE_SUCCESS_PLAN:
		final_events = session.submit_circuit(circuit_id)

	assert_eq(session.state().phase, "bird_offer")
	assert_true(session.state().succeeded)
	assert_eq(session.state().current_patience, 0)
	assert_eq(session.state().cash, 0)
	assert_eq(session.state().last_cash_awarded, 0)
	assert_eq(final_events[-1], {
		"type": "cash_awarded",
		"amount": 0,
		"cash_total": 0,
		"remaining_patience": 0,
	})


func test_every_day_keeps_the_single_five_slot_track() -> void:
	var session = _successful_day_session()
	_complete_successful_day(session)
	session.claim_bird_offer(0)
	var day_two_events: Array[Dictionary] = session.leave_shop()
	assert_eq(day_two_events.map(func(event: Dictionary) -> String: return event.type), ["day_started"])
	assert_eq(session.state().machine_slot_count, 5)

	_complete_successful_day(session)

	var shop: Dictionary = session.state()
	assert_eq(shop.phase, "bird_offer")
	assert_eq(shop.day_number, 2)
	var cash_before_day_three: int = shop.cash

	session.claim_bird_offer(0)
	var day_events: Array[Dictionary] = session.leave_shop()

	assert_eq(day_events.map(func(event: Dictionary) -> String: return event.type), ["day_started"])
	assert_eq(day_events[0].day_number, 3)
	assert_eq(day_events[0].slot_count, 5)
	assert_eq(session.state().slots.size(), 5)
	assert_eq(session.state().cash, cash_before_day_three)


func test_banked_cash_persists_into_day_two() -> void:
	var session = _early_success_session()
	_complete_early_successful_day(session)
	session.claim_bird_offer(0)
	session.leave_shop()

	assert_eq(session.state().day_number, 2)
	assert_eq(session.state().cash, 2)
	assert_eq(session.state().last_cash_awarded, 0)


func test_failed_day_two_awards_nothing_and_retry_preserves_banked_cash() -> void:
	var session = _early_success_session()
	_complete_early_successful_day(session)
	var banked_cash := int(session.state().cash)
	session.claim_bird_offer(0)
	session.leave_shop()
	var final_events: Array[Dictionary] = []

	while session.state().phase == "day":
		final_events = session.submit_circuit("pink")

	assert_eq(session.state().phase, "failed")
	assert_eq(session.state().cash, banked_cash)
	assert_eq(session.state().last_cash_awarded, 0)
	assert_false(final_events.any(func(event: Dictionary) -> bool:
		return event.type == "cash_awarded"
	))

	session.restart()

	assert_eq(session.state().phase, "day")
	assert_eq(session.state().day_number, 2)
	assert_eq(session.state().cash, banked_cash)


func test_restarting_day_two_preserves_its_nine_point_target() -> void:
	var session = _successful_day_session()
	_complete_successful_day(session)
	session.claim_bird_offer(0)
	session.leave_shop()
	session.submit_circuit("red")

	session.restart()

	assert_eq(session.state().day_number, 2)
	assert_eq(session.state().target_score, 9)
	assert_eq(session.state().score, 0)
	assert_eq(session.state().current_patience, 10)


func test_restart_cannot_bypass_the_success_shop() -> void:
	var session = _successful_day_session()
	_complete_successful_day(session)
	var before: Dictionary = session.state()

	session.restart()

	assert_eq(session.state(), before)


func test_failure_offers_no_shop_and_retry_replays_the_same_day() -> void:
	var flock = ProducerFlock.new([{"kind": "chicken"}])
	var session = ChickenDaySession.new(7, flock, IdentityShuffler.new())
	var opening: Dictionary = session.state()

	var final_events: Array[Dictionary] = []
	for circuit_id in ["red", "blue", "red"]:
		final_events = session.submit_circuit(circuit_id)
	assert_eq(session.state().phase, "failed")
	assert_true(session.state().shop_stock.is_empty())
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
	assert_eq(session.state().current_patience, 10)
	assert_eq(session.state().cash, 0)


func _successful_day_session():
	var producers: Array[Dictionary] = []
	for kind: String in SUCCESSFUL_DAY_EGGS:
		producers.append({"kind": kind})
	return ChickenDaySession.new(42, ProducerFlock.new(producers), IdentityShuffler.new())


func _early_success_session(tier := 0):
	var producers: Array[Dictionary] = []
	for egg_index in range(7):
		producers.append({"kind": "chicken", "tier": tier})
	return ChickenDaySession.new(42, ProducerFlock.new(producers), IdentityShuffler.new())


func _funded_early_shop_session(minimum_cash: int):
	var session = _early_success_session()
	while true:
		_complete_early_successful_day(session)
		if int(session.state().cash) >= minimum_cash:
			return session
		session.claim_bird_offer(0)
		session.leave_shop()


func _complete_successful_day(session) -> Array[Dictionary]:
	var final_events: Array[Dictionary] = []
	for circuit_id in EARLY_SUCCESS_PLAN:
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
