extends GutTest

const MainScene = preload("res://src/ui/hopper_tap_main.tscn")


func test_game_exposes_five_individual_spoons_and_three_hopper_previews() -> void:
	var main := await _add_game()
	var grandma = main.get_node_or_null("GrandmaSidebar")
	var stage: Control = main.get_node("Stage")

	for slot_number in range(1, 6):
		var slot = main.get_node("Stage/Bays/Slot%d" % slot_number)
		var spoon = main.get_node("Stage/Spoons/Spoon%d" % slot_number)
		var spoon_button = main.get_node("Stage/SpoonControls/SpoonButton%d" % slot_number)
		assert_true(slot.is_egg_cup_mode())
		assert_gt(slot.stage_content_scale(), 1.0)
		assert_gte(slot.size.x, 150.0)
		assert_eq(spoon_button.control_form(), "button")
		assert_eq(spoon_button.text, "")
		assert_gte(spoon_button.size.x, 120.0)
		assert_gte(spoon_button.size.y, 70.0)
		assert_gt(spoon_button.get_global_rect().position.y, slot.get_global_rect().get_center().y)
		assert_false(spoon.is_circuit_marked())
	for preview_number in range(1, 4):
		assert_not_null(main.get_node_or_null("Hopper/Preview/Next%d" % preview_number))
	assert_not_null(main.get_node_or_null("Stage/Table"))
	assert_null(main.get_node_or_null("Title"))
	assert_null(main.get_node_or_null("Instructions"))
	assert_null(main.get_node_or_null("TapPips"))
	assert_not_null(main.get_node_or_null("WorkshopBackdrop"))
	assert_not_null(main.get_node_or_null("Stage/StationBackplates"))
	assert_not_null(main.get_node_or_null("Stage/Table/Apron"))
	assert_not_null(main.get_node_or_null("Hopper/Chute"))
	assert_null(main.get_node_or_null("Stage/YolkStreakDisplay"))
	var yolk_display: Control = main.get_node("Stage/YolkComboDisplay")
	assert_not_null(yolk_display.get_node_or_null("YolkBall"))
	assert_null(yolk_display.get_node_or_null("AwardPanel"))
	assert_lt(yolk_display.ball_global_position().y, main.get_node("Stage/Bays/Slot3").get_global_rect().get_center().y)
	assert_true(stage.get_global_rect().has_point(yolk_display.ball_global_position()))
	assert_not_null(main.get_node_or_null("Hopper/HopperDropPoint"))
	assert_null(main.get_node_or_null("Stage/Levers"))
	assert_not_null(grandma)
	if grandma == null:
		return
	assert_not_null(grandma.get_node_or_null("GrandmaPortrait"))
	assert_not_null(grandma.get_node_or_null("TapCard/TapPips"))
	assert_null(grandma.get_node_or_null("YolkStreakDisplay"))
	assert_null(grandma.get_node_or_null("YolkComboDisplay"))
	assert_not_null(grandma.get_node_or_null("HungerCard/HungerValue"))
	assert_not_null(grandma.get_node_or_null("HungerCard/HungerChange"))
	assert_not_null(grandma.get_node_or_null("HungerCard/NextIncrease"))
	assert_gt(grandma.get_global_rect().get_center().x, stage.get_global_rect().get_center().x)
	assert_false(grandma.get_global_rect().intersects(stage.get_global_rect()))
	assert_null(main.get_node_or_null("Hunger"))
	assert_null(main.get_node_or_null("HungerIntent"))

	var state: Dictionary = main.game_state()
	assert_eq(state.slots[2].kind, "sparrow")
	assert_eq(state.pipe[0].kind, "spoonbill")
	assert_eq(state.hunger, 10)
	assert_false(state.has("break_streak"))
	assert_eq(state.taps_remaining, 5)
	assert_eq(grandma.hunger_value(), 10)
	assert_eq(grandma.next_increase(), 1)
	assert_eq(grandma.get_node("HungerCard/HungerValue").text, "10")
	assert_eq(grandma.get_node("HungerCard/NextIncrease").text, "NEXT RESPONSE +1")
	assert_almost_eq(grandma.hunger_ratio(), 0.0, 0.00001)
	assert_true(grandma.is_idle_motion_active())
	assert_string_contains(grandma.get_node("TapCard/TapPips").text, "● ● ● ● ●")
	assert_eq(main.get_node("Stage/SpoonControls/SpoonButton3").circuit_color, Color("cf4f8b"))
	assert_eq(main.get_node("Stage/SpoonControls/SpoonButton3").circuit_symbol, "spark")
	assert_eq(main.get_node("Stage/SpoonControls/SpoonButton4").circuit_color, Color("58a83f"))
	assert_eq(main.get_node("Stage/SpoonControls/SpoonButton4").circuit_symbol, "triangle")
	assert_eq(main.get_node("Stage/SpoonControls/SpoonButton5").circuit_color, Color("efa91a"))
	assert_eq(main.get_node("Stage/SpoonControls/SpoonButton5").circuit_symbol, "square")


