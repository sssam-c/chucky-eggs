extends GutTest

const ChickenDay = preload("res://src/domain/chicken_day.gd")


func test_tantrum_damages_only_the_spoons_that_fired_after_the_belt_moves() -> void:
	var day = ChickenDay.new(["chicken", "chicken", "chicken"], 99, 4)

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(day.snapshot().spoon_integrity, [3, 4, 3, 4, 4])
	assert_lt(_event_types(events).find("conveyor_advanced"), _event_types(events).find("grandma_tantrum_started"))
	assert_eq(_events_of_type(events, "spoon_damaged").map(
		func(event: Dictionary) -> int: return int(event.slot_index)
	), [0, 2])


func test_broken_spoons_do_not_fire_but_the_other_spoon_on_a_paired_circuit_can() -> void:
	var day = ChickenDay.new(["chicken", "chicken", "chicken", "chicken"], 99, 1)
	day.resolve_circuit("red")

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(events[0].type, "thwack_rejected")
	assert_eq(events[0].reason, "broken_circuit")


func test_shock_absorber_moves_under_a_fired_spoon_takes_the_hit_and_stuns_grandma() -> void:
	var day = ChickenDay.new(["shock_absorber", "chicken", "chicken"], 99, 4)

	var events: Array[Dictionary] = day.resolve_circuit("blue")

	assert_eq(day.snapshot().spoon_integrity, [4, 4, 4, 3, 4])
	assert_true(day.snapshot().grandma_stunned)
	assert_eq(_events_of_type(events, "shock_absorbed").size(), 1)
	assert_eq(_events_of_type(events, "shock_absorbed")[0].slot_index, 1)
	assert_eq(_events_of_type(events, "egg_damaged").filter(
		func(event: Dictionary) -> bool: return event.cause == "grandma_tantrum"
	).size(), 1)
	assert_eq(_events_of_type(events, "grandma_stunned").size(), 1)


func test_stun_skips_exactly_one_future_tantrum() -> void:
	var day = ChickenDay.new(["shock_absorber", "chicken", "chicken", "chicken"], 99, 4)
	day.resolve_circuit("blue")

	var skipped_events: Array[Dictionary] = day.resolve_circuit("pink")
	var resumed_events: Array[Dictionary] = day.resolve_circuit("pink")

	assert_eq(_events_of_type(skipped_events, "grandma_tantrum_skipped").size(), 1)
	assert_eq(_events_of_type(skipped_events, "spoon_damaged").size(), 0)
	assert_eq(_events_of_type(resumed_events, "spoon_damaged").size(), 1)
	assert_false(day.snapshot().grandma_stunned)


func _events_of_type(events: Array[Dictionary], event_type: String) -> Array[Dictionary]:
	var matching: Array[Dictionary] = []
	for event: Dictionary in events:
		if event.type == event_type:
			matching.append(event)
	return matching


func _event_types(events: Array[Dictionary]) -> Array[String]:
	var types: Array[String] = []
	for event: Dictionary in events:
		types.append(String(event.type))
	return types
