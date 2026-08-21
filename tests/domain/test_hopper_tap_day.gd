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
		{"id": "green_4", "slot_index": 3, "color": "green"},
		{"id": "gold_5", "slot_index": 4, "color": "gold"},
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
	assert_false(state.has("break_streak"))


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
	assert_eq(events[0].spoon_color, "green")
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
	assert_eq(events[2].combo_count, 1)
	assert_eq(events[2].combo_multiplier, 1)
	assert_eq(events[3].total_yolk, 1)
	assert_eq(events[3].base_yolks, [1])
	assert_eq(events[3].base_yolk_total, 1)
	assert_eq(events[3].eggs_broken, 1)
	assert_eq(events[3].combo_multiplier, 1)
	assert_eq(events[3].hunger, 9)
	assert_eq(day.snapshot().hunger, 9)
	assert_false(day.snapshot().has("break_streak"))


func test_breaks_on_separate_taps_never_build_a_combo() -> void:
	var day = HopperTapDay.new([
		"sparrow", "sparrow", "chicken", "chicken", "chicken",
	], 20)

	var first_events: Array[Dictionary] = day.resolve_spoon(0)
	var second_events: Array[Dictionary] = day.resolve_spoon(1)
	var first_hatch: Dictionary = _events_of_type(first_events, "egg_hatched")[0]
	var second_hatch: Dictionary = _events_of_type(second_events, "egg_hatched")[0]

	assert_eq(first_hatch.combo_count, 1)
	assert_eq(first_hatch.yolk, 1)
	assert_eq(second_hatch.combo_count, 1)
	assert_eq(second_hatch.combo_multiplier, 1)
	assert_eq(second_hatch.yolk, 1)
	assert_eq(_events_of_type(second_events, "yolk_delivered")[0].total_yolk, 1)
	assert_eq(day.snapshot().hunger, 18)
	assert_false(day.snapshot().has("break_streak"))


func test_zero_break_tap_emits_no_combo_bookkeeping() -> void:
	var day = HopperTapDay.new([
		"sparrow", "sparrow", "chicken", "chicken", "chicken",
	], 20)
	day.resolve_spoon(0)

	var zero_break_events: Array[Dictionary] = day.resolve_spoon(2)
	var next_break_events: Array[Dictionary] = day.resolve_spoon(1)
	var next_hatch: Dictionary = _events_of_type(next_break_events, "egg_hatched")[0]

	assert_false(_event_types(zero_break_events).has("break_streak_reset"))
	assert_eq(next_hatch.combo_count, 1)
	assert_eq(next_hatch.yolk, 1)
	assert_false(day.snapshot().has("break_streak"))


func test_one_tap_multiplies_the_complete_break_cascade_by_its_egg_count() -> void:
	var day = HopperTapDay.new([
		"sparrow", "cuckoo", "chicken", "chicken", "chicken",
	], 99)
	day.resolve_spoon(1)
	day.resolve_spoon(1)
	day.resolve_spoon(1)

	var events: Array[Dictionary] = day.resolve_spoon(0)
	var hatches: Array[Dictionary] = _events_of_type(events, "egg_hatched")

	assert_eq(hatches.map(func(event: Dictionary) -> int: return int(event.slot_index)), [0, 1])
	assert_eq(hatches.map(func(event: Dictionary) -> int: return int(event.combo_count)), [2, 2])
	assert_eq(hatches.map(func(event: Dictionary) -> int: return int(event.combo_multiplier)), [2, 2])
	assert_eq(hatches.map(func(event: Dictionary) -> int: return int(event.yolk)), [2, 2])
	var delivery: Dictionary = _events_of_type(events, "yolk_delivered")[0]
	assert_eq(delivery.base_yolks, [1, 1])
	assert_eq(delivery.base_yolk_total, 2)
	assert_eq(delivery.eggs_broken, 2)
	assert_eq(delivery.combo_multiplier, 2)
	assert_eq(delivery.total_yolk, 4)
	assert_eq(day.snapshot().hunger, 95)


func test_woodpecker_break_fires_the_right_spoon_for_free_and_joins_the_combo() -> void:
	var day = HopperTapDay.new([
		"woodpecker", "sparrow", "chicken", "chicken", "chicken",
	], 99, 10)
	for setup_tap in range(3):
		day.resolve_spoon(0)

	var events: Array[Dictionary] = day.resolve_spoon(0)
	var fires: Array[Dictionary] = _events_of_type(events, "spoon_fired")
	var hatches: Array[Dictionary] = _events_of_type(events, "egg_hatched")
	var delivery: Dictionary = _events_of_type(events, "yolk_delivered")[0]

	assert_eq(_event_types(events), [
		"spoon_fired", "egg_damaged", "egg_hatched",
		"spoon_fired", "egg_damaged", "egg_hatched",
		"yolk_delivered", "tap_spent",
	])
	assert_eq(fires.size(), 2)
	assert_eq(fires[0].cause, "paid_tap")
	assert_eq(fires[0].slot_index, 0)
	assert_eq(fires[1].cause, "woodpecker_break")
	assert_eq(fires[1].slot_index, 1)
	assert_eq(fires[1].source_slot_index, 0)
	assert_eq(fires[1].source_egg_instance_id, hatches[0].egg_instance_id)
	assert_eq(hatches.map(func(event: Dictionary) -> String: return String(event.kind)), [
		"woodpecker", "sparrow",
	])
	assert_eq(hatches.map(func(event: Dictionary) -> int: return int(event.combo_count)), [2, 2])
	assert_eq(delivery.base_yolks, [2, 1])
	assert_eq(delivery.combo_multiplier, 2)
	assert_eq(delivery.total_yolk, 6)
	assert_eq(_events_of_type(events, "tap_spent").size(), 1)
	assert_eq(day.snapshot().taps_remaining, 6)
	assert_eq(day.snapshot().hunger, 93)


