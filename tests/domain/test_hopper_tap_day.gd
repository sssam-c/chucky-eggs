extends GutTest

const HopperTapDay = preload("res://src/domain/hopper_tap_day.gd")


func test_five_individual_spoons_expose_fixed_colours_and_hopper_preview() -> void:
	var day = HopperTapDay.new([
		"chicken", "cuckoo", "sparrow", "plover", "chicken",
		"spoonbill", "cuckoo", "sparrow", "chicken",
	], 10)
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
	assert_eq(state.hunger, 10)
	assert_eq(state.taps_remaining, 5)
	assert_eq(state.taps_per_phase, 5)
	assert_eq(state.tap_phase, 1)
	assert_eq(state.next_hunger_increase, 1)
	assert_eq(state.break_streak, 0)


func test_one_spoon_damages_only_its_egg_without_moving_the_board() -> void:
	var day = HopperTapDay.new([
		"chicken", "chicken", "chicken", "chicken", "chicken", "spoonbill",
	], 99)
	var before_ids: Array = day.snapshot().slots.map(
		func(egg: Dictionary) -> int: return int(egg.egg_instance_id)
	)

	var events: Array[Dictionary] = day.resolve_spoon(3)
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), ["spoon_fired", "egg_damaged", "tap_spent"])
	assert_eq(events[0].slot_index, 3)
	assert_eq(events[0].spoon_color, "red")
	assert_eq(events[1].slot_index, 3)
	assert_eq(state.slots[3].toughness, 2)
	assert_eq(state.slots.map(func(egg: Dictionary) -> int: return int(egg.egg_instance_id)), before_ids)
	assert_eq(state.taps_remaining, 4)


func test_pink_spoon_deals_two_direct_damage_to_spoonbill() -> void:
	var day = HopperTapDay.new([
		"chicken", "chicken", "spoonbill", "chicken", "chicken",
	], 99)

	var events: Array[Dictionary] = day.resolve_spoon(2)

	assert_eq(_event_types(events), ["spoon_fired", "egg_damaged", "tap_spent"])
	assert_eq(events[1].damage_amount, 2)
	assert_eq(events[1].remaining_toughness, 3)


func test_all_hatches_finish_before_hopper_refills_vacancies_in_hatch_order() -> void:
	var day = HopperTapDay.new([
		"sparrow", "cuckoo", "chicken", "chicken", "chicken",
		"chicken", "spoonbill", "plover",
	], 99)

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
		"egg_hatched", "egg_hatched", "yolk_delivered",
		"egg_entered", "egg_entered", "tap_spent",
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


func test_yolk_reduces_hunger_before_the_paid_tap_is_recorded() -> void:
	var day = HopperTapDay.new([
		"sparrow", "chicken", "chicken", "chicken", "chicken", "spoonbill",
	], 10)

	var events: Array[Dictionary] = day.resolve_spoon(0)

	assert_eq(_event_types(events), [
		"spoon_fired", "egg_damaged", "egg_hatched", "yolk_delivered",
		"egg_entered", "tap_spent",
	])
	assert_eq(events[2].yolk, 1)
	assert_eq(events[2].base_yolk, 1)
	assert_eq(events[2].break_streak, 1)
	assert_eq(events[2].streak_multiplier, 1)
	assert_eq(events[3].total_yolk, 1)
	assert_eq(events[3].hunger, 9)
	assert_eq(day.snapshot().hunger, 9)
	assert_eq(day.snapshot().break_streak, 1)


func test_consecutive_breaks_multiply_each_eggs_yolk_by_the_current_streak() -> void:
	var day = HopperTapDay.new([
		"sparrow", "sparrow", "chicken", "chicken", "chicken",
	], 20)

	var first_events: Array[Dictionary] = day.resolve_spoon(0)
	var second_events: Array[Dictionary] = day.resolve_spoon(1)
	var first_hatch: Dictionary = _events_of_type(first_events, "egg_hatched")[0]
	var second_hatch: Dictionary = _events_of_type(second_events, "egg_hatched")[0]

	assert_eq(first_hatch.break_streak, 1)
	assert_eq(first_hatch.yolk, 1)
	assert_eq(second_hatch.break_streak, 2)
	assert_eq(second_hatch.streak_multiplier, 2)
	assert_eq(second_hatch.yolk, 2)
	assert_eq(_events_of_type(second_events, "yolk_delivered")[0].total_yolk, 2)
	assert_eq(day.snapshot().hunger, 17)
	assert_eq(day.snapshot().break_streak, 2)


