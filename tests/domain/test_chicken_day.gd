extends GutTest

const ChickenDay = preload("res://src/domain/chicken_day.gd")
const AUTHORED_PATTERN: Array[String] = [
	"chicken", "cuckoo", "chicken", "spoonbill",
	"cuckoo", "plover", "chicken", "chicken",
]


class ReverseShuffler:
	extends RefCounted

	var shuffled_bins: Array[Array] = []

	func shuffle_dictionaries(values: Array[Dictionary]) -> Array[Dictionary]:
		shuffled_bins.append(values.duplicate(true))
		var shuffled := values.duplicate(true)
		shuffled.reverse()
		return shuffled


func test_plover_is_a_four_point_high_commitment_egg() -> void:
	assert_eq(ChickenDay.PLOVER_TOUGHNESS, 6)
	assert_eq(ChickenDay.PLOVER_POINTS, 4)
	assert_eq(ChickenDay.egg_definition("plover").effect, "screen_left")


func test_sparrow_is_a_single_hit_single_point_egg() -> void:
	assert_eq(ChickenDay.SPARROW_TOUGHNESS, 1)
	assert_eq(ChickenDay.SPARROW_POINTS, 1)
	assert_eq(ChickenDay.egg_definition("sparrow"), {
		"kind": "sparrow", "toughness": 1, "points": 1, "effect": "none",
	})


func test_new_effect_species_have_the_settled_base_egg_definitions() -> void:
	assert_eq(ChickenDay.egg_definition("quail"), {
		"kind": "quail", "toughness": 2, "points": 1, "effect": "appetiser",
		"effects": [{"type": "appetiser"}],
	})
	assert_eq(ChickenDay.egg_definition("maleo"), {
		"kind": "maleo", "toughness": 6, "points": 3, "effect": "sulphurous",
		"effects": [{"type": "sulphurous"}],
	})
	assert_eq(ChickenDay.egg_definition("ostrich"), {
		"kind": "ostrich", "toughness": 7, "points": 3, "effect": "shockwave",
		"effects": [{"type": "shockwave"}],
	})
	assert_eq(ChickenDay.egg_definition("kiwi"), {
		"kind": "kiwi", "toughness": 3, "points": 0,
		"effect": "deceptively_filling",
		"effects": [{"type": "deceptively_filling", "duration": 8}],
	})


func test_new_species_eggs_receive_their_effects_without_test_injection() -> void:
	var state: Dictionary = ChickenDay.new([
		"quail", "maleo", "ostrich", "kiwi",
	], 99).snapshot()
	var eggs: Array[Dictionary] = [state.slots[0]]
	for egg: Dictionary in state.pipe:
		eggs.append(egg)

	for egg: Dictionary in eggs:
		assert_eq(egg.effects, ChickenDay.egg_definition(String(egg.kind)).effects)
		assert_eq(egg.all_other_effects.size(), 1)


func test_grandma_starts_with_ten_patience() -> void:
	var state: Dictionary = ChickenDay.new(["chicken"]).snapshot()

	assert_eq(state.starting_patience, 10)
	assert_eq(state.current_patience, 10)
	assert_false("remaining_thwacks" in state)


func test_resolved_thwack_consumes_exactly_one_patience() -> void:
	var day = ChickenDay.new(["chicken", "cuckoo"])

	var events: Array[Dictionary] = day.resolve_circuit("red")
	var patience_events := events.filter(
		func(event: Dictionary) -> bool: return event.type == "patience_spent"
	)

	assert_eq(patience_events, [{
		"type": "patience_spent",
		"amount": 1,
		"current_patience": 9,
	}])
	assert_eq(day.snapshot().current_patience, 9)


