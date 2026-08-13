class_name ChickenDaySession
extends RefCounted

const ChickenDay = preload("res://src/domain/chicken_day.gd")
const ProducerFlock = preload("res://src/domain/producer_flock.gd")
const SeededShuffler = preload("res://src/core/seeded_shuffler.gd")
const DEFAULT_DAY_SEED := 20260813
const REWARD_SEED_STEP := 1009

var _day
var _flock
var _day_seed: int
var _shuffler
var _day_number := 1
var _phase := "day"
var _reward_choices: Array[Dictionary] = []


func _init(day_seed := DEFAULT_DAY_SEED, flock = null, shuffler = null) -> void:
	_day_seed = day_seed
	_flock = flock if flock != null else ProducerFlock.new()
	_shuffler = shuffler
	_start_day()


func state() -> Dictionary:
	var current_state: Dictionary = _day.snapshot()
	current_state["producers"] = _flock.snapshot()
	current_state["day_number"] = _day_number
	current_state["phase"] = _phase
	current_state["reward_choices"] = _reward_choices.duplicate(true)
	return current_state


func submit_circuit(circuit_id: String) -> Array[Dictionary]:
	if _phase != "day":
		return [{"type": "thwack_rejected", "reason": "wrong_phase"}]
	var events: Array[Dictionary] = _day.resolve_circuit(circuit_id)
	for event: Dictionary in events:
		if event.type != "day_ended":
			continue
		if event.succeeded:
			_phase = "reward"
			_reward_choices = _create_reward_choices()
		else:
			_phase = "failed"
	return events


func restart() -> void:
	if _phase == "reward":
		return
	_start_day()


func select_producer(kind: String) -> Array[Dictionary]:
	if _phase != "reward":
		return [{"type": "producer_selection_rejected", "reason": "wrong_phase"}]
	if not _reward_choices.any(
		func(choice: Dictionary) -> bool: return choice.kind == kind
	):
		return [{"type": "producer_selection_rejected", "reason": "not_offered"}]

	var producer: Dictionary = _flock.add_producer(kind)
	var daily_egg_count: int = _flock.lay_daily_egg_kinds().size()
	var events: Array[Dictionary] = [{
		"type": "producer_added",
		"producer": producer.duplicate(true),
		"flock_size": _flock.snapshot().size(),
		"daily_egg_count": daily_egg_count,
	}]
	_day_number += 1
	_start_day()
	events.append({
		"type": "day_started",
		"day_number": _day_number,
		"daily_egg_count": daily_egg_count,
		"production": _production_snapshot(),
	})
	return events


func _start_day() -> void:
	_phase = "day"
	_reward_choices.clear()
	var laid_eggs: Array[String] = _flock.lay_daily_egg_kinds()
	var current_day_seed: int = _day_seed + _day_number - 1
	var day_shuffler = _shuffler if _shuffler != null else SeededShuffler.new(current_day_seed)
	var shuffled_eggs: Array[String] = day_shuffler.shuffle_strings(laid_eggs)
	_day = ChickenDay.new(shuffled_eggs)


func _create_reward_choices() -> Array[Dictionary]:
	var reward_seed := _day_seed + _day_number * REWARD_SEED_STEP
	var ordered_kinds: Array[String] = SeededShuffler.new(reward_seed).shuffle_strings(
		ProducerFlock.PRODUCER_KINDS
	)
	var choices: Array[Dictionary] = []
	for kind: String in ordered_kinds.slice(0, 3):
		var choice := ProducerFlock.producer_for_kind(kind)
		choice.merge(ChickenDay.egg_definition(kind))
		choices.append(choice)
	return choices


func _production_snapshot() -> Array[Dictionary]:
	var production: Array[Dictionary] = []
	for producer: Dictionary in _flock.snapshot():
		var produced_egg := ChickenDay.egg_definition(String(producer.kind))
		var fact: Dictionary = producer.duplicate(true)
		fact.merge(produced_egg)
		production.append(fact)
	return production
