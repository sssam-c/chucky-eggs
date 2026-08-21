extends GutTest

const HopperTapSession = preload("res://src/game/hopper_tap_session.gd")
const ChickenDay = preload("res://src/domain/chicken_day.gd")


class IdentityShuffler:
	extends RefCounted

	func shuffle_strings(values: Array[String]) -> Array[String]:
		return values.duplicate()


func test_session_is_the_only_request_path_and_returns_safe_state() -> void:
	var session = HopperTapSession.new(
		HopperTapSession.DEFAULT_RUN_SEED, IdentityShuffler.new()
	)
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
	var session = HopperTapSession.new(
		HopperTapSession.DEFAULT_RUN_SEED, IdentityShuffler.new()
	)
	session.submit_spoon(2)

	session.restart()
	var state: Dictionary = session.state()

	assert_eq(state.hunger, 10)
	assert_eq(state.taps_remaining, state.taps_per_phase)
	assert_eq(state.tap_phase, 1)
	assert_eq(state.next_hunger_increase, 1)
	assert_eq(state.slots[2].kind, "sparrow")
	assert_eq(state.pipe[0].kind, "spoonbill")


func test_authored_red_route_builds_a_same_tap_double_break_jackpot() -> void:
	var session = HopperTapSession.new(HopperTapSession.DEFAULT_RUN_SEED, IdentityShuffler.new())
	session.submit_spoon(0)
	session.submit_spoon(0)
	session.submit_spoon(1)
	var combo_events: Array[Dictionary] = session.submit_spoon(0)
	var final_state: Dictionary = session.state()
	var hatches: Array = combo_events.filter(
		func(event: Dictionary) -> bool: return String(event.type) == "egg_hatched"
	)
	var delivery: Dictionary = combo_events.filter(
		func(event: Dictionary) -> bool: return String(event.type) == "yolk_delivered"
	)[0]

	assert_eq(hatches.map(func(event: Dictionary) -> String: return String(event.kind)), [
		"chicken", "cuckoo",
	])
	assert_eq(hatches.map(func(event: Dictionary) -> int: return int(event.combo_count)), [2, 2])
	assert_eq(hatches.map(func(event: Dictionary) -> int: return int(event.yolk)), [6, 2])
	assert_eq(delivery.base_yolks, [3, 1])
	assert_eq(delivery.combo_multiplier, 2)
	assert_eq(delivery.total_yolk, 8)
	assert_eq(final_state.hunger, 2)
	assert_eq(final_state.tap_phase, 1)
	assert_eq(final_state.taps_remaining, 1)
	assert_false(final_state.ended)


func test_equal_run_seeds_replay_round_order_and_reward_offers() -> void:
	var first = HopperTapSession.new(4107)
	var second = HopperTapSession.new(4107)

	assert_eq(_egg_kinds(first.state()), _egg_kinds(second.state()))
	assert_eq(first.state().reward_offers, second.state().reward_offers)
	assert_eq(first.state().run_seed, 4107)
	assert_eq(first.state().round_number, 1)
	assert_eq(first.state().round_starting_hunger, 10)


func test_different_run_seeds_can_change_the_first_round_order() -> void:
	var first = HopperTapSession.new(4107)
	var second = HopperTapSession.new(4108)

	assert_ne(_egg_kinds(first.state()), _egg_kinds(second.state()))


func test_reward_is_rejected_before_round_one_success() -> void:
	var session = HopperTapSession.new()

	var events: Array[Dictionary] = session.choose_reward(0)

	assert_eq(events, [{"type": "reward_rejected", "reason": "wrong_phase"}])
	assert_eq(session.state().round_number, 1)


func test_woodpecker_is_reward_only_with_four_toughness_and_two_yolk() -> void:
	assert_false(HopperTapSession.AUTHORED_EGGS.has("woodpecker"))
	assert_false(HopperTapSession.SEEDED_BASE_EGGS.has("woodpecker"))
	assert_true(HopperTapSession.REWARD_POOL.has("woodpecker"))
	var definition: Dictionary = ChickenDay.egg_definition("woodpecker")
	assert_eq(definition.toughness, 4)
	assert_eq(definition.points, 2)
	assert_eq(definition.effect, "break_tap_right")


