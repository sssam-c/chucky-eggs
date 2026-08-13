extends GutTest


func test_main_renders_initial_day_state_and_accessibility_controls() -> void:
	var main := _add_main()

	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 0 / 10")
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 20")
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot1").egg_summary(), "TOUGHNESS 4")
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot2").egg_summary(), "EMPTY")
	assert_eq(main.get_node("Content/Stage/Pipe/Preview").get_child_count(), 3)
	assert_string_contains(main.get_node("Content/Stage/Pipe/Preview/Next1").egg_summary(), "CUCKOO")
	assert_string_contains(main.get_node("Content/Stage/Pipe/Preview/Next1").egg_summary(), "1 POINT")
	assert_string_contains(main.get_node("Content/Stage/Pipe/Preview/Next3").egg_summary(), "PLOVER")
	assert_string_contains(main.get_node("Content/Stage/Pipe/Preview/Next3").egg_summary(), "2 POINTS")
	assert_string_contains(main.get_node("Content/Stage/Pipe/Preview/Next3").egg_summary(), "TOUGHNESS 6")
	var echo_trace: Control = main.get_node("Content/Stage/EchoTrace")
	assert_false(echo_trace.visible)
	assert_not_null(main.get_node("Content/Accessibility/Mute"))
	assert_not_null(main.get_node("Content/Accessibility/ReducedMotion"))


func test_stage_has_one_fixed_key_and_rear_hammer_for_each_belt_slot() -> void:
	var main := _add_main()
	var slots := main.get_node("Content/Stage/Belt/Slots")
	var keys := main.get_node("Content/Stage/KeyBank")
	var hammers := main.get_node("Content/Stage/HammerBank")

	assert_eq(slots.get_child_count(), 5)
	assert_eq(keys.get_child_count(), 5)
	assert_eq(hammers.get_child_count(), 5)
	for slot_index in range(5):
		assert_eq(keys.get_child(slot_index).slot_index, slot_index)
		assert_eq(hammers.get_child(slot_index).slot_index, slot_index)
		assert_true(hammers.get_child(slot_index).is_idle_back_facing())


func test_key_depresses_toward_player_and_hammer_keeps_fixed_pivot() -> void:
	var main := _add_main()
	var key = main.get_node("Content/Stage/KeyBank/Key1")
	var hammer = main.get_node("Content/Stage/HammerBank/Hammer1")
	var pivot_before: Vector2 = hammer.pivot_global_position()

	key.set_press_amount(1.0)
	hammer.set_strike_amount(1.0)

	assert_gt(key.press_amount, 0.99)
	assert_gt(hammer.strike_amount, 0.99)
	assert_almost_eq(hammer.pivot_global_position().x, pivot_before.x, 0.1)
	assert_almost_eq(hammer.pivot_global_position().y, pivot_before.y, 0.1)


func test_second_press_is_ignored_while_presentation_barrier_is_active() -> void:
	var main := _add_main()
	var key_one: Button = main.get_node("Content/Stage/KeyBank/Key1")
	var completion_count := [0]
	main.playback_completed.connect(func() -> void: completion_count[0] += 1)

	key_one.pressed.emit()
	key_one.pressed.emit()

	assert_true(main.is_input_locked())
	await main.playback_completed
	await get_tree().process_frame
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 19")
	assert_eq(completion_count[0], 1)


func test_resolver_events_are_presented_once_in_order() -> void:
	var main := _add_main()
	main.set_reduced_motion(true)
	var presented: Array[String] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))

	main.get_node("Content/Stage/KeyBank/Key1").pressed.emit()
	await main.playback_completed
	await get_tree().process_frame

	assert_eq(presented, [
		"egg_damaged",
		"conveyor_advanced",
		"thwack_spent",
		"egg_entered",
	])
	assert_false(main.is_input_locked())


func test_cuckoo_echo_damage_is_presented_before_the_belt_advances() -> void:
	var main := _add_main()
	main.set_reduced_motion(true)
	await _press_and_wait(main, "Slot1")
	var presented: Array[String] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))

	await _press_and_wait(main, "Slot2")

	assert_eq(presented, [
		"egg_damaged",
		"egg_damaged",
		"conveyor_advanced",
		"thwack_spent",
		"egg_entered",
	])
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot2").egg_summary(), "CUCKOO")
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot2").egg_summary(), "TOUGHNESS 3")


func test_plover_swap_is_presented_before_the_belt_advances() -> void:
	var main := _add_main()
	main.set_reduced_motion(true)
	await _press_and_wait(main, "Slot1")
	await _press_and_wait(main, "Slot2")
	await _press_and_wait(main, "Slot1")
	await _press_and_wait(main, "Slot4")
	var presented: Array[String] = []
	main.presentation_event.connect(func(event_type: String) -> void: presented.append(event_type))

	await _press_and_wait(main, "Slot2")

	assert_eq(presented, [
		"egg_damaged",
		"eggs_swapped",
		"conveyor_advanced",
		"egg_discarded",
		"thwack_spent",
		"egg_entered",
	])
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot2").egg_summary(), "PLOVER")
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot2").egg_summary(), "TOUGHNESS 5")


func test_restart_cancels_active_playback_without_stale_day_state() -> void:
	var main := _add_main()
	var completion_count := 0
	main.playback_completed.connect(func() -> void: completion_count += 1)

	main.get_node("Content/Stage/KeyBank/Key1").pressed.emit()
	main.restart_day()
	await get_tree().create_timer(0.5).timeout

	assert_false(main.is_input_locked())
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 20")
	assert_string_contains(main.get_node("Content/Stage/Belt/Slots/Slot1").egg_summary(), "TOUGHNESS 4")
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


func test_four_targeted_presses_hatch_and_score() -> void:
	var main := _add_main()
	main.set_reduced_motion(true)

	for slot_name in ["Slot1", "Slot2", "Slot3", "Slot4"]:
		await _press_and_wait(main, slot_name)

	assert_eq(main.get_node("Content/Header/Score").text, "SCORE 3 / 10")
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 16")
	assert_string_contains(main.get_node("Content/Feedback").text, "hatched")


func test_day_result_appears_after_twenty_thwacks_and_restart_restores_day() -> void:
	var main := _add_main()
	main.set_reduced_motion(true)

	for turn in range(20):
		await _press_and_wait(main, "Slot1")

	var result_panel: Control = main.get_node("ResultOverlay")
	assert_true(result_panel.visible)
	assert_eq(main.get_node("ResultOverlay/Card/Content/Result").text, "DAY FAILED")
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 0")

	main.get_node("ResultOverlay/Card/Content/Restart").pressed.emit()

	assert_false(result_panel.visible)
	assert_eq(main.get_node("Content/Header/Thwacks").text, "THWACKS 20")


func _press_and_wait(main: Control, slot_name: String) -> void:
	main.get_node("Content/Stage/KeyBank/%s" % slot_name.replace("Slot", "Key")).pressed.emit()
	await main.playback_completed
	await get_tree().process_frame


func _add_main() -> Control:
	var packed_scene := load("res://src/ui/main.tscn") as PackedScene
	var main := packed_scene.instantiate() as Control
	add_child_autofree(main)
	return main
