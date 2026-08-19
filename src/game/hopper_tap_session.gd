class_name HopperTapSession
extends RefCounted

const HopperTapDay = preload("res://src/domain/hopper_tap_day.gd")
const AUTHORED_EGGS: Array[String] = [
	"chicken", "cuckoo", "sparrow", "plover", "chicken",
	"spoonbill", "cuckoo", "sparrow", "chicken", "spoonbill", "plover", "cuckoo",
]
const STARTING_HUNGER := 10
const TAPS_PER_PHASE := 5
const FIRST_HUNGER_INCREASE := 1
const HUNGER_GROWTH := 1

var _day


func _init() -> void:
	restart()


func state() -> Dictionary:
	return _day.snapshot()


func submit_spoon(slot_index: int) -> Array[Dictionary]:
	return _day.resolve_spoon(slot_index)


func restart() -> void:
	_day = HopperTapDay.new(
		AUTHORED_EGGS,
		STARTING_HUNGER,
		TAPS_PER_PHASE,
		FIRST_HUNGER_INCREASE,
		HUNGER_GROWTH
	)
