class_name ChickenDay
extends RefCounted

const GrandmaPatience = preload("res://src/domain/grandma_patience.gd")
const GrandmaEffects = preload("res://src/domain/grandma_effects.gd")
const EggEffects = preload("res://src/domain/egg_effects.gd")
const SLOT_COUNT := 5
const PIPE_PREVIEW_COUNT := 3
const STARTING_PATIENCE := 10
const STARTING_SPOON_INTEGRITY := 4
const DEFAULT_TARGET_SCORE := 10
const CHICKEN_TOUGHNESS := 3
const CHICKEN_POINTS := 3
const CUCKOO_TOUGHNESS := 4
const CUCKOO_POINTS := 1
const SPARROW_TOUGHNESS := 1
const SPARROW_POINTS := 1
const PLOVER_TOUGHNESS := 6
const PLOVER_POINTS := 4
const SPOONBILL_TOUGHNESS := 5
const SPOONBILL_POINTS := 4
const QUAIL_TOUGHNESS := 2
const QUAIL_POINTS := 1
const MALEO_TOUGHNESS := 6
const MALEO_POINTS := 3
const OSTRICH_TOUGHNESS := 7
const OSTRICH_POINTS := 3
const KIWI_TOUGHNESS := 3
const KIWI_POINTS := 0
const SOFT_SHELLED_TOUGHNESS := 3
const SOFT_SHELLED_POINTS := 3
var _slots: Array[Dictionary] = []
var _hopper: Array[Dictionary] = []
var _bin: Array[Dictionary] = []
var _recycle_shuffler
var _patience
var _score := 0
var _ended := false
var _succeeded := false
var _daily_egg_count := 0
var _target_score: int
var _circuits: Array[Dictionary] = []
var _grandma_effects = GrandmaEffects.new()
var _effective_target_score: int
var _next_egg_instance_id := 1
var _resolved_egg_ids_this_thwack := {}
var _spoon_integrity: Array[int] = []
var _starting_spoon_integrity := STARTING_SPOON_INTEGRITY


func _init(
	daily_eggs: Array,
	target_score := DEFAULT_TARGET_SCORE,
	starting_spoon_integrity := STARTING_SPOON_INTEGRITY,
	recycle_shuffler = null
) -> void:
	assert(not daily_eggs.is_empty(), "A day needs at least one laid egg.")
	assert(target_score > 0, "A day needs a positive target score.")
	assert(starting_spoon_integrity > 0, "Spoons need positive starting Integrity.")
	_starting_spoon_integrity = starting_spoon_integrity
	_spoon_integrity.resize(SLOT_COUNT)
	_spoon_integrity.fill(starting_spoon_integrity)
	# Kept only as inert compatibility state while this tentative branch is evaluated.
	_patience = GrandmaPatience.new(STARTING_PATIENCE)
	_target_score = target_score
	_effective_target_score = target_score
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
		"hopper_contents": _hopper_contents_snapshot(),
		"bin": _bin.duplicate(true),
		"hopper_egg_count": _hopper.size(),
		"bin_egg_count": _bin.size(),
		"daily_egg_count": _daily_egg_count,
		"circuits": _circuits.duplicate(true),
		"slot_count": _slots.size(),
		"current_patience": _patience.current(),
		"starting_patience": _patience.starting(),
		"spoon_integrity": _spoon_integrity.duplicate(),
		"starting_spoon_integrity": _starting_spoon_integrity,
		"score": _score,
		"satisfaction": _score,
		"target_score": _target_score,
		"effective_target_score": _effective_target_score,
		"grandma_effects": _grandma_effects.snapshot(),
		"ended": _ended,
		"succeeded": _succeeded,
	}


func _hopper_contents_snapshot() -> Array[Dictionary]:
	var contents := _hopper.duplicate(true)
	contents.sort_custom(_egg_content_precedes)
	return contents


func _egg_content_precedes(first: Dictionary, second: Dictionary) -> bool:
	var first_kind := String(first.get("kind", ""))
	var second_kind := String(second.get("kind", ""))
	if first_kind != second_kind:
		return first_kind < second_kind
	for key in ["tier", "toughness", "max_toughness", "points"]:
		var first_value := float(first.get(key, 0.0))
		var second_value := float(second.get(key, 0.0))
		if not is_equal_approx(first_value, second_value):
			return first_value < second_value
	return false


