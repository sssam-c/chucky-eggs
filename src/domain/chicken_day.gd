class_name ChickenDay
extends RefCounted

const BASE_SLOT_COUNT := 5
const HAIRPIN_SLOT_COUNT := 10
const PIPE_PREVIEW_COUNT := 3
const STARTING_THWACKS := 20
const DEFAULT_TARGET_SCORE := 15
const CHICKEN_TOUGHNESS := 3
const CHICKEN_POINTS := 3
const CUCKOO_TOUGHNESS := 4
const CUCKOO_POINTS := 1
const PLOVER_TOUGHNESS := 6
const PLOVER_POINTS := 4
const SPOONBILL_TOUGHNESS := 5
const SPOONBILL_POINTS := 4
var _slots: Array[Dictionary] = []
var _hopper: Array[Dictionary] = []
var _remaining_thwacks := STARTING_THWACKS
var _score := 0
var _ended := false
var _succeeded := false
var _daily_egg_count := 0
var _target_score: int
var _circuits: Array[Dictionary] = []


func _init(
	daily_egg_kinds: Array[String],
	target_score := DEFAULT_TARGET_SCORE,
	slot_count := BASE_SLOT_COUNT
) -> void:
	assert(not daily_egg_kinds.is_empty(), "A day needs at least one laid egg.")
	assert(target_score > 0, "A day needs a positive target score.")
	assert(slot_count in [BASE_SLOT_COUNT, HAIRPIN_SLOT_COUNT], "Unsupported conveyor size.")
	_target_score = target_score
	_circuits = circuits_for_slot_count(slot_count)
	for slot_index in range(slot_count):
		_slots.append({})
	for kind: String in daily_egg_kinds:
		_hopper.append(_new_egg(kind))
	_daily_egg_count = _hopper.size()
	_slots[0] = _hopper.pop_front()


func snapshot() -> Dictionary:
	return {
		"slots": _slots.duplicate(true),
		"pipe": _hopper.slice(0, PIPE_PREVIEW_COUNT).duplicate(true),
		"hopper_egg_count": _hopper.size(),
		"daily_egg_count": _daily_egg_count,
		"circuits": _circuits.duplicate(true),
		"slot_count": _slots.size(),
		"remaining_thwacks": _remaining_thwacks,
		"score": _score,
		"target_score": _target_score,
		"ended": _ended,
		"succeeded": _succeeded,
	}


func resolve_circuit(circuit_id: String) -> Array[Dictionary]:
	if _ended:
		return [{"type": "thwack_rejected", "reason": "day_ended"}]
	var circuit := _circuit(circuit_id)
	if circuit.is_empty():
		return [{"type": "thwack_rejected", "reason": "invalid_circuit"}]

	var circuit_slot_indices: Array[int] = []
	var occupied_slot_indices: Array[int] = []
	for slot_index: int in circuit.slot_indices:
		circuit_slot_indices.append(slot_index)
		if not _slots[slot_index].is_empty():
			occupied_slot_indices.append(slot_index)
	if occupied_slot_indices.is_empty():
		return [{"type": "thwack_rejected", "reason": "empty_circuit"}]

	var events: Array[Dictionary] = [{
		"type": "circuit_fired",
		"circuit_id": circuit_id,
		"slot_indices": circuit_slot_indices,
		"occupied_slot_indices": occupied_slot_indices,
	}]
	_damage_eggs(occupied_slot_indices, circuit_id, events)
	_retreat_surviving_plovers_left(occupied_slot_indices, events)
	_advance_conveyor(events)
	_spend_thwack(events)

	if _remaining_thwacks == 0 or _score >= _target_score:
		_end_day(events)
	else:
		_refill_belt(events)
		if _hopper.is_empty() and _conveyor_is_empty():
			_end_day(events)

	return events


func _circuit(circuit_id: String) -> Dictionary:
	for circuit: Dictionary in _circuits:
		if circuit.id == circuit_id:
			return circuit
	return {}


func _damage_eggs(
	primary_slot_indices: Array[int],
	circuit_id: String,
	events: Array[Dictionary]
) -> void:
	# Apply the whole direct-and-echo batch before resolving any hatch. Empty
	# linked slots have already been omitted while their spoons still visibly fire.
	var direct_damage_by_slot := {}
	for primary_slot_index: int in primary_slot_indices:
		var damage_amount := _direct_damage_amount(circuit_id, primary_slot_index)
		direct_damage_by_slot[primary_slot_index] = damage_amount
		_apply_damage(primary_slot_index, damage_amount, "spoon", primary_slot_index, events)

	for primary_slot_index: int in primary_slot_indices:
		for slot_index in range(_slots.size()):
			if absi(slot_index - primary_slot_index) != 1 or _slots[slot_index].is_empty():
				continue
			if _slots[slot_index].kind == "cuckoo":
				_apply_damage(
					slot_index,
					direct_damage_by_slot[primary_slot_index],
					"cuckoo_echo",
					primary_slot_index,
					events
				)

	_resolve_hatches(events)


func _apply_damage(
	slot_index: int,
	damage_amount: int,
	cause: String,
	source_slot_index: int,
	events: Array[Dictionary]
) -> void:
	_slots[slot_index].toughness = maxi(_slots[slot_index].toughness - damage_amount, 0)
	events.append({
		"type": "egg_damaged",
		"slot_index": slot_index,
		"kind": _slots[slot_index].kind,
		"cause": cause,
		"source_slot_index": source_slot_index,
		"damage_amount": damage_amount,
		"remaining_toughness": _slots[slot_index].toughness,
	})


