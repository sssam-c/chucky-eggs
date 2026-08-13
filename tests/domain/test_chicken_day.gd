extends GutTest

const ChickenDay = preload("res://src/domain/chicken_day.gd")
const AUTHORED_PATTERN: Array[String] = [
	"chicken", "cuckoo", "chicken", "spoonbill",
	"cuckoo", "plover", "chicken", "chicken",
]


func test_plover_is_a_four_point_high_commitment_egg() -> void:
	assert_eq(ChickenDay.PLOVER_TOUGHNESS, 6)
	assert_eq(ChickenDay.PLOVER_POINTS, 4)


func test_finite_daily_pool_exposes_only_the_next_three_eggs() -> void:
	var state: Dictionary = ChickenDay.new([
		"chicken", "cuckoo", "plover", "chicken", "cuckoo",
	]).snapshot()

	assert_eq(state.slots[0].kind, "chicken")
	assert_eq(state.pipe.map(func(egg: Dictionary) -> String: return egg.kind), [
		"cuckoo", "plover", "chicken",
	])
	assert_eq(state.hopper_egg_count, 4)


func test_day_ends_when_the_finite_pool_and_conveyor_are_empty() -> void:
	var day = ChickenDay.new(["chicken"])
	var final_events: Array[Dictionary] = []

	for circuit_id in ["red", "blue", "red"]:
		final_events = day.resolve_circuit(circuit_id)

	var state: Dictionary = day.snapshot()
	assert_true(state.ended)
	assert_eq(state.remaining_thwacks, 17)
	assert_true(state.pipe.is_empty())
	assert_true(state.slots.all(func(egg: Dictionary) -> bool: return egg.is_empty()))
	assert_eq(_event_types(final_events).slice(-3), [
		"thwack_spent", "day_remainder_discarded", "day_ended",
	])
	assert_eq(final_events[-1].remaining_thwacks, 17)


func test_day_exposes_the_three_fixed_spoon_circuits() -> void:
	var state: Dictionary = _new_authored_day().snapshot()

	assert_eq(state.circuits, [
		{"id": "red", "slot_indices": [0, 2]},
		{"id": "blue", "slot_indices": [1, 3]},
		{"id": "pink", "slot_indices": [4]},
	])
	assert_eq(state.slots[0].kind, "chicken")
	assert_eq(state.slots[0].toughness, 3)
	assert_eq(state.pipe.map(func(egg: Dictionary) -> String: return egg.kind), [
		"cuckoo", "chicken", "spoonbill",
	])
	assert_eq(state.pipe[2].toughness, 5)
	assert_eq(state.pipe[2].points, 4)


func test_red_fires_slots_one_and_three_and_wastes_the_empty_strike() -> void:
	var day = _new_authored_day()

	var events: Array[Dictionary] = day.resolve_circuit("red")
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"circuit_fired",
		"egg_damaged",
		"conveyor_advanced",
		"thwack_spent",
		"egg_entered",
	])
	assert_eq(events[0].circuit_id, "red")
	assert_eq(events[0].slot_indices, [0, 2])
	assert_eq(events[0].occupied_slot_indices, [0])
	assert_eq(events[1].slot_index, 0)
	assert_eq(events[1].damage_amount, 1)
	assert_eq(state.remaining_thwacks, 19)
	assert_eq(state.slots[1].kind, "chicken")
	assert_eq(state.slots[1].toughness, 2)


func test_circuit_is_rejected_only_when_all_of_its_slots_are_empty() -> void:
	var day = _new_authored_day()
	var before: Dictionary = day.snapshot()

	var events: Array[Dictionary] = day.resolve_circuit("blue")

	assert_eq(_event_types(events), ["thwack_rejected"])
	assert_eq(events[0].reason, "empty_circuit")
	assert_eq(day.snapshot(), before)


func test_unknown_circuit_is_rejected_without_spending_time() -> void:
	var day = _new_authored_day()
	var before: Dictionary = day.snapshot()

	var events: Array[Dictionary] = day.resolve_circuit("green")

	assert_eq(_event_types(events), ["thwack_rejected"])
	assert_eq(events[0].reason, "invalid_circuit")
	assert_eq(day.snapshot(), before)


