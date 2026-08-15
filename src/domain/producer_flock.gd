class_name ProducerFlock
extends RefCounted

const PRODUCER_KINDS: Array[String] = ["chicken", "cuckoo", "plover", "spoonbill"]
const STARTING_DOUBLE_YOLK_CHANCE := 0.02
const QUALITY_STEP := 1.5
const STARTING_PRODUCERS: Array[Dictionary] = [
	{"kind": "chicken"},
	{"kind": "chicken"},
	{"kind": "chicken"},
	{"kind": "chicken"},
	{"kind": "chicken"},
	{"kind": "chicken"},
	{"kind": "chicken"},
	{"kind": "chicken"},
	{"kind": "chicken"},
	{"kind": "chicken"},
	{"kind": "cuckoo"},
	{"kind": "cuckoo"},
	{"kind": "cuckoo"},
	{"kind": "plover"},
	{"kind": "plover"},
]
const BASE_DOUBLE_YOLK_CHANCES := {
	"chicken": STARTING_DOUBLE_YOLK_CHANCE,
	"cuckoo": 0.0,
	"plover": 0.0,
	"spoonbill": 0.0,
}

var _producers: Array[Dictionary] = []


func _init(producers: Array[Dictionary] = STARTING_PRODUCERS) -> void:
	for supplied: Dictionary in producers:
		var kind := String(supplied.get("kind", ""))
		var tier := int(supplied.get("tier", 0))
		assert(kind in PRODUCER_KINDS, "A producer needs a known egg kind.")
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


func add_producer(kind: String) -> Dictionary:
	var producer := producer_for_kind(kind)
	if producer.is_empty():
		return {}
	_producers.append(producer)
	return producer.duplicate(true)


func remove_producer(kind: String, tier := -1) -> Dictionary:
	if _producers.size() <= 1:
		return {}
	var selected_tier := int(tier)
	if selected_tier < 0:
		selected_tier = lowest_tier(kind)
	for producer_index in range(_producers.size()):
		if (
			String(_producers[producer_index].kind) != kind
			or int(_producers[producer_index].tier) != selected_tier
		):
			continue
		return _producers.pop_at(producer_index).duplicate(true)
	return {}


func merge_producers(kind: String, tier: int) -> Dictionary:
	if not can_merge(kind, tier):
		return {}
	var removed := 0
	for producer_index in range(_producers.size() - 1, -1, -1):
		var producer: Dictionary = _producers[producer_index]
		if producer.kind != kind or int(producer.tier) != tier:
			continue
		_producers.remove_at(producer_index)
		removed += 1
		if removed == 2:
			break
	var merged := {"kind": kind, "tier": tier + 1}
	_producers.append(merged)
	return merged.duplicate(true)


func can_merge(kind: String, tier: int) -> bool:
	return kind in PRODUCER_KINDS and tier >= 0 and count_producers(kind, tier) >= 2


func count_producers(kind: String, tier := -1) -> int:
	return _producers.filter(func(producer: Dictionary) -> bool:
		return producer.kind == kind and (tier < 0 or int(producer.tier) == tier)
	).size()


func lowest_tier(kind: String) -> int:
	var result := -1
	for producer: Dictionary in _producers:
		if producer.kind != kind:
			continue
		var tier := int(producer.tier)
		result = tier if result < 0 else mini(result, tier)
	return result


static func quality_multiplier(tier: int) -> float:
	assert(tier >= 0, "A quality tier cannot be negative.")
	return pow(QUALITY_STEP, tier)


static func double_yolk_chance(kind: String, tier: int) -> float:
	if kind not in BASE_DOUBLE_YOLK_CHANCES:
		return 0.0
	return minf(float(BASE_DOUBLE_YOLK_CHANCES[kind]) * quality_multiplier(tier), 1.0)


static func producer_for_kind(kind: String) -> Dictionary:
	if kind not in PRODUCER_KINDS:
		return {}
	return {
		"kind": kind,
		"tier": 0,
	}
