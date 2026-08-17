class_name ChickenDaySession
extends RefCounted

const ChickenDay = preload("res://src/domain/chicken_day.gd")
const ProducerFlock = preload("res://src/domain/producer_flock.gd")
const SeededChanceRoller = preload("res://src/core/seeded_chance_roller.gd")
const SeededShuffler = preload("res://src/core/seeded_shuffler.gd")
const DEFAULT_DAY_SEED := 20260813
const REWARD_SEED_STEP := 1009
const REWARD_QUALITY_SEED_STEP := 37
const DOUBLE_YOLK_SEED_STEP := 9
const DAY_ONE_TARGET := 10
const LATER_DAY_TARGET := 9
const REMOVE_BIRD_PRICE := 3
const QUALITY_ADVANCE_CHANCE := 0.25

var _day
var _flock
var _day_seed: int
var _shuffler
var _day_number := 1
var _phase := "day"
var _bird_offer: Array[Dictionary] = []
var _bird_offer_claimed := true
var _removal_used_tonight := false
var _cash := 0
var _last_cash_awarded := 0
var _starting_patience := ChickenDay.STARTING_PATIENCE


func _init(
	day_seed := DEFAULT_DAY_SEED,
	flock = null,
	shuffler = null,
	initial_day_number := 1
) -> void:
	_day_seed = day_seed
	_flock = flock if flock != null else ProducerFlock.new()
	_shuffler = shuffler
	_day_number = maxi(int(initial_day_number), 1)
	_start_day()


func state() -> Dictionary:
	var current_state: Dictionary = _day.snapshot()
	current_state["producers"] = _flock.snapshot()
	current_state["flock_overview"] = _production_snapshot()
	current_state["day_number"] = _day_number
	current_state["next_day_target_score"] = _target_for_day(_day_number + 1)
	current_state["phase"] = _phase
	current_state["bird_offer"] = _bird_offer.duplicate(true)
	current_state["bird_offer_claimed"] = _bird_offer_claimed
	current_state["removal_used_tonight"] = _removal_used_tonight
	current_state["shop_stock"] = _shop_stock()
	current_state["quality_groups"] = _quality_groups_snapshot()
	current_state["projected_flock_size"] = _flock.snapshot().size()
	current_state["cash"] = _cash
	current_state["last_cash_awarded"] = _last_cash_awarded
	current_state["machine_slot_count"] = ChickenDay.SLOT_COUNT
	current_state["starting_patience"] = _starting_patience
	current_state["machine_circuits"] = ChickenDay.circuits_for_slot_count(ChickenDay.SLOT_COUNT)
	return current_state


func submit_circuit(circuit_id: String) -> Array[Dictionary]:
	if _phase != "day":
		return [{"type": "thwack_rejected", "reason": "wrong_phase"}]
	var events: Array[Dictionary] = _day.resolve_circuit(circuit_id)
	var ended_event: Dictionary = {}
	for event: Dictionary in events:
		if event.type != "day_ended":
			continue
		ended_event = event
		if event.succeeded:
			_phase = "bird_offer"
			_bird_offer = _create_bird_offer()
			_bird_offer_claimed = false
		else:
			_phase = "failed"
	if not ended_event.is_empty() and ended_event.succeeded:
		_last_cash_awarded = int(ended_event.current_patience)
		_cash += _last_cash_awarded
		events.append({
			"type": "cash_awarded",
			"amount": _last_cash_awarded,
			"cash_total": _cash,
			"remaining_patience": int(ended_event.current_patience),
		})
	return events


func restart() -> void:
	if _phase in ["bird_offer", "shop"]:
		return
	_start_day()


func claim_bird_offer(choice_index: int) -> Array[Dictionary]:
	if _phase != "bird_offer":
		return [_shop_action_rejected("bird_offer", "wrong_phase")]
	if _bird_offer_claimed:
		return [_shop_action_rejected("bird_offer", "already_claimed")]
	if choice_index < 0 or choice_index >= _bird_offer.size():
		return [_shop_action_rejected("bird_offer", "not_offered")]

	var selected: Dictionary = _bird_offer[choice_index]
	var producer: Dictionary = _flock.add_producer(String(selected.kind), int(selected.tier))
	_bird_offer.clear()
	_bird_offer_claimed = true
	_phase = "shop"
	return [{
		"type": "bird_offer_claimed",
		"producer": producer.duplicate(true),
		"cash_total": _cash,
		"flock_size": _flock.snapshot().size(),
		"daily_egg_count": _flock.lay_daily_egg_kinds().size(),
	}]


func remove_bird(producer_index: int) -> Array[Dictionary]:
	if _phase != "shop":
		return [_shop_action_rejected("removal", "wrong_phase")]
	if not _bird_offer_claimed:
		return [_shop_action_rejected("removal", "bird_offer_unclaimed")]
	if _removal_used_tonight:
		return [_shop_action_rejected("removal", "nightly_limit")]
	if _flock.snapshot().size() <= 1:
		return [_shop_action_rejected("removal", "last_bird")]
	if producer_index < 0 or producer_index >= _flock.snapshot().size():
		return [_shop_action_rejected("removal", "not_available")]
	if _cash < REMOVE_BIRD_PRICE:
		return [_shop_action_rejected("removal", "insufficient_cash")]
	var removed: Dictionary = _flock.remove_producer_at(producer_index)
	_cash -= REMOVE_BIRD_PRICE
	_removal_used_tonight = true
	return [{
		"type": "bird_removed",
		"producer": removed,
		"price": REMOVE_BIRD_PRICE,
		"cash_total": _cash,
		"flock_size": _flock.snapshot().size(),
		"daily_egg_count": _flock.lay_daily_egg_kinds().size(),
	}]


