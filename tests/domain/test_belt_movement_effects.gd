extends GutTest

const ChickenDay = preload("res://src/domain/chicken_day.gd")


func test_temporary_movement_eggs_have_simple_prototype_values() -> void:
	for kind in ["oily", "nostalgic"]:
		var definition: Dictionary = ChickenDay.egg_definition(kind)
		assert_eq(definition.toughness, 3)
		assert_eq(definition.points, 1)
		assert_eq(definition.thwack_effect, kind)
	assert_eq(ChickenDay.egg_definition("gloopy"), {
		"kind": "gloopy",
		"toughness": 2,
		"points": -1,
		"effect": "gloopy",
		"thwack_effect": "gloopy",
	})


func test_hatching_gloopy_produces_negative_yolk_and_can_lower_satisfaction_below_zero() -> void:
	var day = ChickenDay.new(["gloopy"], 99, 12)
	day.resolve_circuit("red")

	var events: Array[Dictionary] = day.resolve_circuit("red")
	var hatch: Dictionary = _events_of_type(events, "egg_hatched")[0]

	assert_eq(hatch.kind, "gloopy")
	assert_eq(hatch.base_points, -1)
	assert_eq(hatch.yolk_produced, -1)
	assert_eq(hatch.points_awarded, -1)
	assert_eq(hatch.score, -1)
	assert_eq(day.snapshot().score, -1)


func test_negative_gloopy_yolk_does_not_consume_or_receive_appetiser() -> void:
	var appetiser_sparrow := {
		"kind": "sparrow",
		"effects": [{"type": "appetiser"}],
	}
	var day = ChickenDay.new([
		appetiser_sparrow, "chicken", "gloopy", "chicken", "chicken",
	], 99, 12)
	day.resolve_circuit("red")

	var events: Array[Dictionary] = day.resolve_circuit("red")
	var hatch: Dictionary = _events_of_type(events, "egg_hatched")[0]

	assert_eq(hatch.kind, "gloopy")
	assert_eq(hatch.appetiser_multiplier, 1)
	assert_eq(hatch.points_awarded, -1)
	assert_eq(day.snapshot().score, 0)
	assert_eq(day.snapshot().grandma_effects.appetiser_charges, 1)


func test_oily_adds_one_forward_step_before_the_normal_step_for_one_condition() -> void:
	var day = ChickenDay.new([
		"oily", "chicken", "chicken", "chicken", "chicken", "chicken", "chicken",
	], 99, 12)

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(_events_of_type(events, "conveyor_advanced").size(), 2)
	assert_eq(_events_of_type(events, "belt_condition_spent").size(), 1)
	assert_eq(day.snapshot().belt_condition, 11)
	assert_eq(day.snapshot().slots[2].kind, "oily")


func test_nostalgic_reverses_once_then_normal_movement_restores_the_layout() -> void:
	var day = ChickenDay.new([
		"nostalgic", "chicken", "chicken", "chicken", "chicken", "chicken",
	], 99, 12)
	var opening_ids := _slot_ids(day.snapshot())

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(_events_of_type(events, "conveyor_reversed").size(), 1)
	assert_eq(_events_of_type(events, "egg_returned_to_hopper").size(), 1)
	assert_eq(_events_of_type(events, "conveyor_advanced").size(), 1)
	assert_eq(_slot_ids(day.snapshot()), opening_ids)
	assert_eq(day.snapshot().bin_egg_count, 0)


func test_gloopy_blocks_the_normal_step_but_the_thwack_still_costs_condition() -> void:
	var day = ChickenDay.new([
		"gloopy", "chicken", "chicken", "chicken", "chicken", "chicken",
	], 99, 12)
	var opening_ids := _slot_ids(day.snapshot())

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(_events_of_type(events, "movement_instruction_cancelled").size(), 1)
	assert_eq(_events_of_type(events, "conveyor_advanced").size(), 0)
	assert_eq(_events_of_type(events, "conveyor_reversed").size(), 0)
	assert_eq(_slot_ids(day.snapshot()), opening_ids)
	assert_eq(day.snapshot().belt_condition, 11)


func test_direct_effects_resolve_left_to_right_before_normal_movement() -> void:
	var day = ChickenDay.new([
		"gloopy", "chicken", "oily", "chicken", "chicken", "chicken",
	], 99, 12)
	var preview: Dictionary = day.movement_preview("red")

	assert_eq(preview.sequence, ["jam", "forward", "forward"])
	assert_eq(preview.outcomes, ["armed", "blocked", "execute"])

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(_events_of_type(events, "movement_instruction_cancelled")[0].source, "oily")
	assert_eq(_events_of_type(events, "conveyor_advanced").size(), 1)


func test_nostalgic_before_gloopy_reverses_then_blocks_the_normal_step() -> void:
	var day = ChickenDay.new([
		"nostalgic", "chicken", "gloopy", "chicken", "chicken", "chicken",
	], 99, 12)
	var preview: Dictionary = day.movement_preview("red")

	assert_eq(preview.sequence, ["reverse", "jam", "forward"])
	assert_eq(preview.outcomes, ["execute", "armed", "blocked"])

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(_events_of_type(events, "conveyor_reversed").size(), 1)
	assert_eq(_events_of_type(events, "conveyor_advanced").size(), 0)
	assert_eq(_events_of_type(events, "movement_instruction_cancelled")[0].source, "normal")


func test_stacked_gloopy_expires_after_the_turn() -> void:
	var day = ChickenDay.new([
		"gloopy", "chicken", "gloopy", "chicken", "chicken", "chicken",
	], 99, 12)

	var first_events: Array[Dictionary] = day.resolve_circuit("red")
	var second_events: Array[Dictionary] = day.resolve_circuit("blue")

	assert_eq(_events_of_type(first_events, "movement_jams_expired")[0].amount, 1)
	assert_eq(_events_of_type(first_events, "conveyor_advanced").size(), 0)
	assert_eq(_events_of_type(second_events, "conveyor_advanced").size(), 1)


func test_indirect_shockwave_damage_does_not_trigger_an_oily_instruction() -> void:
	var shockwave_sparrow := {
		"kind": "sparrow",
		"effects": [{"type": "shockwave"}],
	}
	var day = ChickenDay.new([
		shockwave_sparrow, "oily", "chicken", "chicken", "chicken", "chicken",
	], 99, 12)

	var events: Array[Dictionary] = day.resolve_circuit("red")

	assert_eq(_events_of_type(events, "shockwave_fired").size(), 1)
	assert_eq(_events_of_type(events, "conveyor_advanced").size(), 1)


func test_snapshot_exposes_domain_resolved_previews_for_every_circuit() -> void:
	var day = ChickenDay.new([
		"gloopy", "nostalgic", "oily", "chicken", "chicken",
	], 99, 12)
	var previews: Dictionary = day.snapshot().movement_previews

	assert_eq(previews.red.sequence, ["jam", "forward", "forward"])
	assert_eq(previews.blue.sequence, ["reverse", "forward"])
	assert_eq(previews.pink.sequence, ["forward"])


func _events_of_type(events: Array[Dictionary], event_type: String) -> Array[Dictionary]:
	var matching: Array[Dictionary] = []
	for event: Dictionary in events:
		if event.type == event_type:
			matching.append(event)
	return matching


func _slot_ids(state: Dictionary) -> Array[int]:
	var ids: Array[int] = []
	for egg: Dictionary in state.slots:
		ids.append(-1 if egg.is_empty() else int(egg.egg_instance_id))
	return ids
