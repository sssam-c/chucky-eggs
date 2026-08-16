class_name ChickenDay
extends RefCounted

const SLOT_COUNT := 5
const PIPE_PREVIEW_COUNT := 3
const STARTING_THWACKS := 10
const DEFAULT_TARGET_SCORE := 8
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
var _bin: Array[Dictionary] = []
var _recycle_shuffler
var _remaining_thwacks := STARTING_THWACKS
var _score := 0
var _ended := false
var _succeeded := false
var _daily_egg_count := 0
var _target_score: int
var _circuits: Array[Dictionary] = []


func _init(
	daily_eggs: Array,
	target_score := DEFAULT_TARGET_SCORE,
	starting_thwacks := STARTING_THWACKS,
	recycle_shuffler = null
) -> void:
	assert(not daily_eggs.is_empty(), "A day needs at least one laid egg.")
	assert(target_score > 0, "A day needs a positive target score.")
	assert(starting_thwacks > 0, "A day needs at least one thwack.")
	_remaining_thwacks = starting_thwacks
	_target_score = target_score
	_recycle_shuffler = recycle_shuffler
	_circuits = circuits_for_slot_count(SLOT_COUNT)
	for slot_index in range(SLOT_COUNT):
		_slots.append({})
	for laid_egg: Variant in daily_eggs:
		_hopper.append(_new_egg(laid_egg))
	_daily_egg_count = _hopper.size()
	_slots[0] = _hopper.pop_front()


func snapshot() -> Dictionary:
	return {
		"slots": _slots.duplicate(true),
		"pipe": _hopper.slice(0, PIPE_PREVIEW_COUNT).duplicate(true),
		"hopper_egg_count": _hopper.size(),
		"bin_egg_count": _bin.size(),
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
		if _hopper.is_empty() and _bin.is_empty() and _conveyor_is_empty():
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
		var base_points := int(egg.points)
		var exact_base_points := float(egg.get("exact_base_points", base_points))
		var is_double_yolker := bool(egg.get("is_double_yolker", false))
		var points_awarded := base_points * 2 if is_double_yolker else base_points
		_score += points_awarded
		events.append({
			"type": "egg_hatched",
			"slot_index": slot_index,
			"kind": egg.kind,
			"tier": int(egg.get("tier", 0)),
			"base_points": base_points,
			"exact_base_points": exact_base_points,
			"double_yolker": is_double_yolker,
			"points_awarded": points_awarded,
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


static func screen_left_destination(slot_index: int, slot_count := SLOT_COUNT) -> int:
	assert(slot_count == SLOT_COUNT, "The conveyor has exactly five slots.")
	return slot_index - 1 if slot_index > 0 else -1


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
		_bin.append(fallen_egg)
		events.append({
			"type": "egg_binned",
			"egg": fallen_egg.duplicate(true),
			"remaining_toughness": fallen_egg.toughness,
			"bin_egg_count": _bin.size(),
		})


func _spend_thwack(events: Array[Dictionary]) -> void:
	_remaining_thwacks -= 1
	events.append({
		"type": "thwack_spent",
		"remaining_thwacks": _remaining_thwacks,
	})


func _refill_belt(events: Array[Dictionary]) -> void:
	if _hopper.is_empty() and _conveyor_is_empty():
		_recycle_bin(events)
	if _hopper.is_empty():
		return
	_slots[0] = _hopper.pop_front()
	events.append({
		"type": "egg_entered",
		"slot_index": 0,
		"egg": _slots[0].duplicate(true),
		"pipe": _hopper.slice(0, PIPE_PREVIEW_COUNT).duplicate(true),
	})


func _recycle_bin(events: Array[Dictionary]) -> void:
	if _bin.is_empty():
		return
	var recyclable: Array[Dictionary] = _bin.duplicate(true)
	_hopper = (
		_recycle_shuffler.shuffle_dictionaries(recyclable)
		if _recycle_shuffler != null
		else recyclable
	)
	_bin.clear()
	events.append({
		"type": "bin_reshuffled",
		"hopper_egg_count": _hopper.size(),
		"bin_egg_count": 0,
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
	discarded_count += _bin.size()

	for slot_index in range(_slots.size()):
		_slots[slot_index] = {}
	_hopper.clear()
	_bin.clear()
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
	assert(slot_count == SLOT_COUNT, "The conveyor has exactly five slots.")
	return [
		{"id": "red", "slot_indices": [0, 2]},
		{"id": "blue", "slot_indices": [1, 3]},
		{"id": "pink", "slot_indices": [4]},
	]


func _new_egg(laid_egg: Variant) -> Dictionary:
	var kind := String(laid_egg.get("kind", "")) if laid_egg is Dictionary else String(laid_egg)
	var definition := egg_definition(kind)
	assert(not definition.is_empty(), "Unknown egg kind: %s" % kind)
	var double_yolk_chance := (
		float(laid_egg.get("double_yolk_chance", 0.0))
		if laid_egg is Dictionary
		else 0.0
	)
	var is_double_yolker := (
		bool(laid_egg.get("is_double_yolker", false))
		if laid_egg is Dictionary
		else false
	)
	var tier := (
		int(laid_egg.get("tier", 0))
		if laid_egg is Dictionary
		else 0
	)
	var quality_multiplier := (
		float(laid_egg.get("quality_multiplier", 1.0))
		if laid_egg is Dictionary
		else 1.0
	)
	assert(tier >= 0, "An egg's quality tier cannot be negative.")
	assert(quality_multiplier >= 1.0, "An egg's quality multiplier cannot be below one.")
	assert(double_yolk_chance >= 0.0 and double_yolk_chance <= 1.0, "Double Yolker chance must be between zero and one.")
	var exact_base_points := float(definition.points) * quality_multiplier
	var exact_max_toughness := float(definition.toughness) * quality_multiplier
	var max_toughness := ceili(exact_max_toughness)
	return {
		"kind": definition.kind,
		"tier": tier,
		"toughness": max_toughness,
		"max_toughness": max_toughness,
		"exact_max_toughness": exact_max_toughness,
		"points": floori(exact_base_points),
		"exact_base_points": exact_base_points,
		"double_yolk_chance": double_yolk_chance,
		"is_double_yolker": is_double_yolker,
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
