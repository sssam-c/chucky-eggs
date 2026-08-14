extends GutTest

const ChickenDaySession = preload("res://src/game/chicken_day_session.gd")
const ProducerFlock = preload("res://src/domain/producer_flock.gd")
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


func test_main_renders_initial_day_and_shell_information() -> void:
	var main := _add_main()

	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 0 / 15")
	assert_eq(main.get_node("Content/Header/Cash").text, "CASH £0")
	assert_eq(main.get_node("Content/Header/Cash").accessibility_name, "Cash balance £0")
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 20")
	assert_eq(main.get_node("Content/Header/HopperCount").text, "HOPPER 14")
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


func test_stage_starts_with_three_levers_and_five_visible_colour_matched_spoons() -> void:
	var main := _add_main()
	var circuits := main.get_node("Content/Stage/CircuitBank")
	var hammers := main.get_node("Content/Stage/HammerBank")

	assert_eq(circuits.get_child_count(), 5)
	assert_eq(circuits.get_children().filter(func(control: Control) -> bool:
		return control.visible
	).size(), 3)
	assert_eq(hammers.get_child_count(), 5)
	assert_eq(circuits.get_node("RedCircuit").circuit_id, "red")
	assert_eq(circuits.get_node("RedCircuit").slot_indices, [0, 2])
	assert_eq(circuits.get_node("RedCircuit").circuit_symbol, "diamond")
	assert_eq(circuits.get_node("BlueCircuit").slot_indices, [1, 3])
	assert_eq(circuits.get_node("BlueCircuit").circuit_symbol, "circle")
	assert_eq(circuits.get_node("PinkCircuit").slot_indices, [4])
	assert_eq(circuits.get_node("PinkCircuit").circuit_symbol, "spark")
	assert_eq(hammers.get_node("Hammer1").circuit_id, "red")
	assert_eq(hammers.get_node("Hammer2").circuit_id, "blue")
	assert_eq(hammers.get_node("Hammer3").circuit_id, "red")
	assert_eq(hammers.get_node("Hammer4").circuit_id, "blue")
	assert_eq(hammers.get_node("Hammer5").circuit_id, "pink")
	assert_eq(hammers.get_node("Hammer5").circuit_symbol, "spark")
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

		hammer.set_strike_amount(1.0)
		assert_gt(hammer.z_index, main.get_node("Content/Stage/Belt").z_index)
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


func test_crunch_audio_streams_are_present_and_non_empty() -> void:
	var main := _add_main()
	var audio_root: Node = main.get_node("Presentation/Audio")

	for player_name in ["Lever", "Impact", "DoubleClink", "Echo", "Shuffle", "Hatch", "Score", "Belt", "Loss", "Pipe"]:
		var player: AudioStreamPlayer = audio_root.get_node(player_name)
		assert_not_null(player.stream, "%s has a stream" % player_name)
		assert_gt(player.stream.data.size(), 1000, "%s stream contains PCM data" % player_name)


func test_day_result_appears_when_hopper_and_conveyor_are_empty() -> void:
	var main := _add_main_for_ordered_eggs(["chicken"])
	main.set_reduced_motion(true)

	for circuit_name in ["RedCircuit", "BlueCircuit", "RedCircuit"]:
		await _press_and_wait(main, circuit_name)

	var result_panel: Control = main.get_node("ResultOverlay")
	assert_true(result_panel.visible)
	assert_eq(main.get_node("ResultOverlay/Card/Content/Result").text, "DAY FAILED")
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 17")
	assert_false(main.get_node("ResultOverlay/Card/Content/RewardChoices").visible)
	assert_true(main.get_node("ResultOverlay/Card/Content/Restart").visible)
	assert_eq(main.get_node("ResultOverlay/Card/Content/Restart").text, "RETRY DAY 1")
	assert_eq(main.get_node("ResultOverlay/Card/Content/CashPayout").text, "NO CASH EARNED  •  BALANCE £0")

	main.get_node("ResultOverlay/Card/Content/Restart").pressed.emit()
	assert_false(result_panel.visible)
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 20")


