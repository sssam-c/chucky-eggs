extends GutTest

const ChickenDay = preload("res://src/domain/chicken_day.gd")


func test_day_starts_with_an_authored_chicken_cuckoo_and_plover_queue() -> void:
	var day = ChickenDay.new()
	var state: Dictionary = day.snapshot()

	assert_eq(state.remaining_thwacks, 20)
	assert_eq(state.score, 0)
	assert_eq(state.target_score, 10)
	assert_false(state.ended)
	assert_eq(state.slots.size(), 5)
	assert_eq(state.slots[0].kind, "chicken")
	assert_eq(state.slots[0].toughness, 4)
	assert_eq(state.slots[0].points, 3)
	assert_true(state.slots[1].is_empty())
	assert_eq(state.pipe.size(), 3)
	assert_eq(state.pipe[0].kind, "cuckoo")
	assert_eq(state.pipe[0].points, 1)
	assert_eq(state.pipe[1].kind, "chicken")
	assert_eq(state.pipe[2].kind, "plover")
	assert_eq(state.pipe[2].points, 2)
	assert_eq(state.pipe[0].toughness, 4)
	assert_eq(state.pipe[2].toughness, 6)
	assert_eq(state.pipe[2].max_toughness, 6)


func test_thwack_damages_the_target_then_advances_and_refills_once() -> void:
	var day = ChickenDay.new()

	var events: Array[Dictionary] = day.resolve_thwack(0)
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"egg_damaged",
		"conveyor_advanced",
		"thwack_spent",
		"egg_entered",
	])
	assert_eq(state.remaining_thwacks, 19)
	assert_eq(state.slots[0].kind, "cuckoo")
	assert_eq(state.slots[0].toughness, 4)
	assert_eq(state.slots[1].toughness, 3)
	assert_eq(state.pipe.size(), 3)


func test_cuckoo_echoes_once_when_another_egg_is_damaged() -> void:
	var day = ChickenDay.new()
	day.resolve_thwack(0)

	var events: Array[Dictionary] = day.resolve_thwack(1)
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"egg_damaged",
		"egg_damaged",
		"conveyor_advanced",
		"thwack_spent",
		"egg_entered",
	])
	assert_eq(events[0].cause, "spoon")
	assert_eq(events[0].kind, "chicken")
	assert_eq(events[1].cause, "cuckoo_echo")
	assert_eq(events[1].kind, "cuckoo")
	assert_eq(events[1].source_slot_index, 1)
	assert_eq(state.slots[1].kind, "cuckoo")
	assert_eq(state.slots[1].toughness, 3)
	assert_eq(state.slots[2].kind, "chicken")
	assert_eq(state.slots[2].toughness, 2)


func test_cuckoo_does_not_echo_damage_from_a_non_adjacent_egg() -> void:
	var day = ChickenDay.new()
	day.resolve_thwack(0)
	day.resolve_thwack(0)
	day.resolve_thwack(0)

	var events: Array[Dictionary] = day.resolve_thwack(0)
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"egg_damaged",
		"conveyor_advanced",
		"thwack_spent",
		"egg_entered",
	])
	assert_eq(state.slots[3].kind, "cuckoo")
	assert_eq(state.slots[3].toughness, 2)


func test_damage_batch_completes_before_hatches_resolve_in_conveyor_order() -> void:
	var day = ChickenDay.new()

	day.resolve_thwack(0)
	day.resolve_thwack(0)
	day.resolve_thwack(2)
	day.resolve_thwack(3)
	var events: Array[Dictionary] = day.resolve_thwack(4)
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"egg_damaged",
		"egg_damaged",
		"egg_hatched",
		"egg_hatched",
		"conveyor_advanced",
		"thwack_spent",
		"egg_entered",
	])
	assert_eq(events[0].cause, "spoon")
	assert_eq(events[1].cause, "cuckoo_echo")
	assert_eq(events[2].kind, "cuckoo")
	assert_eq(events[3].kind, "chicken")
	assert_eq(state.score, 4)
	assert_eq(state.remaining_thwacks, 15)
	assert_true(state.slots[4].is_empty())


func test_surviving_plover_swaps_backward_before_the_conveyor_advances() -> void:
	var day = ChickenDay.new()
	_advance_plover_to_second_slot(day)

	var events: Array[Dictionary] = day.resolve_thwack(1)
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"egg_damaged",
		"eggs_swapped",
		"conveyor_advanced",
		"egg_discarded",
		"thwack_spent",
		"egg_entered",
	])
	assert_eq(events[1].from_slot_index, 1)
	assert_eq(events[1].to_slot_index, 0)
	assert_eq(events[1].kind, "plover")
	assert_eq(events[1].slots[0].kind, "plover")
	assert_eq(events[1].slots[1].kind, "chicken")
	assert_eq(state.slots[1].kind, "plover")
	assert_eq(state.slots[1].toughness, 5)
	assert_eq(state.slots[2].kind, "chicken")