func resolve_circuit(circuit_id: String) -> Array[Dictionary]:
	if _ended:
		return [{"type": "thwack_rejected", "reason": "day_ended"}]
	var circuit := _circuit(circuit_id)
	if circuit.is_empty():
		return [{"type": "thwack_rejected", "reason": "invalid_circuit"}]

	var circuit_slot_indices: Array[int] = []
	var occupied_slot_indices: Array[int] = []
	for slot_index: int in circuit.slot_indices:
		if _spoon_integrity[slot_index] <= 0:
			continue
		circuit_slot_indices.append(slot_index)
		if not _slots[slot_index].is_empty():
			occupied_slot_indices.append(slot_index)
	if circuit_slot_indices.is_empty():
		return [{
			"type": "thwack_rejected",
			"reason": "broken_circuit",
			"circuit_id": circuit_id,
		}]

	var events: Array[Dictionary] = []
	_resolved_egg_ids_this_thwack.clear()
	_score = _grandma_effects.begin_thwack(_target_score, _score, events)
	_effective_target_score = _grandma_effects.effective_appetite(_target_score)
	events.append({
		"type": "circuit_fired",
		"circuit_id": circuit_id,
		"slot_indices": circuit_slot_indices,
		"occupied_slot_indices": occupied_slot_indices,
	})
	_damage_eggs(
		occupied_slot_indices,
		circuit_id,
		events,
		"spoon",
		-1,
		circuit_slot_indices
	)
	_retreat_surviving_plovers_left(occupied_slot_indices, events)
	_advance_conveyor(events)
	_spend_patience(events)
	_refill_belt(events)

	# Success takes precedence after the complete thwack, including impact wear.
	var succeeded_this_thwack: bool = _score >= _effective_target_score
	var spoons_failed: bool = _spoon_integrity.all(func(value: int) -> bool: return value <= 0)
	var completed_effective_target := _effective_target_score
	if succeeded_this_thwack:
		_end_day(events, true, completed_effective_target)
	elif spoons_failed:
		_end_day(events, false, completed_effective_target)
	else:
		if _hopper.is_empty() and _bin.is_empty() and _conveyor_is_empty():
			_end_day(events, false, completed_effective_target)

	return events


func _egg_has_effect(egg: Dictionary, effect_type: String) -> bool:
	if egg.is_empty():
		return false
	for effect: Dictionary in egg.get("effects", []):
		if String(effect.get("type", "")) == effect_type:
			return true
	return false


func _circuit(circuit_id: String) -> Dictionary:
	for circuit: Dictionary in _circuits:
		if circuit.id == circuit_id:
			return circuit
	return {}


func _damage_eggs(
	primary_slot_indices: Array[int],
	circuit_id: String,
	events: Array[Dictionary],
	direct_cause := "spoon",
	source_slot_override := -1,
	physical_spoon_slot_indices: Array[int] = []
) -> void:
	# Apply the whole direct-and-echo batch before resolving any hatch. Empty
	# linked slots have already been omitted while their spoons still visibly fire.
	var impact_facts_by_slot := {}
	for slot_index: int in physical_spoon_slot_indices:
		var egg: Dictionary = _slots[slot_index]
		impact_facts_by_slot[slot_index] = {
			"struck_egg": not egg.is_empty(),
			"soft_shelled": _egg_has_effect(egg, EggEffects.SOFT_SHELLED),
			"egg_instance_id": int(egg.get("egg_instance_id", -1)),
			"kind": String(egg.get("kind", "")),
		}
	var direct_damage_by_slot := {}
	for primary_slot_index: int in primary_slot_indices:
		var damage_amount := _direct_damage_amount(circuit_id, primary_slot_index)
		direct_damage_by_slot[primary_slot_index] = damage_amount
		_apply_damage(
			primary_slot_index,
			damage_amount,
			direct_cause,
			source_slot_override if source_slot_override >= 0 else primary_slot_index,
			circuit_id,
			events
		)

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
					circuit_id,
					events
				)

	_apply_spoon_wear(physical_spoon_slot_indices, impact_facts_by_slot, direct_cause, events)
	_resolve_hatches(events, circuit_id)


