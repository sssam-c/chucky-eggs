class_name HopperTapDay
extends RefCounted

const ChickenDay = preload("res://src/domain/chicken_day.gd")
const SLOT_COUNT := 5
const PIPE_PREVIEW_COUNT := 3
const DEFAULT_STARTING_HUNGER := 10
const DEFAULT_TAPS_PER_PHASE := 5
const DEFAULT_FIRST_HUNGER_INCREASE := 1
const DEFAULT_HUNGER_GROWTH := 1
const SPOONS: Array[Dictionary] = [
	{"id": "red_1", "slot_index": 0, "color": "red"},
	{"id": "blue_2", "slot_index": 1, "color": "blue"},
	{"id": "pink_3", "slot_index": 2, "color": "pink"},
	{"id": "green_4", "slot_index": 3, "color": "green"},
	{"id": "gold_5", "slot_index": 4, "color": "gold"},
]

var _slots: Array[Dictionary] = []
var _hopper: Array[Dictionary] = []
var _hunger: int
var _taps_remaining: int
var _taps_per_phase: int
var _tap_phase := 1
var _break_streak := 0
var _next_hunger_increase: int
var _hunger_growth: int
var _ended := false
var _succeeded := false
var _next_egg_instance_id := 1
var _resolved_egg_ids: Dictionary = {}
var _vacancy_slots_in_hatch_order: Array[int] = []


func _init(
	daily_eggs: Array,
	starting_hunger := DEFAULT_STARTING_HUNGER,
	taps_per_phase := DEFAULT_TAPS_PER_PHASE,
	first_hunger_increase := DEFAULT_FIRST_HUNGER_INCREASE,
	hunger_growth := DEFAULT_HUNGER_GROWTH
) -> void:
	assert(not daily_eggs.is_empty(), "A tap-combo round needs at least one egg.")
	assert(starting_hunger > 0, "A tap-combo day needs positive starting Hunger.")
	assert(taps_per_phase > 0, "A Tap phase needs at least one paid tap.")
	assert(first_hunger_increase > 0, "Grandma's Hunger phase must add Hunger.")
	assert(hunger_growth >= 0, "Hunger escalation cannot be negative.")
	_hunger = starting_hunger
	_taps_remaining = taps_per_phase
	_taps_per_phase = taps_per_phase
	_next_hunger_increase = first_hunger_increase
	_hunger_growth = hunger_growth
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
		"hunger": _hunger,
		"taps_remaining": _taps_remaining,
		"taps_per_phase": _taps_per_phase,
		"tap_phase": _tap_phase,
		"break_streak": _break_streak,
		"next_hunger_increase": _next_hunger_increase,
		"ended": _ended,
		"succeeded": _succeeded,
	}


func resolve_spoon(slot_index: int) -> Array[Dictionary]:
	if _ended:
		return [{"type": "spoon_rejected", "reason": "day_ended"}]
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
	var total_yolk := _resolve_hatches(events)
	if total_yolk > 0:
		var hunger_before := _hunger
		_hunger = maxi(_hunger - total_yolk, 0)
		events.append({
			"type": "yolk_delivered",
			"total_yolk": total_yolk,
			"hunger_before": hunger_before,
			"hunger": _hunger,
			"break_streak": _break_streak,
		})
	else:
		_reset_break_streak(events, "empty_tap")
	_retreat_surviving_direct_plover(slot_index, events)
	_refill_vacancies(events)

	_taps_remaining = maxi(_taps_remaining - 1, 0)
	events.append({
		"type": "tap_spent",
		"taps_remaining": _taps_remaining,
		"taps_per_phase": _taps_per_phase,
		"tap_phase": _tap_phase,
	})

	if _hunger <= 0:
		_end_day(events, true)
	elif _hopper.is_empty() and _all_slots_empty():
		_end_day(events, false)
	elif _taps_remaining <= 0:
		_resolve_hunger_phase(events)
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


func _resolve_hatches(events: Array[Dictionary]) -> int:
	var total_yolk := 0
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
		_break_streak += 1
		var base_yolk := int(egg.points)
		var yolk := base_yolk * _break_streak
		total_yolk += yolk
		events.append({
			"type": "egg_hatched",
			"egg_instance_id": egg_instance_id,
			"slot_index": slot_index,
			"kind": String(egg.kind),
			"base_yolk": base_yolk,
			"points_awarded": yolk,
			"yolk": yolk,
			"break_streak": _break_streak,
			"streak_multiplier": _break_streak,
		})
	return total_yolk


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


func _resolve_hunger_phase(events: Array[Dictionary]) -> void:
	_reset_break_streak(events, "hunger_phase")
	events.append({
		"type": "tap_phase_ended",
		"tap_phase": _tap_phase,
		"hunger": _hunger,
		"hunger_increase": _next_hunger_increase,
	})
	var applied_increase := _next_hunger_increase
	_hunger += applied_increase
	events.append({
		"type": "hunger_increased",
		"tap_phase": _tap_phase,
		"amount": applied_increase,
		"hunger": _hunger,
	})
	_tap_phase += 1
	_next_hunger_increase += _hunger_growth
	_taps_remaining = _taps_per_phase
	events.append({
		"type": "tap_phase_started",
		"tap_phase": _tap_phase,
		"taps_remaining": _taps_remaining,
		"taps_per_phase": _taps_per_phase,
		"next_hunger_increase": _next_hunger_increase,
		"hunger": _hunger,
	})


func _reset_break_streak(events: Array[Dictionary], reason: String) -> void:
	if _break_streak <= 0:
		return
	var previous_streak := _break_streak
	_break_streak = 0
	events.append({
		"type": "break_streak_reset",
		"previous_streak": previous_streak,
		"break_streak": _break_streak,
		"reason": reason,
	})


func _end_day(events: Array[Dictionary], succeeded: bool) -> void:
	_ended = true
	_succeeded = succeeded
	events.append({
		"type": "day_ended",
		"hunger": _hunger,
		"tap_phase": _tap_phase,
		"taps_remaining": _taps_remaining,
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
