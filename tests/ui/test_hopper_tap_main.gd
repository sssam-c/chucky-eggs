extends GutTest

const PrototypeScene = preload("res://src/ui/hopper_tap_main.tscn")


func test_prototype_exposes_five_individual_spoons_and_three_hopper_previews() -> void:
	var main := await _add_prototype()

	for slot_number in range(1, 6):
		assert_not_null(main.get_node_or_null("Stage/Bays/Slot%d" % slot_number))
		assert_not_null(main.get_node_or_null("Stage/Hammers/Hammer%d" % slot_number))
		assert_not_null(main.get_node_or_null("Stage/Levers/Lever%d" % slot_number))
	for preview_number in range(1, 4):
		assert_not_null(main.get_node_or_null("Hopper/Preview/Next%d" % preview_number))

	var state: Dictionary = main.prototype_state()
	assert_eq(state.slots[2].kind, "sparrow")
	assert_eq(state.pipe[0].kind, "spoonbill")
	assert_eq(state.hunger, 10)
	assert_eq(state.taps_remaining, 5)
	assert_eq(main.get_node("Hunger").text, "HUNGER  10")
	assert_string_contains(main.get_node("TapPips").text, "● ● ● ● ●")
	assert_eq(main.get_node("HungerIntent").text, "GRANDMA NEXT  +1 HUNGER")
	assert_eq(main.get_node("Stage/Levers/Lever3").circuit_color, Color("cf4f8b"))
	assert_eq(main.get_node("Stage/Levers/Lever3").circuit_symbol, "spark")


func test_pink_lever_opens_sparrow_and_routes_spoonbill_into_pink_bay() -> void:
	var main := await _add_prototype()
	main.set_reduced_motion(true)

	main.get_node("Stage/Levers/Lever3").pressed.emit()
	await main.playback_completed
	await get_tree().process_frame
	var state: Dictionary = main.prototype_state()

	assert_eq(state.hunger, 9)
	assert_eq(state.taps_remaining, 4)
	assert_eq(state.slots[2].kind, "spoonbill")
	assert_eq(main.get_node("Stage/Bays/Slot3").egg_kind(), "spoonbill")
	assert_eq(main.get_node("Hopper/Preview/Next1").egg_kind(), "cuckoo")
	assert_eq(main.get_node("Hunger").text, "HUNGER  9")


func test_second_input_is_ignored_while_a_tap_cascade_is_playing() -> void:
	var main := await _add_prototype()
	var lever: Button = main.get_node("Stage/Levers/Lever1")
	lever.pressed.emit()
	lever.pressed.emit()

	await main.playback_completed
	await get_tree().process_frame

	assert_eq(main.prototype_state().taps_remaining, 4)


func test_fifth_tap_presents_grandmas_response_before_refreshing_taps() -> void:
	var main := await _add_prototype()
	main.set_reduced_motion(true)
	var presented: Array[String] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))
	var lever: Button = main.get_node("Stage/Levers/Lever3")

	for tap_index in range(5):
		lever.pressed.emit()
		await main.playback_completed
		await get_tree().process_frame

	var state: Dictionary = main.prototype_state()
	assert_eq(state.tap_phase, 2)
	assert_eq(state.hunger, 4)
	assert_eq(state.taps_remaining, 5)
	assert_eq(state.next_hunger_increase, 2)
	assert_eq(presented.slice(presented.size() - 3), [
		"tap_phase_ended", "hunger_increased", "tap_phase_started",
	])
	assert_eq(main.get_node("Hunger").text, "HUNGER  4")
	assert_string_contains(main.get_node("TapPips").text, "● ● ● ● ●")
	assert_eq(main.get_node("HungerIntent").text, "GRANDMA NEXT  +2 HUNGER")
	assert_false(main.get_node("HungerPhasePanel").visible)


func test_restart_restores_the_authored_opening() -> void:
	var main := await _add_prototype()
	main.set_reduced_motion(true)
	main.get_node("Stage/Levers/Lever3").pressed.emit()
	await main.playback_completed
	await get_tree().process_frame

	main.get_node("Restart").pressed.emit()

	assert_eq(main.prototype_state().hunger, 10)
	assert_eq(main.prototype_state().taps_remaining, 5)
	assert_eq(main.prototype_state().tap_phase, 1)
	assert_eq(main.prototype_state().slots[2].kind, "sparrow")
	assert_eq(main.prototype_state().pipe[0].kind, "spoonbill")


func _add_prototype() -> Control:
	var main: Control = PrototypeScene.instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	return main
