extends GutTest

const ChickenDaySession = preload("res://src/game/chicken_day_session.gd")


func test_session_is_the_request_pathway_and_returns_a_safe_snapshot() -> void:
	var session = ChickenDaySession.new()
	var exposed_state: Dictionary = session.state()
	exposed_state.remaining_thwacks = 2
	exposed_state.slots[0].toughness = 1

	var events: Array[Dictionary] = session.submit_thwack(0)
	var actual_state: Dictionary = session.state()

	assert_eq(events[0].type, "egg_damaged")
	assert_eq(actual_state.remaining_thwacks, 19)
	assert_eq(actual_state.slots[1].toughness, 3)


func test_restart_replaces_the_day_with_initial_state() -> void:
	var session = ChickenDaySession.new()
	session.submit_thwack(0)

	session.restart()

	assert_eq(session.state().remaining_thwacks, 20)
	assert_eq(session.state().slots[0].toughness, 4)
