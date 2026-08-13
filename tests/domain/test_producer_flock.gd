extends GutTest

const ProducerFlock = preload("res://src/domain/producer_flock.gd")


func test_starting_flock_has_ten_producers_and_lays_fifteen_eggs() -> void:
	var flock = ProducerFlock.new()
	var producers: Array[Dictionary] = flock.snapshot()
	var egg_kinds: Array[String] = flock.lay_daily_egg_kinds()

	assert_eq(producers.size(), 10)
	assert_eq(_count_kind(producers, "chicken"), 5)
	assert_eq(_count_kind(producers, "cuckoo"), 3)
	assert_eq(_count_kind(producers, "plover"), 2)
	assert_eq(egg_kinds.size(), 15)
	assert_eq(egg_kinds.count("chicken"), 10)
	assert_eq(egg_kinds.count("cuckoo"), 3)
	assert_eq(egg_kinds.count("plover"), 2)


func test_each_starting_producer_exposes_its_daily_yield() -> void:
	var producers: Array[Dictionary] = ProducerFlock.new().snapshot()

	for producer: Dictionary in producers:
		assert_eq(producer.daily_yield, 2 if producer.kind == "chicken" else 1)


func test_adding_a_producer_expands_the_roster_and_daily_output() -> void:
	var flock = ProducerFlock.new()
	var original_daily_output := flock.lay_daily_egg_kinds().size()

	var added: Dictionary = flock.add_producer("spoonbill")

	assert_eq(added, {"kind": "spoonbill", "daily_yield": 1})
	assert_eq(flock.snapshot().size(), 11)
	assert_eq(flock.lay_daily_egg_kinds().size(), original_daily_output + 1)
	assert_eq(flock.lay_daily_egg_kinds().count("spoonbill"), 1)


func test_chicken_addition_contributes_its_two_egg_yield() -> void:
	var flock = ProducerFlock.new([])

	flock.add_producer("chicken")

	assert_eq(flock.lay_daily_egg_kinds(), ["chicken", "chicken"])


func _count_kind(producers: Array[Dictionary], kind: String) -> int:
	return producers.filter(
		func(producer: Dictionary) -> bool: return producer.kind == kind
	).size()
