class_name ChickenDay
extends RefCounted

const SLOT_COUNT := 5
const PIPE_PREVIEW_COUNT := 3
const STARTING_THWACKS := 20
const TARGET_SCORE := 10
const CHICKEN_TOUGHNESS := 4
const CHICKEN_POINTS := 3
const CUCKOO_TOUGHNESS := 4
const CUCKOO_POINTS := 1
const LAYING_PATTERN := [
	"chicken",
	"cuckoo",
	"chicken",
	"chicken",
	"chicken",
	"chicken",
]

var _slots: Array[Dictionary] = []
var _pipe: Array[Dictionary] = []
var _remaining_thwacks := STARTING_THWACKS
var _score := 0
var _ended := false
var _succeeded := false
var _next_egg_index := 0


func _init() -> void:
	for slot_index in range(SLOT_COUNT):
		_slots.append({})
	_slots[0] = _lay_next_egg()
	for preview_index in range(PIPE_PREVIEW_COUNT):
		_pipe.append(_lay_next_egg())


func snapshot() -> Dictionary:
	return {
		"slots": _slots.duplicate(true),
		"pipe": _pipe.duplicate(true),
		"remaining_thwacks": _remaining_thwacks,
		"score": _score,
		"target_score": TARGET_SCORE,
		"ended": _ended,
		"succeeded": _succeeded,
	}


func resolve_thwack(slot_index: int) -> Array[Dictionary]:
	if _ended:
		return [{"type": "thwack_rejected", "reason": "day_ended"}]
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return [{"type": "thwack_rejected", "reason": "invalid_slot"}]
	if _slots[slot_index].is_empty():
		return [{"type": "thwack_rejected", "reason": "empty_slot"}]

	var events: Array[Dictionary] = []
	_damage_eggs([slot_index], events)
	_advance_conveyor(events)
	_spend_thwack(events)

	if _remaining_thwacks == 0:
		_end_day(events)
	else:
		_refill_belt(events)

	return events


func _damage_eggs(primary_slot_indices: Array[int], events: Array[Dictionary]) -> void:
	# Apply the whole damage batch before resolving any hatch. This keeps a future
	# multi-target spoon deterministic and prevents a hatch from erasing an echo.
	for primary_slot_index: int in primary_slot_indices:
		_apply_damage(primary_slot_index, "spoon", primary_slot_index, events)

	for primary_slot_index: int in primary_slot_indices:
		for slot_index in range(_slots.size()):
			if absi(slot_index - primary_slot_index) != 1 or _slots[slot_index].is_empty():
				continue
			if _slots[slot_index].kind == "cuckoo":
				_apply_damage(slot_index, "cuckoo_echo", primary_slot_index, events)

	_resolve_hatches(events)


func _apply_damage(
	slot_index: int,
	cause: String,
	source_slot_index: int,
	events: Array[Dictionary]
) -> void:
	_slots[slot_index].toughness = maxi(_slots[slot_index].toughness - 1, 0)
	events.append({
		"type": "egg_damaged",
		"slot_index": slot_index,
		"kind": _slots[slot_index].kind,
		"cause": cause,
		"source_slot_index": source_slot_index,
		"remaining_toughness": _slots[slot_index].toughness,
	})


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
			"target_score": TARGET_SCORE,
		})


func _advance_conveyor(events: Array[Dictionary]) -> void:
	var fallen_egg: Dictionary = _slots[SLOT_COUNT - 1]
	for slot_index in range(SLOT_COUNT - 1, 0, -1):
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
	_slots[0] = _pipe.pop_front()
	_pipe.append(_lay_next_egg())
	events.append({
		"type": "egg_entered",
		"slot_index": 0,
		"egg": _slots[0].duplicate(true),
		"pipe": _pipe.duplicate(true),
	})


func _end_day(events: Array[Dictionary]) -> void:
	var discarded_count := 0
	for egg: Dictionary in _slots:
		if not egg.is_empty():
			discarded_count += 1
	discarded_count += _pipe.size()

	for slot_index in range(SLOT_COUNT):
		_slots[slot_index] = {}
	_pipe.clear()
	_ended = true
	_succeeded = _score >= TARGET_SCORE
	events.append({
		"type": "day_remainder_discarded",
		"discarded_count": discarded_count,
	})
	events.append({
		"type": "day_ended",
		"score": _score,
		"target_score": TARGET_SCORE,
		"succeeded": _succeeded,
	})


func _lay_next_egg() -> Dictionary:
	var kind: String = LAYING_PATTERN[_next_egg_index % LAYING_PATTERN.size()]
	_next_egg_index += 1
	return _new_egg(kind)


func _new_egg(kind: String) -> Dictionary:
	if kind == "cuckoo":
		return {
			"kind": "cuckoo",
			"toughness": CUCKOO_TOUGHNESS,
			"points": CUCKOO_POINTS,
		}
	return {
		"kind": "chicken",
		"toughness": CHICKEN_TOUGHNESS,
		"points": CHICKEN_POINTS,
	}
