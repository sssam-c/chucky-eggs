extends GutTest

const ChickenDaySession = preload("res://src/game/chicken_day_session.gd")
const ProducerFlock = preload("res://src/domain/producer_flock.gd")
const MotionTokens = preload("res://src/presentation/motion_tokens.gd")
const BirdPortrait = preload("res://src/ui/bird_portrait.gd")
const EggVisual = preload("res://src/ui/egg_visual.gd")
const AUTHORED_DAILY_EGGS: Array[String] = [
	"chicken", "cuckoo", "chicken", "spoonbill",
	"cuckoo", "plover", "chicken", "chicken",
	"chicken", "cuckoo", "chicken", "spoonbill",
	"cuckoo", "plover", "chicken", "chicken",
	"chicken", "cuckoo", "chicken", "spoonbill",
	"cuckoo", "plover", "chicken", "chicken",
]
const EARLY_SUCCESS_CIRCUITS: Array[String] = [
	"RedCircuit", "RedCircuit", "RedCircuit", "BlueCircuit", "RedCircuit", "RedCircuit",
	"RedCircuit", "BlueCircuit", "BlueCircuit", "PinkCircuit", "PinkCircuit",
]


class IdentityShuffler:
	extends RefCounted

	func shuffle_strings(values: Array[String]) -> Array[String]:
		return values.duplicate()

	func shuffle_dictionaries(values: Array[Dictionary]) -> Array[Dictionary]:
		return values.duplicate(true)


func test_each_species_selects_distinct_illustrated_portrait_and_egg_art() -> void:
	var portrait := BirdPortrait.new()
	var egg_visual := EggVisual.new()
	add_child_autofree(portrait)
	add_child_autofree(egg_visual)

	if not portrait.has_method("artwork_region") or not egg_visual.has_method("artwork_region"):
		fail_test("Species visuals must expose their illustrated atlas selection.")
		return

	var portrait_regions: Array[Rect2] = []
	var egg_regions: Array[Rect2] = []
	for kind in ["chicken", "cuckoo", "plover", "spoonbill"]:
		portrait.set_bird_kind(kind)
		egg_visual.set_egg({"kind": kind, "toughness": 3, "max_toughness": 3, "points": 1})
		var portrait_region: Rect2 = portrait.artwork_region()
		var egg_region: Rect2 = egg_visual.artwork_region()
		assert_true(portrait_region.has_area())
		assert_true(egg_region.has_area())
		assert_false(portrait_regions.has(portrait_region))
		assert_false(egg_regions.has(egg_region))
		portrait_regions.append(portrait_region)
		egg_regions.append(egg_region)

	assert_true(ResourceLoader.exists("res://assets/generated/bird_portraits_v1.png"))
	assert_true(ResourceLoader.exists("res://assets/generated/egg_shells_v1.png"))


func test_machine_materials_and_ambience_respect_reduced_motion() -> void:
	var main := _add_main()
	var stage: Control = main.get_node("Content/Stage/Workshop")
	if not stage.has_method("material_texture_count"):
		fail_test("The machine must expose its material texture integration.")
		return
	assert_eq(stage.material_texture_count(), 2)
	assert_true(ResourceLoader.exists("res://assets/generated/dark_timber_v1.png"))
	assert_true(ResourceLoader.exists("res://assets/generated/cast_iron_v1.png"))

	var ambience = main.get_node_or_null("Content/Stage/Ambience")
	assert_not_null(ambience)
	if ambience == null:
		return
	assert_gt(ambience.mote_count(), 0)
	assert_true(ambience.is_motion_active())

	main.set_reduced_motion(true)
	assert_true(ambience.is_reduced_motion())
	assert_false(ambience.is_motion_active())

	main.set_reduced_motion(false)
	assert_false(ambience.is_reduced_motion())
	assert_true(ambience.is_motion_active())


func test_main_renders_initial_day_and_shell_information() -> void:
	var main := _add_main()

	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 0 / 15")
	assert_eq(main.get_node("Content/Header/Cash").text, "CASH £0")
	assert_eq(main.get_node("Content/Header/Cash").accessibility_name, "Cash balance £0")
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 20")
	assert_eq(main.get_node("Content/Header/HopperCount").text, "HOPPER 14")
	var shell_legend: Label = main.get_node("Content/Header/ShellLegend")
	assert_string_contains(shell_legend.text, "DOUBLE YOLK 2%")
	assert_string_contains(shell_legend.text, "RIPPLE")
	assert_string_contains(shell_legend.text, "RETREAT LEFT")
	assert_string_contains(shell_legend.text, "PINK ×2")
	assert_false(shell_legend.text.contains("\n"))
	assert_false(
		main.get_node("Content/Header/Thwacks").get_global_rect().intersects(
			main.get_node("Content/Header/HopperCount").get_global_rect()
		)
	)
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot1").egg_summary(), "TOUGHNESS 3")
	assert_eq(main.get_node("Content/Stage/Pipe/Preview").get_child_count(), 3)
	for preview in main.get_node("Content/Stage/Pipe/Preview").get_children():
		assert_true(preview.egg_kind() in ["chicken", "cuckoo", "plover"])
	assert_not_null(main.get_node("Content/Accessibility/Mute"))
	assert_not_null(main.get_node("Content/Accessibility/ReducedMotion"))
	assert_true(main.theme.has_stylebox("normal", "Button"))
	assert_true(main.theme.has_stylebox("checked", "CheckButton"))


func test_integrated_header_and_footer_keep_day_three_controls_clear() -> void:
	var main := _add_main()
	assert_true(main.start_dev_day(3))
	await get_tree().process_frame

	var header_cabinet: Control = main.get_node("Content/Header/HeaderCabinet")
	for instrument_path in ["TitlePlate", "ShellLegendPlate", "HudPlate"]:
		assert_true(header_cabinet.get_global_rect().encloses(
			(main.get_node("Content/Header/%s" % instrument_path) as Control).get_global_rect()
		))

	var footer_plate: Control = main.get_node("Content/FooterPlate")
	var feedback: Control = main.get_node("Content/Feedback")
	assert_true(footer_plate.get_global_rect().encloses(feedback.get_global_rect()))
	assert_false(main.get_node("Content/Controls").visible)
	for circuit_button: Control in main.get_node("Content/Stage/CircuitBank").get_children():
		if circuit_button.visible:
			assert_false(circuit_button.get_global_rect().intersects(footer_plate.get_global_rect()))


func test_debug_mode_can_replace_the_run_with_a_fresh_day_three() -> void:
	var main := _add_main()

	assert_true(InputMap.has_action("dev_start_day_3"))
	assert_true(main.start_dev_day(3))

	assert_true(main.is_dev_mode())
	assert_eq(main.dev_day_number(), 3)
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 0 / 20")
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 20")
	assert_eq(main.get_node("Content/Stage/Belt/Slots").get_children().filter(
		func(slot: Control) -> bool: return slot.visible
	).size(), 10)
	assert_eq(main.get_node("Content/Stage/CircuitBank").get_children().filter(
		func(control: Control) -> bool: return control.visible
	).size(), 5)
	assert_string_contains(main.get_node("Content/Feedback").text, "DEV MODE  •  DAY 3")

	main.restart_day()

	assert_eq(main.dev_day_number(), 3)
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 0 / 20")