func _apply_spoon_wear(
	spoon_slot_indices: Array[int],
	impact_facts_by_slot: Dictionary,
	cause: String,
	events: Array[Dictionary]
) -> void:
	for slot_index: int in spoon_slot_indices:
		var impact_facts: Dictionary = impact_facts_by_slot[slot_index]
		if bool(impact_facts.soft_shelled):
			events.append({
				"type": "spoon_wear_prevented",
				"slot_index": slot_index,
				"reason": "soft_shelled",
				"cause": cause,
				"egg_instance_id": int(impact_facts.egg_instance_id),
				"kind": String(impact_facts.kind),
				"remaining_integrity": _spoon_integrity[slot_index],
				"starting_integrity": _starting_spoon_integrity,
			})
			continue
		_spoon_integrity[slot_index] = maxi(_spoon_integrity[slot_index] - 1, 0)
		events.append({
			"type": "spoon_worn",
			"slot_index": slot_index,
			"wear_amount": 1,
			"cause": cause,
			"struck_egg": bool(impact_facts.struck_egg),
			"remaining_integrity": _spoon_integrity[slot_index],
			"starting_integrity": _starting_spoon_integrity,
			"broken": _spoon_integrity[slot_index] == 0,
		})


func _apply_damage(
	slot_index: int,
	damage_amount: int,
	cause: String,
	source_slot_index: int,
	circuit_id: String,
	events: Array[Dictionary]
) -> void:
	if slot_index < 0 or slot_index >= _slots.size() or _slots[slot_index].is_empty():
		return
	_slots[slot_index].toughness = maxi(_slots[slot_index].toughness - damage_amount, 0)
	events.append({
		"type": "egg_damaged",
		"slot_index": slot_index,
		"kind": _slots[slot_index].kind,
		"cause": cause,
		"source_slot_index": source_slot_index,
		"damage_amount": damage_amount,
		"remaining_toughness": _slots[slot_index].toughness,
		"circuit_id": circuit_id,
	})


func _direct_damage_amount(circuit_id: String, slot_index: int) -> int:
	if circuit_id == "pink" and _slots[slot_index].kind == "spoonbill":
		return 2
	return 1


func _resolve_hatches(events: Array[Dictionary], circuit_id: String) -> void:
	for slot_index in range(_slots.size()):
		if _slots[slot_index].is_empty() or _slots[slot_index].toughness > 0:
			continue
		var egg: Dictionary = _slots[slot_index]
		var egg_instance_id := int(egg.egg_instance_id)
		if _resolved_egg_ids_this_thwack.has(egg_instance_id):
			continue
		_resolved_egg_ids_this_thwack[egg_instance_id] = true
		_slots[slot_index] = {}
		var base_points := int(egg.points)
		var exact_base_points := float(egg.get("exact_base_points", base_points))
		var is_double_yolker := bool(egg.get("is_double_yolker", false))
		var yolk_produced := base_points * 2 if is_double_yolker else base_points
		var appetiser_multiplier := _grandma_effects.appetiser_multiplier_for_yolk(
			yolk_produced, events
		)
		var points_awarded := yolk_produced * appetiser_multiplier
		_score += points_awarded
		events.append({
			"type": "egg_hatched",
			"egg_instance_id": egg_instance_id,
			"slot_index": slot_index,
			"kind": egg.kind,
			"tier": int(egg.get("tier", 0)),
			"base_points": base_points,
			"exact_base_points": exact_base_points,
			"double_yolker": is_double_yolker,
			"yolk_produced": yolk_produced,
			"appetiser_multiplier": appetiser_multiplier,
			"points_awarded": points_awarded,
			"score": _score,
			"satisfaction": _score,
			"target_score": _target_score,
			"effective_target_score": _effective_target_score,
			"sulphurous_suppression": int(
				_grandma_effects.snapshot().sulphurous_suppression
			),
		})
		_resolve_break_actions(egg, slot_index, circuit_id, events)


func _resolve_break_actions(
	egg: Dictionary,
	slot_index: int,
	circuit_id: String,
	events: Array[Dictionary]
) -> void:
	var effects: Array[Dictionary] = []
	effects.assign(egg.get("effects", []))
	for action: Dictionary in EggEffects.break_actions(
		effects, slot_index, circuit_id, _slots.size()
	):
		if action.type == "grandma_effect":
			_grandma_effects.activate(action.effect, events, _target_score, _score)
			_effective_target_score = _grandma_effects.effective_appetite(_target_score)
		else:
			_resolve_shockwave(action, events)


