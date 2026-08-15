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


func test_dictionary_shuffle_replays_and_preserves_hidden_egg_facts() -> void:
	var eggs: Array[Dictionary] = [
		{"kind": "chicken", "is_double_yolker": true},
		{"kind": "cuckoo", "is_double_yolker": false},
		{"kind": "plover", "is_double_yolker": false},
	]
	var first: Array[Dictionary] = SeededShuffler.new(42).shuffle_dictionaries(eggs)
	var second: Array[Dictionary] = SeededShuffler.new(42).shuffle_dictionaries(eggs)

	assert_eq(first, second)
	assert_eq(first.filter(func(egg: Dictionary) -> bool:
		return bool(egg.is_double_yolker)
	).size(), 1)
	assert_eq(eggs[0].kind, "chicken", "the supplied order is not mutated")