func test_plover_shell_information_shows_the_four_point_payoff() -> void:
	var main := _add_main_for_ordered_eggs(["plover"])
	var slot = main.get_node("Content/Stage/Belt/Slots/Slot1")
	var summary: String = slot.egg_summary()

	assert_string_contains(summary, "TOUGHNESS 6")
	assert_string_contains(summary, "4 POINTS")
	assert_eq(slot.effect_emblem(), "screen_left")


func test_merged_egg_shows_its_quality_tier_and_floored_gameplay_score() -> void:
	var flock = ProducerFlock.new([{"kind": "chicken", "tier": 1}])
	var session = ChickenDaySession.new(42, flock, IdentityShuffler.new())
	var main := _add_main()
	main.replace_session(session)
	var slot = main.get_node("Content/Stage/Belt/Slots/Slot1")

	assert_eq(slot.current_egg().tier, 1)
	assert_almost_eq(float(slot.current_egg().exact_base_points), 4.5, 0.00001)
	assert_string_contains(slot.egg_summary(), "4 POINTS")
	assert_false(slot.egg_summary().contains("4.5"))
	assert_string_contains(slot.egg_description(), "Prize")
	assert_eq(slot.quality_tier(), 1)
	assert_eq(slot.quality_ring_count(), 1)


func test_stage_colours_belt_sections_and_keeps_five_spoons_neutral() -> void:
	var main := _add_main()
	var circuits := main.get_node("Content/Stage/CircuitBank")
	var hammers := main.get_node("Content/Stage/HammerBank")
	var slots := main.get_node("Content/Stage/Belt/Slots")
	var machine_stage := main.get_node("Content/Stage/Workshop")

	assert_eq(circuits.get_child_count(), 5)
	assert_eq(circuits.get_children().filter(func(control: Control) -> bool:
		return control.visible
	).size(), 3)
	assert_eq(hammers.get_child_count(), 5)
	assert_eq(hammers.get_children().filter(func(control: Control) -> bool:
		return control.visible
	).size(), 5)
	assert_eq(circuits.get_node("RedCircuit").circuit_id, "red")
	assert_eq(circuits.get_node("RedCircuit").slot_indices, [0, 2])
	assert_eq(circuits.get_node("RedCircuit").circuit_symbol, "diamond")
	assert_eq(circuits.get_node("BlueCircuit").slot_indices, [1, 3])
	assert_eq(circuits.get_node("BlueCircuit").circuit_symbol, "circle")
	assert_eq(circuits.get_node("PinkCircuit").slot_indices, [4])
	assert_eq(circuits.get_node("PinkCircuit").circuit_symbol, "spark")
	var expected_slot_circuits := ["red", "blue", "red", "blue", "pink"]
	for slot_index in range(5):
		var slot: Control = slots.get_node("Slot%d" % (slot_index + 1))
		assert_eq(slot.circuit_id(), expected_slot_circuits[slot_index])
		assert_gt(slot.circuit_color().a, 0.9)
		assert_eq(machine_stage.belt_section_circuit_id(slot_index), expected_slot_circuits[slot_index])
	for hammer: Control in hammers.get_children():
		assert_false(hammer.is_circuit_marked())
	for circuit_lever: Button in circuits.get_children():
		assert_eq(circuit_lever.control_form(), "lever")
		assert_eq(circuit_lever.text, "")


func test_circuit_lever_has_a_clear_mechanical_throw_and_resets_to_idle() -> void:
	var main := _add_main()
	var lever: Button = main.get_node("Content/Stage/CircuitBank/RedCircuit")
	var idle_handle: Vector2 = lever.lever_handle_center()

	lever.set_press_amount(1.0)
	var pulled_handle: Vector2 = lever.lever_handle_center()

	assert_gt(pulled_handle.x, idle_handle.x)
	assert_gt(pulled_handle.y, idle_handle.y)
	assert_gt(idle_handle.distance_to(pulled_handle), 30.0)
	lever.reset_pose()
	assert_eq(lever.press_amount, 0.0)
	assert_eq(lever.lever_handle_center(), idle_handle)
	assert_eq(lever.mapping_text(), "1+3")


func test_focused_lever_highlights_its_linked_belt_sections() -> void:
	var main := _add_main()
	var stage = main.get_node("Content/Stage/Workshop")
	var red: Button = main.get_node("Content/Stage/CircuitBank/RedCircuit")

	assert_true(red.has_focus())
	assert_eq(stage.highlighted_circuit_id(), "red")

	main.set_reduced_motion(true)
	await _press_and_wait(main, "RedCircuit")
	var blue: Button = main.get_node("Content/Stage/CircuitBank/BlueCircuit")
	assert_false(blue.disabled)
	blue.grab_focus()
	await get_tree().process_frame

	assert_eq(stage.highlighted_circuit_id(), "blue")


func test_early_line_spoons_are_wall_pinned_behind_eggs_and_tip_bowl_first() -> void:
	var main := _add_main()
	var hammers := main.get_node("Content/Stage/HammerBank")
	var slots := main.get_node("Content/Stage/Belt/Slots")

	for slot_index in range(5):
		var hammer = hammers.get_node("Hammer%d" % (slot_index + 1))
		var slot: Control = slots.get_node("Slot%d" % (slot_index + 1))
		var impact: Vector2 = slot.impact_global_position()
		var hinge: Vector2 = hammer.pivot_global_position()
		var stored_bowl: Vector2 = hammer.stored_bowl_global_position()
		var contact_bowl: Vector2 = hammer.contact_bowl_global_position()

		assert_true(hammer.is_wall_pinned_spoon())
		assert_true(hammer.uses_authored_landing_frames())
		assert_eq(hammer.landing_frame_count(), 9)
		assert_true(slot.is_bare_belt_mode())
		assert_almost_eq(stored_bowl.x, impact.x, 1.0)
		assert_almost_eq(hinge.x, impact.x, 1.0)
		assert_lt(stored_bowl.y, hinge.y)
		assert_lt(hinge.y, impact.y)
		assert_lte(impact.y - hinge.y, 18.0)
		assert_almost_eq(contact_bowl.x, impact.x, 1.0)
		assert_almost_eq(contact_bowl.y, impact.y, 1.0)
		assert_lt(hammer.stored_bowl_screen_size().x, hammer.stored_bowl_screen_size().y)
		assert_gt(hammer.contact_bowl_screen_size().x, hammer.contact_bowl_screen_size().y * 3.0)
		assert_gte(hammer.contact_bowl_screen_size().y, 26.0)

		hammer.set_strike_amount(0.50)
		assert_eq(hammer.landing_frame_index(), 4)
		assert_lt(
			hammer.current_bowl_global_positions()[0].distance_to(hinge),
			2.0
		)
		var edge_visual: Dictionary = hammer.bowl_visuals()[0]
		assert_gt(edge_visual.radii.x, edge_visual.radii.y * 2.5)
		assert_eq(hammer.z_index, 0)
		assert_gt(hammer.bowl_foreground_z_index(), main.get_node("Content/Stage/Belt").z_index)

		hammer.set_strike_amount(1.0)
		assert_eq(hammer.landing_frame_index(), 8)
		assert_eq(hammer.z_index, 0)
		assert_gt(hammer.bowl_foreground_z_index(), main.get_node("Content/Stage/Belt").z_index)
		hammer.reset_pose()


