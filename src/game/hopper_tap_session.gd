class_name HopperTapSession
extends RefCounted

const HopperTapDay = preload("res://src/domain/hopper_tap_day.gd")
const ChickenDay = preload("res://src/domain/chicken_day.gd")
const SeededShuffler = preload("res://src/core/seeded_shuffler.gd")

const AUTHORED_EGGS: Array[String] = [
	"chicken", "cuckoo", "sparrow", "plover", "chicken",
	"spoonbill", "cuckoo", "sparrow", "chicken", "spoonbill", "plover", "cuckoo",
]
const SEEDED_BASE_EGGS: Array[String] = [
	"spoonbill", "chicken", "cuckoo", "sparrow", "plover", "chicken",
	"cuckoo", "plover", "spoonbill", "sparrow", "chicken", "cuckoo",
]
const REWARD_POOL: Array[String] = [
	"chicken", "cuckoo", "sparrow", "plover", "spoonbill", "woodpecker",
]
const DEFAULT_RUN_SEED := 20260820
const ROUND_COUNT := 2
const ROUND_ONE_HUNGER := 10
const ROUND_TWO_HUNGER := 12
const STARTING_HUNGER := ROUND_ONE_HUNGER
const TAPS_PER_PHASE := 5
const FIRST_HUNGER_INCREASE := 1
const HUNGER_GROWTH := 1
const REWARD_SEED_STEP := 104729
const ROUND_SEED_STEP := 209759

var _day
var _run_seed: int
var _round_number := 1
var _round_starting_hunger := ROUND_ONE_HUNGER
var _round_order: Array[String] = []
var _flock: Array[String] = []
var _reward_offers: Array[String] = []
var _chosen_reward := ""
var _awaiting_reward := false
var _run_ended := false
var _run_succeeded := false
var _shuffler
var _dev_mode := false
var _dev_starting_eggs: Array[String] = []
var _dev_starting_hunger := ROUND_TWO_HUNGER


func _init(run_seed := DEFAULT_RUN_SEED, shuffler = null) -> void:
	_run_seed = int(run_seed)
	_shuffler = shuffler
	restart()


static func create_dev_session(
	egg_kinds: Array[String], starting_hunger := ROUND_TWO_HUNGER
):
	assert(not egg_kinds.is_empty(), "A dev round needs at least one egg.")
	assert(starting_hunger > 0, "A dev round needs positive Hunger.")
	for kind: String in egg_kinds:
		assert(
			kind in REWARD_POOL and not ChickenDay.egg_definition(kind).is_empty(),
			"A dev round needs a current tabletop egg kind."
		)
	var session = HopperTapSession.new()
	session._dev_mode = true
	session._dev_starting_eggs = egg_kinds.duplicate()
	session._dev_starting_hunger = int(starting_hunger)
	session._restart_dev_round()
	return session


func state() -> Dictionary:
	var current_state: Dictionary = _day.snapshot()
	current_state["run_seed"] = _run_seed
	current_state["round_number"] = _round_number
	current_state["round_count"] = ROUND_COUNT
	current_state["round_starting_hunger"] = _round_starting_hunger
	current_state["round_egg_count"] = _round_order.size()
	current_state["round_order"] = _round_order.duplicate()
	current_state["reward_offers"] = _reward_offers.duplicate()
	current_state["chosen_reward"] = _chosen_reward
	current_state["awaiting_reward"] = _awaiting_reward
	current_state["run_ended"] = _run_ended
	current_state["run_succeeded"] = _run_succeeded
	current_state["dev_mode"] = _dev_mode
	current_state["dev_starting_eggs"] = _dev_starting_eggs.duplicate()
	current_state["dev_starting_hunger"] = _dev_starting_hunger
	return current_state