func test_sparrow_hatches_on_its_first_hit_and_doubles_its_point_when_rolled() -> void:
	var day = ChickenDay.new([{
		"kind": "sparrow",
		"double_yolk_chance": 0.05,
		"is_double_yolker": true,
	}], 10)

	var events: Array[Dictionary] = day.resolve_circuit("red")
	var hatch: Dictionary = events.filter(
		func(event: Dictionary) -> bool: return event.type == "egg_hatched"
	)[0]

	assert_eq(hatch.kind, "sparrow")
	assert_eq(hatch.base_points, 1)
	assert_eq(hatch.points_awarded, 2)
	assert_true(hatch.double_yolker)


func test_daily_pool_exposes_three_preview_eggs_and_non_positional_hopper_contents() -> void:
	var state: Dictionary = ChickenDay.new([
		"chicken", "spoonbill", "plover", "cuckoo", "sparrow",
	]).snapshot()

	assert_eq(state.slots[0].kind, "chicken")
	assert_eq(state.pipe.map(func(egg: Dictionary) -> String: return egg.kind), [
		"spoonbill", "plover", "cuckoo",
	])
	assert_eq(state.hopper_contents.map(func(egg: Dictionary) -> String: return egg.kind), [
		"cuckoo", "plover", "sparrow", "spoonbill",
	])
	assert_false("hopper" in state)
	assert_eq(state.hopper_egg_count, 4)


func test_day_ends_when_every_egg_has_hatched() -> void:
	var day = ChickenDay.new(["chicken"])
	var final_events: Array[Dictionary] = []

	for circuit_id in ["red", "blue", "red"]:
		final_events = day.resolve_circuit(circuit_id)

	var state: Dictionary = day.snapshot()
	assert_true(state.ended)
	assert_eq(state.current_patience, 7)
	assert_true(state.pipe.is_empty())
	assert_true(state.slots.all(func(egg: Dictionary) -> bool: return egg.is_empty()))
	assert_eq(_event_types(final_events).slice(-2), [
		"day_remainder_discarded", "day_ended",
	])
	assert_eq(final_events[-1].current_patience, 7)


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


func test_fallen_egg_keeps_damage_and_recycles_when_the_hopper_is_empty() -> void:
	var shuffler := ReverseShuffler.new()
	var day = ChickenDay.new([{
		"kind": "spoonbill",
		"tier": 1,
		"quality_multiplier": 1.5,
	}], 99, 20, shuffler)
	var final_events: Array[Dictionary] = []

	for circuit_id in ["red", "blue", "red", "blue", "pink"]:
		final_events = day.resolve_circuit(circuit_id)

	assert_eq(_event_types(final_events), [
		"circuit_fired",
		"egg_damaged",
		"spoon_worn",
		"conveyor_advanced",
		"egg_binned",
		"patience_spent",
		"bin_reshuffled",
		"egg_entered",
	])
	assert_eq(shuffler.shuffled_bins.size(), 1)
	assert_eq(shuffler.shuffled_bins[0][0].kind, "spoonbill")
	assert_eq(shuffler.shuffled_bins[0][0].toughness, 2)
	var state: Dictionary = day.snapshot()
	assert_eq(state.bin_egg_count, 0)
	assert_eq(state.hopper_egg_count, 0)
	assert_eq(state.slots[0].kind, "spoonbill")
	assert_eq(state.slots[0].toughness, 2)
	assert_eq(state.slots[0].max_toughness, 8)
	assert_false(state.ended)


