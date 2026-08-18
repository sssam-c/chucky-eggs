extends GutTest

const ChickenDay = preload("res://src/domain/chicken_day.gd")


func test_appetiser_charge_doubles_one_future_positive_yolk_and_is_consumed() -> void:
	var day = ChickenDay.new([
		_effect_egg("appetiser"),
		"chicken",
	], 99)
	var app_events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(_hatches(app_events)[0].points_awarded, 1)
	assert_eq(day.snapshot().grandma_effects.appetiser_charges, 1)

	var hatch: Dictionary = _resolve_until_hatch(day)
	assert_eq(hatch.yolk_produced, 3)
	assert_eq(hatch.appetiser_multiplier, 2)
	assert_eq(hatch.points_awarded, 6)
	assert_eq(day.snapshot().grandma_effects.appetiser_charges, 0)


func test_appetiser_stacks_as_duration_across_two_eligible_eggs() -> void:
	var day = ChickenDay.new([
		"sparrow", "chicken", "sparrow", "chicken",
		{
			"kind": "sparrow",
			"effects": [{"type": "appetiser"}, {"type": "appetiser"}],
		},
	], 99)
	day.resolve_circuit("pink")
	assert_eq(day.snapshot().grandma_effects.appetiser_charges, 2)

	var later_hatches := _hatches(day.resolve_circuit("blue"))
	assert_eq(later_hatches.map(
		func(event: Dictionary) -> int: return event.points_awarded
	), [2, 2])
	assert_true(later_hatches.all(func(event: Dictionary) -> bool:
		return event.appetiser_multiplier == 2
	))
	assert_eq(day.snapshot().grandma_effects.appetiser_charges, 0)


func test_appetiser_can_affect_later_but_not_earlier_egg_in_same_batch() -> void:
	var earlier_day = ChickenDay.new([
		_effect_egg("appetiser"),
		"chicken",
		"sparrow",
	], 99)
	var earlier_hatches := _hatches(earlier_day.resolve_circuit("red"))
	assert_eq(earlier_hatches.map(
		func(event: Dictionary) -> int: return event.points_awarded
	), [1, 2])
	assert_eq(earlier_day.snapshot().grandma_effects.appetiser_charges, 0)

	var later_day = ChickenDay.new([
		"sparrow",
		"chicken",
		_effect_egg("appetiser"),
	], 99)
	var later_hatches := _hatches(later_day.resolve_circuit("red"))
	assert_eq(later_hatches.map(
		func(event: Dictionary) -> int: return event.points_awarded
	), [1, 1])
	assert_eq(later_day.snapshot().grandma_effects.appetiser_charges, 1)


func test_each_sulphurous_egg_permanently_suppresses_two_appetite_once() -> void:
	var day = ChickenDay.new([
		_effect_egg("sulphurous"),
		_effect_egg("sulphurous"),
		"chicken",
	], 20)
	var first: Array[Dictionary] = day.resolve_circuit("red")
	var first_activations := first.filter(func(event: Dictionary) -> bool:
		return event.type == "grandma_effect_activated" and event.effect_type == "sulphurous"
	)
	assert_eq(first_activations.size(), 1)
	assert_eq(first_activations[0].suppression_added, 2)
	assert_eq(first_activations[0].effective_appetite, 18)
	assert_lt(_event_types(first).find("egg_hatched"), _event_types(first).find("grandma_effect_activated"))
	assert_lt(_event_types(first).find("grandma_effect_activated"), _event_types(first).find("conveyor_advanced"))
	assert_eq(day.snapshot().grandma_effects.sulphurous_suppression, 2)
	assert_eq(day.snapshot().effective_target_score, 18)

	var second: Array[Dictionary] = day.resolve_circuit("red")
	var second_activations := second.filter(func(event: Dictionary) -> bool:
		return event.type == "grandma_effect_activated" and event.effect_type == "sulphurous"
	)
	assert_eq(second_activations.size(), 1)
	assert_eq(second_activations[0].suppression_added, 2)
	assert_eq(second_activations[0].effective_appetite, 16)
	assert_eq(day.snapshot().grandma_effects.sulphurous_suppression, 4)
	assert_eq(day.snapshot().target_score, 20)
	assert_eq(day.snapshot().effective_target_score, 16)

	var later: Array[Dictionary] = day.resolve_circuit("blue")
	assert_false(later.any(func(event: Dictionary) -> bool:
		return event.type == "grandma_effect_activated" and event.effect_type == "sulphurous"
	))
	assert_eq(day.snapshot().effective_target_score, 16)


func test_sulphurous_can_succeed_on_its_hatching_thwack_without_lowering_appetite_below_one() -> void:
	var day = ChickenDay.new([
		_effect_egg("sulphurous"),
		"chicken",
	], 2, 20)
	var success_events: Array[Dictionary] = day.resolve_circuit("red")
	assert_true(success_events.any(func(event: Dictionary) -> bool:
		return event.type == "day_ended" and event.succeeded
	))
	var activation: Dictionary = success_events.filter(func(event: Dictionary) -> bool:
		return event.type == "grandma_effect_activated" and event.effect_type == "sulphurous"
	)[0]
	assert_eq(activation.suppression_added, 1)
	assert_eq(activation.effective_appetite, 1)
	assert_eq(success_events.filter(func(event: Dictionary) -> bool:
		return event.type == "day_ended"
	)[0].effective_target_score, 1)
	assert_eq(day.snapshot().target_score, 2)
	assert_eq(day.snapshot().effective_target_score, 1)