func test_only_circuits_with_an_occupied_linked_slot_are_available() -> void:
	var main := _add_main()
	var red: Button = main.get_node("Content/Stage/CircuitBank/RedCircuit")
	var blue: Button = main.get_node("Content/Stage/CircuitBank/BlueCircuit")
	var pink: Button = main.get_node("Content/Stage/CircuitBank/PinkCircuit")

	assert_false(red.disabled)
	assert_true(blue.disabled)
	assert_true(pink.disabled)
	assert_true(red.has_focus())


func test_circuit_levers_have_no_hover_text_and_describe_connections_accessibly() -> void:
	var main := _add_main()
	var red: Button = main.get_node("Content/Stage/CircuitBank/RedCircuit")
	var pink: Button = main.get_node("Content/Stage/CircuitBank/PinkCircuit")

	assert_eq(red.tooltip_text, "")
	assert_eq(red.accessibility_name, "Red diamond lever")
	assert_string_contains(red.accessibility_description, "slots 1 and 3")
	assert_string_contains(red.accessibility_description, "Slot 1: Chicken egg")
	assert_string_contains(red.accessibility_description, "Slot 3: empty")
	assert_eq(pink.accessibility_name, "Pink spark lever")


func test_red_fires_both_connected_spoons_even_when_one_slot_is_empty() -> void:
	var main := _add_main()
	main.set_reduced_motion(true)
	var fired_slots: Array[int] = []
	main.get_node("Presentation").hammer_fired.connect(
		func(slot_index: int) -> void: fired_slots.append(slot_index)
	)

	await _press_and_wait(main, "RedCircuit")

	assert_eq(fired_slots, [0, 2])
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 19")
	assert_eq(main.get_node("Content/Header/HopperCount").text, "HOPPER 13")
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot2").egg_summary(), "TOUGHNESS 2")


func test_circuit_event_and_damage_are_presented_before_the_belt_advances() -> void:
	var main := _add_main()
	main.set_reduced_motion(true)
	var presented: Array[String] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))

	await _press_and_wait(main, "RedCircuit")

	assert_eq(presented, [
		"circuit_fired",
		"egg_damaged",
		"conveyor_advanced",
		"thwack_spent",
		"egg_entered",
	])


func test_original_spoon_rebounds_before_the_egg_damage_response() -> void:
	var main := _add_main()
	main.set_reduced_motion(true)
	var red_spoon: Control = main.get_node("Content/Stage/HammerBank/Hammer1")
	var strike_amounts_during_damage: Array[float] = []
	main.presentation_event.connect(func(event_type: String) -> void:
		if event_type == "egg_damaged":
			strike_amounts_during_damage.append(red_spoon.strike_amount)
	)

	await _press_and_wait(main, "RedCircuit")

	assert_eq(strike_amounts_during_damage, [0.0])
	assert_eq(red_spoon.strike_amount, 0.0)
	assert_false(main.is_input_locked())


func test_second_circuit_press_is_ignored_while_presentation_barrier_is_active() -> void:
	var main := _add_main()
	var red: Button = main.get_node("Content/Stage/CircuitBank/RedCircuit")
	var completion_count := [0]
	main.playback_completed.connect(func() -> void: completion_count[0] += 1)

	red.pressed.emit()
	red.pressed.emit()

	assert_true(main.is_input_locked())
	await main.playback_completed
	await get_tree().process_frame
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 19")
	assert_eq(completion_count[0], 1)


func test_red_pair_presents_two_cuckoo_echoes_before_hatching_and_advancing() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)
	await _press_and_wait(main, "RedCircuit")
	await _press_and_wait(main, "BlueCircuit")
	var presented: Array[String] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))

	await _press_and_wait(main, "RedCircuit")

	assert_eq(presented.slice(0, 7), [
		"circuit_fired",
		"egg_damaged",
		"egg_damaged",
		"egg_damaged",
		"egg_damaged",
		"egg_hatched",
		"conveyor_advanced",
	])
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 3 / 15")


func test_hatch_burst_carries_resolved_points_into_the_score_before_event_completion() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)
	await _press_and_wait(main, "RedCircuit")
	await _press_and_wait(main, "BlueCircuit")
	main.set_reduced_motion(false)
	var presenter := main.get_node("Presentation")
	var payoff := main.get_node("Content/HatchPayoff")
	var milestones: Array[String] = []
	var score_when_burst_started := [""]
	var point_text_when_burst_started := [""]
	presenter.hatch_payoff_started.connect(
		func(_slot_index: int, _points_awarded: int) -> void:
			score_when_burst_started[0] = main.get_node("Content/Header/Score").text
			point_text_when_burst_started[0] = payoff.point_text()
			milestones.append("burst")
	)
	presenter.score_committed.connect(
		func(points_awarded: int, score: int) -> void:
			milestones.append("score:%d:%d" % [points_awarded, score])
	)
	main.presentation_event.connect(
		func(event_type: String) -> void:
			if event_type == "egg_hatched":
				milestones.append("event")
	)

	await _press_and_wait(main, "RedCircuit")

	assert_eq(score_when_burst_started[0], "SCORE 0 / 15")
	assert_eq(point_text_when_burst_started[0], "+3")
	assert_gte(payoff.fragment_count(), 12)
	assert_eq(milestones, ["burst", "score:3:3", "event"])
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 3 / 15")
	assert_false(payoff.is_active())


func test_double_yolk_eggs_look_identical_and_do_not_expose_parent_odds() -> void:
	var flock = ProducerFlock.new([
		{"kind": "chicken"},
		{"kind": "chicken"},
		{"kind": "chicken"},
	])
	var session = ChickenDaySession.new(42, flock, IdentityShuffler.new())
	var main := _add_main()
	main.replace_session(session)
	var first_slot = main.get_node("Content/Stage/Belt/Slots/Slot1")

	assert_eq(float(first_slot.current_egg().double_yolk_chance), 0.02)
	assert_false(first_slot.egg_summary().contains("DOUBLE"))
	assert_false(first_slot.egg_summary().contains("1 IN"))
	assert_false(first_slot.egg_summary().contains("10%"))
	assert_false(first_slot.egg_description().contains("Double Yolker"))
	var previews: Array[Node] = main.get_node("Content/Stage/Pipe/Preview").get_children()
	assert_eq(float(previews[0].current_egg().double_yolk_chance), 0.02)
	assert_eq(float(previews[1].current_egg().double_yolk_chance), 0.02)
	assert_eq(previews[0].egg_summary(), previews[1].egg_summary())
	assert_eq(previews[0].egg_description(), previews[1].egg_description())