func test_round_one_reward_adds_one_egg_and_starts_harder_round_two() -> void:
	var session = HopperTapSession.new(
		HopperTapSession.DEFAULT_RUN_SEED, IdentityShuffler.new()
	)
	_win_current_round(session)
	var offered: Array = session.state().reward_offers

	var events: Array[Dictionary] = session.choose_reward(1)
	var state: Dictionary = session.state()

	assert_eq(events.map(func(event: Dictionary) -> String: return String(event.type)), [
		"reward_selected", "round_started",
	])
	assert_eq(state.round_number, 2)
	assert_eq(state.round_starting_hunger, 12)
	assert_eq(state.hunger, 12)
	assert_eq(state.round_egg_count, 13)
	assert_eq(state.chosen_reward, offered[1])
	assert_false(state.awaiting_reward)
	assert_false(state.run_ended)
	assert_eq(_egg_kinds(state).count(String(offered[1])),
		HopperTapSession.AUTHORED_EGGS.count(String(offered[1])) + 1)


func test_retry_round_two_preserves_seed_reward_and_order() -> void:
	var session = HopperTapSession.new(
		HopperTapSession.DEFAULT_RUN_SEED, IdentityShuffler.new()
	)
	_win_current_round(session)
	session.choose_reward(0)
	var before: Dictionary = session.state()
	session.submit_spoon(0)

	session.retry_round()
	var after: Dictionary = session.state()

	assert_eq(after.run_seed, before.run_seed)
	assert_eq(after.chosen_reward, before.chosen_reward)
	assert_eq(after.round_number, 2)
	assert_eq(after.hunger, 12)
	assert_eq(_egg_kinds(after), _egg_kinds(before))


func test_dev_session_starts_and_restarts_an_exact_ordered_round() -> void:
	var dev_eggs: Array[String] = [
		"chicken", "woodpecker", "spoonbill", "cuckoo", "woodpecker", "sparrow",
	]
	var session = HopperTapSession.create_dev_session(dev_eggs, 17)
	var state: Dictionary = session.state()

	assert_true(state.dev_mode)
	assert_eq(state.dev_starting_eggs, dev_eggs)
	assert_eq(state.dev_starting_hunger, 17)
	assert_eq(state.round_number, 2)
	assert_eq(state.hunger, 17)
	assert_eq(state.round_starting_hunger, 17)
	assert_eq(state.round_order, dev_eggs)
	assert_eq(_egg_kinds(state), dev_eggs)

	session.submit_spoon(0)
	session.restart()
	state = session.state()
	assert_true(state.dev_mode)
	assert_eq(state.hunger, 17)
	assert_eq(state.round_order, dev_eggs)
	assert_eq(_egg_kinds(state), dev_eggs)

	session.start_new_run(4812)
	assert_false(session.state().dev_mode)
	assert_eq(session.state().run_seed, 4812)


func _win_current_round(session) -> void:
	for tap_index in range(80):
		var state: Dictionary = session.state()
		if state.ended:
			assert_true(state.succeeded, "Greedy test route should complete the round")
			return
		var chosen_slot := -1
		var lowest_toughness := 999
		for slot_index in range(state.slots.size()):
			var egg: Dictionary = state.slots[slot_index]
			if not egg.is_empty() and int(egg.toughness) < lowest_toughness:
				chosen_slot = slot_index
				lowest_toughness = int(egg.toughness)
		session.submit_spoon(chosen_slot)
	fail_test("Greedy test route did not complete the round")


func _egg_kinds(state: Dictionary) -> Array[String]:
	var kinds: Array[String] = []
	for egg: Dictionary in state.slots:
		if not egg.is_empty():
			kinds.append(String(egg.kind))
	for egg: Dictionary in state.hopper_contents:
		kinds.append(String(egg.kind))
	return kinds
