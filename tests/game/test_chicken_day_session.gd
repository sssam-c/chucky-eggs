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


func test_session_builds_a_five_egg_ten_thwack_day_from_the_starting_flock() -> void:
	var state: Dictionary = ChickenDaySession.new(42).state()

	assert_eq(state.day_number, 1)
	assert_eq(state.target_score, 8)
	assert_eq(state.cash, 0)
	assert_eq(state.last_cash_awarded, 0)
	assert_eq(state.producers.size(), 5)
	assert_eq(state.daily_egg_count, 5)
	assert_eq(state.hopper_egg_count, 4)
	assert_eq(state.pipe.size(), 3)
	assert_eq(state.starting_thwacks, 10)
	assert_eq(state.remaining_thwacks, 10)
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

	assert_eq(chicken_group.bird_count, 3)
	assert_eq(chicken_group.points, 3)
	assert_eq(chicken_group.double_yolk_chance, 0.02)
	assert_eq(chicken_group.display_double_yolk_percent, 2)
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
	assert_eq(state.remaining_thwacks, 10)

	session.submit_circuit("red")
	session.restart()

	assert_eq(session.state().day_number, 3)
	assert_eq(session.state().machine_slot_count, 5)
	assert_eq(session.state().remaining_thwacks, 10)


func test_session_is_the_request_pathway_and_returns_a_safe_snapshot() -> void:
	var session = ChickenDaySession.new()
	var exposed_state: Dictionary = session.state()
	exposed_state.remaining_thwacks = 2
	exposed_state.slots[0].toughness = 1

	var events: Array[Dictionary] = session.submit_circuit("red")
	var actual_state: Dictionary = session.state()

	assert_eq(events[0].type, "circuit_fired")
	assert_eq(actual_state.remaining_thwacks, 9)
	assert_eq(actual_state.slots[1].toughness, 2)


func test_restart_replaces_the_day_with_initial_state() -> void:
	var session = ChickenDaySession.new()
	session.submit_circuit("red")

	session.restart()

	assert_eq(session.state().remaining_thwacks, 10)
	assert_eq(session.state().slots[0].toughness, 3)


func test_success_opens_one_shop_with_deterministic_stock_and_bank_balance() -> void:
	var session = _successful_day_session()

	var final_events: Array[Dictionary] = _complete_successful_day(session)
	var state: Dictionary = session.state()
	var offered_kinds: Array = state.shop_stock.recruitment.map(
		func(choice: Dictionary) -> String: return choice.kind
	)

	assert_eq(state.phase, "shop")
	assert_eq(state.day_number, 1)
	assert_eq(state.next_day_target_score, 9)
	assert_eq(state.shop_stock.recruitment.size(), 3)
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
	assert_true(state.shop_stock.recruitment.all(func(offer: Dictionary) -> bool:
		return offer.price == 3
	))
	assert_eq(state.shop_stock.retirement.price, 2)
	assert_eq(state.shop_stock.pairing_sources.size(), 4)
	assert_true(state.shop_stock.pairing_sources.all(func(source: Dictionary) -> bool:
		return source.available_pair_count >= 1 and source.eligible_partners.size() == 1
	))
	var chicken_source: Dictionary = state.shop_stock.pairing_sources.filter(
		func(source: Dictionary) -> bool: return source.kind == "chicken" and source.tier == 0
	)[0]
	var chicken_merge: Dictionary = chicken_source.eligible_partners[0]
	assert_eq(chicken_merge.price, 1)
	assert_eq(chicken_merge.current_points, 3)
	assert_eq(chicken_merge.next_points, 4)
	assert_almost_eq(float(chicken_merge.next_exact_points), 4.5, 0.00001)
	assert_eq(chicken_merge.current_toughness, 3)
	assert_eq(chicken_merge.next_toughness, 5)
	assert_almost_eq(float(chicken_merge.next_exact_toughness), 4.5, 0.00001)
	assert_eq(chicken_merge.current_double_yolk_percent, 2)
	assert_eq(chicken_merge.next_double_yolk_percent, 3)
	assert_almost_eq(float(chicken_merge.next_double_yolk_chance), 0.03, 0.00001)
	assert_eq(state.shop_stock.factory_upgrades.size(), 1)
	assert_eq(final_events[-1].type, "cash_awarded")
	assert_gt(final_events[-1].amount, 0)
	assert_eq(final_events[-1].amount, final_events[-1].remaining_thwacks)
	assert_eq(final_events[-1].cash_total, final_events[-1].amount)


func test_pairing_catalog_lists_owned_groups_and_only_exact_match_partners() -> void:
	var session = _early_success_session()
	_complete_early_successful_day(session)

	var source: Dictionary = session.state().shop_stock.pairing_sources[0]

	assert_eq(source.kind, "chicken")
	assert_eq(source.tier, 0)
	assert_eq(source.available_count, 7)
	assert_eq(source.available_pair_count, 3)
	assert_eq(source.eligible_partners.size(), 1)
	assert_eq(source.eligible_partners[0].kind, "chicken")
	assert_eq(source.eligible_partners[0].tier, 0)
	assert_eq(source.eligible_partners[0].price, 1)

	assert_eq(session.queue_merge("chicken", 0)[0].type, "producer_merge_queued")

	source = session.state().shop_stock.pairing_sources[0]
	assert_eq(source.available_count, 5)
	assert_eq(source.available_pair_count, 2)
	assert_eq(source.eligible_partners.size(), 1)