func test_parent_loading_tile_does_not_repeat_species_level_odds() -> void:
	var tile = (load("res://src/presentation/producer_output_tile.tscn") as PackedScene).instantiate()
	add_child_autofree(tile)
	tile.render_producer({
		"kind": "chicken",
		"toughness": 3,
		"points": 3,
		"double_yolk_chance": 0.10,
	})

	assert_eq(tile.odds_text(), "")
	assert_eq(float(tile.production_fact.double_yolk_chance), 0.10)


func test_double_yolker_hatch_has_a_large_two_yolk_six_point_payoff() -> void:
	var flock = ProducerFlock.new([
		{"kind": "chicken"},
		{"kind": "chicken"},
		{"kind": "chicken"},
		{"kind": "chicken"},
	])
	var session = null
	for day_seed in range(1000):
		var candidate = ChickenDaySession.new(day_seed, flock, IdentityShuffler.new())
		if bool(candidate.state().slots[0].is_double_yolker):
			session = candidate
			break
	assert_not_null(session)
	var main := _add_main()
	main.replace_session(session)
	main.set_reduced_motion(true)
	await _press_and_wait(main, "RedCircuit")
	await _press_and_wait(main, "BlueCircuit")
	main.set_reduced_motion(false)
	var payoff := main.get_node("Content/HatchPayoff")
	var reveal := ["", "", 0]
	main.get_node("Presentation").hatch_payoff_started.connect(
		func(_slot_index: int, _points_awarded: int) -> void:
			reveal[0] = payoff.jackpot_text()
			reveal[1] = payoff.point_text()
			reveal[2] = payoff.yolk_count()
	)

	await _press_and_wait(main, "RedCircuit")

	assert_eq(reveal, ["DOUBLE YOLKER!", "+6", 2])
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 6 / 15")
	assert_eq(main.get_node("Content/Feedback").text, "DOUBLE YOLKER! A Chicken hatched for 6 points.")
	assert_false(payoff.is_active())


func test_restart_clears_an_interrupted_hatch_payoff_without_committing_score() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)
	await _press_and_wait(main, "RedCircuit")
	await _press_and_wait(main, "BlueCircuit")
	main.set_reduced_motion(false)
	var presenter := main.get_node("Presentation")
	var payoff := main.get_node("Content/HatchPayoff")
	var committed_scores: Array[int] = []
	presenter.score_committed.connect(
		func(_points_awarded: int, score: int) -> void: committed_scores.append(score)
	)

	main.get_node("Content/Stage/CircuitBank/RedCircuit").pressed.emit()
	await presenter.hatch_payoff_started
	assert_true(payoff.is_active())
	main.restart_day()
	await get_tree().process_frame

	assert_false(payoff.is_active())
	assert_eq(payoff.point_text(), "")
	assert_eq(committed_scores, [])
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 0 / 15")


func test_pink_spoonbill_combo_presents_double_damage_and_the_cuckoo_payoff() -> void:
	var main := _add_main_for_ordered_eggs([
		"spoonbill", "cuckoo", "chicken", "chicken", "chicken", "chicken",
	])
	main.set_reduced_motion(true)
	for circuit_name in [
		"RedCircuit", "RedCircuit", "BlueCircuit", "RedCircuit",
	]:
		await _press_and_wait(main, circuit_name)
	var presented: Array[String] = []
	var points_landed: Array[int] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))
	main.get_node("Presentation").score_committed.connect(
		func(points_awarded: int, _score: int) -> void: points_landed.append(points_awarded)
	)

	await _press_and_wait(main, "PinkCircuit")

	assert_eq(presented.slice(0, 5), [
		"circuit_fired", "egg_damaged", "egg_damaged",
		"egg_hatched", "conveyor_advanced",
	])
	assert_eq(points_landed, [1])
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 1 / 15")
	assert_eq(main.get_node("Content/Feedback").text, "Crack! A Cuckoo hatched for 1 point.")


func test_restart_cancels_active_circuit_playback_without_stale_state() -> void:
	var main := _add_main()
	var completion_count := 0
	main.playback_completed.connect(func() -> void: completion_count += 1)

	main.get_node("Content/Stage/CircuitBank/RedCircuit").pressed.emit()
	main.restart_day()
	await get_tree().create_timer(0.5).timeout

	assert_false(main.is_input_locked())
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 20")
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot1").egg_summary(), "TOUGHNESS 3")
	assert_eq(completion_count, 0)


func test_mute_and_reduced_motion_controls_update_presentation() -> void:
	var main := _add_main()

	main.set_muted(true)
	main.set_reduced_motion(true)

	assert_true(main.is_muted())
	assert_true(main.is_reduced_motion())
	assert_true(main.get_node("Content/Accessibility/Mute").button_pressed)
	assert_true(main.get_node("Content/Accessibility/ReducedMotion").button_pressed)
	assert_true(main.get_node("Presentation/UIFeedback").is_muted())
	assert_true(main.get_node("Presentation/UIFeedback").is_reduced_motion())


func test_ui_feedback_uses_shared_motion_tokens_and_cancellable_control_motion() -> void:
	var main := _add_main()
	var feedback = main.get_node("Presentation/UIFeedback")
	var action: Button = main.get_node("ResultOverlay/Card/Content/Restart")

	assert_lt(MotionTokens.SNAP, MotionTokens.SETTLE)
	assert_lt(MotionTokens.SETTLE, MotionTokens.REVEAL)
	assert_true(feedback.is_control_registered(action))
	assert_true(feedback.is_control_registered(
		main.get_node("WorkshopOverlay/Card/Content/RewardChoices/Choice1")
	))
	assert_gte(feedback.registered_control_count(), 12)

	main.set_reduced_motion(false)
	action.button_down.emit()
	assert_true(feedback.is_control_animating(action))
	main.set_reduced_motion(true)
	assert_false(feedback.is_control_animating(action))
	assert_eq(action.scale, Vector2.ONE)


func test_resolved_hud_facts_trigger_non_blocking_ui_feedback() -> void:
	var main := _add_main()
	main.set_reduced_motion(false)
	var feedback = main.get_node("Presentation/UIFeedback")
	var kinds: Array[String] = []
	feedback.feedback_presented.connect(
		func(kind: String) -> void: kinds.append(kind)
	)

	await _press_and_wait(main, "RedCircuit")

	assert_true("thwacks" in kinds)
	assert_true("hopper" in kinds)
	assert_true(feedback.has_active_motion())
	main.set_reduced_motion(true)
	assert_false(feedback.has_active_motion())
	assert_eq(main.get_node("Content/Header/Thwacks").scale, Vector2.ONE)
	assert_eq(main.get_node("Content/Header/HopperCount").scale, Vector2.ONE)
	assert_eq(main.get_node("Content/Header/Thwacks").modulate, Color.WHITE)
	assert_eq(main.get_node("Content/Header/HopperCount").modulate, Color.WHITE)


