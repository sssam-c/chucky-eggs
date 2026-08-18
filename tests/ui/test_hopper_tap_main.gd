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
	assert_eq(main.get_node("Stage/Levers/Lever3").circuit_color, Color("cf4f8b"))
	assert_eq(main.get_node("Stage/Levers/Lever3").circuit_symbol, "spark")


func test_pink_lever_opens_sparrow_and_routes_spoonbill_into_pink_bay() -> void:
	var main := await _add_prototype()
	main.set_reduced_motion(true)

	main.get_node("Stage/Levers/Lever3").pressed.emit()
	await main.playback_completed
	await get_tree().process_frame
	var state: Dictionary = main.prototype_state()

	assert_eq(state.score, 1)
	assert_eq(state.pulls_remaining, state.maximum_pulls - 1)
	assert_eq(state.slots[2].kind, "spoonbill")
	assert_eq(main.get_node("Stage/Bays/Slot3").egg_kind(), "spoonbill")
	assert_eq(main.get_node("Hopper/Preview/Next1").egg_kind(), "cuckoo")


func test_second_input_is_ignored_while_a_tap_cascade_is_playing() -> void:
	var main := await _add_prototype()
	var lever: Button = main.get_node("Stage/Levers/Lever1")
	lever.pressed.emit()
	lever.pressed.emit()

	await main.playback_completed
	await get_tree().process_frame

	assert_eq(main.prototype_state().pulls_remaining, 11)


func test_restart_restores_the_authored_opening() -> void:
	var main := await _add_prototype()
	main.set_reduced_motion(true)
	main.get_node("Stage/Levers/Lever3").pressed.emit()
	await main.playback_completed
	await get_tree().process_frame

	main.get_node("Restart").pressed.emit()

	assert_eq(main.prototype_state().score, 0)
	assert_eq(main.prototype_state().slots[2].kind, "sparrow")
	assert_eq(main.prototype_state().pipe[0].kind, "spoonbill")


func _add_prototype() -> Control:
	var main: Control = PrototypeScene.instantiate()
	add_child_autofree(main)
	await get_tree().process_frame
	return main