func test_woodpecker_breaks_chain_right_sequentially_before_refill() -> void:
	var day = HopperTapDay.new([
		"woodpecker", "woodpecker", "sparrow", "chicken", "chicken",
		"spoonbill", "plover", "cuckoo",
	], 99, 20)
	for setup_tap in range(3):
		day.resolve_spoon(1)
		day.resolve_spoon(0)

	var events: Array[Dictionary] = day.resolve_spoon(0)
	var fires: Array[Dictionary] = _events_of_type(events, "spoon_fired")
	var hatches: Array[Dictionary] = _events_of_type(events, "egg_hatched")
	var entries: Array[Dictionary] = _events_of_type(events, "egg_entered")

	assert_eq(fires.map(func(event: Dictionary) -> int: return int(event.slot_index)), [0, 1, 2])
	assert_eq(fires.map(func(event: Dictionary) -> String: return String(event.cause)), [
		"paid_tap", "woodpecker_break", "woodpecker_break",
	])
	assert_eq(hatches.map(func(event: Dictionary) -> int: return int(event.slot_index)), [0, 1, 2])
	assert_eq(hatches.map(func(event: Dictionary) -> String: return String(event.kind)), [
		"woodpecker", "woodpecker", "sparrow",
	])
	assert_eq(_events_of_type(events, "yolk_delivered")[0].total_yolk, 15)
	assert_eq(entries.map(func(event: Dictionary) -> int: return int(event.slot_index)), [0, 1, 2])
	assert_eq(entries.map(func(event: Dictionary) -> String: return String(event.egg.kind)), [
		"spoonbill", "plover", "cuckoo",
	])
	assert_gt(_event_types(events).find("egg_entered"), _event_types(events).rfind("spoon_fired"))
	assert_eq(_events_of_type(events, "tap_spent").size(), 1)


func test_woodpecker_at_the_right_edge_has_no_tap_target() -> void:
	var day = HopperTapDay.new([
		"chicken", "chicken", "chicken", "chicken", "woodpecker",
	], 99, 10)
	for setup_tap in range(3):
		day.resolve_spoon(4)

	var events: Array[Dictionary] = day.resolve_spoon(4)

	assert_eq(_events_of_type(events, "spoon_fired").size(), 1)
	assert_eq(_events_of_type(events, "egg_hatched")[0].kind, "woodpecker")
	assert_eq(_events_of_type(events, "yolk_delivered")[0].total_yolk, 2)
	assert_eq(_events_of_type(events, "tap_spent").size(), 1)


func test_woodpecker_uses_the_right_spoons_colour_and_cuckoo_reactions() -> void:
	var day = HopperTapDay.new([
		"chicken", "woodpecker", "spoonbill", "cuckoo", "chicken",
	], 99, 10)
	for setup_tap in range(3):
		day.resolve_spoon(1)

	var events: Array[Dictionary] = day.resolve_spoon(1)
	var fires: Array[Dictionary] = _events_of_type(events, "spoon_fired")
	var damages: Array[Dictionary] = _events_of_type(events, "egg_damaged")

	assert_eq(fires.map(func(event: Dictionary) -> String: return String(event.spoon_color)), [
		"blue", "pink",
	])
	assert_eq(damages.map(func(event: Dictionary) -> String: return String(event.kind)), [
		"woodpecker", "spoonbill", "cuckoo",
	])
	assert_eq(damages.map(func(event: Dictionary) -> int: return int(event.damage_amount)), [
		1, 2, 2,
	])
	assert_eq(day.snapshot().slots[2].toughness, 3)
	assert_eq(day.snapshot().slots[3].toughness, 2)


func test_hunger_phase_carries_no_combo_state_between_taps() -> void:
	var day = HopperTapDay.new([
		"chicken", "sparrow", "chicken", "chicken", "chicken",
	], 20)
	day.resolve_spoon(0)
	day.resolve_spoon(2)
	day.resolve_spoon(3)
	day.resolve_spoon(4)

	var events: Array[Dictionary] = day.resolve_spoon(1)

	assert_eq(_events_of_type(events, "egg_hatched")[0].combo_count, 1)
	assert_false(_event_types(events).has("break_streak_reset"))
	assert_lt(_event_types(events).find("yolk_delivered"), _event_types(events).find("tap_spent"))
	assert_lt(_event_types(events).find("tap_spent"), _event_types(events).find("tap_phase_ended"))
	assert_false(day.snapshot().has("break_streak"))


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
	], 5)
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