func test_crunch_audio_streams_are_present_and_non_empty() -> void:
	var main := _add_main()
	var audio_root: Node = main.get_node("Presentation/Audio")

	for player_name in ["Lever", "Impact", "DoubleClink", "Echo", "Shuffle", "Hatch", "Score", "Belt", "Loss", "Pipe"]:
		var player: AudioStreamPlayer = audio_root.get_node(player_name)
		assert_not_null(player.stream, "%s has a stream" % player_name)
		assert_gt(player.stream.data.size(), 1000, "%s stream contains PCM data" % player_name)
	var ui_audio_root: Node = main.get_node("Presentation/UIFeedback/Audio")
	for player_name in ["Focus", "Press", "Confirm", "Reject", "Panel"]:
		var player: AudioStreamPlayer = ui_audio_root.get_node(player_name)
		assert_not_null(player.stream, "%s UI sound has a stream" % player_name)
		assert_gt(player.stream.data.size(), 1000, "%s UI sound contains PCM data" % player_name)


func test_day_result_appears_when_hopper_and_conveyor_are_empty() -> void:
	var main := _add_main_for_ordered_eggs(["chicken"])
	main.set_reduced_motion(true)

	for circuit_name in ["RedCircuit", "BlueCircuit", "RedCircuit"]:
		await _press_and_wait(main, circuit_name)

	var result_panel: Control = main.get_node("ResultOverlay")
	assert_true(result_panel.visible)
	assert_eq(main.get_node("ResultOverlay/Card/Content/Result").text, "DAY FAILED")
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 17")
	assert_false(main.get_node("WorkshopOverlay").visible)
	assert_true(main.get_node("ResultOverlay/Card/Content/Restart").visible)
	assert_eq(main.get_node("ResultOverlay/Card/Content/Restart").text, "RETRY DAY 1")
	assert_eq(main.get_node("ResultOverlay/Card/Content/CashPayout").text, "NO CASH EARNED  •  BALANCE £0")
	assert_eq(
		main.get_node("ResultOverlay/Card/Content/FlockSummary").text,
		"FLOCK 1 PRODUCER  •  DAILY OUTPUT 1 EGG"
	)

	main.get_node("ResultOverlay/Card/Content/Restart").pressed.emit()
	assert_false(result_panel.visible)
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 20")


func test_success_result_ledger_is_acknowledged_before_the_store_opens() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)

	await _complete_successful_day(main, false)
	await get_tree().process_frame

	var result_overlay: Control = main.get_node("ResultOverlay")
	var result_card: Control = main.get_node("ResultOverlay/Card")
	assert_true(result_overlay.visible)
	assert_false(main.get_node("WorkshopOverlay").visible)
	assert_eq(main.get_node("ResultOverlay/Card/Content/Result").text, "DAY 1 COMPLETE")
	assert_string_contains(
		main.get_node("ResultOverlay/Card/Content/ResultScore").text,
		"TARGET MET"
	)
	assert_string_contains(
		main.get_node("ResultOverlay/Card/Content/CashPayout").text,
		"BALANCE £8"
	)
	assert_string_contains(
		main.get_node("ResultOverlay/Card/Content/FlockSummary").text,
		"FLOCK 24"
	)
	for panel_path in ["HeaderRack", "LedgerPanel", "ActionWell"]:
		assert_true(result_card.get_global_rect().encloses(
			main.get_node("ResultOverlay/Card/Content/%s" % panel_path).get_global_rect()
		))
	var action: Button = main.get_node("ResultOverlay/Card/Content/Restart")
	assert_eq(action.text, "ENTER THE GENERAL STORE")
	assert_true(action.has_focus())
	assert_false(main.is_result_transition_active())

	action.pressed.emit()
	await get_tree().process_frame

	assert_false(result_overlay.visible)
	assert_true(main.get_node("WorkshopOverlay").visible)
	assert_true(main.get_node(
		"WorkshopOverlay/Card/Content/RewardChoices/Choice1"
	).has_focus())


func test_result_reveal_is_cancelled_when_the_session_is_replaced() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(false)

	await _complete_successful_day(main, false)

	assert_true(main.is_result_transition_active())
	main.replace_session(ChickenDaySession.new())
	await get_tree().process_frame
	assert_false(main.is_result_transition_active())
	assert_false(main.get_node("ResultOverlay").visible)


func test_success_opens_one_shop_with_three_legible_recruitment_offers() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)

	await _complete_successful_day(main)

	var choices: HBoxContainer = main.get_node("WorkshopOverlay/Card/Content/RewardChoices")
	var offered_kinds: Array[String] = []
	for choice in choices.get_children().filter(func(button: Button) -> bool: return button.visible):
		offered_kinds.append(choice.producer_kind)
		assert_eq(choice.portrait_kind(), choice.producer_kind)
		assert_eq(choice.preview_egg_kind(), choice.producer_kind)
		assert_eq(choice.preview_egg_count(), 1)
		assert_string_contains(choice.card_text(), "EGG")
		assert_string_contains(choice.card_text(), "TOUGHNESS")
		assert_string_contains(choice.card_text(), "POINT")
		assert_string_contains(choice.card_text(), "£3")
		assert_eq(choice.tooltip_text, "")
	assert_false(main.get_node("ResultOverlay").visible)
	assert_true(main.get_node("WorkshopOverlay").visible)
	assert_gt(main.get_node("WorkshopOverlay").z_index, main.get_node("Content").z_index)
	assert_true(choices.visible)
	assert_eq(choices.get_child_count(), 3)
	assert_eq(offered_kinds.duplicate().reduce(
		func(unique: Array, kind: String) -> Array:
			if kind not in unique:
				unique.append(kind)
			return unique,
		[]
	).size(), 3)
	assert_string_contains(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopSummary").text,
		"DAY 2 TARGET 20"
	)
	assert_eq(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopBalance").text,
		"BALANCE £8"
	)
	assert_string_contains(main.get_node("WorkshopOverlay/Card/Content/MergeSummary").text, "0 MERGES QUEUED")
	var chicken_source := _pairing_source_button(main, "chicken:0")
	assert_not_null(chicken_source)
	assert_string_contains(chicken_source.text, "STANDARD CHICKEN")
	assert_string_contains(chicken_source.text, "PERFECT PAIRS")
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 8")
	await get_tree().process_frame
	assert_true(choices.get_child(0).has_focus())
	var shop_card: Control = main.get_node("WorkshopOverlay/Card")
	assert_true(main.get_global_rect().encloses(shop_card.get_global_rect()))
	for shop_section_path in [
		"WorkshopOverlay/Card/Content/RewardChoices",
		"WorkshopOverlay/Card/Content/MergeActions",
		"WorkshopOverlay/Card/Content/RetirementActions",
		"WorkshopOverlay/Card/Content/WorkshopActions",
	]:
		assert_true(shop_card.get_global_rect().encloses(
			(main.get_node(shop_section_path) as Control).get_global_rect()
		), "%s stays inside the shop card" % shop_section_path)
	var header_rack: Control = main.get_node("WorkshopOverlay/Card/Content/HeaderRack")
	for header_path in ["Title", "WorkshopBalance", "WorkshopSummary"]:
		assert_true(header_rack.get_global_rect().encloses(
			(main.get_node("WorkshopOverlay/Card/Content/%s" % header_path) as Control).get_global_rect()
		), "%s stays inside the store header" % header_path)
	var recruitment_panel: Control = main.get_node(
		"WorkshopOverlay/Card/Content/RecruitmentPanel"
	)
	assert_true(recruitment_panel.get_global_rect().encloses(choices.get_global_rect()))
	for choice: Button in choices.get_children():
		assert_gte(choice.custom_minimum_size.x, 320.0)
		assert_gte(choice.custom_minimum_size.y, 200.0)
	assert_true(main.get_node(
		"WorkshopOverlay/Card/Content/ManagementPanel"
	).get_global_rect().encloses(
		main.get_node("WorkshopOverlay/Card/Content/MergeActions").get_global_rect()
	))
	assert_true(main.get_node(
		"WorkshopOverlay/Card/Content/FlockLedger"
	).get_global_rect().encloses(
		main.get_node("WorkshopOverlay/Card/Content/RetirementActions").get_global_rect()
	))


