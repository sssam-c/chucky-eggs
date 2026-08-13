extends GutTest

const SeededShuffler = preload("res://src/core/seeded_shuffler.gd")


func test_equal_seeds_replay_the_same_shuffle() -> void:
	var values: Array[String] = ["a", "b", "c", "d", "e", "f"]

	assert_eq(
		SeededShuffler.new(42).shuffle_strings(values),
		SeededShuffler.new(42).shuffle_strings(values)
	)


func test_known_seed_changes_the_supplied_order() -> void:
	var values: Array[String] = ["a", "b", "c", "d", "e", "f"]

	assert_ne(SeededShuffler.new(42).shuffle_strings(values), values)


func test_shuffle_preserves_every_supplied_value() -> void:
	var values: Array[String] = ["chicken", "chicken", "cuckoo", "plover"]
	var shuffled: Array[String] = SeededShuffler.new(99).shuffle_strings(values)

	shuffled.sort()
	values.sort()
	assert_eq(shuffled, values)
