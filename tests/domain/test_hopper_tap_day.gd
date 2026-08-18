extends GutTest

const HopperTapDay = preload("res://src/domain/hopper_tap_day.gd")


func test_five_individual_spoons_expose_fixed_colours_and_hopper_preview() -> void:
	var day = HopperTapDay.new([
		"chicken", "cuckoo", "sparrow", "plover", "chicken",
		"spoonbill", "cuckoo", "sparrow", "chicken",
	], 99, 12)
	var state: Dictionary = day.snapshot()

	assert_eq(state.spoons, [
		{"id": "red_1", "slot_index": 0, "color": "red"},
		{"id": "blue_2", "slot_index": 1, "color": "blue"},
		{"id": "pink_3", "slot_index": 2, "color": "pink"},
		{"id": "red_4", "slot_index": 3, "color": "red"},
		{"id": "blue_5", "slot_index": 4, "color": "blue"},
	])
	assert_eq(state.slots.map(func(egg: Dictionary) -> String: return egg.kind), [
		"chicken", "cuckoo", "sparrow", "plover", "chicken",
	])
	assert_eq(state.pipe.map(func(egg: Dictionary) -> String: return egg.kind), [
		"spoonbill", "cuckoo", "sparrow",
	])


func test_one_spoon_damages_only_its_egg_without_moving_the_board() -> void:
	var day = HopperTapDay.new([
		"chicken", "chicken", "chicken", "chicken", "chicken", "spoonbill",
	], 99, 12)
	var before_ids: Array = day.snapshot().slots.map(
		func(egg: Dictionary) -> int: return int(egg.egg_instance_id)
	)

	var events: Array[Dictionary] = day.resolve_spoon(3)
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), ["spoon_fired", "egg_damaged", "pull_spent"])
	assert_eq(events[0].slot_index, 3)
	assert_eq(events[0].spoon_color, "red")
	assert_eq(events[1].slot_index, 3)
	assert_eq(state.slots[3].toughness, 2)
	assert_eq(state.slots.map(func(egg: Dictionary) -> int: return int(egg.egg_instance_id)), before_ids)
	assert_eq(state.pulls_remaining, 11)


func test_pink_spoon_deals_two_direct_damage_to_spoonbill() -> void:
	var day = HopperTapDay.new([
		"chicken", "chicken", "spoonbill", "chicken", "chicken",
	], 99, 12)

	var events: Array[Dictionary] = day.resolve_spoon(2)

	assert_eq(_event_types(events), ["spoon_fired", "egg_damaged", "pull_spent"])
	assert_eq(events[1].damage_amount, 2)
	assert_eq(events[1].remaining_toughness, 3)


func test_all_hatches_finish_before_hopper_refills_vacancies_in_hatch_order() -> void:
	var day = HopperTapDay.new([
		"sparrow", "cuckoo", "chicken", "chicken", "chicken",
		"chicken", "spoonbill", "plover",
	], 99, 12)

	# The first Sparrow opens and its neighbouring Cuckoo copies that hit.
	day.resolve_spoon(0)
	# The incoming Chicken takes three Red hits. On the third, it opens while
	# the adjacent Cuckoo takes its fourth echo and opens in the same cascade.
	day.resolve_spoon(0)
	day.resolve_spoon(0)
	var events: Array[Dictionary] = day.resolve_spoon(0)
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"spoon_fired", "egg_damaged", "egg_damaged",
		"egg_hatched", "egg_hatched",
		"egg_entered", "egg_entered", "pull_spent",
	])
	var first_entry_index := _event_types(events).find("egg_entered")
	var last_hatch_index := _event_types(events).rfind("egg_hatched")
	assert_gt(first_entry_index, last_hatch_index)
	assert_eq(events[first_entry_index].slot_index, 0)
	assert_eq(events[first_entry_index].egg.kind, "spoonbill")
	assert_eq(events[first_entry_index + 1].slot_index, 1)
	assert_eq(events[first_entry_index + 1].egg.kind, "plover")
	assert_eq(state.slots[0].kind, "spoonbill")
	assert_eq(state.slots[1].kind, "plover")


func test_spending_the_last_pull_finishes_after_the_complete_cascade() -> void:
	var day = HopperTapDay.new([
		"sparrow", "chicken", "chicken", "chicken", "chicken", "spoonbill",
	], 99, 1)

	var events: Array[Dictionary] = day.resolve_spoon(0)
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"spoon_fired", "egg_damaged", "egg_hatched", "egg_entered",
		"pull_spent", "round_ended",
	])
	assert_eq(state.slots[0].kind, "spoonbill")
	assert_true(state.ended)
	assert_false(state.succeeded)
	assert_eq(day.resolve_spoon(0)[0].reason, "round_ended")


func _event_types(events: Array[Dictionary]) -> Array[String]:
	var types: Array[String] = []
	for event: Dictionary in events:
		types.append(String(event.type))
	return types