func test_pairing_picker_greys_unmatched_sources_then_queues_the_chosen_match() -> void:
	var producers: Array[Dictionary] = []
	for egg_index in range(7):
		producers.append({"kind": "chicken"})
	var session = ChickenDaySession.new(
		42, ProducerFlock.new(producers), IdentityShuffler.new()
	)
	for circuit_id in [
		"red", "red", "red", "blue", "red", "red",
		"red", "blue", "blue", "pink", "pink",
	]:
		session.submit_circuit(circuit_id)
		if session.state().phase != "day":
			break
	assert_eq(session.state().phase, "shop")
	assert_eq(session.purchase_producer("cuckoo")[0].type, "producer_purchased")

	var main := _add_main()
	main.set_reduced_motion(true)
	main.replace_session(session)
	await get_tree().process_frame

	var source_buttons: VBoxContainer = main.get_node(
		"WorkshopOverlay/Card/Content/MergeActions/PairingSources/SourceScroll/PairingSourceButtons"
	)
	var partner_buttons: VBoxContainer = main.get_node(
		"WorkshopOverlay/Card/Content/MergeActions/PairingPartners/PartnerScroll/PairingPartnerButtons"
	)
	assert_eq(source_buttons.get_child_count(), 2)
	assert_eq(partner_buttons.get_child_count(), 0)

	var chicken_source: Button
	var cuckoo_source: Button
	for button: Button in source_buttons.get_children():
		if String(button.get_meta("pairing_source_id")) == "chicken:0":
			chicken_source = button
		if String(button.get_meta("pairing_source_id")) == "cuckoo:0":
			cuckoo_source = button
	assert_not_null(chicken_source)
	assert_not_null(cuckoo_source)
	assert_false(chicken_source.disabled)
	assert_true(cuckoo_source.disabled)
	assert_string_contains(cuckoo_source.text, "NO PERFECT MATCH")
	assert_true(main.get_node("Presentation/UIFeedback").is_control_registered(chicken_source))

	chicken_source.pressed.emit()
	await get_tree().process_frame

	assert_eq(partner_buttons.get_child_count(), 1)
	var partner: Button = partner_buttons.get_child(0)
	assert_false(partner.disabled)
	assert_string_contains(partner.text, "PERFECT MATCH")
	assert_string_contains(partner.text, "£1")
	assert_string_contains(partner.accessibility_description, "one pound")

	var cash_before := int(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopBalance").text.trim_prefix("BALANCE £")
	)
	partner.pressed.emit()
	await get_tree().process_frame

	assert_eq(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopBalance").text,
		"BALANCE £%d" % (cash_before - 1)
	)
	assert_string_contains(main.get_node("WorkshopOverlay/Card/Content/MergeSummary").text, "1 MERGE QUEUED")
	assert_string_contains(main.get_node("WorkshopOverlay/Card/Content/WorkshopStatus").text, "£1 PAID")


func test_store_motion_is_cancellable_and_reduced_motion_opens_immediately() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(false)

	await _complete_successful_day(main)

	assert_true(main.get_node("WorkshopOverlay").visible)
	assert_true(main.is_workshop_transition_active())
	main.replace_session(ChickenDaySession.new())
	await get_tree().process_frame
	assert_false(main.is_workshop_transition_active())
	assert_false(main.get_node("WorkshopOverlay").visible)

	main = _add_authored_main()
	main.set_reduced_motion(true)
	await _complete_successful_day(main)
	assert_true(main.get_node("WorkshopOverlay").visible)
	assert_false(main.is_workshop_transition_active())


func test_early_success_shows_unused_thwack_payout_and_persistent_balance() -> void:
	var daily_eggs: Array[String] = []
	daily_eggs.resize(7)
	daily_eggs.fill("chicken")
	var main := _add_main_for_ordered_eggs(daily_eggs)
	main.set_reduced_motion(true)
	var presented: Array[String] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))

	for circuit_name: String in EARLY_SUCCESS_CIRCUITS:
		await _press_and_wait(main, circuit_name)

	assert_eq(presented.slice(-3), ["day_remainder_discarded", "day_ended", "cash_awarded"])
	assert_eq(main.get_node("Content/Header/Cash").text, "CASH £10")
	assert_eq(main.get_node("Content/Header/Cash").accessibility_name, "Cash balance £10")
	assert_eq(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopBalance").text,
		"BALANCE £10"
	)
	assert_true(main.get_node("ResultOverlay").visible)
	assert_false(main.get_node("WorkshopOverlay").visible)
	main.get_node("ResultOverlay/Card/Content/Restart").pressed.emit()
	await get_tree().process_frame
	assert_true(main.get_node("WorkshopOverlay").visible)