func test_bin_waits_for_the_conveyor_to_clear_before_reshuffling() -> void:
	var shuffler := ReverseShuffler.new()
	var day = ChickenDay.new(["spoonbill", "spoonbill"], 99, 10, shuffler)
	var first_binned_events: Array[Dictionary] = []

	for circuit_id in ["red", "red", "red", "red", "pink"]:
		first_binned_events = day.resolve_circuit(circuit_id)

	assert_true(_event_types(first_binned_events).has("egg_binned"))
	assert_false(_event_types(first_binned_events).has("bin_reshuffled"))
	assert_false(_event_types(first_binned_events).has("egg_entered"))
	assert_eq(shuffler.shuffled_bins.size(), 0)
	assert_eq(day.snapshot().bin_egg_count, 1)
	assert_eq(day.snapshot().hopper_egg_count, 0)
	assert_eq(day.snapshot().slots[4].kind, "spoonbill")

	var clear_events: Array[Dictionary] = day.resolve_circuit("pink")

	assert_eq(_event_types(clear_events).slice(-6), [
		"spoon_worn", "conveyor_advanced", "egg_binned", "patience_spent",
		"bin_reshuffled", "egg_entered",
	])
	assert_eq(shuffler.shuffled_bins.size(), 1)
	assert_eq(shuffler.shuffled_bins[0].size(), 2)
	assert_eq(day.snapshot().bin_egg_count, 0)
	assert_eq(day.snapshot().hopper_egg_count, 1)
	assert_eq(day.snapshot().slots[0].kind, "spoonbill")


func test_red_fires_slots_one_and_three_and_wastes_the_empty_strike() -> void:
	var day = _new_authored_day()

	var events: Array[Dictionary] = day.resolve_circuit("red")
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"circuit_fired",
		"egg_damaged",
		"spoon_worn",
		"spoon_worn",
		"conveyor_advanced",
		"patience_spent",
		"egg_entered",
	])
	assert_eq(events[0].circuit_id, "red")
	assert_eq(events[0].slot_indices, [0, 2])
	assert_eq(events[0].occupied_slot_indices, [0])
	assert_eq(events[1].slot_index, 0)
	assert_eq(events[1].damage_amount, 1)
	assert_eq(state.current_patience, 9)
	assert_eq(state.slots[1].kind, "chicken")
	assert_eq(state.slots[1].toughness, 2)


func test_empty_circuit_consumes_patience_and_advances_without_damage() -> void:
	var day = _new_authored_day()

	var events: Array[Dictionary] = day.resolve_circuit("blue")
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(events), [
		"circuit_fired",
		"spoon_worn",
		"spoon_worn",
		"conveyor_advanced",
		"patience_spent",
		"egg_entered",
	])
	assert_eq(events[0].circuit_id, "blue")
	assert_eq(events[0].slot_indices, [1, 3])
	assert_eq(events[0].occupied_slot_indices, [])
	assert_eq(state.current_patience, 9)
	assert_eq(state.slots[1].kind, "chicken")
	assert_eq(state.slots[1].toughness, 3)


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
		"spoon_worn",
		"spoon_worn",
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


func test_hidden_double_yolker_chicken_awards_six_points_once_when_hatched() -> void:
	var laid_eggs: Array = [{
		"kind": "chicken",
		"double_yolk_chance": 0.10,
		"is_double_yolker": true,
	}]
	var day = ChickenDay.new(laid_eggs, 99)
	day.resolve_circuit("red")
	day.resolve_circuit("blue")

	var events: Array[Dictionary] = day.resolve_circuit("red")
	var hatches := events.filter(func(event: Dictionary) -> bool:
		return event.type == "egg_hatched"
	)

	assert_eq(hatches.size(), 1)
	assert_true(hatches[0].double_yolker)
	assert_eq(hatches[0].base_points, 3)
	assert_eq(hatches[0].points_awarded, 6)
	assert_eq(hatches[0].score, 6)


func test_unsuccessful_double_yolker_roll_keeps_the_chicken_at_three_points() -> void:
	var laid_eggs: Array = [{
		"kind": "chicken",
		"double_yolk_chance": 0.10,
		"is_double_yolker": false,
	}]
	var day = ChickenDay.new(laid_eggs, 99)
	day.resolve_circuit("red")
	day.resolve_circuit("blue")

	var events: Array[Dictionary] = day.resolve_circuit("red")
	var hatch: Dictionary = events.filter(func(event: Dictionary) -> bool:
		return event.type == "egg_hatched"
	)[0]

	assert_false(hatch.double_yolker)
	assert_eq(hatch.points_awarded, 3)


