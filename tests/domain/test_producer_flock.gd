extends GutTest

const ProducerFlock = preload("res://src/domain/producer_flock.gd")


class EligibleEggsDoubleRoller:
	extends RefCounted

	func roll(chance: float) -> bool:
		return chance > 0.0


func test_starting_flock_has_eight_one_egg_producers_including_three_sparrows() -> void:
	var flock = ProducerFlock.new()
	var producers: Array[Dictionary] = flock.snapshot()
	var egg_kinds: Array[String] = flock.lay_daily_egg_kinds()

	assert_eq(producers.size(), 8)
	assert_eq(_count_kind(producers, "chicken"), 3)
	assert_eq(_count_kind(producers, "cuckoo"), 2)
	assert_eq(_count_kind(producers, "sparrow"), 3)
	assert_eq(_count_kind(producers, "plover"), 0)
	assert_eq(egg_kinds.size(), 8)
	assert_eq(egg_kinds.count("chicken"), 3)
	assert_eq(egg_kinds.count("cuckoo"), 2)
	assert_eq(egg_kinds.count("sparrow"), 3)
	assert_eq(egg_kinds.count("plover"), 0)
	assert_true(producers.all(func(producer: Dictionary) -> bool:
		return producer.tier == 0
	))


func test_starting_chickens_share_the_standard_quality_double_yolker_chance() -> void:
	var flock = ProducerFlock.new()
	var producers: Array[Dictionary] = flock.snapshot()
	var laid_eggs: Array[Dictionary] = flock.lay_daily_eggs(EligibleEggsDoubleRoller.new())

	assert_true(producers.all(func(producer: Dictionary) -> bool:
		return not producer.has("double_yolk_chance")
	))
	assert_eq(laid_eggs.filter(func(egg: Dictionary) -> bool:
		return egg.kind == "chicken" and is_equal_approx(float(egg.double_yolk_chance), 0.02)
	).size(), 3)
	assert_eq(laid_eggs.filter(func(egg: Dictionary) -> bool:
		return bool(egg.is_double_yolker)
	).size(), 6)
	assert_true(laid_eggs.all(func(egg: Dictionary) -> bool:
		return egg.has_all([
			"kind", "tier", "quality_multiplier", "double_yolk_chance", "is_double_yolker",
		])
	))


func test_standard_sparrows_have_five_percent_double_yolker_chance() -> void:
	var laid_eggs: Array[Dictionary] = ProducerFlock.new([
		{"kind": "sparrow"},
	]).lay_daily_eggs(EligibleEggsDoubleRoller.new())

	assert_eq(laid_eggs.size(), 1)
	assert_almost_eq(float(laid_eggs[0].double_yolk_chance), 0.05, 0.00001)
	assert_true(laid_eggs[0].is_double_yolker)


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

	assert_eq(added, {"kind": "spoonbill", "tier": 0})
	assert_eq(flock.snapshot().size(), original_daily_output + 1)
	assert_eq(flock.lay_daily_egg_kinds().size(), original_daily_output + 1)
	assert_eq(flock.lay_daily_egg_kinds().count("spoonbill"), 1)


func test_chicken_addition_contributes_one_egg() -> void:
	var flock = ProducerFlock.new([])

	flock.add_producer("chicken")

	assert_eq(flock.lay_daily_egg_kinds(), ["chicken"])


func test_adding_an_offered_quality_preserves_that_birds_tier() -> void:
	var flock = ProducerFlock.new([])

	assert_eq(flock.add_producer("plover", 3), {"kind": "plover", "tier": 3})
	assert_eq(flock.snapshot(), [{"kind": "plover", "tier": 3}])


func test_quality_compounds_exactly_while_laid_eggs_keep_the_real_values() -> void:
	var flock = ProducerFlock.new([
		{"kind": "chicken", "tier": 2}, {"kind": "cuckoo", "tier": 1},
	])
	var eggs: Array[Dictionary] = flock.lay_daily_eggs(EligibleEggsDoubleRoller.new())

	assert_almost_eq(float(eggs[0].quality_multiplier), 2.25, 0.00001)
	assert_almost_eq(float(eggs[0].double_yolk_chance), 0.045, 0.00001)
	assert_eq(eggs[0].tier, 2)
	assert_almost_eq(float(eggs[1].quality_multiplier), 1.5, 0.00001)
	assert_eq(eggs[1].double_yolk_chance, 0.0)


func test_removing_by_overview_position_targets_that_exact_flock_entry() -> void:
	var flock = ProducerFlock.new([
		{"kind": "chicken", "tier": 1}, {"kind": "chicken"}, {"kind": "plover"},
	])

	assert_eq(flock.remove_producer_at(0), {"kind": "chicken", "tier": 1})
	assert_eq(flock.lay_daily_egg_kinds(), ["chicken", "plover"])
	assert_true(flock.remove_producer_at(9).is_empty())
	assert_eq(flock.snapshot().size(), 2)
	assert_true(flock.snapshot().all(func(producer: Dictionary) -> bool:
		return producer.has_all(["kind", "tier"])
	))


func _count_kind(producers: Array[Dictionary], kind: String) -> int:
	return producers.filter(
		func(producer: Dictionary) -> bool: return producer.kind == kind
	).size()
