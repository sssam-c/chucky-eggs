class_name ProducerFlock
extends RefCounted

const PRODUCER_KINDS: Array[String] = [
	"chicken", "cuckoo", "sparrow", "plover", "spoonbill",
	"quail", "maleo", "ostrich", "kiwi",
]
const DEV_ONLY_EGG_KINDS: Array[String] = ["soft_shelled"]
const KNOWN_KINDS: Array[String] = PRODUCER_KINDS + DEV_ONLY_EGG_KINDS
const STARTING_DOUBLE_YOLK_CHANCE := 0.02
const SPARROW_DOUBLE_YOLK_CHANCE := 0.05
const QUALITY_STEP := 1.5
const STARTING_PRODUCERS: Array[Dictionary] = [
	{"kind": "chicken"},
	{"kind": "chicken"},
	{"kind": "chicken"},
	{"kind": "cuckoo"},
	{"kind": "cuckoo"},
	{"kind": "sparrow"},
	{"kind": "sparrow"},
	{"kind": "sparrow"},
]
const BASE_DOUBLE_YOLK_CHANCES := {
	"chicken": STARTING_DOUBLE_YOLK_CHANCE,
	"cuckoo": 0.0,
	"sparrow": SPARROW_DOUBLE_YOLK_CHANCE,
	"plover": 0.0,
	"spoonbill": 0.0,
	"quail": 0.0,
	"maleo": 0.01,
	"ostrich": 0.01,
	"kiwi": 0.0,
}

var _producers: Array[Dictionary] = []


func _init(producers: Array[Dictionary] = STARTING_PRODUCERS) -> void:
	for supplied: Dictionary in producers:
		var kind := String(supplied.get("kind", ""))
		var tier := int(supplied.get("tier", 0))
		assert(kind in KNOWN_KINDS, "A producer needs a known egg kind.")
		assert(tier >= 0, "A producer quality tier cannot be negative.")
		_producers.append({"kind": kind, "tier": tier})


func snapshot() -> Array[Dictionary]:
	return _producers.duplicate(true)


func quality_groups_snapshot() -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	for kind: String in PRODUCER_KINDS:
		var tiers: Array[int] = []
		for producer: Dictionary in _producers:
			if producer.kind == kind and int(producer.tier) not in tiers:
				tiers.append(int(producer.tier))
		tiers.sort()
		for tier: int in tiers:
			groups.append({
				"kind": kind,
				"tier": tier,
				"bird_count": count_producers(kind, tier),
				"quality_multiplier": quality_multiplier(tier),
				"double_yolk_chance": double_yolk_chance(kind, tier),
			})
	return groups


func lay_daily_egg_kinds() -> Array[String]:
	var egg_kinds: Array[String] = []
	for producer: Dictionary in _producers:
		egg_kinds.append(String(producer.kind))
	return egg_kinds


func lay_daily_eggs(chance_roller) -> Array[Dictionary]:
	var eggs: Array[Dictionary] = []
	for producer: Dictionary in _producers:
		var kind := String(producer.kind)
		var tier := int(producer.tier)
		var chance := double_yolk_chance(kind, tier)
		assert(chance >= 0.0 and chance <= 1.0, "Double Yolker chance must be between zero and one.")
		eggs.append({
			"kind": kind,
			"tier": tier,
			"quality_multiplier": quality_multiplier(tier),
			"double_yolk_chance": chance,
			"is_double_yolker": chance_roller.roll(chance),
		})
	return eggs


func add_producer(kind: String, tier := 0) -> Dictionary:
	var producer := producer_for_kind(kind, tier)
	if producer.is_empty():
		return {}
	_producers.append(producer)
	return producer.duplicate(true)


func remove_producer_at(producer_index: int) -> Dictionary:
	if _producers.size() <= 1 or producer_index < 0 or producer_index >= _producers.size():
		return {}
	return _producers.pop_at(producer_index).duplicate(true)


func count_producers(kind: String, tier := -1) -> int:
	return _producers.filter(func(producer: Dictionary) -> bool:
		return producer.kind == kind and (tier < 0 or int(producer.tier) == tier)
	).size()


static func quality_multiplier(tier: int) -> float:
	assert(tier >= 0, "A quality tier cannot be negative.")
	return pow(QUALITY_STEP, tier)


static func double_yolk_chance(kind: String, tier: int) -> float:
	if kind not in BASE_DOUBLE_YOLK_CHANCES:
		return 0.0
	return minf(float(BASE_DOUBLE_YOLK_CHANCES[kind]) * quality_multiplier(tier), 1.0)


static func producer_for_kind(kind: String, tier := 0) -> Dictionary:
	if kind not in KNOWN_KINDS or tier < 0:
		return {}
	return {
		"kind": kind,
		"tier": tier,
	}