func test_quality_uses_exact_multiplier_but_rounds_gameplay_score_down() -> void:
	var day = ChickenDay.new([{
		"kind": "chicken",
		"tier": 1,
		"quality_multiplier": 1.5,
		"double_yolk_chance": 0.03,
		"is_double_yolker": true,
	}])
	var initial_egg: Dictionary = day.snapshot().slots[0]
	assert_eq(initial_egg.toughness, 5)
	assert_eq(initial_egg.max_toughness, 5)
	assert_almost_eq(float(initial_egg.exact_max_toughness), 4.5, 0.00001)

	var events: Array[Dictionary] = []
	for circuit_id in ["red", "blue", "red", "blue", "pink"]:
		events = day.resolve_circuit(circuit_id)
	var hatch: Dictionary = events.filter(func(event: Dictionary) -> bool:
		return event.type == "egg_hatched"
	)[0]

	assert_eq(hatch.base_points, 4)
	assert_eq(hatch.points_awarded, 8)
	assert_eq(hatch.score, 8)
	assert_almost_eq(float(hatch.exact_base_points), 4.5, 0.00001)
	assert_eq(hatch.tier, 1)


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
	var day = ChickenDay.new([
		"spoonbill", "cuckoo", "chicken", "chicken", "chicken", "chicken",
	])
	for circuit_id in ["red", "red", "blue", "red"]:
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


func test_surviving_directly_struck_plover_retreats_one_bay_to_screen_left() -> void:
	var day = ChickenDay.new(["plover", "chicken", "chicken"])
	day.resolve_circuit("red")

	var events: Array[Dictionary] = day.resolve_circuit("blue")
	var state: Dictionary = day.snapshot()
	var swaps := events.filter(
		func(event: Dictionary) -> bool: return event.type == "eggs_swapped"
	)

	assert_eq(swaps.size(), 1)
	assert_eq(swaps[0].from_slot_index, 1)
	assert_eq(swaps[0].to_slot_index, 0)
	assert_eq(swaps[0].direction, "screen_left")
	assert_eq(state.slots[1].kind, "plover")
	assert_eq(state.slots[1].toughness, 4)


func test_unhatched_egg_is_binned_after_slot_five() -> void:
	var day = _new_authored_day()
	var final_events: Array[Dictionary] = []

	for turn in range(5):
		final_events = day.resolve_circuit("red")

	var binned := final_events.filter(
		func(event: Dictionary) -> bool: return event.type == "egg_binned"
	)
	assert_eq(binned.size(), 1)
	assert_eq(binned[0].remaining_toughness, 1)
	assert_eq(binned[0].bin_egg_count, 1)
	var state: Dictionary = day.snapshot()
	assert_eq(state.bin_egg_count, 1)
	assert_eq(state.bin.size(), 1)
	assert_eq(state.bin[0].kind, "chicken")
	assert_eq(state.bin[0].toughness, 1)


func test_breaking_all_five_spoons_ends_day_and_rejects_further_requests() -> void:
	var eggs: Array[String] = []
	eggs.resize(12)
	eggs.fill("chicken")
	var day = ChickenDay.new(eggs, 99, 1)

	for circuit_id in ["red", "blue", "pink"]:
		var events: Array[Dictionary] = day.resolve_circuit(circuit_id)
		assert_ne(events[0].type, "thwack_rejected")

	var state: Dictionary = day.snapshot()
	assert_true(state.ended)
	assert_eq(state.spoon_integrity, [0, 0, 0, 0, 0])
	assert_true(state.slots.all(func(egg: Dictionary) -> bool: return egg.is_empty()))
	assert_true(state.pipe.is_empty())
	var rejected: Array[Dictionary] = day.resolve_circuit("red")
	assert_eq(rejected[0].reason, "day_ended")