func test_pink_spoon_opens_sparrow_and_drops_spoonbill_from_hopper_into_pink_cup() -> void:
	var main := await _add_game()
	main.set_reduced_motion(true)
	assert_false(main.get_node("GrandmaSidebar").is_idle_motion_active())
	var drops: Array[Dictionary] = []
	var combos: Array[Dictionary] = []
	var merges: Array[Dictionary] = []
	var deliveries: Array[Dictionary] = []
	var hunger_changes: Array[Dictionary] = []
	main.get_node("TapPresenter").egg_drop_started.connect(
		func(slot_index: int, origin: Vector2, destination: Vector2) -> void:
			drops.append({
				"slot_index": slot_index,
				"origin": origin,
				"destination": destination,
			})
	)
	main.get_node("TapPresenter").combo_announced.connect(
		func(combo_count: int, callout: String, total_yolk: int) -> void:
			combos.append({
				"combo_count": combo_count,
				"callout": callout,
				"total_yolk": total_yolk,
			})
	)
	main.get_node("TapPresenter").yolk_merge_started.connect(
		func(base_yolk: int, origin: Vector2, destination: Vector2) -> void:
			merges.append({
				"base_yolk": base_yolk,
				"origin": origin,
				"destination": destination,
			})
	)
	main.get_node("TapPresenter").yolk_delivery_started.connect(
		func(total_yolk: int, origin: Vector2, destination: Vector2) -> void:
			deliveries.append({
				"total_yolk": total_yolk,
				"origin": origin,
				"destination": destination,
			})
	)
	main.get_node("TapPresenter").hunger_subtraction_presented.connect(
		func(hunger_before: int, amount: int, hunger_after: int) -> void:
			hunger_changes.append({
				"before": hunger_before,
				"amount": amount,
				"after": hunger_after,
			})
	)

	main.get_node("Stage/SpoonControls/SpoonButton3").pressed.emit()
	await main.playback_completed
	await get_tree().process_frame
	var state: Dictionary = main.game_state()

	assert_eq(state.hunger, 9)
	assert_eq(state.taps_remaining, 4)
	assert_eq(state.slots[2].kind, "spoonbill")
	assert_eq(main.get_node("Stage/Bays/Slot3").egg_kind(), "spoonbill")
	assert_eq(main.get_node("Hopper/Preview/Next1").egg_kind(), "cuckoo")
	assert_eq(main.get_node("GrandmaSidebar").hunger_value(), 9)
	assert_almost_eq(main.get_node("GrandmaSidebar").hunger_ratio(), 0.1, 0.00001)
	assert_eq(drops.size(), 1)
	assert_eq(drops[0].slot_index, 2)
	assert_eq(drops[0].origin, main.get_node("Hopper/HopperDropPoint").get_global_rect().get_center())
	assert_lt(drops[0].origin.y, drops[0].destination.y)
	assert_true(combos.is_empty())
	assert_eq(merges.size(), 1)
	assert_eq(merges[0].base_yolk, 1)
	assert_eq(merges[0].origin, main.get_node("Stage/Bays/Slot3").hatch_global_position())
	assert_eq(merges[0].destination, main.get_node("Stage/YolkComboDisplay").ball_global_position())
	assert_eq(deliveries.size(), 1)
	assert_eq(deliveries[0].total_yolk, 1)
	assert_eq(
		deliveries[0].destination,
		main.get_node("GrandmaSidebar").delivery_global_position()
	)
	assert_eq(deliveries[0].origin, main.get_node("Stage/YolkComboDisplay").ball_global_position())
	assert_gt(deliveries[0].destination.x, deliveries[0].origin.x)
	assert_eq(hunger_changes, [{"before": 10, "amount": 1, "after": 9}])
	assert_false(main.get_node("Stage/YolkComboDisplay").visible)
	assert_false(main.get_node("GrandmaSidebar/HungerCard/HungerChange").visible)


