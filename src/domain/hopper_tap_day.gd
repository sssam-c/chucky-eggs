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
var _next_hunger_increase: int
var _hunger_growth: int
var _ended := false
var _succeeded := false
var _next_egg_instance_id := 1
var _resolved_egg_ids: Dictionary = {}
var _next_spoon_fire_id := 1


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

	var events: Array[Dictionary] = []
	_resolved_egg_ids.clear()
	_next_spoon_fire_id = 1
	var hatched_eggs: Array[Dictionary] = []
	var vacancy_frames: Array[Array] = []
	var paid_tap_vacancies: Array[int] = _resolve_spoon_fire(
		slot_index, "paid_tap", {}, 0, events, hatched_eggs, vacancy_frames
	)
	var hatch_result: Dictionary = _finalize_hatches(events, hatched_eggs)
	var total_yolk := int(hatch_result.total_yolk)
	if total_yolk > 0:
		var hunger_before := _hunger
		_hunger = maxi(_hunger - total_yolk, 0)
		events.append({
			"type": "yolk_delivered",
			"base_yolks": hatch_result.base_yolks,
			"base_yolk_total": int(hatch_result.base_yolk_total),
			"eggs_broken": int(hatch_result.eggs_broken),
			"combo_multiplier": int(hatch_result.combo_multiplier),
			"total_yolk": total_yolk,
			"hunger_before": hunger_before,
			"hunger": _hunger,
		})
	_refill_vacancies(paid_tap_vacancies, events)
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


func _resolve_spoon_fire(
	slot_index: int,
	cause: String,
	source_hatch: Dictionary,
	parent_fire_id: int,
	events: Array[Dictionary],
	all_hatched_eggs: Array[Dictionary],
	vacancy_frames: Array[Array]
) -> Array[int]:
	assert(not _slots[slot_index].is_empty(), "A spoon can only fire into an occupied cup.")
	var spoon: Dictionary = SPOONS[slot_index]
	var fire_id := _next_spoon_fire_id
	_next_spoon_fire_id += 1
	var fire_event := {
		"type": "spoon_fired",
		"fire_id": fire_id,
		"parent_fire_id": parent_fire_id,
		"cause": cause,
		"spoon_id": String(spoon.id),
		"spoon_color": String(spoon.color),
		"slot_index": slot_index,
	}
	if not source_hatch.is_empty():
		fire_event["source_egg_instance_id"] = int(source_hatch.egg_instance_id)
		fire_event["source_slot_index"] = int(source_hatch.slot_index)
	events.append(fire_event)

	var spoon_color := String(spoon.color)
	var damage_amount := _direct_damage_amount(slot_index, spoon_color)
	_apply_damage(
		slot_index, damage_amount, "spoon", slot_index, spoon_color, fire_id, events
	)
	_apply_cuckoo_echoes(slot_index, damage_amount, spoon_color, fire_id, events)
	var newly_hatched: Array[Dictionary] = _resolve_hatches(events, fire_id)
	all_hatched_eggs.append_array(newly_hatched)
	var vacancy_slots: Array[int] = []
	for hatched_egg: Dictionary in newly_hatched:
		vacancy_slots.append(int(hatched_egg.slot_index))
	vacancy_frames.append(vacancy_slots)
	_retreat_surviving_direct_plover(slot_index, vacancy_frames, events)

	for hatched_egg: Dictionary in newly_hatched:
		if String(hatched_egg.kind) != "woodpecker":
			continue
		var right_slot_index := int(hatched_egg.slot_index) + 1
		if right_slot_index >= SLOT_COUNT or _slots[right_slot_index].is_empty():
			continue
		_resolve_spoon_fire(
			right_slot_index,
			"woodpecker_break",
			hatched_egg,
			fire_id,
			events,
			all_hatched_eggs,
			vacancy_frames
		)
	if cause != "paid_tap":
		_refill_vacancies(vacancy_slots, events)
	vacancy_frames.pop_back()
	return vacancy_slots


func _direct_damage_amount(slot_index: int, spoon_color: String) -> int:
	if spoon_color == "pink" and String(_slots[slot_index].kind) == "spoonbill":
		return 2
	return 1