func test_satisfying_grandma_when_spoons_break_succeeds_after_full_resolution() -> void:
	var day = ChickenDay.new(["sparrow"], 1, 1)

	var final_events: Array[Dictionary] = day.resolve_circuit("red")
	var state: Dictionary = day.snapshot()

	assert_eq(_event_types(final_events), [
		"circuit_fired",
		"egg_damaged",
		"spoon_worn",
		"spoon_worn",
		"egg_hatched",
		"conveyor_advanced",
		"patience_spent",
		"day_remainder_discarded",
		"day_ended",
	])
	assert_eq(state.spoon_integrity[0], 0)
	assert_true(state.succeeded)
	assert_true(final_events[-1].succeeded)


func test_breaking_all_spoons_without_satisfying_grandma_fails() -> void:
	var eggs: Array[String] = []
	eggs.resize(12)
	eggs.fill("chicken")
	var day = ChickenDay.new(eggs, 99, 1)
	var final_events: Array[Dictionary] = []
	for circuit_id in ["red", "blue", "pink"]:
		final_events = day.resolve_circuit(circuit_id)
	var state: Dictionary = day.snapshot()

	assert_eq(state.spoon_integrity, [0, 0, 0, 0, 0])
	assert_false(state.succeeded)
	assert_false(final_events[-1].succeeded)


func test_day_succeeds_at_ten_or_more_points() -> void:
	var chicken_pool: Array[String] = []
	chicken_pool.resize(24)
	chicken_pool.fill("chicken")
	var day = ChickenDay.new(chicken_pool, ChickenDay.DEFAULT_TARGET_SCORE, 99)
	var circuit_plan := [
		"red", "red", "red", "blue", "red", "red", "red", "blue", "blue", "pink", "pink",
	]
	var final_events: Array[Dictionary] = []

	for circuit_id in circuit_plan:
		final_events = day.resolve_circuit(circuit_id)
		assert_ne(final_events[0].type, "thwack_rejected")
		if day.snapshot().ended:
			break

	assert_true(day.snapshot().ended)
	assert_true(day.snapshot().succeeded)
	assert_eq(day.snapshot().target_score, 10)
	assert_gte(day.snapshot().score, 10)
	assert_eq(_event_types(final_events).slice(-2), [
		"day_remainder_discarded", "day_ended",
	])
	assert_true(_event_types(final_events).has("egg_entered"))
	assert_gt(final_events[-2].discarded_count, 0)


func test_day_fails_below_its_target() -> void:
	var spoonbill_pool: Array[String] = []
	spoonbill_pool.resize(24)
	spoonbill_pool.fill("spoonbill")
	var day = ChickenDay.new(spoonbill_pool, 20, 1)
	var final_events: Array[Dictionary] = []

	for circuit_id in ["red", "blue", "pink"]:
		final_events = day.resolve_circuit(circuit_id)

	assert_true(day.snapshot().ended)
	assert_false(day.snapshot().succeeded)
	assert_eq(day.snapshot().target_score, 20)
	assert_lt(day.snapshot().score, 20)
	var day_ended: Dictionary = final_events.filter(
		func(event: Dictionary) -> bool: return event.type == "day_ended"
	)[0]
	assert_eq(day_ended.target_score, 20)
	assert_eq(day_ended.spoon_integrity, [0, 0, 0, 0, 0])


func _event_types(events: Array[Dictionary]) -> Array[String]:
	var types: Array[String] = []
	for event: Dictionary in events:
		types.append(event.type)
	return types


func _new_authored_day():
	var daily_eggs: Array[String] = []
	for egg_index in range(24):
		daily_eggs.append(AUTHORED_PATTERN[egg_index % AUTHORED_PATTERN.size()])
	return ChickenDay.new(daily_eggs, ChickenDay.DEFAULT_TARGET_SCORE, 99)