func test_red_damages_both_occupied_slots_before_a_cuckoo_between_them_echoes_twice() -> void:
	var day = _new_authored_day()
	day.resolve_circuit("red")
	day.resolve_circuit("blue")

	var events: Array[Dictionary] = day.resolve_circuit("red")
	var damage_events := events.filter(
		func(event: Dictionary) -> bool: return event.type == "egg_damaged"
	)

	assert_eq(_event_types(events).slice(0, 7), [
		"circuit_fired",
		"egg_damaged",
		"egg_damaged",
		"egg_damaged",
		"egg_damaged",
		"egg_hatched",
		"conveyor_advanced",
	])
	assert_eq(damage_events.map(func(event: Dictionary) -> int: return event.slot_index), [0, 2, 1, 1])
	assert_eq(damage_events.map(func(event: Dictionary) -> String: return event.cause), [
		"spoon", "spoon", "cuckoo_echo", "cuckoo_echo",
	])
	assert_eq(damage_events[2].source_slot_index, 0)
	assert_eq(damage_events[3].source_slot_index, 2)
	assert_eq(damage_events[3].remaining_toughness, 1)


func test_complete_paired_damage_batch_precedes_conveyor_ordered_hatches() -> void:
	var day = _new_authored_day()
	day.resolve_circuit("red")
	day.resolve_circuit("blue")
	var events: Array[Dictionary] = day.resolve_circuit("red")

	var last_damage_index := -1
	var first_hatch_index := events.size()
	for event_index in range(events.size()):
		if events[event_index].type == "egg_damaged":
			last_damage_index = event_index
		if events[event_index].type == "egg_hatched":
			first_hatch_index = mini(first_hatch_index, event_index)

	assert_gt(first_hatch_index, last_damage_index)
	var hatches := events.filter(func(event: Dictionary) -> bool: return event.type == "egg_hatched")
	assert_eq(hatches.size(), 1)
	assert_eq(hatches[0].kind, "chicken")


func test_pink_deals_two_damage_to_a_spoonbill_in_slot_five() -> void:
	var day = _new_authored_day()
	for circuit_id in ["red", "blue", "red", "red", "blue", "red", "pink"]:
		day.resolve_circuit(circuit_id)
	assert_eq(day.snapshot().slots[4].kind, "spoonbill")
	assert_eq(day.snapshot().slots[4].toughness, 2)

	var events: Array[Dictionary] = day.resolve_circuit("pink")
	var damage_events := events.filter(
		func(event: Dictionary) -> bool: return event.type == "egg_damaged"
	)
	var hatches := events.filter(
		func(event: Dictionary) -> bool: return event.type == "egg_hatched"
	)

	assert_eq(events[0].slot_indices, [4])
	assert_eq(damage_events[0].slot_index, 4)
	assert_eq(damage_events[0].kind, "spoonbill")
	assert_eq(damage_events[0].cause, "spoon")
	assert_eq(damage_events[0].damage_amount, 2)
	assert_eq(damage_events[0].remaining_toughness, 0)
	assert_true(hatches.any(func(event: Dictionary) -> bool:
		return event.kind == "spoonbill" and event.points_awarded == 4
	))


func test_cuckoo_copies_the_full_two_damage_from_a_pink_struck_spoonbill() -> void:
	var day = _new_authored_day()
	for circuit_id in ["red", "blue", "red", "red", "blue", "red", "pink"]:
		day.resolve_circuit(circuit_id)
	assert_eq(day.snapshot().slots[3].kind, "cuckoo")
	assert_eq(day.snapshot().slots[4].kind, "spoonbill")

	var events: Array[Dictionary] = day.resolve_circuit("pink")
	var damage_events := events.filter(
		func(event: Dictionary) -> bool: return event.type == "egg_damaged"
	)

	assert_eq(damage_events.map(func(event: Dictionary) -> String: return event.kind), [
		"spoonbill", "cuckoo",
	])
	assert_eq(damage_events.map(func(event: Dictionary) -> int: return event.damage_amount), [2, 2])
	assert_eq(damage_events[1].cause, "cuckoo_echo")
	assert_eq(damage_events[1].source_slot_index, 4)
	assert_eq(damage_events[1].remaining_toughness, 0)