func test_second_input_is_ignored_while_a_tap_cascade_is_playing() -> void:
	var main := await _add_game()
	var spoon_button: Button = main.get_node("Stage/SpoonControls/SpoonButton1")
	spoon_button.pressed.emit()
	spoon_button.pressed.emit()

	await main.playback_completed
	await get_tree().process_frame

	assert_eq(main.game_state().taps_remaining, 4)


func test_zero_break_tap_has_no_combo_reset_interruption() -> void:
	var main := await _add_game()
	main.set_reduced_motion(true)
	var presented: Array[String] = []
	main.presentation_event.connect(
		func(event_type: String) -> void: presented.append(event_type)
	)
	var pink_spoon: Button = main.get_node("Stage/SpoonControls/SpoonButton3")
	pink_spoon.pressed.emit()
	await main.playback_completed
	await get_tree().process_frame
	presented.clear()

	pink_spoon.pressed.emit()
	await main.playback_completed
	await get_tree().process_frame

	assert_false(presented.has("break_streak_reset"))
	assert_false(main.game_state().has("break_streak"))
	assert_eq(main.game_state().hunger, 9)
	assert_false(main.get_node("Stage/YolkComboDisplay").visible)
	assert_false(main.is_input_locked())


func test_same_tap_double_break_announces_one_flat_combo() -> void:
	var main := await _add_game()
	main.set_reduced_motion(true)
	var combos: Array[Dictionary] = []
	main.get_node("TapPresenter").combo_announced.connect(
		func(combo_count: int, callout: String, total_yolk: int) -> void:
			combos.append({
				"combo_count": combo_count,
				"callout": callout,
				"total_yolk": total_yolk,
				"ball_amount": main.get_node("Stage/YolkComboDisplay").ball_amount(),
				"ball_visible": main.get_node("Stage/YolkComboDisplay").visible,
			})
	)
	var route: Array[Button] = [
		main.get_node("Stage/SpoonControls/SpoonButton1"),
		main.get_node("Stage/SpoonControls/SpoonButton1"),
		main.get_node("Stage/SpoonControls/SpoonButton2"),
		main.get_node("Stage/SpoonControls/SpoonButton1"),
	]
	for spoon_button: Button in route:
		spoon_button.pressed.emit()
		await main.playback_completed
		await get_tree().process_frame

	assert_eq(combos, [{
		"combo_count": 2,
		"callout": "DOUBLE YOLKER!",
		"total_yolk": 8,
		"ball_amount": 8,
		"ball_visible": true,
	}])
	assert_eq(main.game_state().hunger, 2)
	assert_false(main.get_node("Stage/YolkComboDisplay").visible)
	assert_false(main.is_input_locked())


