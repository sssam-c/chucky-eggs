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


class IdentityShuffler:
	extends RefCounted

	func shuffle_strings(values: Array[String]) -> Array[String]:
		return values.duplicate()


func test_main_renders_initial_day_and_shell_information() -> void:
	var main := _add_main()

	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 0 / 10")
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


func test_plover_shell_information_shows_the_four_point_payoff() -> void:
	var main := _add_main_for_ordered_eggs(["plover"])
	var summary: String = main.get_node("Content/Stage/Belt/Slots/Slot1").egg_summary()

	assert_string_contains(summary, "TOUGHNESS 6")
	assert_string_contains(summary, "4 POINTS")


func test_stage_has_three_circuit_controls_and_five_colour_matched_spoons() -> void:
	var main := _add_main()
	var circuits := main.get_node("Content/Stage/CircuitBank")
	var hammers := main.get_node("Content/Stage/HammerBank")

	assert_eq(circuits.get_child_count(), 3)
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


func test_each_spoon_bowl_aligns_with_its_egg_slot_at_rest_and_contact() -> void:
	var main := _add_main()
	var hammers := main.get_node("Content/Stage/HammerBank")
	var slots := main.get_node("Content/Stage/Belt/Slots")

	for slot_index in range(5):
		var hammer = hammers.get_node("Hammer%d" % (slot_index + 1))
		var slot: Control = slots.get_node("Slot%d" % (slot_index + 1))
		var slot_center := slot.global_position + slot.size * 0.5
		var stored_bowl: Vector2 = hammer.stored_bowl_global_position()
		var contact_bowl: Vector2 = hammer.contact_bowl_global_position()

		assert_almost_eq(stored_bowl.x, slot_center.x, 1.0)
		assert_lt(stored_bowl.y, slot.global_position.y)
		assert_almost_eq(contact_bowl.x, slot_center.x, 1.0)
		assert_almost_eq(contact_bowl.y, slot_center.y, 1.0)


func test_only_circuits_with_an_occupied_linked_slot_are_available() -> void:
	var main := _add_main()
	var red: Button = main.get_node("Content/Stage/CircuitBank/RedCircuit")
	var blue: Button = main.get_node("Content/Stage/CircuitBank/BlueCircuit")
	var pink: Button = main.get_node("Content/Stage/CircuitBank/PinkCircuit")

	assert_false(red.disabled)
	assert_true(blue.disabled)
	assert_true(pink.disabled)
	assert_true(red.has_focus())


func test_circuit_controls_have_no_hover_text_and_describe_connections_accessibly() -> void:
	var main := _add_main()
	var red: Button = main.get_node("Content/Stage/CircuitBank/RedCircuit")
	var pink: Button = main.get_node("Content/Stage/CircuitBank/PinkCircuit")

	assert_eq(red.tooltip_text, "")
	assert_eq(red.accessibility_name, "Red diamond circuit")
	assert_string_contains(red.accessibility_description, "slots 1 and 3")
	assert_string_contains(red.accessibility_description, "Slot 1: Chicken egg")
	assert_string_contains(red.accessibility_description, "Slot 3: empty")
	assert_eq(pink.accessibility_name, "Pink spark circuit")


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
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 3 / 10")


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

	assert_eq(score_when_burst_started[0], "SCORE 0 / 10")
	assert_eq(point_text_when_burst_started[0], "+3")
	assert_gte(payoff.fragment_count(), 12)
	assert_eq(milestones, ["burst", "score:3:3", "event"])
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 3 / 10")
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
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 0 / 10")


func test_pink_spoonbill_combo_presents_double_damage_and_both_score_payoffs() -> void:
	var main := _add_authored_main()
	main.set_reduced_motion(true)
	for circuit_name in [
		"RedCircuit", "BlueCircuit", "RedCircuit", "RedCircuit",
		"BlueCircuit", "RedCircuit", "PinkCircuit",
	]:
		await _press_and_wait(main, circuit_name)
	var presented: Array[String] = []
	var points_landed: Array[int] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))
	main.get_node("Presentation").score_committed.connect(
		func(points_awarded: int, _score: int) -> void: points_landed.append(points_awarded)
	)

	await _press_and_wait(main, "PinkCircuit")

	assert_eq(presented.slice(0, 6), [
		"circuit_fired", "egg_damaged", "egg_damaged",
		"egg_hatched", "egg_hatched", "conveyor_advanced",
	])
	assert_eq(points_landed, [1, 4])
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 9 / 10")
	assert_eq(main.get_node("Content/Feedback").text, "Crack! 2 eggs hatched for 5 points.")


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

	for player_name in ["Impact", "Echo", "Shuffle", "Hatch", "Score", "Belt", "Loss", "Pipe"]:
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
	await get_tree().process_frame
	assert_true(choices.get_child(0).has_focus())


func test_selecting_a_producer_starts_day_two_with_its_full_yield() -> void:
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
	await main.production_loading_completed
	await get_tree().process_frame

	assert_eq(loading_facts, [Vector2i(25, 24 + first_choice.daily_yield)])
	assert_false(main.get_node("ResultOverlay").visible)
	assert_false(main.get_node("ProductionLoader").visible)
	assert_eq(main.get_node("Content/Header/HopperCount").text, "HOPPER %d" % expected_hopper_count)
	assert_string_contains(main.get_node("Content/Feedback").text, "DAY 2")
	assert_false(main.get_node("Content/Stage/Belt/Slots/Slot1").current_egg().is_empty())


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
	assert_eq(started_count[0], 1)
	assert_true(main.is_input_locked())
	assert_true(main.get_node("ProductionLoader").is_active())

	main.replace_session(ChickenDaySession.new())
	await get_tree().create_timer(0.25).timeout

	assert_false(main.get_node("ProductionLoader").is_active())
	assert_false(main.get_node("ProductionLoader").visible)
	assert_false(main.is_input_locked())
	assert_eq(completion_count[0], 0)
	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 0 / 10")


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
		await _press_and_wait(main, circuit_name)


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