func test_plover_in_the_first_slot_cannot_swap_backward() -> void:
	var day = ChickenDay.new()
	day.resolve_thwack(0)
	day.resolve_thwack(1)
	day.resolve_thwack(0)

	var events: Array[Dictionary] = day.resolve_thwack(0)
	var state: Dictionary = day.snapshot()

	assert_false(_event_types(events).has("eggs_swapped"))
	assert_eq(state.slots[1].kind, "plover")
	assert_eq(state.slots[1].toughness, 5)


func test_plover_hatches_before_it_can_swap_backward() -> void:
	var day = ChickenDay.new()
	_advance_plover_to_second_slot(day)
	for hit_index in range(5):
		day.resolve_thwack(1)

	var events: Array[Dictionary] = day.resolve_thwack(1)
	var hatches := events.filter(func(event: Dictionary) -> bool: return event.type == "egg_hatched")

	assert_eq(events[0].type, "egg_damaged")
	assert_eq(events[0].kind, "plover")
	assert_eq(hatches.size(), 1)
	assert_eq(hatches[0].kind, "plover")
	assert_eq(hatches[0].points_awarded, 2)
	assert_false(_event_types(events).has("eggs_swapped"))


func test_unhatched_egg_is_discarded_after_slot_five() -> void:
	var day = ChickenDay.new()

	for turn in range(5):
		var events: Array[Dictionary] = day.resolve_thwack(0)
		if turn == 4:
			var discarded := events.filter(func(event: Dictionary) -> bool: return event.type == "egg_discarded")
			assert_eq(discarded.size(), 1)
			assert_eq(discarded[0].reason, "belt_end")
			assert_eq(discarded[0].remaining_toughness, 3)


func test_empty_slot_request_is_rejected_without_spending_time() -> void:
	var day = ChickenDay.new()
	var before: Dictionary = day.snapshot()

	var events: Array[Dictionary] = day.resolve_thwack(1)

	assert_eq(_event_types(events), ["thwack_rejected"])
	assert_eq(events[0].reason, "empty_slot")
	assert_eq(day.snapshot(), before)


func test_twentieth_thwack_ends_day_and_discards_every_remaining_egg() -> void:
	var day = ChickenDay.new()

	while day.snapshot().remaining_thwacks > 0:
		var final_events: Array[Dictionary] = day.resolve_thwack(0)
		if day.snapshot().ended:
			assert_eq(final_events[-1].type, "day_ended")

	var state: Dictionary = day.snapshot()
	assert_true(state.ended)
	assert_eq(state.remaining_thwacks, 0)
	assert_true(state.slots.all(func(egg: Dictionary) -> bool: return egg.is_empty()))
	assert_true(state.pipe.is_empty())

	var rejected: Array[Dictionary] = day.resolve_thwack(0)
	assert_eq(_event_types(rejected), ["thwack_rejected"])
	assert_eq(rejected[0].reason, "day_ended")


func test_day_fails_below_ten_points() -> void:
	var day = ChickenDay.new()

	for turn in range(20):
		day.resolve_thwack(0)

	var state: Dictionary = day.snapshot()
	assert_true(state.ended)
	assert_false(state.succeeded)
	assert_lt(state.score, 10)


func test_day_succeeds_at_ten_or_more_points() -> void:
	var day = ChickenDay.new()
	var winning_slots := [0, 1, 2, 0, 4, 2, 3, 4, 0, 1, 2, 0, 4, 2, 3, 4, 0, 1, 2, 3]

	for slot_index: int in winning_slots:
		var events: Array[Dictionary] = day.resolve_thwack(slot_index)
		assert_ne(events[0].type, "thwack_rejected")

	var state: Dictionary = day.snapshot()
	assert_true(state.ended)
	assert_true(state.succeeded)
	assert_gte(state.score, 10)


func _event_types(events: Array[Dictionary]) -> Array[String]:
	var types: Array[String] = []
	for event: Dictionary in events:
		types.append(event.type)
	return types


func _advance_plover_to_second_slot(day) -> void:
	day.resolve_thwack(0)
	day.resolve_thwack(1)
	day.resolve_thwack(0)
	day.resolve_thwack(3)
