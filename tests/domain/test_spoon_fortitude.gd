extends GutTest

const ChickenDay = preload("res://src/domain/chicken_day.gd")


func test_each_physical_impact_wears_its_spoon_before_the_belt_moves() -> void:
	var day = ChickenDay.new(["chicken", "chicken"], 99, 4)

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(day.snapshot().spoon_integrity, [3, 4, 3, 4, 4])
	assert_eq(_events_of_type(events, "spoon_worn").map(
		func(event: Dictionary) -> int: return int(event.slot_index)
	), [0, 2])
	assert_lt(_event_types(events).find("spoon_worn"), _event_types(events).find("conveyor_advanced"))
	assert_eq(_events_of_type(events, "spoon_worn")[1].struck_egg, false)


func test_broken_spoons_do_not_fire_but_the_other_spoon_on_a_paired_circuit_can() -> void:
	var day = ChickenDay.new(["chicken", "chicken", "chicken", "chicken"], 99, 1)
	day.resolve_circuit("red")

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(events[0].type, "thwack_rejected")
	assert_eq(events[0].reason, "broken_circuit")


func test_soft_shelled_egg_takes_normal_damage_and_prevents_only_its_striking_spoons_wear() -> void:
	var day = ChickenDay.new(["soft_shelled", "chicken", "chicken"], 99, 4)

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(day.snapshot().spoon_integrity, [4, 4, 3, 4, 4])
	assert_eq(_events_of_type(events, "egg_damaged")[0].damage_amount, 1)
	assert_eq(_events_of_type(events, "egg_damaged")[0].remaining_toughness, 2)
	assert_eq(_events_of_type(events, "spoon_wear_prevented").size(), 1)
	assert_eq(_events_of_type(events, "spoon_wear_prevented")[0].slot_index, 0)
	assert_eq(_events_of_type(events, "spoon_wear_prevented")[0].reason, "soft_shelled")
	assert_eq(_events_of_type(events, "spoon_worn")[0].slot_index, 2)


func test_shockwave_uses_adjacent_intact_spoons_and_wears_them_on_empty_bays() -> void:
	var shockwave_sparrow := {
		"kind": "sparrow",
		"effects": [{"type": "shockwave"}],
	}
	var day = ChickenDay.new([shockwave_sparrow], 99, 1)

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(_events_of_type(events, "shockwave_fired")[0].slot_indices, [1])
	assert_eq(day.snapshot().spoon_integrity, [0, 0, 0, 1, 1])
	assert_eq(_events_of_type(events, "spoon_worn").map(
		func(event: Dictionary) -> int: return int(event.slot_index)
	), [0, 2, 1])
	assert_eq(_events_of_type(events, "spoon_worn")[2].cause, "shockwave")
	assert_eq(_events_of_type(events, "spoon_worn")[2].struck_egg, false)


func test_shockwave_skips_an_adjacent_broken_spoon() -> void:
	var shockwave_sparrow := {
		"kind": "sparrow",
		"effects": [{"type": "shockwave"}],
	}
	var day = ChickenDay.new([
		"chicken", "chicken", "chicken", "chicken", "chicken", shockwave_sparrow,
	], 99, 1)
	day.resolve_circuit("blue")

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(_events_of_type(events, "shockwave_fired")[0].slot_indices, [])
	assert_eq(_events_of_type(events, "spoon_worn").map(
		func(event: Dictionary) -> int: return int(event.slot_index)
	), [0, 2])


func test_soft_shelled_also_prevents_wear_from_a_shockwave_spoon() -> void:
	var shockwave_sparrow := {
		"kind": "sparrow",
		"effects": [{"type": "shockwave"}],
	}
	var day = ChickenDay.new([
		"soft_shelled", "chicken", "chicken", "chicken", "chicken", shockwave_sparrow,
	], 99, 4)
	day.resolve_circuit("blue")

	var events: Array[Dictionary] = day.resolve_circuit("red")
	var prevention_events := _events_of_type(events, "spoon_wear_prevented")

	assert_eq(prevention_events.size(), 1)
	assert_eq(prevention_events[0].slot_index, 1)
	assert_eq(prevention_events[0].cause, "shockwave")
	assert_eq(day.snapshot().spoon_integrity[1], 3)
	assert_eq(day.snapshot().slots[2].kind, "soft_shelled")
	assert_eq(day.snapshot().slots[2].toughness, 2)


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