func leave_shop() -> Array[Dictionary]:
	if _phase != "shop":
		return [{"type": "shop_leave_rejected", "reason": "wrong_phase"}]
	if not _bird_offer_claimed:
		return [{"type": "shop_leave_rejected", "reason": "bird_offer_unclaimed"}]

	var events: Array[Dictionary] = []
	var daily_egg_count: int = _flock.lay_daily_egg_kinds().size()
	_day_number += 1
	_start_day()
	events.append({
		"type": "day_started",
		"day_number": _day_number,
		"target_score": _day.snapshot().target_score,
		"daily_egg_count": daily_egg_count,
		"slot_count": ChickenDay.SLOT_COUNT,
		"production": _production_snapshot(),
	})
	return events


func _start_day() -> void:
	_phase = "day"
	_bird_offer.clear()
	_bird_offer_claimed = true
	_removal_used_tonight = false
	_last_cash_awarded = 0
	var current_day_seed: int = _day_seed + _day_number - 1
	var laid_eggs: Array[Dictionary] = _flock.lay_daily_eggs(
		SeededChanceRoller.new(current_day_seed + DOUBLE_YOLK_SEED_STEP)
	)
	var day_shuffler = _shuffler if _shuffler != null else SeededShuffler.new(current_day_seed)
	var shuffled_eggs: Array[Dictionary] = day_shuffler.shuffle_dictionaries(laid_eggs)
	_day = ChickenDay.new(
		shuffled_eggs,
		_target_for_day(_day_number),
		_starting_patience,
		day_shuffler
	)


func _target_for_day(day_number: int) -> int:
	return DAY_ONE_TARGET if day_number == 1 else LATER_DAY_TARGET


func _create_bird_offer() -> Array[Dictionary]:
	var reward_seed := _day_seed + _day_number * REWARD_SEED_STEP
	var ordered_kinds: Array[String] = SeededShuffler.new(reward_seed).shuffle_strings(
		ProducerFlock.PRODUCER_KINDS
	)
	var quality_roller = SeededChanceRoller.new(reward_seed + REWARD_QUALITY_SEED_STEP)
	var choices: Array[Dictionary] = []
	for kind: String in ordered_kinds.slice(0, 3):
		var tier := 0
		while quality_roller.roll(QUALITY_ADVANCE_CHANCE):
			tier += 1
		choices.append(_producer_offer(kind, tier))
	return choices


func _producer_offer(kind: String, tier: int) -> Dictionary:
	var choice := ProducerFlock.producer_for_kind(kind, tier)
	var definition := ChickenDay.egg_definition(kind)
	var multiplier := ProducerFlock.quality_multiplier(tier)
	choice.merge(definition)
	choice["tier"] = tier
	choice["exact_toughness"] = float(definition.toughness) * multiplier
	choice["toughness"] = ceili(float(choice.exact_toughness))
	choice["exact_points"] = float(definition.points) * multiplier
	choice["points"] = floori(float(choice.exact_points))
	choice["double_yolk_chance"] = ProducerFlock.double_yolk_chance(kind, tier)
	return choice


func _shop_stock() -> Dictionary:
	if _phase != "shop":
		return {}
	return {"removal": {"price": REMOVE_BIRD_PRICE}}


func _quality_groups_snapshot() -> Array[Dictionary]:
	var groups: Array[Dictionary] = _flock.quality_groups_snapshot()
	for group: Dictionary in groups:
		var definition := ChickenDay.egg_definition(String(group.kind))
		var exact_points := float(definition.points) * float(group.quality_multiplier)
		var exact_toughness := float(definition.toughness) * float(group.quality_multiplier)
		group["exact_points"] = exact_points
		group["points"] = floori(exact_points)
		group["exact_toughness"] = exact_toughness
		group["toughness"] = ceili(exact_toughness)
		group["display_double_yolk_percent"] = floori(float(group.double_yolk_chance) * 100.0)
	return groups


func _shop_action_rejected(category: String, reason: String) -> Dictionary:
	return {
		"type": "shop_action_rejected",
		"category": category,
		"reason": reason,
	}


func _production_snapshot() -> Array[Dictionary]:
	var production: Array[Dictionary] = []
	for producer: Dictionary in _flock.snapshot():
		var produced_egg := ChickenDay.egg_definition(String(producer.kind))
		var tier := int(producer.tier)
		var multiplier := ProducerFlock.quality_multiplier(tier)
		produced_egg["tier"] = tier
		produced_egg["exact_toughness"] = float(produced_egg.toughness) * multiplier
		produced_egg["toughness"] = ceili(float(produced_egg.toughness) * multiplier)
		produced_egg["exact_points"] = float(produced_egg.points) * multiplier
		produced_egg["points"] = floori(float(produced_egg.points) * multiplier)
		produced_egg["double_yolk_chance"] = ProducerFlock.double_yolk_chance(
			String(producer.kind), tier
		)
		var fact: Dictionary = producer.duplicate(true)
		fact.merge(produced_egg)
		production.append(fact)
	return production
