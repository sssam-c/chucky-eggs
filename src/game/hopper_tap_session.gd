class_name HopperTapSession
extends RefCounted

const HopperTapDay = preload("res://src/domain/hopper_tap_day.gd")
const AUTHORED_EGGS: Array[String] = [
	"chicken", "cuckoo", "sparrow", "plover", "chicken",
	"spoonbill", "cuckoo", "sparrow", "chicken", "spoonbill", "plover", "cuckoo",
]
const TARGET_SCORE := 10
const STARTING_PULLS := 12

var _day


func _init() -> void:
	restart()


func state() -> Dictionary:
	return _day.snapshot()


func submit_spoon(slot_index: int) -> Array[Dictionary]:
	return _day.resolve_spoon(slot_index)


func restart() -> void:
	_day = HopperTapDay.new(AUTHORED_EGGS, TARGET_SCORE, STARTING_PULLS)