func test_restart_cancels_an_active_combo_without_stale_score_state() -> void:
	var main := await _add_game()
	main.set_reduced_motion(true)
	var setup_route: Array[Button] = [
		main.get_node("Stage/SpoonControls/SpoonButton1"),
		main.get_node("Stage/SpoonControls/SpoonButton1"),
		main.get_node("Stage/SpoonControls/SpoonButton2"),
	]
	for spoon_button: Button in setup_route:
		spoon_button.pressed.emit()
		await main.playback_completed
		await get_tree().process_frame
	main.set_reduced_motion(false)
	var combo_started := [false]
	var presenter: Node = main.get_node("TapPresenter")
	presenter.combo_announced.connect(
		func(_combo_count: int, _callout: String, _total_yolk: int) -> void:
			combo_started[0] = true
			main.get_node("Restart").pressed.emit()
	,
		CONNECT_ONE_SHOT
	)

	main.get_node("Stage/SpoonControls/SpoonButton1").pressed.emit()
	await presenter.combo_announced
	await get_tree().process_frame
	await get_tree().process_frame

	assert_true(combo_started[0])
	assert_eq(main.game_state().hunger, 10)
	assert_eq(main.game_state().taps_remaining, 5)
	assert_eq(main.game_state().slots[0].kind, "chicken")
	assert_false(main.get_node("Stage/YolkComboDisplay").visible)
	assert_false(main.get_node("GrandmaSidebar/HungerCard/HungerChange").visible)
	assert_false(main.is_input_locked())


func test_fifth_tap_presents_grandmas_response_before_refreshing_taps() -> void:
	var main := await _add_game()
	main.set_reduced_motion(true)
	var presented: Array[String] = []
	var phase_was_owned_by_grandma := [false]
	main.presentation_event.connect(
		func(event_type: String) -> void:
			presented.append(event_type)
			if event_type == "tap_phase_ended":
				phase_was_owned_by_grandma[0] = main.get_node("GrandmaSidebar").is_phase_visible()
	)
	var plover_route: Array[Button] = [
		main.get_node("Stage/SpoonControls/SpoonButton4"),
		main.get_node("Stage/SpoonControls/SpoonButton3"),
		main.get_node("Stage/SpoonControls/SpoonButton2"),
		main.get_node("Stage/SpoonControls/SpoonButton1"),
		main.get_node("Stage/SpoonControls/SpoonButton1"),
	]

	for spoon_button: Button in plover_route:
		spoon_button.pressed.emit()
		await main.playback_completed
		await get_tree().process_frame

	var state: Dictionary = main.game_state()
	assert_eq(state.tap_phase, 2)
	assert_eq(state.hunger, 11)
	assert_eq(state.taps_remaining, 5)
	assert_eq(state.next_hunger_increase, 2)
	assert_eq(presented.slice(presented.size() - 3), [
		"tap_phase_ended", "hunger_increased", "tap_phase_started",
	])
	assert_eq(main.get_node("GrandmaSidebar").hunger_value(), 11)
	assert_eq(main.get_node("GrandmaSidebar").next_increase(), 2)
	assert_string_contains(main.get_node("GrandmaSidebar/TapCard/TapPips").text, "● ● ● ● ●")
	assert_true(phase_was_owned_by_grandma[0])
	assert_false(main.get_node("GrandmaSidebar").is_phase_visible())


func test_restart_restores_the_authored_opening() -> void:
	var main := await _add_game()
	main.set_reduced_motion(true)
	main.get_node("Stage/SpoonControls/SpoonButton3").pressed.emit()
	await main.playback_completed
	await get_tree().process_frame

	main.get_node("Restart").pressed.emit()

	assert_eq(main.game_state().hunger, 10)
	assert_eq(main.game_state().taps_remaining, 5)
	assert_eq(main.game_state().tap_phase, 1)
	assert_eq(main.game_state().slots[2].kind, "sparrow")
	assert_eq(main.game_state().pipe[0].kind, "spoonbill")
	assert_eq(main.get_node("GrandmaSidebar").hunger_value(), 10)
	assert_eq(main.get_node("GrandmaSidebar").next_increase(), 1)


func _add_game() -> Control:
	var main: Control = MainScene.instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	return main
