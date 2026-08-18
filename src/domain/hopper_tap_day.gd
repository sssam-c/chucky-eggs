class_name HopperTapDay
extends RefCounted

const ChickenDay = preload("res://src/domain/chicken_day.gd")
const SLOT_COUNT := 5
const PIPE_PREVIEW_COUNT := 3
const DEFAULT_PULLS := 12
const DEFAULT_TARGET_SCORE := 10
const SPOONS: Array[Dictionary] = [
	{"id": "red_1", "slot_index": 0, "color": "red"},
	{"id": "blue_2", "slot_index": 1, "color": "blue"},
	{"id": "pink_3", "slot_index": 2, "color": "pink"},
	{"id": "red_4", "slot_index": 3, "color": "red"},
	{"id": "blue_5", "slot_index": 4, "color": "blue"},
]

var _slots: Array[Dictionary] = []
var _hopper: Array[Dictionary] = []
var _score := 0
var _target_score: int
var _pulls_remaining: int
var _maximum_pulls: int
var _ended := false
var _succeeded := false
var _next_egg_instance_id := 1
var _resolved_egg_ids: Dictionary = {}
var _vacancy_slots_in_hatch_order: Array[int] = []


func _init(
	daily_eggs: Array,
	target_score := DEFAULT_TARGET_SCORE,
	starting_pulls := DEFAULT_PULLS
) -> void:
	assert(not daily_eggs.is_empty(), "A tap-combo round needs at least one egg.")
	assert(target_score > 0, "A tap-combo round needs a positive Appetite.")
	assert(starting_pulls > 0, "A tap-combo round needs at least one spoon pull.")
	_target_score = target_score
	_pulls_remaining = starting_pulls
	_maximum_pulls = starting_pulls
	for slot_index in range(SLOT_COUNT):
		_slots.append({})
	for laid_egg: Variant in daily_eggs:
		_hopper.append(_new_egg(laid_egg))
	for slot_index in range(mini(SLOT_COUNT, _hopper.size())):
		_slots[slot_index] = _hopper.pop_front()


func snapshot() -> Dictionary:
	return {
		"slots": _slots.duplicate(true),
		"pipe": _hopper.slice(0, PIPE_PREVIEW_COUNT).duplicate(true),
		"hopper_contents": _hopper.duplicate(true),
		"hopper_egg_count": _hopper.size(),
		"spoons": SPOONS.duplicate(true),
		"slot_count": SLOT_COUNT,
		"score": _score,
		"target_score": _target_score,
		"pulls_remaining": _pulls_remaining,
		"maximum_pulls": _maximum_pulls,
		"ended": _ended,
		"succeeded": _succeeded,
	}


func resolve_spoon(slot_index: int) -> Array[Dictionary]:
	if _ended:
		return [{"type": "spoon_rejected", "reason": "round_ended"}]
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return [{"type": "spoon_rejected", "reason": "invalid_slot"}]
	if _slots[slot_index].is_empty():
		return [{"type": "spoon_rejected", "reason": "empty_slot"}]

	var spoon: Dictionary = SPOONS[slot_index]
	var events: Array[Dictionary] = [{
		"type": "spoon_fired",
		"spoon_id": String(spoon.id),
		"spoon_color": String(spoon.color),
		"slot_index": slot_index,
	}]
	_resolved_egg_ids.clear()
	_vacancy_slots_in_hatch_order.clear()

	var damage_amount := _direct_damage_amount(slot_index, String(spoon.color))
	_apply_damage(slot_index, damage_amount, "spoon", slot_index, String(spoon.color), events)
	_apply_cuckoo_echoes(slot_index, damage_amount, String(spoon.color), events)
	_resolve_hatches(events)
	_retreat_surviving_direct_plover(slot_index, events)
	_refill_vacancies(events)

	_pulls_remaining = maxi(_pulls_remaining - 1, 0)
	events.append({
		"type": "pull_spent",
		"remaining_pulls": _pulls_remaining,
		"maximum_pulls": _maximum_pulls,
	})

	if _score >= _target_score:
		_end_round(events, true)
	elif _pulls_remaining <= 0 or (_hopper.is_empty() and _all_slots_empty()):
		_end_round(events, false)
	return events


func _direct_damage_amount(slot_index: int, spoon_color: String) -> int:
	if spoon_color == "pink" and String(_slots[slot_index].kind) == "spoonbill":
		return 2
	return 1