func test_shop_allows_multiple_purchases_then_leave_starts_day_two() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)
	await _complete_successful_day(main)
	var first_choice = main.get_node("WorkshopOverlay/Card/Content/RewardChoices/Choice1")
	var expected_hopper_count := 24
	var loading_facts: Array[Vector2i] = []
	main.production_loading_started.connect(
		func(producer_count: int, egg_count: int) -> void:
			loading_facts.append(Vector2i(producer_count, egg_count))
	)

	first_choice.pressed.emit()
	await get_tree().process_frame

	assert_false(main.get_node("ResultOverlay").visible)
	assert_true(main.get_node("WorkshopOverlay").visible)
	assert_eq(main.get_node("WorkshopOverlay/Card/Content/WorkshopBalance").text, "BALANCE £5")
	assert_string_contains(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopStatus").text,
		"RECRUITED"
	)
	_pairing_source_button(main, "chicken:0").pressed.emit()
	await get_tree().process_frame
	main.get_node(
		"WorkshopOverlay/Card/Content/MergeActions/PairingPartners/PartnerScroll/PairingPartnerButtons"
	).get_child(0).pressed.emit()
	await get_tree().process_frame
	assert_eq(main.get_node("WorkshopOverlay/Card/Content/WorkshopBalance").text, "BALANCE £4")
	assert_string_contains(main.get_node("WorkshopOverlay/Card/Content/MergeSummary").text, "1 MERGE QUEUED")
	assert_string_contains(main.get_node("WorkshopOverlay/Card/Content/WorkshopStatus").text, "PAIR QUEUED")
	var ui_feedback = main.get_node("Presentation/UIFeedback")
	assert_eq(ui_feedback.last_feedback_kind(), "confirm")
	var extra_thwack: Button = main.get_node(
		"WorkshopOverlay/Card/Content/MergeActions/FactoryColumn/ExtraThwack"
	)
	extra_thwack.pressed.emit()
	await get_tree().process_frame
	assert_eq(ui_feedback.last_feedback_kind(), "reject")
	assert_string_contains(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopStatus").text,
		"PURCHASE DECLINED"
	)
	assert_eq(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").text,
		"LEAVE SHOP & START DAY 2"
	)

	main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").pressed.emit()
	await main.production_loading_completed
	await get_tree().process_frame

	assert_eq(loading_facts, [Vector2i(24, 24)])
	assert_false(main.get_node("ResultOverlay").visible)
	assert_false(main.get_node("WorkshopOverlay").visible)
	assert_false(main.get_node("ProductionLoader").visible)
	assert_eq(main.get_node("Content/Header/HopperCount").text, "HOPPER %d" % (expected_hopper_count - 1))
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 0 / 20")
	assert_string_contains(main.get_node("Content/Feedback").text, "DAY 2")
	assert_false(main.get_node("Content/Stage/Belt/Slots/Slot1").current_egg().is_empty())
	assert_false(main.get_node("Content/Stage/Belt/Slots/Slot6").visible)
	for hammer_index in range(1, 6):
		assert_true(
			main.get_node("Content/Stage/HammerBank/Hammer%d" % hammer_index)
			.is_wall_pinned_spoon()
		)


func test_day_three_refit_uses_five_single_spoons_with_targeted_extension() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)
	await _complete_successful_day(main)
	main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").pressed.emit()
	await main.production_loading_completed

	await _complete_successful_day(main)
	assert_true(main.get_node("WorkshopOverlay").visible)
	assert_string_contains(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopStatus").text,
		"FREE TEN-BAY HAIRPIN REFIT"
	)
	assert_eq(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").text,
		"FREE REFIT & START DAY 3"
	)

	main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").pressed.emit()
	await main.production_loading_completed
	await get_tree().process_frame

	var circuits := main.get_node("Content/Stage/CircuitBank")
	assert_eq(circuits.get_node("RedCircuit").slot_indices, [0, 2])
	assert_eq(circuits.get_node("BlueCircuit").slot_indices, [1, 3])
	assert_eq(circuits.get_node("GreenCircuit").slot_indices, [6, 8])
	assert_eq(circuits.get_node("PurpleCircuit").slot_indices, [7, 9])
	assert_eq(circuits.get_node("PinkCircuit").slot_indices, [4, 5])
	assert_string_contains(circuits.get_node("RedCircuit").accessibility_description, "slots 1 and 3")
	assert_string_contains(circuits.get_node("GreenCircuit").accessibility_description, "slots 7 and 9")
	assert_string_contains(circuits.get_node("GreenCircuit").accessibility_name, "Green triangle lever")
	assert_string_contains(circuits.get_node("PurpleCircuit").accessibility_name, "Purple hexagon lever")
	assert_true(circuits.get_children().all(func(control: Control) -> bool:
		return control.visible
	))
	assert_true(circuits.get_node("RedCircuit").has_focus())
	for slot_number in range(1, 11):
		assert_true(main.get_node("Content/Stage/Belt/Slots/Slot%d" % slot_number).visible)
	assert_false(main.has_node("Content/Stage/Belt/Slots/Slot11"))
	for hammer_number in range(1, 6):
		assert_true(main.get_node(
			"Content/Stage/HammerBank/Hammer%d" % hammer_number
		).visible)
	assert_false(main.has_node("Content/Stage/HammerBank/Hammer6"))

	var hairpin_slots: Array[Control] = []
	for slot_number in range(1, 11):
		hairpin_slots.append(main.get_node("Content/Stage/Belt/Slots/Slot%d" % slot_number))
	var expected_slot_circuits := [
		"red", "blue", "red", "blue", "pink",
		"pink", "green", "purple", "green", "purple",
	]
	for slot_index in range(hairpin_slots.size()):
		assert_eq(hairpin_slots[slot_index].circuit_id(), expected_slot_circuits[slot_index])
		assert_eq(
			main.get_node("Content/Stage/Workshop").belt_section_circuit_id(slot_index),
			expected_slot_circuits[slot_index]
		)
	for slot_index in range(1, 5):
		assert_eq(hairpin_slots[slot_index].position.y, hairpin_slots[0].position.y)
		assert_gt(hairpin_slots[slot_index].position.x, hairpin_slots[slot_index - 1].position.x)
	assert_eq(hairpin_slots[5].position.x, hairpin_slots[4].position.x)
	assert_gt(hairpin_slots[5].position.y, hairpin_slots[4].position.y)
	for slot_index in range(6, 10):
		assert_eq(hairpin_slots[slot_index].position.y, hairpin_slots[5].position.y)
		assert_lt(hairpin_slots[slot_index].position.x, hairpin_slots[slot_index - 1].position.x)
	assert_lt(main.get_node("Content/Stage/Belt/Drop").position.x, hairpin_slots[9].position.x)
	assert_gte(hairpin_slots[0].scale.x, 0.70)
	assert_true(hairpin_slots.all(func(slot: Control) -> bool: return slot.is_bare_belt_mode()))
	var lower_edge := hairpin_slots[9].position.y + hairpin_slots[9].size.y * hairpin_slots[9].scale.y
	for circuit_button: Button in circuits.get_children():
		assert_gt(circuit_button.position.y, lower_edge)
	var presenter := main.get_node("Presentation")
	for slot_index in range(5):
		assert_eq(presenter.target_extension_for_slot(slot_index), 0.0)
	for slot_index in range(5, 10):
		assert_eq(presenter.target_extension_for_slot(slot_index), 1.0)
	for hammer_index in range(5):
		var hammer: Control = main.get_node(
			"Content/Stage/HammerBank/Hammer%d" % (hammer_index + 1)
		)
		var top_slot: Control = hairpin_slots[hammer_index]
		var bottom_slot: Control = hairpin_slots[9 - hammer_index]
		var top_crown: Vector2 = top_slot.impact_global_position()
		var bottom_crown: Vector2 = bottom_slot.impact_global_position()
		var contact_points: Array[Vector2] = hammer.contact_points_global()
		assert_true(hammer.is_telescoping_spoon())
		assert_eq(contact_points.size(), 2)
		assert_almost_eq(contact_points[0].x, top_crown.x, 1.0)
		assert_almost_eq(contact_points[0].y, top_crown.y, 1.0)
		assert_almost_eq(contact_points[1].x, bottom_crown.x, 1.0)
		assert_almost_eq(contact_points[1].y, bottom_crown.y, 1.0)
		var hinge: Vector2 = hammer.pivot_global_position()
		assert_almost_eq(hinge.x, top_crown.x, 1.0)
		assert_lt(hammer.stored_bowl_global_position().y, hinge.y)
		hammer.extension_amount = 1.0
		hammer.set_strike_amount(1.0)
		assert_almost_eq(hammer.current_bowl_global_positions()[0].x, bottom_crown.x, 1.0)
		assert_almost_eq(hammer.current_bowl_global_positions()[0].y, bottom_crown.y, 1.0)
		hammer.extension_amount = 0.0
		assert_almost_eq(hammer.current_bowl_global_positions()[0].x, top_crown.x, 1.0)
		assert_almost_eq(hammer.current_bowl_global_positions()[0].y, top_crown.y, 1.0)
		hammer.reset_pose()

	var pink_hammer: Control = main.get_node("Content/Stage/HammerBank/Hammer5")

	var fired_spoons: Array[int] = []
	var extension_amounts_at_strikes: Array[float] = []
	var spoon_motion_phases: Array[String] = []
	main.set_reduced_motion(false)
	main.get_node("Presentation").hammer_fired.connect(
		func(spoon_index: int) -> void: fired_spoons.append(spoon_index)
	)
	main.get_node("Presentation").spoon_motion_phase_reached.connect(
		func(phase: String) -> void: spoon_motion_phases.append(phase)
	)
	main.presentation_event.connect(func(event_type: String) -> void:
		if event_type == "spoon_struck":
			extension_amounts_at_strikes.append(
				pink_hammer.extension_amount
			)
	)
	await _press_and_wait(main, "RedCircuit")
	assert_eq(fired_spoons, [0, 2])
	assert_true(extension_amounts_at_strikes.is_empty())
	assert_true(spoon_motion_phases.is_empty())
	assert_eq(main.get_node("Content/Stage/HammerBank/Hammer1").strike_amount, 0.0)
	assert_eq(main.get_node("Content/Stage/HammerBank/Hammer3").strike_amount, 0.0)
	assert_false(main.is_input_locked())

	await _press_and_wait(main, "RedCircuit")
	await _press_and_wait(main, "BlueCircuit")
	await _press_and_wait(main, "RedCircuit")
	fired_spoons.clear()
	spoon_motion_phases.clear()
	extension_amounts_at_strikes.clear()
	await _press_and_wait(main, "PinkCircuit")
	assert_eq(fired_spoons, [4])
	assert_eq(extension_amounts_at_strikes, [1.0, 0.0])
	assert_eq(spoon_motion_phases, [
		"extended_on_wall", "near_contact", "returned_to_wall",
		"retracted_on_wall", "far_contact",
	])
	assert_eq(pink_hammer.strike_amount, 0.0)
	assert_eq(pink_hammer.extension_amount, 0.0)
	assert_false(main.is_input_locked())


