class_name ChickenDaySession
extends RefCounted

const ChickenDay = preload("res://src/domain/chicken_day.gd")
const ProducerFlock = preload("res://src/domain/producer_flock.gd")
const SeededChanceRoller = preload("res://src/core/seeded_chance_roller.gd")
const SeededShuffler = preload("res://src/core/seeded_shuffler.gd")
const DEFAULT_DAY_SEED := 20260813
const REWARD_SEED_STEP := 1009
const DOUBLE_YOLK_SEED_STEP := 9
const DAY_ONE_TARGET := 15
const LATER_DAY_TARGET := 20
const HAIRPIN_REFIT_DAY := 3
const RECRUIT_PRICE := 3
const RETIRE_PRICE := 2
const EXTRA_THWACK_PRICE := 5

var _day
var _flock
var _day_seed: int
var _shuffler
var _day_number := 1
var _phase := "day"
var _shop_recruitment: Array[Dictionary] = []
var _pending_merges: Dictionary = {}
var _cash := 0
var _last_cash_awarded := 0
var _machine_slot_count := ChickenDay.BASE_SLOT_COUNT
var _starting_thwacks := ChickenDay.STARTING_THWACKS
var _factory_upgrades: Dictionary = {"extra_thwack": false}


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
	_machine_slot_count = (
		ChickenDay.HAIRPIN_SLOT_COUNT
		if _day_number >= HAIRPIN_REFIT_DAY
		else ChickenDay.BASE_SLOT_COUNT
	)
	_start_day()


func state() -> Dictionary:
	var current_state: Dictionary = _day.snapshot()
	current_state["producers"] = _flock.snapshot()
	current_state["day_number"] = _day_number
	current_state["next_day_target_score"] = _target_for_day(_day_number + 1)
	current_state["phase"] = _phase
	current_state["shop_stock"] = _shop_stock()
	current_state["quality_groups"] = _quality_groups_snapshot()
	current_state["pending_merges"] = _pending_merges_snapshot()
	current_state["projected_flock_size"] = _flock.snapshot().size() - _pending_merge_count()
	current_state["cash"] = _cash
	current_state["last_cash_awarded"] = _last_cash_awarded
	current_state["machine_slot_count"] = _machine_slot_count
	current_state["starting_thwacks"] = _starting_thwacks
	current_state["factory_upgrades"] = _factory_upgrades.duplicate(true)
	current_state["machine_circuits"] = ChickenDay.circuits_for_slot_count(_machine_slot_count)
	current_state["machine_refit_due"] = (
		_phase == "shop"
		and _day_number + 1 == HAIRPIN_REFIT_DAY
		and _machine_slot_count == ChickenDay.BASE_SLOT_COUNT
	)
	current_state["machine_refit_complete"] = _machine_slot_count == ChickenDay.HAIRPIN_SLOT_COUNT
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
			_phase = "shop"
			_shop_recruitment = _create_recruitment_stock()
			_pending_merges.clear()
		else:
			_phase = "failed"
	if not ended_event.is_empty() and ended_event.succeeded:
		_last_cash_awarded = int(ended_event.remaining_thwacks)
		_cash += _last_cash_awarded
		events.append({
			"type": "cash_awarded",
			"amount": _last_cash_awarded,
			"cash_total": _cash,
			"remaining_thwacks": int(ended_event.remaining_thwacks),
		})
	return events


func restart() -> void:
	if _phase == "shop":
		return
	_start_day()


func purchase_producer(kind: String) -> Array[Dictionary]:
	if _phase != "shop":
		return [_purchase_rejected("recruitment", kind, "wrong_phase")]
	if not _shop_recruitment.any(
		func(choice: Dictionary) -> bool: return choice.kind == kind
	):
		return [_purchase_rejected("recruitment", kind, "not_offered")]
	if _cash < RECRUIT_PRICE:
		return [_purchase_rejected("recruitment", kind, "insufficient_cash")]

	var producer: Dictionary = _flock.add_producer(kind)
	_cash -= RECRUIT_PRICE
	_shop_recruitment = _shop_recruitment.filter(
		func(choice: Dictionary) -> bool: return choice.kind != kind
	)
	return [{
		"type": "producer_purchased",
		"producer": producer.duplicate(true),
		"price": RECRUIT_PRICE,
		"cash_total": _cash,
		"flock_size": _flock.snapshot().size(),
		"daily_egg_count": _flock.lay_daily_egg_kinds().size(),
	}]


func purchase_retirement(kind: String) -> Array[Dictionary]:
	if _phase != "shop":
		return [_purchase_rejected("retirement", kind, "wrong_phase")]
	var tier := _lowest_unreserved_tier(kind)
	if kind not in ProducerFlock.PRODUCER_KINDS or tier < 0:
		return [_purchase_rejected("retirement", kind, "not_available")]
	if _flock.snapshot().size() <= 1:
		return [_purchase_rejected("retirement", kind, "last_bird")]
	if _cash < RETIRE_PRICE:
		return [_purchase_rejected("retirement", kind, "insufficient_cash")]
	var retired: Dictionary = _flock.remove_producer(kind, tier)
	_cash -= RETIRE_PRICE
	return [{
		"type": "producer_retired",
		"producer": retired,
		"price": RETIRE_PRICE,
		"cash_total": _cash,
		"flock_size": _flock.snapshot().size(),
		"daily_egg_count": _flock.lay_daily_egg_kinds().size(),
	}]