func test_success_opens_three_legible_producer_choices_instead_of_retry() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)

	await _complete_successful_day(main)

	var choices: HBoxContainer = main.get_node("ResultOverlay/Card/Content/RewardChoices")
	var offered_kinds: Array[String] = []
	for choice in choices.get_children():
		offered_kinds.append(choice.producer_kind)
		assert_eq(choice.portrait_kind(), choice.producer_kind)
		assert_eq(choice.preview_egg_kind(), choice.producer_kind)
		assert_eq(choice.preview_egg_count(), choice.daily_yield)
		assert_string_contains(choice.card_text(), "EGG")
		assert_string_contains(choice.card_text(), "TOUGHNESS")
		assert_string_contains(choice.card_text(), "POINT")
		assert_eq(choice.tooltip_text, "")
	assert_true(main.get_node("ResultOverlay").visible)
	assert_gt(main.get_node("ResultOverlay").z_index, main.get_node("Content").z_index)
	assert_eq(main.get_node("ResultOverlay/Card/Content/Result").text, "CHOOSE A PRODUCER")
	assert_true(choices.visible)
	assert_eq(choices.get_child_count(), 3)
	assert_eq(offered_kinds.duplicate().reduce(
		func(unique: Array, kind: String) -> Array:
			if kind not in unique:
				unique.append(kind)
			return unique,
		[]
	).size(), 3)
	assert_false(main.get_node("ResultOverlay/Card/Content/Restart").visible)
	assert_eq(main.get_node("ResultOverlay/Card/Content/FlockSummary").text, "FLOCK 24 PRODUCERS  •  DAILY OUTPUT 24 EGGS")
	assert_string_contains(
		main.get_node("ResultOverlay/Card/Content/Summary").text,
		"DAY 2 TARGET: 20 POINTS"
	)
	assert_eq(
		main.get_node("ResultOverlay/Card/Content/CashPayout").text,
		"£8 BANKED FROM 8 UNUSED THWACKS  •  BALANCE £8"
	)
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 8")
	await get_tree().process_frame
	assert_true(choices.get_child(0).has_focus())


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
	assert_eq(main.get_node("Content/Header/Cash").text, "CASH £9")
	assert_eq(main.get_node("Content/Header/Cash").accessibility_name, "Cash balance £9")
	assert_eq(
		main.get_node("ResultOverlay/Card/Content/CashPayout").text,
		"£9 BANKED FROM 9 UNUSED THWACKS  •  BALANCE £9"
	)
	assert_true(main.get_node("ResultOverlay").visible)


func test_selecting_a_producer_opens_workshop_then_continue_starts_day_two() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)
	await _complete_successful_day(main)
	var first_choice = main.get_node("ResultOverlay/Card/Content/RewardChoices/Choice1")
	var expected_hopper_count: int = 23 + first_choice.daily_yield
	var loading_facts: Array[Vector2i] = []
	main.production_loading_started.connect(
		func(producer_count: int, egg_count: int) -> void:
			loading_facts.append(Vector2i(producer_count, egg_count))
	)

	first_choice.pressed.emit()
	await get_tree().process_frame

	assert_false(main.get_node("ResultOverlay").visible)
	assert_true(main.get_node("WorkshopOverlay").visible)
	assert_eq(main.get_node("WorkshopOverlay/Card/Content/WorkshopBalance").text, "BALANCE £8")
	assert_string_contains(
		main.get_node("WorkshopOverlay/Card/Content/ExtensionPlate/Offer/WorkshopStatus").text,
		"RED 1+3"
	)
	assert_eq(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").text,
		"START DAY 2"
	)

	main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").pressed.emit()
	await main.production_loading_completed
	await get_tree().process_frame

	assert_eq(loading_facts, [Vector2i(25, 24 + first_choice.daily_yield)])
	assert_false(main.get_node("ResultOverlay").visible)
	assert_false(main.get_node("WorkshopOverlay").visible)
	assert_false(main.get_node("ProductionLoader").visible)
	assert_eq(main.get_node("Content/Header/HopperCount").text, "HOPPER %d" % expected_hopper_count)
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 0 / 20")
	assert_string_contains(main.get_node("Content/Feedback").text, "DAY 2")
	assert_false(main.get_node("Content/Stage/Belt/Slots/Slot1").current_egg().is_empty())
	assert_false(main.get_node("Content/Stage/Belt/Slots/Slot6").visible)
	for hammer_index in range(1, 6):
		assert_true(
			main.get_node("Content/Stage/HammerBank/Hammer%d" % hammer_index)
			.is_wall_pinned_spoon()
		)


