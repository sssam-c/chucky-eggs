class_name ProducerFlock
extends RefCounted

const STARTING_PRODUCERS: Array[Dictionary] = [
	{"kind": "chicken", "daily_yield": 2},
	{"kind": "chicken", "daily_yield": 2},
	{"kind": "chicken", "daily_yield": 2},
	{"kind": "chicken", "daily_yield": 2},
	{"kind": "chicken", "daily_yield": 2},
	{"kind": "cuckoo", "daily_yield": 1},
	{"kind": "cuckoo", "daily_yield": 1},
	{"kind": "cuckoo", "daily_yield": 1},
	{"kind": "plover", "daily_yield": 1},
	{"kind": "plover", "daily_yield": 1},
]

var _producers: Array[Dictionary] = []


func _init(producers: Array[Dictionary] = STARTING_PRODUCERS) -> void:
	_producers.assign(producers.duplicate(true))
	for producer: Dictionary in _producers:
		assert(not String(producer.get("kind", "")).is_empty(), "A producer needs an egg kind.")
		assert(int(producer.get("daily_yield", 0)) > 0, "A producer needs a positive daily yield.")


func snapshot() -> Array[Dictionary]:
	return _producers.duplicate(true)


func lay_daily_egg_kinds() -> Array[String]:
	var egg_kinds: Array[String] = []
	for producer: Dictionary in _producers:
		for egg_index in range(int(producer.daily_yield)):
			egg_kinds.append(String(producer.kind))
	return egg_kinds
