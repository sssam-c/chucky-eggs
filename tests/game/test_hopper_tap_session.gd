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


func test_authored_combo_route_survives_one_hunger_phase_and_satisfies_grandma() -> void:
	var session = HopperTapSession.new()
	for tap_index in range(5):
		session.submit_spoon(2)

	var after_first_phase: Dictionary = session.state()
	assert_eq(after_first_phase.hunger, 4)
	assert_eq(after_first_phase.tap_phase, 2)
	assert_eq(after_first_phase.taps_remaining, 5)

	session.submit_spoon(2)
	session.submit_spoon(0)
	session.submit_spoon(0)
	var winning_events: Array[Dictionary] = session.submit_spoon(0)
	var final_state: Dictionary = session.state()

	assert_eq(final_state.hunger, 0)
	assert_true(final_state.ended)
	assert_true(final_state.succeeded)
	assert_eq(winning_events[-1].type, "day_ended")