func queue_merge(kind: String, tier: int) -> Array[Dictionary]:
	if _phase != "shop":
		return [_purchase_rejected("merge", "%s_%d" % [kind, tier], "wrong_phase")]
	if _unreserved_count(kind, tier) < 2:
		return [_purchase_rejected("merge", "%s_%d" % [kind, tier], "not_available")]
	var offer := _merge_offer(kind, tier)
	var price := int(offer.price)
	if _cash < price:
		return [_purchase_rejected("merge", "%s_%d" % [kind, tier], "insufficient_cash")]
	_cash -= price
	var key := _merge_key(kind, tier)
	_pending_merges[key] = int(_pending_merges.get(key, 0)) + 1
	return [{
		"type": "producer_merge_queued",
		"kind": kind,
		"tier": tier,
		"output_tier": tier + 1,
		"price": price,
		"pair_count": int(_pending_merges[key]),
		"projected_flock_size": _flock.snapshot().size() - _pending_merge_count(),
		"cash_total": _cash,
		"output": offer,
	}]


func purchase_factory_upgrade(upgrade_id: String) -> Array[Dictionary]:
	if _phase != "shop":
		return [_purchase_rejected("factory_upgrade", upgrade_id, "wrong_phase")]
	if upgrade_id != "extra_thwack" or bool(_factory_upgrades.extra_thwack):
		return [_purchase_rejected("factory_upgrade", upgrade_id, "not_available")]
	if _cash < EXTRA_THWACK_PRICE:
		return [_purchase_rejected("factory_upgrade", upgrade_id, "insufficient_cash")]
	_cash -= EXTRA_THWACK_PRICE
	_factory_upgrades["extra_thwack"] = true
	_starting_thwacks += 1
	return [{
		"type": "factory_upgrade_purchased",
		"upgrade_id": upgrade_id,
		"price": EXTRA_THWACK_PRICE,
		"cash_total": _cash,
		"starting_thwacks": _starting_thwacks,
	}]


func leave_shop() -> Array[Dictionary]:
	if _phase != "shop":
		return [{"type": "shop_leave_rejected", "reason": "wrong_phase"}]

	var events: Array[Dictionary] = _apply_pending_merges()
	var daily_egg_count: int = _flock.lay_daily_egg_kinds().size()
	_day_number += 1
	if _day_number == HAIRPIN_REFIT_DAY and _machine_slot_count == ChickenDay.BASE_SLOT_COUNT:
		_machine_slot_count = ChickenDay.HAIRPIN_SLOT_COUNT
		events.append({
			"type": "machine_refitted",
			"day_number": _day_number,
			"slot_count": _machine_slot_count,
			"circuits": ChickenDay.circuits_for_slot_count(_machine_slot_count),
		})
	_start_day()
	events.append({
		"type": "day_started",
		"day_number": _day_number,
		"target_score": _day.snapshot().target_score,
		"daily_egg_count": daily_egg_count,
		"slot_count": _machine_slot_count,
		"production": _production_snapshot(),
	})
	return events


func _start_day() -> void:
	_phase = "day"
	_shop_recruitment.clear()
	_pending_merges.clear()
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
		_machine_slot_count,
		_starting_thwacks
	)


func _target_for_day(day_number: int) -> int:
	return DAY_ONE_TARGET if day_number == 1 else LATER_DAY_TARGET


func _create_recruitment_stock() -> Array[Dictionary]:
	var reward_seed := _day_seed + _day_number * REWARD_SEED_STEP
	var ordered_kinds: Array[String] = SeededShuffler.new(reward_seed).shuffle_strings(
		ProducerFlock.PRODUCER_KINDS
	)
	var choices: Array[Dictionary] = []
	for kind: String in ordered_kinds.slice(0, 3):
		var choice := ProducerFlock.producer_for_kind(kind)
		choice.merge(ChickenDay.egg_definition(kind))
		choice["price"] = RECRUIT_PRICE
		choices.append(choice)
	return choices


func _shop_stock() -> Dictionary:
	if _phase != "shop":
		return {}
	var recruitment := _shop_recruitment.duplicate(true)
	var factory_offers: Array[Dictionary] = []
	if not bool(_factory_upgrades.extra_thwack):
		factory_offers.append({
			"id": "extra_thwack",
			"price": EXTRA_THWACK_PRICE,
			"current_starting_thwacks": _starting_thwacks,
			"next_starting_thwacks": _starting_thwacks + 1,
		})
	return {
		"recruitment": recruitment,
		"retirement": {"price": RETIRE_PRICE},
		"pairing_sources": _pairing_sources(),
		"factory_upgrades": factory_offers,
	}