func test_pink_still_rescues_a_surviving_plover_once() -> void:
	var day = _new_authored_day()
	for turn in range(7):
		day.resolve_circuit("red")
	day.resolve_circuit("blue")
	day.resolve_circuit("red")
	assert_eq(day.snapshot().slots[4].kind, "plover")
	assert_eq(day.snapshot().slots[4].toughness, 5)

	var events: Array[Dictionary] = day.resolve_circuit("pink")
	var state: Dictionary = day.snapshot()
	var swaps := events.filter(
		func(event: Dictionary) -> bool: return event.type == "eggs_swapped"
	)

	assert_eq(swaps.size(), 1)
	assert_eq(swaps[0].from_slot_index, 4)
	assert_eq(swaps[0].to_slot_index, 3)
	assert_eq(state.slots[4].kind, "plover")
	assert_eq(state.slots[4].toughness, 4)


func test_unhatched_egg_is_discarded_after_slot_five() -> void:
	var day = _new_authored_day()
	var final_events: Array[Dictionary] = []

	for turn in range(5):
		final_events = day.resolve_circuit("red")

	var discarded := final_events.filter(
		func(event: Dictionary) -> bool: return event.type == "egg_discarded"
	)
	assert_eq(discarded.size(), 1)
	assert_eq(discarded[0].reason, "belt_end")
	assert_eq(discarded[0].remaining_toughness, 1)


func test_twentieth_valid_circuit_ends_day_and_rejects_further_requests() -> void:
	var day = _new_authored_day()

	for turn in range(20):
		var events: Array[Dictionary] = day.resolve_circuit("red")
		assert_ne(events[0].type, "thwack_rejected")

	var state: Dictionary = day.snapshot()
	assert_true(state.ended)
	assert_eq(state.remaining_thwacks, 0)
	assert_true(state.slots.all(func(egg: Dictionary) -> bool: return egg.is_empty()))
	assert_true(state.pipe.is_empty())
	var rejected: Array[Dictionary] = day.resolve_circuit("red")
	assert_eq(rejected[0].reason, "day_ended")


func test_day_succeeds_at_fifteen_or_more_points() -> void:
	var chicken_pool: Array[String] = []
	chicken_pool.resize(24)
	chicken_pool.fill("chicken")
	var day = ChickenDay.new(chicken_pool)
	var circuit_plan := [
		"red", "red", "red", "blue", "red", "red", "red", "blue", "blue", "pink", "pink",
	]
	var final_events: Array[Dictionary] = []

	for circuit_id in circuit_plan:
		final_events = day.resolve_circuit(circuit_id)
		assert_ne(final_events[0].type, "thwack_rejected")

	assert_true(day.snapshot().ended)
	assert_true(day.snapshot().succeeded)
	assert_eq(day.snapshot().target_score, 15)
	assert_gte(day.snapshot().score, 15)
	assert_eq(day.snapshot().remaining_thwacks, 9)
	assert_eq(_event_types(final_events).slice(-3), [
		"thwack_spent", "day_remainder_discarded", "day_ended",
	])
	assert_false(_event_types(final_events).has("egg_entered"))
	assert_gt(final_events[-2].discarded_count, 0)


func test_day_fails_below_its_target() -> void:
	var spoonbill_pool: Array[String] = []
	spoonbill_pool.resize(24)
	spoonbill_pool.fill("spoonbill")
	var day = ChickenDay.new(spoonbill_pool, 20)
	var final_events: Array[Dictionary] = []

	for turn in range(20):
		final_events = day.resolve_circuit("red")

	assert_true(day.snapshot().ended)
	assert_false(day.snapshot().succeeded)
	assert_eq(day.snapshot().target_score, 20)
	assert_lt(day.snapshot().score, 20)
	var day_ended: Dictionary = final_events.filter(
		func(event: Dictionary) -> bool: return event.type == "day_ended"
	)[0]
	assert_eq(day_ended.target_score, 20)
	assert_eq(day_ended.remaining_thwacks, 0)


func _event_types(events: Array[Dictionary]) -> Array[String]:
	var types: Array[String] = []
	for event: Dictionary in events:
		types.append(event.type)
	return types


func _new_authored_day():
	var daily_eggs: Array[String] = []
	for egg_index in range(24):
		daily_eggs.append(AUTHORED_PATTERN[egg_index % AUTHORED_PATTERN.size()])
	return ChickenDay.new(daily_eggs)