func test_merge_fee_equals_output_tier_and_is_charged_once_when_queued() -> void:
	var standard_session = _early_success_session()
	_complete_early_successful_day(standard_session)
	var standard_cash_before: int = standard_session.state().cash

	var standard_events: Array[Dictionary] = standard_session.queue_merge("chicken", 0)

	assert_eq(standard_events[0].price, 1)
	assert_eq(standard_events[0].cash_total, standard_cash_before - 1)
	assert_eq(standard_session.state().cash, standard_cash_before - 1)

	var prize_producers: Array[Dictionary] = []
	for kind: String in SUCCESSFUL_DAY_EGGS:
		prize_producers.append({"kind": kind})
	prize_producers.append_array([
		{"kind": "chicken", "tier": 1},
		{"kind": "chicken", "tier": 1},
	])
	var prize_session = ChickenDaySession.new(
		42, ProducerFlock.new(prize_producers), IdentityShuffler.new()
	)
	_complete_successful_day(prize_session)
	var prize_cash_before: int = prize_session.state().cash

	var prize_events: Array[Dictionary] = prize_session.queue_merge("chicken", 1)

	assert_eq(prize_events[0].price, 2)
	assert_eq(prize_events[0].cash_total, prize_cash_before - 2)
	assert_eq(prize_session.state().cash, prize_cash_before - 2)


func test_unaffordable_merge_is_rejected_without_cash_or_pair_reservation() -> void:
	var session = _early_success_session()
	_complete_early_successful_day(session)
	assert_eq(session.purchase_retirement("chicken")[0].type, "producer_retired")
	var before: Dictionary = session.state()

	var events: Array[Dictionary] = session.queue_merge("chicken", 0)

	assert_eq(events[0].type, "shop_purchase_rejected")
	assert_eq(events[0].reason, "insufficient_cash")
	assert_eq(session.state(), before)


func test_success_banks_one_pound_per_remaining_thwack_exactly_once() -> void:
	var session = _early_success_session()

	var final_events: Array[Dictionary] = _complete_early_successful_day(session)

	assert_eq(final_events.map(func(event: Dictionary) -> String: return event.type).slice(-3), [
		"day_remainder_discarded", "day_ended", "cash_awarded",
	])
	assert_eq(final_events[-2].remaining_thwacks, 2)
	assert_eq(final_events[-1], {
		"type": "cash_awarded",
		"amount": 2,
		"cash_total": 2,
		"remaining_thwacks": 2,
	})
	assert_eq(session.state().cash, 2)
	assert_eq(session.state().last_cash_awarded, 2)

	assert_eq(session.submit_circuit("red"), [{"type": "thwack_rejected", "reason": "wrong_phase"}])
	assert_eq(session.state().cash, 2)


func test_shop_allows_multiple_saved_cash_purchases_then_leave() -> void:
	var session = _funded_early_shop_session(6)
	var before: Dictionary = session.state()
	var recruited_kind := String(before.shop_stock.recruitment[0].kind)

	var recruit_events: Array[Dictionary] = session.purchase_producer(recruited_kind)
	var merge_events: Array[Dictionary] = session.queue_merge("chicken", 0)
	var retire_events: Array[Dictionary] = session.purchase_retirement("chicken")
	var after_purchases: Dictionary = session.state()

	assert_eq(recruit_events[0].type, "producer_purchased")
	assert_eq(merge_events[0].type, "producer_merge_queued")
	assert_eq(retire_events[0].type, "producer_retired")
	assert_eq(after_purchases.phase, "shop")
	assert_eq(after_purchases.cash, before.cash - 6)
	assert_eq(after_purchases.producers.size(), before.producers.size())
	assert_eq(after_purchases.projected_flock_size, before.producers.size() - 1)
	assert_eq(after_purchases.pending_merges, [{"kind": "chicken", "tier": 0, "pair_count": 1}])

	var day_events: Array[Dictionary] = session.leave_shop()
	var day_two: Dictionary = session.state()

	assert_eq(day_events.map(func(event: Dictionary) -> String: return event.type), [
		"producer_merged", "day_started",
	])
	assert_eq(day_events[0].producer, {"kind": "chicken", "tier": 1})
	assert_eq(day_events[1].production.size(), day_two.producers.size())
	assert_eq(day_two.phase, "day")
	assert_eq(day_two.day_number, before.day_number + 1)
	assert_eq(day_two.cash, before.cash - 6)
	assert_eq(day_two.machine_slot_count, 5)
	assert_true(day_two.slots.all(func(egg: Dictionary) -> bool:
		return egg.is_empty() or egg.tier != 1 or (
			egg.points == 4 and is_equal_approx(egg.double_yolk_chance, 0.03)
		)
	))


