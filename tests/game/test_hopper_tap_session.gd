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
	assert_eq(actual.score, 1)
	assert_eq(actual.slots[2].kind, "spoonbill")
	assert_eq(actual.slots[2].toughness, 5)
	assert_ne(actual.slots[2].toughness, 99)


func test_restart_restores_the_authored_combo_opening() -> void:
	var session = HopperTapSession.new()
	session.submit_spoon(2)

	session.restart()
	var state: Dictionary = session.state()

	assert_eq(state.score, 0)
	assert_eq(state.pulls_remaining, state.maximum_pulls)
	assert_eq(state.slots[2].kind, "sparrow")
	assert_eq(state.pipe[0].kind, "spoonbill")
