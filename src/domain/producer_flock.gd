class_name ProducerFlock
extends RefCounted

const PRODUCER_KINDS: Array[String] = [
	"chicken", "cuckoo", "sparrow", "plover", "spoonbill",
	"quail", "maleo", "ostrich", "oily", "nostalgic", "gloopy",
]
const KNOWN_KINDS: Array[String] = PRODUCER_KINDS
const STARTING_DOUBLE_YOLK_CHANCE := 0.02
const SPARROW_DOUBLE_YOLK_CHANCE := 0.05
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
	"oily": 0.0,
	"nostalgic": 0.0,
	"gloopy": 0.0,
}

var _producers: Array[Dictionary] = []


func _init(producers: Array[Dictionary] = STARTING_PRODUCERS) -> void:
	for supplied: Dictionary in producers:
		var kind := String(supplied.get("kind", ""))
		assert(kind in KNOWN_KINDS, "A producer needs a known egg kind.")
		_producers.append({"kind": kind})


func snapshot() -> Array[Dictionary]:
	return _producers.duplicate(true)


func species_groups_snapshot() -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	for kind: String in PRODUCER_KINDS:
		var bird_count := count_producers(kind)
		if bird_count > 0:
			groups.append({
				"kind": kind,
				"bird_count": bird_count,
				"double_yolk_chance": double_yolk_chance(kind),
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
		var chance := double_yolk_chance(kind)
		assert(chance >= 0.0 and chance <= 1.0, "Double Yolker chance must be between zero and one.")
		eggs.append({
			"kind": kind,
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


func remove_producer_at(producer_index: int) -> Dictionary:
	if _producers.size() <= 1 or producer_index < 0 or producer_index >= _producers.size():
		return {}
	return _producers.pop_at(producer_index).duplicate(true)


func count_producers(kind: String) -> int:
	return _producers.filter(func(producer: Dictionary) -> bool:
		return producer.kind == kind
	).size()


static func double_yolk_chance(kind: String) -> float:
	if kind not in BASE_DOUBLE_YOLK_CHANCES:
		return 0.0
	return float(BASE_DOUBLE_YOLK_CHANCES[kind])


static func producer_for_kind(kind: String) -> Dictionary:
	if kind not in KNOWN_KINDS:
		return {}
	return {"kind": kind}
