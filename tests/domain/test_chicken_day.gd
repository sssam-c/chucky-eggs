extends GutTest

const ChickenDay = preload("res://src/domain/chicken_day.gd")


func test_day_starts_with_one_chicken_and_a_three_egg_preview() -> void:
	var day = ChickenDay.new()
	var state: Dictionary = day.snapshot()

	assert_eq(state.remaining_thwacks, 20)
	assert_eq(state.score, 0)
	assert_false(state.ended)
	assert_eq(state.slots.size(), 5)
	assert_eq(state.slots[0].toughness, 4)
	assert_true(state.slots[1].is_empty())
	assert_eq(state.pipe.size(), 3)
	assert_eq(state.pipe[0].toughness, 4)


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
	assert_eq(state.slots[0].toughness, 4)
	assert_eq(state.slots[1].toughness, 3)
	assert_eq(state.pipe.size(), 3)


func test_four_thwacks_hatch_a_chicken_before_the_fourth_advance() -> void:
	var day = ChickenDay.new()

	day.resolve_thwack(0)
	day.resolve_thwack(1)
	day.resolve_thwack(2)
	var events: Array[Dictionary] = day.resolve_thwack(3)
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"egg_damaged",
		"egg_hatched",
		"conveyor_advanced",
		"thwack_spent",
		"egg_entered",
	])
	assert_eq(state.score, 1)
	assert_eq(state.remaining_thwacks, 16)
	assert_true(state.slots[4].is_empty())


func test_unhatched_egg_is_discarded_after_slot_five() -> void:
	var day = ChickenDay.new()

	for turn in range(5):
		var events: Array[Dictionary] = day.resolve_thwack(0)
		if turn == 4:
			assert_eq(_event_types(events), [
				"egg_damaged",
				"conveyor_advanced",
				"egg_discarded",
				"thwack_spent",
				"egg_entered",
			])
			assert_eq(events[2].reason, "belt_end")
			assert_eq(events[2].remaining_toughness, 3)


func test_empty_slot_request_is_rejected_without_spending_time() -> void:
	var day = ChickenDay.new()
	var before: Dictionary = day.snapshot()

	var events: Array[Dictionary] = day.resolve_thwack(1)

	assert_eq(_event_types(events), ["thwack_rejected"])
	assert_eq(events[0].reason, "empty_slot")
	assert_eq(day.snapshot(), before)


func test_twentieth_thwack_ends_day_and_discards_every_remaining_egg() -> void:
	var day = ChickenDay.new()

	for cycle in range(3):
		day.resolve_thwack(0)
		day.resolve_thwack(1)
		day.resolve_thwack(2)
		day.resolve_thwack(3)
	while day.snapshot().remaining_thwacks > 0:
		var final_events: Array[Dictionary] = day.resolve_thwack(0)
		if day.snapshot().ended:
			assert_eq(final_events[-1].type, "day_ended")

	var state: Dictionary = day.snapshot()
	assert_true(state.ended)
	assert_true(state.succeeded)
	assert_eq(state.score, 3)
	assert_eq(state.remaining_thwacks, 0)
	assert_true(state.slots.all(func(egg: Dictionary) -> bool: return egg.is_empty()))
	assert_true(state.pipe.is_empty())

	var rejected: Array[Dictionary] = day.resolve_thwack(0)
	assert_eq(_event_types(rejected), ["thwack_rejected"])
	assert_eq(rejected[0].reason, "day_ended")


func test_day_fails_below_three_points() -> void:
	var day = ChickenDay.new()

	for turn in range(20):
		day.resolve_thwack(0)

	var state: Dictionary = day.snapshot()
	assert_true(state.ended)
	assert_false(state.succeeded)
	assert_eq(state.score, 0)


func _event_types(events: Array[Dictionary]) -> Array[String]:
	var types: Array[String] = []
	for event: Dictionary in events:
		types.append(event.type)
	return types
