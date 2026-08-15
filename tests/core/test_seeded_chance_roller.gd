extends GutTest

const SeededChanceRoller = preload("res://src/core/seeded_chance_roller.gd")


func test_equal_seeds_replay_the_same_hidden_rolls() -> void:
	var first = SeededChanceRoller.new(42)
	var second = SeededChanceRoller.new(42)
	var first_results: Array[bool] = []
	var second_results: Array[bool] = []
	for roll_index in range(20):
		first_results.append(first.roll(0.10))
		second_results.append(second.roll(0.10))

	assert_eq(first_results, second_results)


func test_zero_and_certain_chances_resolve_at_their_boundaries() -> void:
	var roller = SeededChanceRoller.new(99)

	assert_false(roller.roll(0.0))
	assert_true(roller.roll(1.0))