func _direct_damage_amount(circuit_id: String, slot_index: int) -> int:
	if circuit_id == "pink" and _slots[slot_index].kind == "spoonbill":
		return 2
	return 1


func _resolve_hatches(events: Array[Dictionary]) -> void:
	for slot_index in range(_slots.size()):
		if _slots[slot_index].is_empty() or _slots[slot_index].toughness > 0:
			continue
		var egg: Dictionary = _slots[slot_index]
		_slots[slot_index] = {}
		_score += egg.points
		events.append({
			"type": "egg_hatched",
			"slot_index": slot_index,
			"kind": egg.kind,
			"points_awarded": egg.points,
			"score": _score,
			"target_score": _target_score,
		})


func _retreat_surviving_plovers_left(slot_indices: Array[int], events: Array[Dictionary]) -> void:
	for slot_index: int in slot_indices:
		if _slots[slot_index].is_empty():
			continue
		if _slots[slot_index].kind != "plover":
			continue

		var destination_slot_index := screen_left_destination(slot_index, _slots.size())
		if destination_slot_index < 0:
			continue
		var plover: Dictionary = _slots[slot_index]
		_slots[slot_index] = _slots[destination_slot_index]
		_slots[destination_slot_index] = plover
		events.append({
			"type": "eggs_swapped",
			"kind": "plover",
			"from_slot_index": slot_index,
			"to_slot_index": destination_slot_index,
			"direction": "screen_left",
			"slots": _slots.duplicate(true),
		})


static func screen_left_destination(slot_index: int, slot_count: int) -> int:
	if slot_count == BASE_SLOT_COUNT:
		return slot_index - 1 if slot_index > 0 else -1
	assert(slot_count == HAIRPIN_SLOT_COUNT, "Unsupported conveyor size.")
	if slot_index in range(1, 5):
		return slot_index - 1
	if slot_index in range(5, 9):
		return slot_index + 1
	return -1


func _advance_conveyor(events: Array[Dictionary]) -> void:
	var fallen_egg: Dictionary = _slots[-1]
	for slot_index in range(_slots.size() - 1, 0, -1):
		_slots[slot_index] = _slots[slot_index - 1]
	_slots[0] = {}
	events.append({
		"type": "conveyor_advanced",
		"slots": _slots.duplicate(true),
	})

	if not fallen_egg.is_empty():
		events.append({
			"type": "egg_discarded",
			"reason": "belt_end",
			"remaining_toughness": fallen_egg.toughness,
		})


func _spend_thwack(events: Array[Dictionary]) -> void:
	_remaining_thwacks -= 1
	events.append({
		"type": "thwack_spent",
		"remaining_thwacks": _remaining_thwacks,
	})


func _refill_belt(events: Array[Dictionary]) -> void:
	if _hopper.is_empty():
		return
	_slots[0] = _hopper.pop_front()
	events.append({
		"type": "egg_entered",
		"slot_index": 0,
		"egg": _slots[0].duplicate(true),
		"pipe": _hopper.slice(0, PIPE_PREVIEW_COUNT).duplicate(true),
	})


func _conveyor_is_empty() -> bool:
	return _slots.all(func(egg: Dictionary) -> bool: return egg.is_empty())


func _end_day(events: Array[Dictionary]) -> void:
	var discarded_count := 0
	for egg: Dictionary in _slots:
		if not egg.is_empty():
			discarded_count += 1
	discarded_count += _hopper.size()

	for slot_index in range(_slots.size()):
		_slots[slot_index] = {}
	_hopper.clear()
	_ended = true
	_succeeded = _score >= _target_score
	events.append({
		"type": "day_remainder_discarded",
		"discarded_count": discarded_count,
	})
	events.append({
		"type": "day_ended",
		"score": _score,
		"target_score": _target_score,
		"remaining_thwacks": _remaining_thwacks,
		"succeeded": _succeeded,
	})


static func circuits_for_slot_count(slot_count: int) -> Array[Dictionary]:
	if slot_count == BASE_SLOT_COUNT:
		return [
			{"id": "red", "slot_indices": [0, 2]},
			{"id": "blue", "slot_indices": [1, 3]},
			{"id": "pink", "slot_indices": [4]},
		]
	assert(slot_count == HAIRPIN_SLOT_COUNT, "Unsupported conveyor size.")
	return [
		{"id": "red", "slot_indices": [0, 9]},
		{"id": "blue", "slot_indices": [1, 8]},
		{"id": "green", "slot_indices": [2, 7]},
		{"id": "purple", "slot_indices": [3, 6]},
		{"id": "pink", "slot_indices": [4, 5]},
	]


func _new_egg(kind: String) -> Dictionary:
	var definition := egg_definition(kind)
	assert(not definition.is_empty(), "Unknown egg kind: %s" % kind)
	return {
		"kind": definition.kind,
		"toughness": definition.toughness,
		"max_toughness": definition.toughness,
		"points": definition.points,
	}


static func egg_definition(kind: String) -> Dictionary:
	match kind:
		"chicken":
			return {"kind": kind, "toughness": CHICKEN_TOUGHNESS, "points": CHICKEN_POINTS, "effect": "none"}
		"cuckoo":
			return {"kind": kind, "toughness": CUCKOO_TOUGHNESS, "points": CUCKOO_POINTS, "effect": "adjacent_echo"}
		"plover":
			return {"kind": kind, "toughness": PLOVER_TOUGHNESS, "points": PLOVER_POINTS, "effect": "screen_left"}
		"spoonbill":
			return {"kind": kind, "toughness": SPOONBILL_TOUGHNESS, "points": SPOONBILL_POINTS, "effect": "pink_weakness"}
	return {}