func test_day_three_refit_builds_five_independent_double_bowled_wall_spoons() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)
	await _complete_successful_day(main)
	main.get_node("ResultOverlay/Card/Content/RewardChoices/Choice1").pressed.emit()
	await get_tree().process_frame
	main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").pressed.emit()
	await main.production_loading_completed

	await _complete_successful_day(main)
	main.get_node("ResultOverlay/Card/Content/RewardChoices/Choice1").pressed.emit()
	await get_tree().process_frame

	assert_true(main.get_node("WorkshopOverlay").visible)
	assert_string_contains(
		main.get_node("WorkshopOverlay/Card/Content/ExtensionPlate/Offer/WorkshopStatus").text,
		"FIVE DOUBLE-BOWLED SPOONS"
	)
	assert_eq(
		main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").text,
		"REFIT & START DAY 3"
	)

	main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").pressed.emit()
	await main.production_loading_completed
	await get_tree().process_frame

	var circuits := main.get_node("Content/Stage/CircuitBank")
	assert_eq(circuits.get_node("RedCircuit").slot_indices, [0, 9])
	assert_eq(circuits.get_node("BlueCircuit").slot_indices, [1, 8])
	assert_eq(circuits.get_node("GreenCircuit").slot_indices, [2, 7])
	assert_eq(circuits.get_node("PurpleCircuit").slot_indices, [3, 6])
	assert_eq(circuits.get_node("PinkCircuit").slot_indices, [4, 5])
	assert_string_contains(circuits.get_node("RedCircuit").accessibility_description, "slots 1 and 10")
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
		assert_true(main.get_node("Content/Stage/HammerBank/Hammer%d" % hammer_number).visible)

	var hairpin_slots: Array[Control] = []
	for slot_number in range(1, 11):
		hairpin_slots.append(main.get_node("Content/Stage/Belt/Slots/Slot%d" % slot_number))
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
	var column_lever_names := [
		"RedCircuit", "BlueCircuit", "GreenCircuit", "PurpleCircuit", "PinkCircuit",
	]
	for hammer_index in range(5):
		var hammer: Control = main.get_node(
			"Content/Stage/HammerBank/Hammer%d" % (hammer_index + 1)
		)
		var lever: Control = circuits.get_node(column_lever_names[hammer_index])
		var top_slot: Control = hairpin_slots[hammer_index]
		var bottom_slot: Control = hairpin_slots[9 - hammer_index]
		var top_crown: Vector2 = top_slot.impact_global_position()
		var bottom_crown: Vector2 = bottom_slot.impact_global_position()
		var contact_points: Array[Vector2] = hammer.contact_points_global()
		var stored_points: Array[Vector2] = hammer.stored_bowl_global_positions()
		assert_true(hammer.is_double_bowled_spoon())
		assert_true(hammer.has_continuous_handle())
		assert_true(hammer.uses_authored_double_spoon_frames())
		assert_eq(hammer.double_spoon_frame_count(), 9)
		assert_eq(contact_points.size(), 2)
		assert_eq(stored_points.size(), 2)
		assert_almost_eq(contact_points[0].x, top_crown.x, 1.0)
		assert_almost_eq(contact_points[0].y, top_crown.y, 1.0)
		assert_almost_eq(contact_points[1].x, bottom_crown.x, 1.0)
		assert_almost_eq(contact_points[1].y, bottom_crown.y, 1.0)
		var hinge: Vector2 = hammer.pivot_global_position()
		var lever_conduit_x := (lever.get_global_transform() * (lever.size * 0.5)).x
		assert_almost_eq(hinge.x, lever_conduit_x, 1.0)
		assert_almost_eq(hinge.x, top_crown.x, 1.0)
		assert_almost_eq(stored_points[0].x, hinge.x, 1.0)
		assert_almost_eq(stored_points[1].x, hinge.x, 1.0)
		assert_lt(stored_points[1].y, stored_points[0].y)
		assert_lt(stored_points[0].y, hinge.y)
		hammer.set_strike_amount(0.50)
		assert_eq(hammer.double_spoon_frame_index(), 4)
		var halfway_points: Array[Vector2] = hammer.current_bowl_global_positions()
		var halfway_visuals: Array[Dictionary] = hammer.bowl_visuals()
		assert_almost_eq(halfway_points[0].x, hinge.x, 1.0)
		assert_almost_eq(halfway_points[1].x, hinge.x, 1.0)
		assert_lt(halfway_points[0].distance_to(halfway_points[1]), 2.0)
		assert_false(halfway_visuals[0].get("tracked_far_bowl", false))
		assert_true(halfway_visuals[1].get("tracked_far_bowl", false))
		assert_true(halfway_visuals[0].get("draw_neck", false))
		assert_true(halfway_visuals[1].get("draw_neck", false))
		assert_gt(
			halfway_visuals[1].radii.length(),
			halfway_visuals[0].radii.length() * 1.15
		)
		hammer.set_strike_amount(0.70)
		assert_eq(hammer.double_spoon_frame_index(), 6)
		assert_true(hammer.is_foreground_handle_visible())
		var falling_bowl: Dictionary = hammer.bowl_visuals()[0]
		assert_gt(falling_bowl.tipped_amount, 0.50)
		assert_lt(falling_bowl.radii.x / falling_bowl.radii.y, 2.0)
		var falling_points: Array[Vector2] = hammer.current_bowl_global_positions()
		assert_almost_eq(falling_points[0].x, hinge.x, 1.0)
		assert_almost_eq(falling_points[1].x, hinge.x, 1.0)
		hammer.set_strike_amount(1.0)
		assert_eq(hammer.double_spoon_frame_index(), 8)
		var thrown_points: Array[Vector2] = hammer.current_bowl_global_positions()
		var contact_visuals: Array[Dictionary] = hammer.bowl_visuals()
		assert_eq(hammer.z_index, 0)
		assert_gt(hammer.bowl_foreground_z_index(), main.get_node("Content/Stage/Belt").z_index)
		assert_false(hammer.is_foreground_handle_visible())
		assert_almost_eq(hammer.pivot_global_position().x, hinge.x, 1.0)
		assert_almost_eq(thrown_points[0].x, top_crown.x, 1.0)
		assert_almost_eq(thrown_points[0].y, top_crown.y, 1.0)
		assert_almost_eq(thrown_points[1].x, bottom_crown.x, 1.0)
		assert_almost_eq(thrown_points[1].y, bottom_crown.y, 1.0)
		assert_gt(contact_visuals[1].radii.x, contact_visuals[0].radii.x * 1.25)
		hammer.reset_pose()
		assert_eq(hammer.z_index, 0)
		assert_eq(hammer.bowl_foreground_z_index(), 0)

	var fired_spoons: Array[int] = []
	var double_bowl_strike_amounts_during_damage: Array[float] = []
	main.get_node("Presentation").hammer_fired.connect(
		func(spoon_index: int) -> void: fired_spoons.append(spoon_index)
	)
	main.presentation_event.connect(func(event_type: String) -> void:
		if event_type == "egg_damaged":
			double_bowl_strike_amounts_during_damage.append(
				main.get_node("Content/Stage/HammerBank/Hammer1").strike_amount
			)
	)
	await _press_and_wait(main, "RedCircuit")
	assert_eq(fired_spoons, [0])
	assert_eq(double_bowl_strike_amounts_during_damage, [1.0])
	assert_eq(main.get_node("Content/Stage/HammerBank/Hammer1").strike_amount, 0.0)
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

	main.get_node("ResultOverlay/Card/Content/RewardChoices/Choice1").pressed.emit()
	await get_tree().process_frame
	main.get_node("WorkshopOverlay/Card/Content/WorkshopActions/ContinueWorkshop").pressed.emit()
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
	main.get_node("Content/Stage/CircuitBank/%s" % circuit_name).pressed.emit()
	await main.playback_completed
	await get_tree().process_frame


func _complete_successful_day(main: Control) -> void:
	for circuit_name in [
		"RedCircuit", "BlueCircuit", "RedCircuit", "BlueCircuit", "RedCircuit",
		"BlueCircuit", "RedCircuit", "PinkCircuit", "RedCircuit", "BlueCircuit",
		"RedCircuit", "BlueCircuit", "RedCircuit", "BlueCircuit", "RedCircuit",
		"PinkCircuit", "RedCircuit", "BlueCircuit", "RedCircuit", "BlueCircuit",
	]:
		if main.get_node("Content/Stage/CircuitBank/%s" % circuit_name).disabled:
			continue
		await _press_and_wait(main, circuit_name)
		if main.get_node("ResultOverlay").visible:
			break


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
		producers.append({"kind": kind, "daily_yield": 1})
	var session = ChickenDaySession.new(
		0,
		ProducerFlock.new(producers),
		IdentityShuffler.new()
	)
	var main := _add_main()
	main.replace_session(session)
	return main