func _pairing_sources() -> Array[Dictionary]:
	var sources: Array[Dictionary] = []
	for group: Dictionary in _flock.quality_groups_snapshot():
		var kind := String(group.kind)
		var tier := int(group.tier)
		var available_count := _unreserved_count(kind, tier)
		var eligible_partners: Array[Dictionary] = []
		if available_count >= 2:
			var partner := _merge_offer(kind, tier)
			partner["available_count"] = available_count - 1
			eligible_partners.append(partner)
		sources.append({
			"id": _merge_key(kind, tier),
			"kind": kind,
			"tier": tier,
			"available_count": available_count,
			"available_pair_count": floori(available_count / 2.0),
			"eligible_partners": eligible_partners,
		})
	return sources


func _quality_groups_snapshot() -> Array[Dictionary]:
	var groups: Array[Dictionary] = _flock.quality_groups_snapshot()
	for group: Dictionary in groups:
		var definition := ChickenDay.egg_definition(String(group.kind))
		var exact_points := float(definition.points) * float(group.quality_multiplier)
		group["exact_points"] = exact_points
		group["points"] = floori(exact_points)
		group["display_double_yolk_percent"] = floori(float(group.double_yolk_chance) * 100.0)
		group["reserved_count"] = _reserved_bird_count(String(group.kind), int(group.tier))
	return groups


func _merge_offer(kind: String, tier: int) -> Dictionary:
	var definition := ChickenDay.egg_definition(kind)
	var current_multiplier := ProducerFlock.quality_multiplier(tier)
	var next_multiplier := ProducerFlock.quality_multiplier(tier + 1)
	var current_chance := ProducerFlock.double_yolk_chance(kind, tier)
	var next_chance := ProducerFlock.double_yolk_chance(kind, tier + 1)
	return {
		"id": "%s_%d" % [kind, tier],
		"kind": kind,
		"tier": tier,
		"output_tier": tier + 1,
		"price": tier + 1,
		"current_exact_points": float(definition.points) * current_multiplier,
		"current_points": floori(float(definition.points) * current_multiplier),
		"next_exact_points": float(definition.points) * next_multiplier,
		"next_points": floori(float(definition.points) * next_multiplier),
		"current_double_yolk_chance": current_chance,
		"current_double_yolk_percent": floori(current_chance * 100.0),
		"next_double_yolk_chance": next_chance,
		"next_double_yolk_percent": floori(next_chance * 100.0),
	}


func _pending_merges_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for kind: String in ProducerFlock.PRODUCER_KINDS:
		for group: Dictionary in _flock.quality_groups_snapshot():
			if group.kind != kind:
				continue
			var tier := int(group.tier)
			var pair_count := int(_pending_merges.get(_merge_key(kind, tier), 0))
			if pair_count > 0:
				result.append({"kind": kind, "tier": tier, "pair_count": pair_count})
	return result


func _pending_merge_count() -> int:
	var total := 0
	for pair_count: int in _pending_merges.values():
		total += pair_count
	return total


func _reserved_bird_count(kind: String, tier: int) -> int:
	return int(_pending_merges.get(_merge_key(kind, tier), 0)) * 2


func _unreserved_count(kind: String, tier: int) -> int:
	return _flock.count_producers(kind, tier) - _reserved_bird_count(kind, tier)


func _lowest_unreserved_tier(kind: String) -> int:
	for group: Dictionary in _flock.quality_groups_snapshot():
		if group.kind == kind and _unreserved_count(kind, int(group.tier)) > 0:
			return int(group.tier)
	return -1


func _merge_key(kind: String, tier: int) -> String:
	return "%s:%d" % [kind, tier]


func _apply_pending_merges() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for pending: Dictionary in _pending_merges_snapshot():
		for pair_index in range(int(pending.pair_count)):
			var producer: Dictionary = _flock.merge_producers(pending.kind, pending.tier)
			assert(not producer.is_empty(), "A queued merge must remain valid until shop exit.")
			events.append({
				"type": "producer_merged",
				"kind": pending.kind,
				"input_tier": pending.tier,
				"producer": producer,
				"quality": _merge_offer(pending.kind, pending.tier),
			})
	_pending_merges.clear()
	return events


func _purchase_rejected(category: String, item_id: String, reason: String) -> Dictionary:
	return {
		"type": "shop_purchase_rejected",
		"category": category,
		"item_id": item_id,
		"reason": reason,
	}


func _production_snapshot() -> Array[Dictionary]:
	var production: Array[Dictionary] = []
	for producer: Dictionary in _flock.snapshot():
		var produced_egg := ChickenDay.egg_definition(String(producer.kind))
		var tier := int(producer.tier)
		var multiplier := ProducerFlock.quality_multiplier(tier)
		produced_egg["tier"] = tier
		produced_egg["exact_points"] = float(produced_egg.points) * multiplier
		produced_egg["points"] = floori(float(produced_egg.points) * multiplier)
		produced_egg["double_yolk_chance"] = ProducerFlock.double_yolk_chance(
			String(producer.kind), tier
		)
		var fact: Dictionary = producer.duplicate(true)
		fact.merge(produced_egg)
		production.append(fact)
	return production