func test_zero_break_tap_resets_the_streak_before_the_next_break() -> void:
	var day = HopperTapDay.new([
		"sparrow", "sparrow", "chicken", "chicken", "chicken",
	], 20)
	day.resolve_spoon(0)

	var reset_events: Array[Dictionary] = day.resolve_spoon(2)
	var next_break_events: Array[Dictionary] = day.resolve_spoon(1)
	var next_hatch: Dictionary = _events_of_type(next_break_events, "egg_hatched")[0]

	assert_eq(_events_of_type(reset_events, "break_streak_reset").size(), 1)
	assert_eq(_events_of_type(reset_events, "break_streak_reset")[0].reason, "empty_tap")
	assert_eq(next_hatch.break_streak, 1)
	assert_eq(next_hatch.yolk, 1)
	assert_eq(day.snapshot().break_streak, 1)


func test_one_cascade_advances_the_streak_for_each_left_to_right_break() -> void:
	var day = HopperTapDay.new([
		"sparrow", "cuckoo", "chicken", "chicken", "chicken",
	], 99)
	day.resolve_spoon(1)
	day.resolve_spoon(1)
	day.resolve_spoon(1)

	var events: Array[Dictionary] = day.resolve_spoon(0)
	var hatches: Array[Dictionary] = _events_of_type(events, "egg_hatched")

	assert_eq(hatches.map(func(event: Dictionary) -> int: return int(event.slot_index)), [0, 1])
	assert_eq(hatches.map(func(event: Dictionary) -> int: return int(event.break_streak)), [1, 2])
	assert_eq(hatches.map(func(event: Dictionary) -> int: return int(event.yolk)), [1, 2])
	assert_eq(_events_of_type(events, "yolk_delivered")[0].total_yolk, 3)
	assert_eq(day.snapshot().hunger, 96)


func test_hunger_phase_resets_a_streak_extended_by_the_fifth_tap() -> void:
	var day = HopperTapDay.new([
		"chicken", "sparrow", "chicken", "chicken", "chicken",
	], 20)
	day.resolve_spoon(0)
	day.resolve_spoon(2)
	day.resolve_spoon(3)
	day.resolve_spoon(4)

	var events: Array[Dictionary] = day.resolve_spoon(1)
	var reset: Dictionary = _events_of_type(events, "break_streak_reset")[0]

	assert_eq(_events_of_type(events, "egg_hatched")[0].break_streak, 1)
	assert_eq(reset.reason, "hunger_phase")
	assert_lt(_event_types(events).find("tap_spent"), _event_types(events).find("break_streak_reset"))
	assert_lt(_event_types(events).find("break_streak_reset"), _event_types(events).find("tap_phase_ended"))
	assert_eq(day.snapshot().break_streak, 0)


func test_fifth_tap_resolves_before_hunger_rises_and_the_next_phase_refreshes() -> void:
	var day = HopperTapDay.new([
		"plover", "plover", "plover", "plover", "plover", "chicken",
	], 10)
	for tap_index in range(4):
		day.resolve_spoon(0)

	var events: Array[Dictionary] = day.resolve_spoon(0)
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"spoon_fired", "egg_damaged", "tap_spent", "tap_phase_ended",
		"hunger_increased", "tap_phase_started",
	])
	assert_eq(events[2].taps_remaining, 0)
	assert_eq(events[3].tap_phase, 1)
	assert_eq(events[4].amount, 1)
	assert_eq(events[4].hunger, 11)
	assert_eq(events[5].tap_phase, 2)
	assert_eq(events[5].next_hunger_increase, 2)
	assert_eq(state.hunger, 11)
	assert_eq(state.tap_phase, 2)
	assert_eq(state.taps_remaining, 5)
	assert_eq(state.next_hunger_increase, 2)


func test_victory_on_the_fifth_tap_skips_grandmas_hunger_phase() -> void:
	var day = HopperTapDay.new([
		"chicken", "plover", "plover", "plover", "plover", "sparrow", "sparrow",
	], 8)
	for tap_index in range(4):
		day.resolve_spoon(0)

	var events: Array[Dictionary] = day.resolve_spoon(0)
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"spoon_fired", "egg_damaged", "egg_hatched", "yolk_delivered",
		"tap_spent", "day_ended",
	])
	assert_eq(state.hunger, 0)
	assert_true(state.ended)
	assert_true(state.succeeded)
	assert_false(_event_types(events).has("hunger_increased"))


func test_exhausting_every_egg_above_zero_hunger_fails_without_a_hunger_phase() -> void:
	var day = HopperTapDay.new(["sparrow"], 2)

	var events: Array[Dictionary] = day.resolve_spoon(0)
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"spoon_fired", "egg_damaged", "egg_hatched", "yolk_delivered",
		"tap_spent", "day_ended",
	])
	assert_eq(state.hunger, 1)
	assert_true(state.ended)
	assert_false(state.succeeded)
	assert_eq(day.resolve_spoon(0)[0].reason, "day_ended")


func _event_types(events: Array[Dictionary]) -> Array[String]:
	var types: Array[String] = []
	for event: Dictionary in events:
		types.append(String(event.type))
	return types


func _events_of_type(events: Array[Dictionary], event_type: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for event: Dictionary in events:
		if String(event.type) == event_type:
			matches.append(event)
	return matches
