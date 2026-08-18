extends GutTest

const ChickenDay = preload("res://src/domain/chicken_day.gd")


func test_moving_the_belt_spends_one_condition_after_movement() -> void:
	var day = ChickenDay.new(["chicken", "chicken"], 99, 12)

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(day.snapshot().belt_condition, 11)
	assert_eq(_events_of_type(events, "belt_condition_spent"), [{
		"type": "belt_condition_spent",
		"amount": 1,
		"movement_steps": 1,
		"remaining_condition": 11,
		"maximum_condition": 12,
	}])
	assert_lt(
		_event_types(events).find("conveyor_advanced"),
		_event_types(events).find("belt_condition_spent")
	)


func test_shockwave_strikes_do_not_spend_additional_belt_condition() -> void:
	var shockwave_sparrow := {
		"kind": "sparrow",
		"effects": [{"type": "shockwave"}],
	}
	var day = ChickenDay.new([shockwave_sparrow], 99, 12)

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(_events_of_type(events, "shockwave_fired").size(), 1)
	assert_eq(_events_of_type(events, "belt_condition_spent").size(), 1)
	assert_eq(day.snapshot().belt_condition, 11)


func test_zero_condition_fails_after_the_complete_movement() -> void:
	var eggs: Array[String] = []
	eggs.resize(12)
	eggs.fill("chicken")
	var day = ChickenDay.new(eggs, 99, 1)

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(day.snapshot().belt_condition, 0)
	assert_true(day.snapshot().ended)
	assert_false(day.snapshot().succeeded)
	assert_eq(_event_types(events).slice(-2), ["day_remainder_discarded", "day_ended"])
	assert_eq(events[-1].belt_condition, 0)


func test_success_at_zero_condition_takes_precedence() -> void:
	var day = ChickenDay.new(["sparrow"], 1, 1)

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(day.snapshot().belt_condition, 0)
	assert_true(day.snapshot().succeeded)
	assert_true(events[-1].succeeded)


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