func test_shop_rejects_unaffordable_invalid_and_duplicate_purchases_without_mutation() -> void:
	var session = _funded_early_shop_session(5)

	var factory_events: Array[Dictionary] = session.purchase_factory_upgrade("extra_thwack")
	var after_factory: Dictionary = session.state()
	assert_eq(factory_events[0].type, "factory_upgrade_purchased")
	assert_eq(after_factory.starting_thwacks, 11)

	var duplicate: Array[Dictionary] = session.purchase_factory_upgrade("extra_thwack")
	var unavailable_merge: Array[Dictionary] = session.queue_merge("spoonbill", 0)
	var unstocked: Array[Dictionary] = session.purchase_producer("dragon")

	assert_eq(duplicate[0].reason, "not_available")
	assert_eq(unavailable_merge[0].reason, "not_available")
	assert_eq(unstocked[0].reason, "not_offered")
	assert_eq(session.state(), after_factory)


func test_queued_outputs_cannot_chain_merge_until_a_later_shop() -> void:
	var session = _early_success_session()
	_complete_early_successful_day(session)

	assert_eq(session.queue_merge("chicken", 0)[0].type, "producer_merge_queued")
	var blocked: Array[Dictionary] = session.queue_merge("chicken", 1)
	var state: Dictionary = session.state()

	assert_eq(blocked[0].reason, "not_available")
	assert_eq(state.producers.size(), 7)
	assert_eq(state.projected_flock_size, 6)
	assert_eq(state.pending_merges[0].pair_count, 1)
	var chicken_source: Dictionary = state.shop_stock.pairing_sources.filter(
		func(source: Dictionary) -> bool: return source.kind == "chicken" and source.tier == 0
	)[0]
	assert_eq(chicken_source.available_count, 5)
	assert_eq(chicken_source.eligible_partners.size(), 1)


func test_every_day_keeps_the_single_five_slot_track() -> void:
	var session = _successful_day_session()
	_complete_successful_day(session)
	var day_two_events: Array[Dictionary] = session.leave_shop()
	assert_eq(day_two_events.map(func(event: Dictionary) -> String: return event.type), ["day_started"])
	assert_eq(session.state().machine_slot_count, 5)

	_complete_successful_day(session)

	var shop: Dictionary = session.state()
	assert_eq(shop.phase, "shop")
	assert_eq(shop.day_number, 2)
	var cash_before_day_three: int = shop.cash

	var day_events: Array[Dictionary] = session.leave_shop()

	assert_eq(day_events.map(func(event: Dictionary) -> String: return event.type), ["day_started"])
	assert_eq(day_events[0].day_number, 3)
	assert_eq(day_events[0].slot_count, 5)
	assert_eq(session.state().slots.size(), 5)
	assert_eq(session.state().cash, cash_before_day_three)


func test_banked_cash_persists_into_day_two() -> void:
	var session = _early_success_session()
	_complete_early_successful_day(session)
	session.leave_shop()

	assert_eq(session.state().day_number, 2)
	assert_eq(session.state().cash, 2)
	assert_eq(session.state().last_cash_awarded, 0)


func test_failed_day_two_awards_nothing_and_retry_preserves_banked_cash() -> void:
	var day_one_only_flock: Array[Dictionary] = [
		{"kind": "chicken"}, {"kind": "chicken"},
		{"kind": "cuckoo"}, {"kind": "cuckoo"},
	]
	var session = ChickenDaySession.new(
		42, ProducerFlock.new(day_one_only_flock), IdentityShuffler.new()
	)
	for circuit_id in [
		"red", "red", "red", "red", "blue", "red", "red", "red", "red", "red",
	]:
		session.submit_circuit(circuit_id)
		if session.state().phase != "day":
			break
	assert_true(session.state().succeeded)
	var banked_cash := int(session.state().cash)
	session.leave_shop()
	var final_events: Array[Dictionary] = []

	while session.state().phase == "day":
		var state: Dictionary = session.state()
		var circuit_id := "pink" if not state.slots[4].is_empty() else (
			"red" if not state.slots[0].is_empty() or not state.slots[2].is_empty()
			else "blue"
		)
		final_events = session.submit_circuit(circuit_id)

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
	session.leave_shop()
	session.submit_circuit("red")

	session.restart()

	assert_eq(session.state().day_number, 2)
	assert_eq(session.state().target_score, 9)
	assert_eq(session.state().score, 0)
	assert_eq(session.state().remaining_thwacks, 10)


func test_unoffered_producer_cannot_be_purchased() -> void:
	var session = _successful_day_session()
	_complete_successful_day(session)
	var before: Dictionary = session.state()
	var unoffered_kind := ""
	for kind in ["chicken", "cuckoo", "plover", "spoonbill"]:
		if not before.shop_stock.recruitment.any(
			func(choice: Dictionary) -> bool: return choice.kind == kind
		):
			unoffered_kind = kind

	var events: Array[Dictionary] = session.purchase_producer(unoffered_kind)

	assert_eq(events[0].type, "shop_purchase_rejected")
	assert_eq(events[0].reason, "not_offered")
	assert_eq(session.state(), before)


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
		session.leave_shop()


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
