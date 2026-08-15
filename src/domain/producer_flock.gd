class_name ProducerFlock
extends RefCounted

const PRODUCER_KINDS: Array[String] = ["chicken", "cuckoo", "plover", "spoonbill"]
const PROTOTYPE_DOUBLE_YOLK_CHANCE := 0.10
const STARTING_PRODUCERS: Array[Dictionary] = [
	{"kind": "chicken", "double_yolk_chance": PROTOTYPE_DOUBLE_YOLK_CHANCE},
	{"kind": "chicken", "double_yolk_chance": PROTOTYPE_DOUBLE_YOLK_CHANCE},
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

var _producers: Array[Dictionary] = []


func _init(producers: Array[Dictionary] = STARTING_PRODUCERS) -> void:
	_producers.assign(producers.duplicate(true))
	for producer: Dictionary in _producers:
		assert(not String(producer.get("kind", "")).is_empty(), "A producer needs an egg kind.")


func snapshot() -> Array[Dictionary]:
	return _producers.duplicate(true)


func lay_daily_egg_kinds() -> Array[String]:
	var egg_kinds: Array[String] = []
	for producer: Dictionary in _producers:
		egg_kinds.append(String(producer.kind))
	return egg_kinds


func lay_daily_eggs(chance_roller) -> Array[Dictionary]:
	var eggs: Array[Dictionary] = []
	for producer: Dictionary in _producers:
		var chance := float(producer.get("double_yolk_chance", 0.0))
		assert(chance >= 0.0 and chance <= 1.0, "Double Yolker chance must be between zero and one.")
		eggs.append({
			"kind": String(producer.kind),
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


static func producer_for_kind(kind: String) -> Dictionary:
	if kind not in PRODUCER_KINDS:
		return {}
	return {
		"kind": kind,
	}
