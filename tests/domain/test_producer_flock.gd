extends GutTest

const ProducerFlock = preload("res://src/domain/producer_flock.gd")


func test_starting_flock_has_fifteen_one_egg_producers() -> void:
	var flock = ProducerFlock.new()
	var producers: Array[Dictionary] = flock.snapshot()
	var egg_kinds: Array[String] = flock.lay_daily_egg_kinds()

	assert_eq(producers.size(), 15)
	assert_eq(_count_kind(producers, "chicken"), 10)
	assert_eq(_count_kind(producers, "cuckoo"), 3)
	assert_eq(_count_kind(producers, "plover"), 2)
	assert_eq(egg_kinds.size(), 15)
	assert_eq(egg_kinds.count("chicken"), 10)
	assert_eq(egg_kinds.count("cuckoo"), 3)
	assert_eq(egg_kinds.count("plover"), 2)


func test_every_producer_lays_exactly_one_egg() -> void:
	var producers: Array[Dictionary] = []
	for kind: String in ProducerFlock.PRODUCER_KINDS:
		producers.append(ProducerFlock.producer_for_kind(kind))
	var flock = ProducerFlock.new(producers)

	assert_eq(flock.lay_daily_egg_kinds(), ProducerFlock.PRODUCER_KINDS)


func test_adding_a_producer_adds_one_bird_and_one_daily_egg() -> void:
	var flock = ProducerFlock.new()
	var original_daily_output := flock.lay_daily_egg_kinds().size()

	var added: Dictionary = flock.add_producer("spoonbill")

	assert_eq(added, {"kind": "spoonbill"})
	assert_eq(flock.snapshot().size(), 16)
	assert_eq(flock.lay_daily_egg_kinds().size(), original_daily_output + 1)
	assert_eq(flock.lay_daily_egg_kinds().count("spoonbill"), 1)


func test_chicken_addition_contributes_one_egg() -> void:
	var flock = ProducerFlock.new([])

	flock.add_producer("chicken")

	assert_eq(flock.lay_daily_egg_kinds(), ["chicken"])


func _count_kind(producers: Array[Dictionary], kind: String) -> int:
	return producers.filter(
		func(producer: Dictionary) -> bool: return producer.kind == kind
	).size()