func submit_spoon(slot_index: int) -> Array[Dictionary]:
	if _awaiting_reward or _run_ended:
		return [{"type": "spoon_rejected", "reason": "run_phase"}]
	var events: Array[Dictionary] = _day.resolve_spoon(slot_index)
	if events.is_empty() or String(events[0].type) == "spoon_rejected":
		return events
	var round_state: Dictionary = _day.snapshot()
	if not bool(round_state.ended):
		return events
	events.append({
		"type": "round_ended",
		"round_number": _round_number,
		"succeeded": bool(round_state.succeeded),
	})
	if not bool(round_state.succeeded):
		_run_ended = true
		_run_succeeded = false
		events.append({
			"type": "run_ended",
			"round_number": _round_number,
			"succeeded": false,
		})
	elif _round_number == 1:
		_awaiting_reward = true
		events.append({
			"type": "reward_offered",
			"round_number": _round_number,
			"offers": _reward_offers.duplicate(),
		})
	else:
		_run_ended = true
		_run_succeeded = true
		events.append({
			"type": "run_ended",
			"round_number": _round_number,
			"succeeded": true,
		})
	return events


func choose_reward(choice_index: int) -> Array[Dictionary]:
	if not _awaiting_reward:
		return [{"type": "reward_rejected", "reason": "wrong_phase"}]
	if choice_index < 0 or choice_index >= _reward_offers.size():
		return [{"type": "reward_rejected", "reason": "not_offered"}]
	_chosen_reward = _reward_offers[choice_index]
	_flock.append(_chosen_reward)
	_awaiting_reward = false
	_round_number = 2
	_start_round()
	return [
		{
			"type": "reward_selected",
			"kind": _chosen_reward,
			"round_egg_count": _flock.size(),
		},
		{
			"type": "round_started",
			"round_number": _round_number,
			"starting_hunger": _round_starting_hunger,
			"egg_count": _round_order.size(),
		},
	]


func restart() -> void:
	if _dev_mode:
		_restart_dev_round()
		return
	_round_number = 1
	_flock = (
		AUTHORED_EGGS.duplicate() if _shuffler != null
		else SEEDED_BASE_EGGS.duplicate()
	)
	_reward_offers = _shuffle_strings(REWARD_POOL, _run_seed + REWARD_SEED_STEP).slice(0, 3)
	_chosen_reward = ""
	_awaiting_reward = false
	_run_ended = false
	_run_succeeded = false
	_start_round()


func start_new_run(run_seed := -1) -> void:
	_run_seed = int(run_seed) if int(run_seed) >= 0 else _run_seed + 1
	_dev_mode = false
	_dev_starting_eggs.clear()
	_dev_starting_hunger = ROUND_TWO_HUNGER
	restart()


func retry_round() -> Array[Dictionary]:
	if not bool(_day.snapshot().ended) or _awaiting_reward:
		return [{"type": "retry_rejected", "reason": "round_active"}]
	_run_ended = false
	_run_succeeded = false
	_start_round()
	return [{
		"type": "round_started",
		"round_number": _round_number,
		"starting_hunger": _round_starting_hunger,
		"egg_count": _round_order.size(),
		"retried": true,
	}]


func _start_round() -> void:
	if _dev_mode:
		_round_starting_hunger = _dev_starting_hunger
		_round_order = _dev_starting_eggs.duplicate()
		_day = HopperTapDay.new(
			_round_order,
			_round_starting_hunger,
			TAPS_PER_PHASE,
			FIRST_HUNGER_INCREASE,
			HUNGER_GROWTH
		)
		return
	_round_starting_hunger = (
		ROUND_ONE_HUNGER if _round_number == 1 else ROUND_TWO_HUNGER
	)
	_round_order = _shuffle_strings(
		_flock, _run_seed + (_round_number - 1) * ROUND_SEED_STEP
	)
	_day = HopperTapDay.new(
		_round_order,
		_round_starting_hunger,
		TAPS_PER_PHASE,
		FIRST_HUNGER_INCREASE,
		HUNGER_GROWTH
	)


func _restart_dev_round() -> void:
	_round_number = ROUND_COUNT
	_flock = _dev_starting_eggs.duplicate()
	_reward_offers.clear()
	_chosen_reward = ""
	_awaiting_reward = false
	_run_ended = false
	_run_succeeded = false
	_start_round()


func _shuffle_strings(values: Array[String], seed_value: int) -> Array[String]:
	if _shuffler != null:
		return _shuffler.shuffle_strings(values)
	return SeededShuffler.new(seed_value).shuffle_strings(values)