func test_shockwave_strikes_both_neighbours_without_extra_movement() -> void:
	var day = ChickenDay.new([
		"sparrow",
		_effect_egg("shockwave"),
		"sparrow",
	], 99)
	var events: Array[Dictionary] = day.resolve_circuit("blue")
	var shockwave: Dictionary = events.filter(
		func(event: Dictionary) -> bool: return event.type == "shockwave_fired"
	)[0]
	assert_eq(shockwave.source_slot_index, 1)
	assert_eq(shockwave.slot_indices, [0, 2])
	assert_eq(_hatches(events).size(), 3)
	assert_eq(events.filter(func(event: Dictionary) -> bool:
		return event.type == "conveyor_advanced"
	).size(), 1)


func test_shockwave_handles_boundaries_and_empty_neighbours() -> void:
	var left_day = ChickenDay.new([_effect_egg("shockwave"), "sparrow"], 99)
	var left_events: Array[Dictionary] = left_day.resolve_circuit("red")
	assert_eq(left_events.filter(func(event: Dictionary) -> bool:
		return event.type == "shockwave_fired"
	)[0].slot_indices, [1])
	assert_eq(_hatches(left_events).size(), 2)

	var right_day = ChickenDay.new([
		"chicken", "chicken", "chicken", "chicken", _effect_egg("shockwave"),
	], 99)
	var right_events: Array[Dictionary] = right_day.resolve_circuit("pink")
	assert_eq(right_events.filter(func(event: Dictionary) -> bool:
		return event.type == "shockwave_fired"
	)[0].slot_indices, [3])


func test_shockwave_chains_and_each_broken_egg_resolves_once() -> void:
	var day = ChickenDay.new([
		"sparrow",
		_effect_egg("shockwave"),
		_effect_egg("shockwave"),
	], 99)
	var events: Array[Dictionary] = day.resolve_circuit("blue")
	assert_eq(events.filter(func(event: Dictionary) -> bool:
		return event.type == "shockwave_fired"
	).size(), 2)
	var hatch_ids := _hatches(events).map(
		func(event: Dictionary) -> int: return event.egg_instance_id
	)
	assert_eq(hatch_ids.size(), 3)
	assert_eq(hatch_ids.duplicate().reduce(
		func(unique: Array, egg_id: int) -> Array:
			if not egg_id in unique:
				unique.append(egg_id)
			return unique,
		[]
	).size(), 3)


func test_shockwave_can_trigger_another_on_break_effect_in_conveyor_order() -> void:
	var day = ChickenDay.new([
		_effect_egg("appetiser"),
		_effect_egg("shockwave"),
		"sparrow",
	], 99)
	var events: Array[Dictionary] = day.resolve_circuit("blue")
	var shock_hatches := _hatches(events)

	assert_eq(shock_hatches.map(
		func(event: Dictionary) -> int: return event.slot_index
	), [1, 0, 2])
	assert_eq(shock_hatches.map(
		func(event: Dictionary) -> int: return event.points_awarded
	), [1, 1, 2])
	assert_eq(day.snapshot().grandma_effects.appetiser_charges, 0)


func test_shockwave_inherits_pink_and_uses_spoonbill_direct_vulnerability() -> void:
	var day = ChickenDay.new([
		"chicken", "chicken", "chicken", "spoonbill", _effect_egg("shockwave"),
	], 99)
	assert_eq(day.snapshot().slots[3].kind, "spoonbill")
	assert_eq(day.snapshot().slots[3].toughness, 5)

	var events: Array[Dictionary] = day.resolve_circuit("pink")
	var shock_damage: Dictionary = events.filter(func(event: Dictionary) -> bool:
		return event.type == "egg_damaged" and event.cause == "shockwave"
	)[0]
	assert_eq(shock_damage.kind, "spoonbill")
	assert_eq(shock_damage.circuit_id, "pink")
	assert_eq(shock_damage.damage_amount, 2)
	assert_eq(shock_damage.remaining_toughness, 3)


func test_ending_a_day_clears_all_grandma_effects() -> void:
	var day = ChickenDay.new([_effect_egg("appetiser")], 99)
	var events: Array[Dictionary] = day.resolve_circuit("red")
	assert_true(events.any(func(event: Dictionary) -> bool:
		return event.type == "day_ended"
	))
	assert_eq(day.snapshot().grandma_effects, {
		"appetiser_charges": 0,
		"sulphurous_suppression": 0,
	})


func _effect_egg(effect_type: String) -> Dictionary:
	return {"kind": "sparrow", "effects": [{"type": effect_type}]}


func _hatches(events: Array[Dictionary]) -> Array[Dictionary]:
	var hatches: Array[Dictionary] = []
	for event: Dictionary in events:
		if event.type == "egg_hatched":
			hatches.append(event)
	return hatches


func _event_types(events: Array[Dictionary]) -> Array[String]:
	var types: Array[String] = []
	for event: Dictionary in events:
		types.append(String(event.type))
	return types


func _resolve_until_hatch(day) -> Dictionary:
	for _attempt in range(20):
		var state: Dictionary = day.snapshot()
		var occupied_slot_index := -1
		for slot_index in range(state.slots.size()):
			if not state.slots[slot_index].is_empty():
				occupied_slot_index = slot_index
				break
		var circuit_id := "red"
		if occupied_slot_index in [1, 3]:
			circuit_id = "blue"
		elif occupied_slot_index == 4:
			circuit_id = "pink"
		var hatches := _hatches(day.resolve_circuit(circuit_id))
		if not hatches.is_empty():
			return hatches[0]
	return {}