func _apply_cuckoo_echoes(
	direct_slot_index: int,
	damage_amount: int,
	spoon_color: String,
	fire_id: int,
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
			fire_id,
			events
		)


func _apply_damage(
	slot_index: int,
	damage_amount: int,
	cause: String,
	source_slot_index: int,
	spoon_color: String,
	fire_id: int,
	events: Array[Dictionary]
) -> void:
	var egg: Dictionary = _slots[slot_index]
	egg.toughness = maxi(int(egg.toughness) - damage_amount, 0)
	_slots[slot_index] = egg
	events.append({
		"type": "egg_damaged",
		"fire_id": fire_id,
		"slot_index": slot_index,
		"kind": String(egg.kind),
		"cause": cause,
		"source_slot_index": source_slot_index,
		"spoon_color": spoon_color,
		"damage_amount": damage_amount,
		"remaining_toughness": int(egg.toughness),
	})


func _resolve_hatches(events: Array[Dictionary], fire_id: int) -> Array[Dictionary]:
	var hatched_eggs: Array[Dictionary] = []
	for slot_index in range(SLOT_COUNT):
		if _slots[slot_index].is_empty() or int(_slots[slot_index].toughness) > 0:
			continue
		var egg: Dictionary = _slots[slot_index]
		var egg_instance_id := int(egg.egg_instance_id)
		if _resolved_egg_ids.has(egg_instance_id):
			continue
		_resolved_egg_ids[egg_instance_id] = true
		_slots[slot_index] = {}
		var base_yolk := int(egg.points)
		var hatched_egg := {
			"egg_instance_id": egg_instance_id,
			"slot_index": slot_index,
			"kind": String(egg.kind),
			"base_yolk": base_yolk,
			"caused_by_fire_id": fire_id,
		}
		hatched_eggs.append(hatched_egg)
		events.append({
			"type": "egg_hatched",
			"egg_instance_id": egg_instance_id,
			"slot_index": slot_index,
			"kind": String(egg.kind),
			"base_yolk": base_yolk,
			"caused_by_fire_id": fire_id,
		})
	return hatched_eggs


func _finalize_hatches(
	events: Array[Dictionary], hatched_eggs: Array[Dictionary]
) -> Dictionary:
	var combo_count := hatched_eggs.size()
	var combo_multiplier := maxi(combo_count, 1)
	var base_yolks: Array[int] = []
	var base_yolk_total := 0
	for hatched_egg: Dictionary in hatched_eggs:
		var base_yolk := int(hatched_egg.base_yolk)
		base_yolks.append(base_yolk)
		base_yolk_total += base_yolk
	for event_index in range(events.size()):
		if String(events[event_index].type) != "egg_hatched":
			continue
		var yolk := int(events[event_index].base_yolk) * combo_multiplier
		events[event_index]["points_awarded"] = yolk
		events[event_index]["yolk"] = yolk
		events[event_index]["combo_count"] = combo_count
		events[event_index]["combo_multiplier"] = combo_multiplier
	return {
		"base_yolks": base_yolks,
		"base_yolk_total": base_yolk_total,
		"eggs_broken": combo_count,
		"combo_multiplier": combo_multiplier,
		"total_yolk": base_yolk_total * combo_multiplier,
	}


func _retreat_surviving_direct_plover(
	direct_slot_index: int,
	vacancy_frames: Array[Array],
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
		for frame_index in range(vacancy_frames.size() - 1, -1, -1):
			var vacancy_slots: Array = vacancy_frames[frame_index]
			var vacancy_index := vacancy_slots.find(destination_slot_index)
			if vacancy_index < 0:
				continue
			vacancy_slots[vacancy_index] = direct_slot_index
			break
	events.append({
		"type": "eggs_swapped",
		"kind": "plover",
		"from_slot_index": direct_slot_index,
		"to_slot_index": destination_slot_index,
		"slots": _slots.duplicate(true),
	})


func _refill_vacancies(
	vacancy_slots: Array[int], events: Array[Dictionary]
) -> void:
	for slot_index: int in vacancy_slots:
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
