extends GutTest


func test_main_renders_initial_day_and_shell_information() -> void:
	var main := _add_main()

	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 0 / 10")
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 20")
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot1").egg_summary(), "TOUGHNESS 3")
	assert_eq(main.get_node("Content/Stage/Pipe/Preview").get_child_count(), 3)
	assert_eq(main.get_node("Content/Stage/Pipe/Preview/Next1").effect_emblem(), "echo")
	assert_eq(main.get_node("Content/Stage/Pipe/Preview/Next3").effect_emblem(), "retreat")
	assert_not_null(main.get_node("Content/Accessibility/Mute"))
	assert_not_null(main.get_node("Content/Accessibility/ReducedMotion"))


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
	assert_eq(circuits.get_node("PinkCircuit").circuit_symbol, "triangle")
	assert_eq(hammers.get_node("Hammer1").circuit_id, "red")
	assert_eq(hammers.get_node("Hammer2").circuit_id, "blue")
	assert_eq(hammers.get_node("Hammer3").circuit_id, "red")
	assert_eq(hammers.get_node("Hammer4").circuit_id, "blue")
	assert_eq(hammers.get_node("Hammer5").circuit_id, "pink")


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

	assert_eq(red.tooltip_text, "")
	assert_eq(red.accessibility_name, "Red diamond circuit")
	assert_string_contains(red.accessibility_description, "slots 1 and 3")
	assert_string_contains(red.accessibility_description, "Slot 1: Chicken egg")
	assert_string_contains(red.accessibility_description, "Slot 3: empty")


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
	var main := _add_main()
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


func test_pink_presents_slot_five_plover_rescue_before_belt_movement() -> void:
	var main := _add_main()
	main.set_reduced_motion(true)
	for circuit_name in [
		"RedCircuit", "BlueCircuit", "RedCircuit", "BlueCircuit",
		"RedCircuit", "BlueCircuit", "RedCircuit",
	]:
		await _press_and_wait(main, circuit_name)
	var presented: Array[String] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))

	await _press_and_wait(main, "PinkCircuit")

	assert_eq(presented.slice(0, 4), [
		"circuit_fired", "egg_damaged", "eggs_swapped", "conveyor_advanced",
	])
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot5").egg_summary(), "PLOVER")
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot5").egg_summary(), "TOUGHNESS 5")


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

	for player_name in ["Impact", "Echo", "Shuffle", "Hatch", "Belt", "Loss", "Pipe"]:
		var player: AudioStreamPlayer = audio_root.get_node(player_name)
		assert_not_null(player.stream, "%s has a stream" % player_name)
		assert_gt(player.stream.data.size(), 1000, "%s stream contains PCM data" % player_name)


func test_day_result_appears_after_twenty_valid_circuit_thwacks() -> void:
	var main := _add_main()
	main.set_reduced_motion(true)

	for turn in range(20):
		await _press_and_wait(main, "RedCircuit")

	var result_panel: Control = main.get_node("ResultOverlay")
	assert_true(result_panel.visible)
	assert_eq(main.get_node("ResultOverlay/Card/Content/Result").text, "DAY FAILED")
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 0")

	main.get_node("ResultOverlay/Card/Content/Restart").pressed.emit()
	assert_false(result_panel.visible)
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 20")


func _press_and_wait(main: Control, circuit_name: String) -> void:
	main.get_node("Content/Stage/CircuitBank/%s" % circuit_name).pressed.emit()
	await main.playback_completed
	await get_tree().process_frame


func _add_main() -> Control:
	var packed_scene := load("res://src/ui/main.tscn") as PackedScene
	var main := packed_scene.instantiate() as Control
	add_child_autofree(main)
	return main
