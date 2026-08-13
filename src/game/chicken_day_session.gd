class_name ChickenDaySession
extends RefCounted

const ChickenDay = preload("res://src/domain/chicken_day.gd")
const ProducerFlock = preload("res://src/domain/producer_flock.gd")
const SeededShuffler = preload("res://src/core/seeded_shuffler.gd")
const DEFAULT_DAY_SEED := 20260813

var _day
var _flock
var _day_seed: int
var _shuffler


func _init(day_seed := DEFAULT_DAY_SEED, flock = null, shuffler = null) -> void:
	_day_seed = day_seed
	_flock = flock if flock != null else ProducerFlock.new()
	_shuffler = shuffler
	_start_day()


func state() -> Dictionary:
	var current_state: Dictionary = _day.snapshot()
	current_state["producers"] = _flock.snapshot()
	return current_state


func submit_circuit(circuit_id: String) -> Array[Dictionary]:
	return _day.resolve_circuit(circuit_id)


func restart() -> void:
	_start_day()


func _start_day() -> void:
	var laid_eggs: Array[String] = _flock.lay_daily_egg_kinds()
	var day_shuffler = _shuffler if _shuffler != null else SeededShuffler.new(_day_seed)
	var shuffled_eggs: Array[String] = day_shuffler.shuffle_strings(laid_eggs)
	_day = ChickenDay.new(shuffled_eggs)