func test_replacing_the_session_cancels_an_active_production_loading_sequence() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)
	await _complete_successful_day(main)
	main.set_reduced_motion(false)
	var completion_count := [0]
	var started_count := [0]
	main.production_loading_completed.connect(func() -> void: completion_count[0] += 1)
	main.production_loading_started.connect(
		func(_producer_count: int, _egg_count: int) -> void: started_count[0] += 1
	)

	main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").pressed.emit()
	while started_count[0] == 0:
		await get_tree().process_frame
	assert_eq(started_count[0], 1)
	assert_true(main.is_input_locked())
	assert_true(main.get_node("ProductionLoader").is_active())

	main.replace_session(ChickenDaySession.new())
	await get_tree().create_timer(0.25).timeout

	assert_false(main.get_node("ProductionLoader").is_active())
	assert_false(main.get_node("ProductionLoader").visible)
	assert_false(main.is_input_locked())
	assert_eq(completion_count[0], 0)
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 0 / 15")


func _press_and_wait(main: Control, circuit_name: String) -> void:
	var circuit_button: Button = main.get_node("Content/Stage/CircuitBank/%s" % circuit_name)
	if circuit_button.disabled:
		return
	circuit_button.pressed.emit()
	await main.playback_completed
	await get_tree().process_frame


func _complete_successful_day(main: Control, acknowledge_result := true) -> void:
	for circuit_name in [
		"RedCircuit", "BlueCircuit", "RedCircuit", "BlueCircuit", "RedCircuit",
		"BlueCircuit", "RedCircuit", "PinkCircuit", "RedCircuit", "BlueCircuit",
		"RedCircuit", "BlueCircuit", "RedCircuit", "BlueCircuit", "RedCircuit",
		"PinkCircuit", "RedCircuit", "BlueCircuit", "RedCircuit", "BlueCircuit",
	]:
		if main.get_node("Content/Stage/CircuitBank/%s" % circuit_name).disabled:
			continue
		await _press_and_wait(main, circuit_name)
		if main.get_node("ResultOverlay").visible or main.get_node("WorkshopOverlay").visible:
			break
	if (
		acknowledge_result
		and main.get_node("ResultOverlay").visible
		and main.get_node("ResultOverlay/Card/Content/Result").text.contains("COMPLETE")
	):
		main.get_node("ResultOverlay/Card/Content/Restart").pressed.emit()
		await get_tree().process_frame


func _pairing_source_button(main: Control, source_id: String) -> Button:
	var container: VBoxContainer = main.get_node(
		"WorkshopOverlay/Card/Content/MergeActions/PairingSources/SourceScroll/PairingSourceButtons"
	)
	for button: Button in container.get_children():
		if button.visible and String(button.get_meta("pairing_source_id", "")) == source_id:
			return button
	return null


func _add_main() -> Control:
	var packed_scene := load("res://src/ui/main.tscn") as PackedScene
	var main := packed_scene.instantiate() as Control
	add_child_autofree(main)
	return main


func _add_authored_main() -> Control:
	return _add_main_for_ordered_eggs(AUTHORED_DAILY_EGGS)


func _add_main_for_ordered_eggs(egg_kinds: Array[String]) -> Control:
	var producers: Array[Dictionary] = []
	for kind: String in egg_kinds:
		producers.append({"kind": kind})
	var session = ChickenDaySession.new(
		0,
		ProducerFlock.new(producers),
		IdentityShuffler.new()
	)
	var main := _add_main()
	main.replace_session(session)
	return main