func _resolve_shockwave(action: Dictionary, events: Array[Dictionary]) -> void:
	var slot_indices: Array[int] = []
	for slot_index: int in action.slot_indices:
		if _spoon_integrity[slot_index] > 0:
			slot_indices.append(slot_index)
	var occupied_slot_indices: Array[int] = []
	for slot_index: int in slot_indices:
		if not _slots[slot_index].is_empty():
			occupied_slot_indices.append(slot_index)
	events.append({
		"type": "shockwave_fired",
		"source_slot_index": int(action.source_slot_index),
		"slot_indices": slot_indices,
		"occupied_slot_indices": occupied_slot_indices,
		"circuit_id": String(action.circuit_id),
	})
	_damage_eggs(
		occupied_slot_indices,
		String(action.circuit_id),
		events,
		"shockwave",
		int(action.source_slot_index),
		slot_indices
	)
	_retreat_surviving_plovers_left(occupied_slot_indices, events)


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


func _spend_patience(events: Array[Dictionary]) -> void:
	var amount_spent: int = _patience.lose(1)
	events.append({
		"type": "patience_spent",
		"amount": amount_spent,
		"current_patience": _patience.current(),
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


func _end_day(
	events: Array[Dictionary],
	succeeded: bool,
	completed_effective_target: int
) -> void:
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
	_grandma_effects.clear()
	_effective_target_score = completed_effective_target
	_ended = true
	_succeeded = succeeded
	events.append({
		"type": "day_remainder_discarded",
		"discarded_count": discarded_count,
	})
	events.append({
		"type": "day_ended",
		"score": _score,
		"target_score": _target_score,
		"effective_target_score": completed_effective_target,
		"current_patience": _patience.current(),
		"spoon_integrity": _spoon_integrity.duplicate(),
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
	var raw_effects: Array = definition.get("effects", []).duplicate(true)
	if laid_egg is Dictionary:
		for supplied_effect: Variant in laid_egg.get("effects", []):
			raw_effects.append(supplied_effect)
	var effects := EggEffects.normalize(raw_effects)
	var egg_instance_id := _next_egg_instance_id
	_next_egg_instance_id += 1
	return {
		"egg_instance_id": egg_instance_id,
		"kind": definition.kind,
		"tier": tier,
		"toughness": max_toughness,
		"max_toughness": max_toughness,
		"exact_max_toughness": exact_max_toughness,
		"points": floori(exact_base_points),
		"exact_base_points": exact_base_points,
		"double_yolk_chance": double_yolk_chance,
		"is_double_yolker": is_double_yolker,
		"effects": effects,
		"all_other_effects": EggEffects.descriptions(effects),
	}


static func egg_definition(kind: String) -> Dictionary:
	match kind:
		"chicken":
			return {"kind": kind, "toughness": CHICKEN_TOUGHNESS, "points": CHICKEN_POINTS, "effect": "none"}
		"cuckoo":
			return {"kind": kind, "toughness": CUCKOO_TOUGHNESS, "points": CUCKOO_POINTS, "effect": "adjacent_echo"}
		"sparrow":
			return {"kind": kind, "toughness": SPARROW_TOUGHNESS, "points": SPARROW_POINTS, "effect": "none"}
		"plover":
			return {"kind": kind, "toughness": PLOVER_TOUGHNESS, "points": PLOVER_POINTS, "effect": "screen_left"}
		"spoonbill":
			return {"kind": kind, "toughness": SPOONBILL_TOUGHNESS, "points": SPOONBILL_POINTS, "effect": "pink_weakness"}
		"quail":
			return {
				"kind": kind, "toughness": QUAIL_TOUGHNESS, "points": QUAIL_POINTS,
				"effect": "appetiser", "effects": [{"type": EggEffects.APPETISER}],
			}
		"maleo":
			return {
				"kind": kind, "toughness": MALEO_TOUGHNESS, "points": MALEO_POINTS,
				"effect": "sulphurous", "effects": [{"type": EggEffects.SULPHUROUS}],
			}
		"ostrich":
			return {
				"kind": kind, "toughness": OSTRICH_TOUGHNESS, "points": OSTRICH_POINTS,
				"effect": "shockwave", "effects": [{"type": EggEffects.SHOCKWAVE}],
			}
		"kiwi":
			return {
				"kind": kind, "toughness": KIWI_TOUGHNESS, "points": KIWI_POINTS,
				"effect": "deceptively_filling",
				"effects": [{"type": EggEffects.DECEPTIVELY_FILLING, "duration": 8}],
			}
		"soft_shelled":
			return {
				"kind": kind,
				"toughness": SOFT_SHELLED_TOUGHNESS,
				"points": SOFT_SHELLED_POINTS,
				"effect": "soft_shelled",
				"effects": [{"type": EggEffects.SOFT_SHELLED}],
			}
	return {}