func _apply_cuckoo_echoes(
	direct_slot_index: int,
	damage_amount: int,
	spoon_color: String,
	events: Array[Dictionary]
) -> void:
	for adjacent_slot_index in [direct_slot_index - 1, direct_slot_index + 1]:
		if adjacent_slot_index < 0 or adjacent_slot_index >= SLOT_COUNT:
			continue
		if _slots[adjacent_slot_index].is_empty():
			continue
		if String(_slots[adjacent_slot_index].kind) != "cuckoo":
			continue
		_apply_damage(
			adjacent_slot_index,
			damage_amount,
			"cuckoo_echo",
			direct_slot_index,
			spoon_color,
			events
		)


func _apply_damage(
	slot_index: int,
	damage_amount: int,
	cause: String,
	source_slot_index: int,
	spoon_color: String,
	events: Array[Dictionary]
) -> void:
	var egg: Dictionary = _slots[slot_index]
	egg.toughness = maxi(int(egg.toughness) - damage_amount, 0)
	_slots[slot_index] = egg
	events.append({
		"type": "egg_damaged",
		"slot_index": slot_index,
		"kind": String(egg.kind),
		"cause": cause,
		"source_slot_index": source_slot_index,
		"spoon_color": spoon_color,
		"damage_amount": damage_amount,
		"remaining_toughness": int(egg.toughness),
	})


func _resolve_hatches(events: Array[Dictionary]) -> void:
	for slot_index in range(SLOT_COUNT):
		if _slots[slot_index].is_empty() or int(_slots[slot_index].toughness) > 0:
			continue
		var egg: Dictionary = _slots[slot_index]
		var egg_instance_id := int(egg.egg_instance_id)
		if _resolved_egg_ids.has(egg_instance_id):
			continue
		_resolved_egg_ids[egg_instance_id] = true
		_slots[slot_index] = {}
		_vacancy_slots_in_hatch_order.append(slot_index)
		_score += int(egg.points)
		events.append({
			"type": "egg_hatched",
			"egg_instance_id": egg_instance_id,
			"slot_index": slot_index,
			"kind": String(egg.kind),
			"points_awarded": int(egg.points),
			"score": _score,
			"target_score": _target_score,
		})


func _retreat_surviving_direct_plover(
	direct_slot_index: int,
	events: Array[Dictionary]
) -> void:
	if direct_slot_index <= 0 or _slots[direct_slot_index].is_empty():
		return
	if String(_slots[direct_slot_index].kind) != "plover":
		return
	var destination_slot_index := direct_slot_index - 1
	var destination_was_vacant := _slots[destination_slot_index].is_empty()
	var plover: Dictionary = _slots[direct_slot_index]
	_slots[direct_slot_index] = _slots[destination_slot_index]
	_slots[destination_slot_index] = plover
	if destination_was_vacant:
		var vacancy_index := _vacancy_slots_in_hatch_order.find(destination_slot_index)
		if vacancy_index >= 0:
			_vacancy_slots_in_hatch_order[vacancy_index] = direct_slot_index
	events.append({
		"type": "eggs_swapped",
		"kind": "plover",
		"from_slot_index": direct_slot_index,
		"to_slot_index": destination_slot_index,
		"slots": _slots.duplicate(true),
	})


func _refill_vacancies(events: Array[Dictionary]) -> void:
	for slot_index: int in _vacancy_slots_in_hatch_order:
		if _hopper.is_empty():
			break
		assert(_slots[slot_index].is_empty(), "A hopper egg can only enter a vacant bay.")
		_slots[slot_index] = _hopper.pop_front()
		events.append({
			"type": "egg_entered",
			"slot_index": slot_index,
			"egg": _slots[slot_index].duplicate(true),
			"pipe": _hopper.slice(0, PIPE_PREVIEW_COUNT).duplicate(true),
			"hopper_egg_count": _hopper.size(),
		})


func _end_round(events: Array[Dictionary], succeeded: bool) -> void:
	_ended = true
	_succeeded = succeeded
	events.append({
		"type": "round_ended",
		"score": _score,
		"target_score": _target_score,
		"pulls_remaining": _pulls_remaining,
		"succeeded": _succeeded,
	})


func _all_slots_empty() -> bool:
	return _slots.all(func(egg: Dictionary) -> bool: return egg.is_empty())


func _new_egg(laid_egg: Variant) -> Dictionary:
	var kind := String(laid_egg.get("kind", "")) if laid_egg is Dictionary else String(laid_egg)
	var definition := ChickenDay.egg_definition(kind)
	assert(not definition.is_empty(), "Unknown egg kind: %s" % kind)
	var egg_instance_id := _next_egg_instance_id
	_next_egg_instance_id += 1
	return {
		"egg_instance_id": egg_instance_id,
		"kind": kind,
		"toughness": int(definition.toughness),
		"max_toughness": int(definition.toughness),
		"points": int(definition.points),
		"effects": [],
		"all_other_effects": [],
		"double_yolk_chance": 0.0,
		"is_double_yolker": false,
	}
