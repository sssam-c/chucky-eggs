extends GutTest

const HopperTapSession = preload("res://src/game/hopper_tap_session.gd")


func test_session_is_the_only_request_path_and_returns_safe_state() -> void:
	var session = HopperTapSession.new()
	var exposed: Dictionary = session.state()
	exposed.slots[2].toughness = 99

	var events: Array[Dictionary] = session.submit_spoon(2)
	var actual: Dictionary = session.state()

	assert_eq(events[0].type, "spoon_fired")
	assert_eq(events[0].slot_index, 2)
	assert_eq(actual.hunger, 9)
	assert_eq(actual.taps_remaining, 4)
	assert_eq(actual.slots[2].kind, "spoonbill")
	assert_eq(actual.slots[2].toughness, 5)
	assert_ne(actual.slots[2].toughness, 99)


func test_restart_restores_the_authored_combo_opening() -> void:
	var session = HopperTapSession.new()
	session.submit_spoon(2)

	session.restart()
	var state: Dictionary = session.state()

	assert_eq(state.hunger, 10)
	assert_eq(state.taps_remaining, state.taps_per_phase)
	assert_eq(state.tap_phase, 1)
	assert_eq(state.next_hunger_increase, 1)
	assert_eq(state.slots[2].kind, "sparrow")
	assert_eq(state.pipe[0].kind, "spoonbill")


func test_authored_pink_route_builds_a_double_break_jackpot() -> void:
	var session = HopperTapSession.new()
	session.submit_spoon(2)
	session.submit_spoon(2)
	var setup_events: Array[Dictionary] = session.submit_spoon(2)
	var winning_events: Array[Dictionary] = session.submit_spoon(2)
	var final_state: Dictionary = session.state()
	var setup_hatch: Dictionary = setup_events.filter(
		func(event: Dictionary) -> bool: return String(event.type) == "egg_hatched"
	)[0]
	var winning_hatch: Dictionary = winning_events.filter(
		func(event: Dictionary) -> bool: return String(event.type) == "egg_hatched"
	)[0]
	var delivery: Dictionary = winning_events.filter(
		func(event: Dictionary) -> bool: return String(event.type) == "yolk_delivered"
	)[0]

	assert_eq(setup_hatch.kind, "cuckoo")
	assert_eq(setup_hatch.break_streak, 1)
	assert_eq(setup_hatch.yolk, 1)
	assert_eq(winning_hatch.kind, "spoonbill")
	assert_eq(winning_hatch.break_streak, 2)
	assert_eq(winning_hatch.yolk, 8)
	assert_eq(delivery.total_yolk, 8)
	assert_eq(final_state.hunger, 0)
	assert_eq(final_state.tap_phase, 1)
	assert_eq(final_state.taps_remaining, 1)
	assert_true(final_state.ended)
	assert_true(final_state.succeeded)
	assert_eq(winning_events[-1].type, "day_ended")
