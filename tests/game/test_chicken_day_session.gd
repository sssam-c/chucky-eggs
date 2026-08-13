extends GutTest

const ChickenDaySession = preload("res://src/game/chicken_day_session.gd")


func test_session_builds_a_fifteen_egg_day_from_the_starting_flock() -> void:
	var state: Dictionary = ChickenDaySession.new(42).state()

	assert_eq(state.producers.size(), 10)
	assert_eq(state.daily_egg_count, 15)
	assert_eq(state.hopper_egg_count, 14)
	assert_eq(state.pipe.size(), 3)
	assert_false(state.slots[0].is_empty())


func test_equal_day_seeds_replay_the_same_visible_shuffle() -> void:
	var first: Dictionary = ChickenDaySession.new(42).state()
	var second: Dictionary = ChickenDaySession.new(42).state()

	assert_eq(first.slots, second.slots)
	assert_eq(first.pipe, second.pipe)


func test_session_is_the_request_pathway_and_returns_a_safe_snapshot() -> void:
	var session = ChickenDaySession.new()
	var exposed_state: Dictionary = session.state()
	exposed_state.remaining_thwacks = 2
	exposed_state.slots[0].toughness = 1

	var events: Array[Dictionary] = session.submit_circuit("red")
	var actual_state: Dictionary = session.state()

	assert_eq(events[0].type, "circuit_fired")
	assert_eq(actual_state.remaining_thwacks, 19)
	assert_eq(actual_state.slots[1].toughness, 2)


func test_restart_replaces_the_day_with_initial_state() -> void:
	var session = ChickenDaySession.new()
	session.submit_circuit("red")

	session.restart()

	assert_eq(session.state().remaining_thwacks, 20)
	assert_eq(session.state().slots[0].toughness, 3)
